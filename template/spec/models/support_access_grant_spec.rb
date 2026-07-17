require "rails_helper"

RSpec.describe SupportAccessGrant do
  let(:account) { create(:account) }
  let(:staff) { create(:identity, :staff) }
  let(:granted_by) { create(:identity) }

  def grant!(**overrides)
    described_class.grant!(
      account: account,
      staff_identity: staff,
      granted_by: granted_by,
      reason: "support ticket #42",
      **overrides
    )
  end

  describe ".grant!" do
    it "creates a time-limited grant and records audit evidence" do
      grant = nil

      freeze_time do
        event = expect_audit_event(action: "support_access.grant") do
          grant = grant!
        end

        expect(grant.expires_at).to eq(SupportAccessGrant::DEFAULT_DURATION.from_now)
        expect(event.reason).to eq("support ticket #42")
        expect(event.change_summary).to include("account_id" => account.id, "staff_identity_id" => staff.id)
      end

      expect(grant).to be_active
    end

    it "refuses non-staff identities" do
      expect {
        grant!(staff_identity: granted_by)
      }.to raise_error(ArgumentError, /staff identity/)

      expect(described_class.count).to eq(0)
    end
  end

  describe "#active?" do
    it "expires with time" do
      grant = grant!(duration: 1.hour)

      expect(grant).to be_active
      travel(2.hours) do
        expect(grant).not_to be_active
      end
    end
  end

  describe "#revoke!" do
    it "revokes immediately and records audit evidence" do
      grant = grant!

      event = expect_audit_event(action: "support_access.revoke") do
        grant.revoke!(by: granted_by)
      end

      expect(grant.reload).to be_revoked
      expect(grant).not_to be_active
      expect(event.change_summary).to eq("revoked_by_id" => granted_by.id)
    end
  end

  describe ".with_grant" do
    it "runs the block with impersonation context and audits use" do
      grant = grant!
      captured = nil

      begin_event = expect_audit_event(action: "support_access.begin") do
        expect_audit_event(action: "support_access.end") do
          described_class.with_grant(grant) do
            captured = { account: Current.account, impersonator: Current.impersonator }
          end
        end
      end

      expect(captured).to eq(account: account, impersonator: staff)
      expect(begin_event.account).to eq(account)
      expect(begin_event.impersonator_id).to eq(staff.id)
      expect(Current.account).to be_nil
    end

    it "records a failure end event and re-raises when the block fails" do
      grant = grant!

      event = expect_audit_event(action: "support_access.end", result: "failure") do
        expect {
          described_class.with_grant(grant) { raise "boom" }
        }.to raise_error("boom")
      end

      expect(event.target).to eq(grant)
    end

    it "refuses expired grants without running the block" do
      grant = grant!(duration: 1.minute)

      travel(2.minutes) do
        expect {
          described_class.with_grant(grant) { raise "must not run" }
        }.to raise_error(ArgumentError, /not active/)
      end
    end

    it "refuses revoked grants without running the block" do
      grant = grant!
      grant.revoke!(by: granted_by)

      expect {
        described_class.with_grant(grant) { raise "must not run" }
      }.to raise_error(ArgumentError, /not active/)
    end

    it "refuses missing grants" do
      expect {
        described_class.with_grant(nil) { raise "must not run" }
      }.to raise_error(ArgumentError, /not active/)
    end
  end
end
