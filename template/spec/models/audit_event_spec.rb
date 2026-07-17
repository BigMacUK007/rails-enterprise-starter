require "rails_helper"

RSpec.describe AuditEvent do
  let(:account) { create(:account) }

  describe "append-only enforcement" do
    let(:event) { described_class.record!(action: "spec.event") }

    it "raises when updated" do
      expect { event.update!(reason: "rewritten") }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it "raises when destroyed and keeps the record" do
      expect { event.destroy }.to raise_error(ActiveRecord::ReadOnlyRecord)
      expect(described_class.exists?(event.id)).to be(true)
    end
  end

  describe ".record!" do
    it "captures actor, tenant and correlation context from Current" do
      identity = create(:identity)
      impersonator = create(:identity, :staff)

      event = Current.set(account: account, identity: identity, impersonator: impersonator, request_id: "req-42") do
        described_class.record!(action: "spec.context", changes: { "name" => "value" })
      end

      expect(event.account).to eq(account)
      expect(event.identity).to eq(identity)
      expect(event.impersonator_id).to eq(impersonator.id)
      expect(event.correlation_id).to eq("req-42")
      expect(event.occurred_at).to be_present
      expect(event.change_summary).to eq("name" => "value")
    end

    it "raises inside the business transaction so a critical action cannot outrun its evidence" do
      original_name = account.name
      expect {
        ApplicationRecord.transaction(requires_new: true) do
          account.update!(name: "Renamed During Failure")
          described_class.record!(action: nil)
        end
      }.to raise_error(ActiveRecord::RecordInvalid)

      expect(account.reload.name).to eq(original_name)
    end
  end

  describe ".record" do
    it "swallows failures and logs them instead (non-critical evidence only)" do
      allow(Rails.logger).to receive(:error)

      expect(described_class.record(action: nil)).to be_nil
      expect(Rails.logger).to have_received(:error).with(/AuditEvent.record failed/)
    end

    it "records normally when valid" do
      expect(described_class.record(action: "spec.non_critical")).to be_persisted
    end
  end

  describe AuditEvent::Redactor do
    it "filters sensitive keys deeply, including inside arrays" do
      redacted = described_class.redact(
        "code" => "ABC123",
        "token" => "tk",
        "password" => "pw",
        "profile" => { "api_key" => "k", "display_name" => "Jo" },
        "attempts" => [ { "secret" => "s", "count" => 2 } ]
      )

      expect(redacted["code"]).to eq("[FILTERED]")
      expect(redacted["token"]).to eq("[FILTERED]")
      expect(redacted["password"]).to eq("[FILTERED]")
      expect(redacted["profile"]["api_key"]).to eq("[FILTERED]")
      expect(redacted["profile"]["display_name"]).to eq("Jo")
      expect(redacted["attempts"].first["secret"]).to eq("[FILTERED]")
      expect(redacted["attempts"].first["count"]).to eq(2)
    end

    it "honours the application's filter_parameters patterns" do
      redacted = described_class.redact("national_insurance" => "QQ123456C", "display_name" => "Jo")

      expect(redacted["national_insurance"]).to eq("[FILTERED]")
      expect(redacted["display_name"]).to eq("Jo")
    end

    it "truncates long string values" do
      redacted = described_class.redact("note" => "x" * 600)

      expect(redacted["note"].length).to eq(500)
    end

    it "caps the whole summary at 4KB and marks the truncation" do
      huge = (0...30).to_h { |i| [ format("field_%02d", i), "v" * 400 ] }

      redacted = described_class.redact(huge)

      expect(redacted.to_json.bytesize).to be <= 4.kilobytes
      expect(redacted["_truncated"]).to be(true)
      expect(redacted).to have_key("field_00")
    end

    it "returns an empty hash for non-hash input" do
      expect(described_class.redact(nil)).to eq({})
      expect(described_class.redact("string")).to eq({})
    end
  end

  describe ".export" do
    it "returns only the given account's events, already redacted, and audits the export itself" do
      other_account = create(:account)
      Current.set(account: account) do
        described_class.record!(action: "spec.exportable", changes: { "code" => "ABC123", "name" => "ok" })
      end
      Current.set(account: other_account) do
        described_class.record!(action: "spec.other_tenant")
      end

      rows = nil
      export_event = Current.set(account: account) do
        expect_audit_event(action: "audit.export") do
          rows = described_class.export(account: account)
        end
      end

      actions = rows.map { |row| row["action"] }
      expect(actions).to include("spec.exportable")
      expect(actions).not_to include("spec.other_tenant")

      exportable = rows.find { |row| row["action"] == "spec.exportable" }
      expect(exportable["change_summary"]).to eq("code" => "[FILTERED]", "name" => "ok")
      expect(export_event.target).to eq(account)
    end

    it "rejects an account other than Current.account" do
      other = create(:account)

      Current.set(account: account) do
        expect { described_class.export(account: other) }.to raise_error(Authorization::Denied)
      end
    end
  end
end
