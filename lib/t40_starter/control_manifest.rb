require "yaml"
require "fileutils"
require "time"
require "date"
require_relative "version"
require_relative "verifier"

module T40Starter
  # Builds and writes config/t40/control-manifest.yml in the target app by
  # merging the starter control catalogue (controls.yml) with the manifest's
  # module selections. The verify stage later attaches evidence via
  # ControlManifest.attach_evidence.
  class ControlManifest
    RELATIVE_PATH = File.join("config", "t40", "control-manifest.yml").freeze
    STATUSES = %w[enabled verified deferred not_applicable].freeze
    DEFAULT_OWNER = "project team"

    def initialize(manifest:, starter_root: T40Starter.root, controls_path: nil, now: Time.now)
      @manifest = manifest
      @starter_root = starter_root
      @controls_path = controls_path || File.join(starter_root, "lib", "t40_starter", "controls.yml")
      @now = now
    end

    def catalogue
      @catalogue ||= begin
        data = YAML.safe_load_file(@controls_path)
        controls = data.is_a?(Hash) ? data["controls"] : nil
        raise Error, "control catalogue has no controls list: #{@controls_path}" unless controls.is_a?(Array) && controls.any?

        validate_catalogue!(controls)
        controls
      end
    end

    def build
      {
        "starter_version" => T40Starter::VERSION,
        "manifest_version" => 1,
        "manifest_sha256" => @manifest.sha256,
        "installed_at" => @now.getutc.iso8601,
        "controls" => control_entries
      }
    end

    # Writes the control manifest unless the existing one already records
    # this starter version and manifest digest (idempotent re-apply keeps
    # installed_at and any verify evidence intact). Returns true if written.
    def write(target)
      path = File.join(target, RELATIVE_PATH)
      existing = nil
      if File.file?(path)
        existing = YAML.safe_load_file(path, permitted_classes: [ Date, Time ])
        if existing.is_a?(Hash) &&
           existing["manifest_sha256"] == @manifest.sha256 &&
           existing["starter_version"] == T40Starter::VERSION
          return false
        end
      end
      FileUtils.mkdir_p(File.dirname(path))
      desired = build
      desired = reconcile(desired, existing) if existing.is_a?(Hash)
      File.write(path, desired.to_yaml)
      true
    end

    # Called by the verify stage after every check has passed: enabled
    # controls become verified and carry the evidence summary. Deferred and
    # not-applicable controls are untouched — verification cannot discharge
    # a human decision.
    def self.attach_evidence(target:, checks:, at: Time.now)
      path = File.join(target, RELATIVE_PATH)
      raise Error, "control manifest not found: #{path} (run apply first)" unless File.file?(path)

      data = YAML.safe_load_file(path, permitted_classes: [ Date, Time ])
      raise Error, "control manifest is not a mapping: #{path}" unless data.is_a?(Hash)

      results = Array(checks).map { |check| check.respond_to?(:to_h) ? check.to_h : check }
      by_name = results.to_h { |check| [ check["name"] || check[:name], check ] }
      Array(data["controls"]).each do |control|
        next unless %w[enabled verified].include?(control["status"])

        required = Array(control["evidence_checks"])
        next if required.empty?

        evidence = required.filter_map do |name|
          check = by_name[name]
          next unless check && (check["status"] || check[:status]) == "pass"

          {
            "check" => name,
            "status" => "pass",
            "duration" => check["duration"] || check[:duration],
            "verified_at" => at.getutc.iso8601
          }.compact
        end
        next unless evidence.size == required.size

        control["status"] = "verified"
        control["evidence"] = evidence
      end
      File.write(path, data.to_yaml)
      data
    end

    def self.production_readiness(data)
      blockers = Array(data["controls"]).select do |control|
        control["production_gate"] == true && !%w[verified not_applicable].include?(control["status"])
      end
      {
        "production_ready" => blockers.empty?,
        "blocking_controls" => blockers.map { |control| control["id"] }
      }
    end

    private
      PROJECT_FIELDS = %w[decision notes exception implementation].freeze

      def reconcile(desired, existing)
        previous = Array(existing["controls"]).to_h { |control| [ control["id"], control ] }
        desired["controls"].each do |control|
          old = previous[control["id"]]
          next unless old

          PROJECT_FIELDS.each do |field|
            control[field] = old[field] if old.key?(field)
          end
          next if control["status"] == "not_applicable"

          control["owner"] = old["owner"] if old["owner"].to_s.strip != ""
          if valid_existing_evidence?(old, control)
            control["status"] = "verified"
            control["evidence"] = old["evidence"]
          end
        end
        desired
      end

      def valid_existing_evidence?(old, desired)
        return false unless old["status"] == "verified" && desired["status"] == "enabled"
        return false unless Array(old["evidence_checks"]) == Array(desired["evidence_checks"])

        evidence = Array(old["evidence"])
        checks = evidence.select { |entry| entry["status"] == "pass" }.map { |entry| entry["check"] }
        (Array(desired["evidence_checks"]) - checks).empty?
      end

      def control_entries
        catalogue.map do |control|
          status, owner, reason = resolve(control)
          {
            "id" => control.fetch("id"),
            "name" => control.fetch("name"),
            "category" => control.fetch("category"),
            "status" => status,
            "owner" => owner,
            "evidence" => nil,
            "evidence_checks" => Array(control["evidence_checks"]),
            "production_gate" => control["production_gate"] == true,
            "reason" => reason,
            "reference" => control.fetch("reference")
          }
        end
      end

      def resolve(control)
        applicable, reason = applicable?(control)
        return [ "not_applicable", nil, reason ] unless applicable

        case control.fetch("install_status")
        when "enabled"
          [ "enabled", nil, nil ]
        when "deferred"
          [ "deferred", control.fetch("owner_default", DEFAULT_OWNER), nil ]
        when "conditional"
          module_name = control.fetch("module")
          if @manifest.module_selected?(module_name)
            [ "enabled", nil, nil ]
          else
            [ "not_applicable", nil, "module #{module_name} not selected in the install manifest" ]
          end
        else
          raise Error, "control #{control['id']} has unknown install_status #{control['install_status'].inspect}"
        end
      end

      def applicable?(control)
        conditions = control["applies_when"]
        return [ true, nil ] unless conditions.is_a?(Hash) && conditions.any?

        if conditions.key?("data_risk")
          key = conditions["data_risk"].to_s
          selected = @manifest.data_risk[key] == true
          return [ selected, "manifest data_risk.#{key} is false" ] unless selected
        end
        if conditions.key?("deployment_profile")
          expected = conditions["deployment_profile"].to_s
          selected = @manifest.deployment_profile == expected
          return [ selected, "manifest deployment.profile is #{@manifest.deployment_profile}, not #{expected}" ] unless selected
        end
        if conditions.key?("tenancy_mode")
          expected = conditions["tenancy_mode"].to_s
          selected = @manifest.tenancy_mode == expected
          return [ selected, "manifest tenancy.mode is #{@manifest.tenancy_mode}, not #{expected}" ] unless selected
        end

        [ true, nil ]
      end

      def validate_catalogue!(controls)
        ids = controls.map { |control| control["id"] }
        duplicates = ids.tally.select { |_id, count| count > 1 }.keys
        raise Error, "duplicate control ids: #{duplicates.join(', ')}" if duplicates.any?

        controls.each do |control|
          id = control["id"].to_s
          raise Error, "control has invalid id: #{id.inspect}" unless id.match?(/\A[A-Z]+-\d{2}\z/)
          Array(control["evidence_checks"]).each do |check|
            unless Verifier::CHECK_NAMES.include?(check)
              raise Error, "control #{id} references unknown evidence check #{check.inspect}"
            end
          end
          reference = control["reference"].to_s
          raise Error, "control #{id} has no reference" if reference.empty?
          next if reference_exists?(reference)

          raise Error, "control #{id} references missing evidence path: #{reference}"
        end
      end

      def reference_exists?(reference)
        roots = if reference.start_with?("modules/")
          [ @starter_root ]
        else
          [ File.join(@starter_root, "template"), @starter_root ]
        end
        roots.any? do |root|
          path = File.join(root, reference)
          File.file?(path) || File.file?("#{path}.t40erb")
        end
      end
  end
end
