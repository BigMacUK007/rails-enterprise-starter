require "rails_helper"

RSpec.describe Account do
  let(:account) { create(:account) }

  describe "validations" do
    it "requires a name" do
      expect(build(:account, name: nil)).not_to be_valid
    end
  end

  describe "entitlements" do
    it "denies entitlements by default" do
      expect(account.entitled?(:advanced_reporting)).to be(false)
    end

    it "grants an entitlement and records audit evidence" do
      event = expect_audit_event(action: "entitlement.grant") do
        account.grant_entitlement!(:advanced_reporting)
      end

      expect(account.reload.entitled?(:advanced_reporting)).to be(true)
      expect(event.change_summary).to eq("entitlement" => "advanced_reporting")
      expect(event.target).to eq(account)
    end

    it "revokes an entitlement and records audit evidence" do
      account.grant_entitlement!(:advanced_reporting)

      expect_audit_event(action: "entitlement.revoke") do
        account.revoke_entitlement!(:advanced_reporting)
      end

      expect(account.reload.entitled?(:advanced_reporting)).to be(false)
    end

    it "cannot change entitlements when audit evidence cannot be written" do
      allow(AuditEvent).to receive(:record!).and_raise(StandardError, "audit store unavailable")

      expect {
        account.grant_entitlement!(:advanced_reporting)
      }.to raise_error(StandardError, "audit store unavailable")

      expect(account.reload.entitled?(:advanced_reporting)).to be(false)
    end
  end

  describe "#offboard!" do
    it "revokes access for every active user and records audit evidence" do
      users = create_list(:user, 2, account: account)

      event = expect_audit_event(action: "account.offboard") do
        account.offboard!(reason: "contract ended")
      end

      users.each do |user|
        expect(user.reload.active).to be(false)
      end
      expect(event.reason).to eq("contract ended")
      expect(event.target).to eq(account)
      expect(event.change_summary).to eq("remaining_obligations" => %w[export retention deletion])
    end
  end
end
