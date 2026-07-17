require "date"
require "fileutils"
require "yaml"
require "time"
require_relative "version"

module T40Starter
  # Durable state for the installer workflow. This is deliberately separate
  # from the control manifest: install state answers whether setup completed,
  # while the control manifest records the state of individual controls.
  class InstallState
    RELATIVE_PATH = File.join("config", "t40", "install-state.yml").freeze
    STATUSES = %w[incomplete installed_unverified installation_verified].freeze

    def initialize(target:, manifest:, now: Time.now)
      @target = target
      @manifest = manifest
      @now = now
    end

    def path = File.join(@target, RELATIVE_PATH)

    def exists? = File.file?(path)

    def data
      return {} unless exists?

      YAML.safe_load_file(path, permitted_classes: [ Date, Time ]) || {}
    end

    def incomplete? = data["status"] == "incomplete"

    def mark_installed(changed:)
      existing = data
      if Array(changed).empty? &&
         existing["starter_version"] == VERSION &&
         existing["manifest_sha256"] == @manifest.sha256 &&
         existing["status"] == "installation_verified"
        return false
      end

      write_status("installed_unverified", changed: changed)
    end

    def mark_verified
      write_status("installation_verified", changed: data["changed"] || [])
    end

    def mark_incomplete(failed_stage:, changed:, error:)
      write_status("incomplete", failed_stage: failed_stage, changed: changed, error: error)
    end

    private
      def write_status(status, failed_stage: nil, changed: [], error: nil)
        raise Error, "unknown install status: #{status}" unless STATUSES.include?(status)

        existing = data
        if existing["starter_version"] == VERSION &&
           existing["manifest_sha256"] == @manifest.sha256 &&
           existing["status"] == status
          return false
        end

        payload = {
          "starter_version" => VERSION,
          "manifest_sha256" => @manifest.sha256,
          "status" => status,
          "updated_at" => @now.getutc.iso8601,
          "changed" => Array(changed),
          "failed_stage" => failed_stage,
          "error" => error
        }.compact
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, payload.to_yaml)
        true
      end
  end
end
