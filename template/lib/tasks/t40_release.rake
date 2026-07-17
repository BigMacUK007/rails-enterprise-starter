namespace :t40 do
  desc "Generate machine-readable release evidence and a resolved-gem SPDX SBOM"
  task release_evidence: :environment do
    result = T40::ReleaseEvidence.new(
      release_id: ENV.fetch("T40_RELEASE_ID", T40::Runtime.release),
      required_checks: ENV.fetch("T40_REQUIRED_CHECKS", "rspec,rubocop,brakeman,bundler-audit,gitleaks,migrations").split(","),
      approvals: ENV.fetch("T40_RELEASE_APPROVALS", "").split(",").reject(&:empty?)
    ).generate!
    puts JSON.generate(result.transform_values(&:to_s))
  end
end
