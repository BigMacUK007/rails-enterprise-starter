require "rails_helper"
require "tmpdir"

RSpec.describe T40::ReleaseEvidence do
  around do |example|
    Dir.mktmpdir("t40-release-spec-") do |directory|
      @directory = Pathname(directory)
      @findings = @directory.join("findings.json")
      @exceptions = @directory.join("exceptions.yml")
      @exceptions.write({ "exceptions" => [] }.to_yaml)
      example.run
    end
  end

  it "blocks an unresolved critical or high finding" do
    @findings.write([ { "id" => "CVE-EXAMPLE", "severity" => "high", "status" => "open" } ].to_json)

    expect { build_evidence.generate! }.to raise_error(/release blocked.*CVE-EXAMPLE/)
  end

  it "accepts only an owned, reasoned, unexpired exact exception and writes resolved evidence" do
    @findings.write([ { "id" => "CVE-EXAMPLE", "severity" => "high", "status" => "open" } ].to_json)
    @exceptions.write({ "exceptions" => [ {
      "finding_id" => "CVE-EXAMPLE", "owner" => "Security owner",
      "reason" => "Vendor patch due", "expires_on" => 7.days.from_now.to_date.iso8601
    } ] }.to_yaml)

    result = build_evidence.generate!

    expect(result[:sbom]).to exist
    evidence = JSON.parse(result[:evidence].read)
    expect(evidence).to include("release_id" => "spec-release", "security_blockers" => [])
    expect(evidence["sbom_sha256"]).to match(/\A[0-9a-f]{64}\z/)
  end

  def build_evidence
    described_class.new(release_id: "spec-release", required_checks: [ "rspec" ], approvals: [ "review" ],
      output_dir: @directory.join("output"), findings_path: @findings, exceptions_path: @exceptions)
  end
end
