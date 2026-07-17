require "yaml"
require "date"
require "time"
require_relative "version"
require_relative "control_manifest"
require_relative "install_state"

module T40Starter
  # Human summary of an install: changed capabilities, verification evidence,
  # deferred decisions, required human follow-up and next steps. Reads the
  # target's control manifest; apply/verify results are attached when the
  # stages ran in the same invocation.
  class Report
    def initialize(target:, applied_actions: nil, verify_results: nil)
      @target = target
      @applied_actions = applied_actions
      @verify_results = verify_results
    end

    def control_manifest
      @control_manifest ||= begin
        path = File.join(@target, ControlManifest::RELATIVE_PATH)
        raise Error, "control manifest not found: #{path} (run apply first)" unless File.file?(path)

        YAML.safe_load_file(path, permitted_classes: [ Date, Time ])
      end
    end

    def controls = Array(control_manifest["controls"])

    def deferred_controls = controls.select { |control| control["status"] == "deferred" }

    def status_counts
      counts = Hash.new(0)
      controls.each { |control| counts[control["status"]] += 1 }
      counts
    end

    def to_h
      {
        "stage" => "report",
        "starter_version" => control_manifest["starter_version"],
        "installed_at" => control_manifest["installed_at"],
        "manifest_sha256" => control_manifest["manifest_sha256"],
        "installation_status" => install_state["status"] || "unknown",
        "readiness" => readiness,
        "controls_summary" => status_counts,
        "deferred" => deferred_controls.map { |control| control.slice("id", "name", "owner", "reference") },
        "follow_up" => follow_up_items,
        "next_steps" => next_steps
      }
    end

    def render
      lines = []
      lines << "T40 Enterprise Application Starter #{control_manifest['starter_version']} — install report"
      lines << "Target: #{@target}"
      lines << "Installed at: #{control_manifest['installed_at']}"
      lines << "Installation status: #{install_state['status'] || 'unknown'}"
      lines << "Production ready: #{readiness['production_ready'] ? 'yes' : 'no'}"
      if readiness["blocking_controls"].any?
        lines << "Production blockers: #{readiness['blocking_controls'].join(', ')}"
      end
      lines << ""
      lines.concat(changed_capabilities_section)
      lines.concat(verification_section)
      lines.concat(deferred_section)
      lines.concat(follow_up_section)
      lines.concat(next_steps_section)
      lines << ""
      lines << "This starter supports evidence gathering; it does not by itself provide"
      lines << "ISO 27001, SOC 2, Cyber Essentials, WCAG conformance or legal compliance."
      lines.join("\n") + "\n"
    end

    private
      def install_state
        @install_state ||= begin
          path = File.join(@target, InstallState::RELATIVE_PATH)
          File.file?(path) ? YAML.safe_load_file(path, permitted_classes: [ Date, Time ]) : {}
        end
      end

      def readiness
        control_readiness = ControlManifest.production_readiness(control_manifest)
        installation_verified = install_state["status"] == "installation_verified"
        control_readiness.merge(
          "installation_verified" => installation_verified,
          "production_ready" => installation_verified && control_readiness["production_ready"]
        )
      end

      def changed_capabilities_section
        lines = [ "Changed capabilities" ]
        if @applied_actions
          if @applied_actions.empty?
            lines << "  No changes this run — the target already matched this starter version and manifest."
          else
            files = @applied_actions.count { |action| action.type != :edit }
            edits = @applied_actions.count { |action| action.type == :edit }
            lines << "  #{files} file(s) installed, #{edits} marked edit(s) applied."
          end
        end
        counts = status_counts
        lines << "  Controls: #{counts['enabled'] + counts['verified']} active, " \
                 "#{counts['deferred']} deferred, #{counts['not_applicable']} not applicable."
        by_category = controls.reject { |control| control["status"] == "not_applicable" }
                              .group_by { |control| control["category"] }
        lines << "  Active control categories: #{by_category.keys.sort.join(', ')}."
        lines << ""
        lines
      end

      def verification_section
        lines = [ "Verification evidence" ]
        if @verify_results
          @verify_results.each do |result|
            lines << format("  %-14s %-5s %8.2fs", result.name, result.status, result.duration)
          end
        else
          evidence = controls.map { |control| control['evidence'] }.compact.uniq
          if evidence.empty?
            lines << "  Not yet verified — run: bin/setup-enterprise verify --target #{@target}"
          else
            evidence.each { |entry| lines << "  #{entry}" }
          end
        end
        lines << ""
        lines
      end

      def deferred_section
        lines = [ "Deferred decisions (owner required)" ]
        if deferred_controls.empty?
          lines << "  None."
        else
          deferred_controls.each do |control|
            lines << "  #{control['id']}  #{control['name']}"
            lines << "        owner: #{control['owner']} — see #{control['reference']}"
          end
        end
        lines << ""
        lines
      end

      def follow_up_section
        [ "Required human follow-up" ] + follow_up_items.map { |item| "  - #{item}" } + [ "" ]
      end

      def next_steps_section
        [ "Next steps" ] + next_steps.map { |step| "  - #{step}" } + [ "" ]
      end

      def follow_up_items
        items = []
        items << "Assign owners and dates to the #{deferred_controls.size} deferred control(s) above." if deferred_controls.any?
        items << "Complete the documentation templates under docs/ (status: template)."
        items << "Provide the secret references listed in config/t40/required-environment.yml per environment."
        items << "Run the DPIA screening in docs/privacy/dpia-screening.md before production."
        items
      end

      def next_steps
        [
          "bin/rails db:prepare",
          "bin/rails t40:bootstrap ADMIN_EMAIL=you@example.com ACCOUNT_NAME=\"Your Account\"",
          "bundle exec rspec",
          "bin/setup-enterprise verify --target #{@target}"
        ]
      end
  end
end
