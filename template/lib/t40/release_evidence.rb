require "bundler"
require "date"
require "digest"
require "fileutils"
require "json"
require "open3"
require "pathname"
require "yaml"

module T40
  class ReleaseEvidence
    OUTPUT_DIR = Rails.root.join("tmp", "release-evidence")
    BLOCKING_SEVERITIES = %w[critical high].freeze

    def initialize(release_id: T40::Runtime.release, required_checks: [], approvals: [],
      output_dir: OUTPUT_DIR,
      findings_path: Rails.root.join("tmp", "security-findings.json"),
      exceptions_path: Rails.root.join("config", "t40", "security-exceptions.yml"))
      @release_id = release_id
      @required_checks = required_checks
      @approvals = approvals
      @output_dir = Pathname(output_dir)
      @findings_path = Pathname(findings_path)
      @exceptions_path = Pathname(exceptions_path)
    end

    def generate!
      blockers = unapproved_blockers
      raise "release blocked by security findings: #{blockers.map { |finding| finding["id"] }.join(", ")}" if blockers.any?

      FileUtils.mkdir_p(@output_dir)
      sbom = build_sbom
      sbom_path = @output_dir.join("sbom.spdx.json")
      File.write(sbom_path, JSON.pretty_generate(sbom) + "\n")
      evidence = {
        "release_id" => @release_id,
        "source_revision" => source_revision,
        "generated_at" => Time.current.utc.iso8601,
        "required_checks" => @required_checks,
        "approvals" => @approvals,
        "sbom" => sbom_path.basename.to_s,
        "sbom_sha256" => Digest::SHA256.file(sbom_path).hexdigest,
        "security_blockers" => []
      }
      evidence_path = @output_dir.join("release-evidence.json")
      File.write(evidence_path, JSON.pretty_generate(evidence) + "\n")
      { sbom: sbom_path, evidence: evidence_path }
    end

    private
      def build_sbom
        packages = Bundler.load.specs.sort_by { |spec| [ spec.name, spec.version.to_s ] }.map do |spec|
          {
            "SPDXID" => "SPDXRef-Gem-#{spdx_id(spec.name)}-#{spdx_id(spec.version.to_s)}",
            "name" => spec.name,
            "versionInfo" => spec.version.to_s,
            "downloadLocation" => "NOASSERTION",
            "filesAnalyzed" => false,
            "licenseConcluded" => "NOASSERTION",
            "licenseDeclared" => "NOASSERTION",
            "externalRefs" => [ {
              "referenceCategory" => "PACKAGE-MANAGER",
              "referenceType" => "purl",
              "referenceLocator" => "pkg:gem/#{spec.name}@#{spec.version}"
            } ]
          }
        end
        {
          "spdxVersion" => "SPDX-2.3",
          "dataLicense" => "CC0-1.0",
          "SPDXID" => "SPDXRef-DOCUMENT",
          "name" => "#{Rails.application.class.module_parent_name}-#{@release_id}",
          "documentNamespace" => "https://t40.example/spdx/#{spdx_id(@release_id)}-#{source_revision}",
          "creationInfo" => {
            "created" => Time.current.utc.iso8601,
            "creators" => [ "Tool: T40::ReleaseEvidence/#{T40::Installation.starter_version}" ]
          },
          "packages" => packages
        }
      end

      def unapproved_blockers
        findings.select do |finding|
          BLOCKING_SEVERITIES.include?(finding["severity"].to_s.downcase) &&
            finding["status"].to_s != "resolved" && !valid_exception?(finding["id"])
        end
      end

      def findings
        return [] unless @findings_path.exist?

        data = JSON.parse(@findings_path.read)
        data.is_a?(Array) ? data : Array(data["findings"])
      end

      def valid_exception?(finding_id)
        security_exceptions.any? do |exception|
          exception["finding_id"] == finding_id &&
            exception["owner"].to_s.strip.present? &&
            exception["reason"].to_s.strip.present? &&
            Date.iso8601(exception["expires_on"].to_s) >= Date.current
        rescue Date::Error
          false
        end
      end

      def security_exceptions
        return [] unless @exceptions_path.exist?

        Array(YAML.safe_load_file(@exceptions_path, permitted_classes: [ Date ])["exceptions"])
      end

      def source_revision
        ENV["GITHUB_SHA"].presence || Open3.capture2("git", "rev-parse", "HEAD", chdir: Rails.root).first.strip.presence || "unknown"
      rescue StandardError
        "unknown"
      end

      def spdx_id(value)
        value.to_s.gsub(/[^A-Za-z0-9.-]/, "-")
      end
  end
end
