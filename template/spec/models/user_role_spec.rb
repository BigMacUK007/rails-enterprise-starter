require "rails_helper"

RSpec.describe User::Role do
  let(:owner)  { create(:user, :owner) }
  let(:admin)  { create(:user, :admin) }
  let(:member) { create(:user, :member) }

  describe "role hierarchy" do
    it "treats owners as administrators" do
      expect(owner).to be_owner
      expect(owner).to be_admin
    end

    it "does not treat members as administrators" do
      expect(member).not_to be_admin
    end
  end

  describe "capability matrix" do
    it "grants owners every capability (owner is a superset of admin)" do
      expect(owner.can_manage_users?).to be(true)
      expect(owner.can_manage_account?).to be(true)
      expect(owner.can_export_data?).to be(true)
      expect(owner.can_view_audit_log?).to be(true)
      expect(owner.can_grant_support_access?).to be(true)
    end

    it "grants admins management and evidence capabilities but not account ownership" do
      expect(admin.can_manage_users?).to be(true)
      expect(admin.can_export_data?).to be(true)
      expect(admin.can_view_audit_log?).to be(true)
      expect(admin.can_manage_account?).to be(false)
      expect(admin.can_grant_support_access?).to be(false)
    end

    it "denies members every capability (default deny)" do
      expect(member.can_manage_users?).to be(false)
      expect(member.can_manage_account?).to be(false)
      expect(member.can_export_data?).to be(false)
      expect(member.can_view_audit_log?).to be(false)
      expect(member.can_grant_support_access?).to be(false)
    end
  end

  describe "#can_change? and #can_administer?" do
    it "lets admins change and administer non-owners but never owners" do
      other_member = create(:user, :member, account: admin.account)

      expect(admin.can_change?(other_member)).to be(true)
      expect(admin.can_administer?(other_member)).to be(true)
      expect(admin.can_change?(owner)).to be(false)
      expect(admin.can_administer?(owner)).to be(false)
    end

    it "lets users change themselves but not administer themselves" do
      expect(member.can_change?(member)).to be(true)
      expect(member.can_administer?(member)).to be(false)
    end
  end
end
