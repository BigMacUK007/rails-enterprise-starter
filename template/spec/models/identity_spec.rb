require "rails_helper"

RSpec.describe Identity do
  describe "email address" do
    it "normalises email addresses" do
      identity = create(:identity, email_address: "  Person@EXAMPLE.com ")

      expect(identity.email_address).to eq("person@example.com")
    end

    it "rejects malformed email addresses" do
      expect(build(:identity, email_address: "not-an-email")).not_to be_valid
    end

    it "enforces uniqueness case-insensitively" do
      create(:identity, email_address: "person@example.com")

      expect(build(:identity, email_address: "PERSON@example.com")).not_to be_valid
    end
  end

  describe "#send_magic_link" do
    it "creates a magic link and enqueues the timing-resistant delivery job" do
      identity = create(:identity)

      expect {
        identity.send_magic_link
      }.to change { identity.magic_links.count }.by(1)
        .and have_enqueued_job(MagicLinkRequestJob).with(identity.email_address)
    end
  end

  describe "destruction" do
    it "deactivates memberships instead of deleting them" do
      user = create(:user)
      identity = user.identity

      identity.destroy!

      expect(user.reload.active).to be(false)
      expect(user.identity_id).to be_nil
    end
  end

  describe "privacy" do
    it "is registered as a privacy subject" do
      expect(PrivacySubject.registered_models).to include(Identity)
    end

    it "exports the personal data it holds" do
      identity = create(:identity)
      account = create(:account)
      create(:user, identity: identity, account: account)
      session = identity.sessions.create!(ip_address: "203.0.113.7", user_agent: "SpecBrowser")

      export = Current.set(account: account, identity: identity) { T40::Privacy.export_for(identity) }

      expect(export["email_address"]).to eq(identity.email_address)
      expect(export["sessions"].first).to include("ip_address" => "203.0.113.7", "user_agent" => "SpecBrowser")
      expect(export["sessions"].first["created_at"]).to eq(session.created_at.iso8601)
    end

    it "erases irreversibly and records audit evidence" do
      identity = create(:identity)
      identity.sessions.create!
      identity.magic_links.create!

      event = expect_audit_event(action: "privacy.erase") do
        identity.privacy_erase!
      end

      expect(identity.reload.email_address).to eq("erased-#{identity.id}@invalid.example")
      expect(identity.sessions.count).to eq(0)
      expect(identity.magic_links.count).to eq(0)
      expect(event.target).to eq(identity)
    end

    it "treats only identities without active memberships as erasure candidates" do
      identity = create(:identity)
      expect(T40::Privacy.erasure_candidate?(identity)).to be(true)

      create(:user, identity: identity)
      expect(T40::Privacy.erasure_candidate?(identity)).to be(false)

      expect(T40::Privacy.erasure_candidate?(create(:identity, :staff))).to be(false)
    end
  end
end
