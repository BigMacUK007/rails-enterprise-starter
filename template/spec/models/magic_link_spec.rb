require "rails_helper"

RSpec.describe MagicLink do
  let(:identity) { create(:identity) }

  describe "code generation" do
    it "generates an upper-case alphanumeric code of fixed length from a secure source" do
      magic_link = identity.magic_links.create!

      expect(magic_link.code).to match(/\A[A-Z0-9]{#{MagicLink::CODE_LENGTH}}\z/)
    end

    it "enforces uniqueness of codes" do
      magic_link = identity.magic_links.create!
      duplicate = identity.magic_links.build(code: magic_link.code)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:code]).to be_present
    end
  end

  describe "expiry" do
    it "expires after EXPIRATION_TIME" do
      freeze_time do
        magic_link = identity.magic_links.create!

        expect(magic_link.expires_at).to eq(MagicLink::EXPIRATION_TIME.from_now)
      end
    end

    it "cannot be consumed once expired" do
      magic_link = identity.magic_links.create!

      travel(MagicLink::EXPIRATION_TIME + 1.minute) do
        expect(MagicLink.consume(magic_link.code, identity: identity, purpose: :sign_in)).to be_nil
      end
    end
  end

  describe ".consume" do
    it "is single use: consuming destroys the link so it can never be replayed" do
      magic_link = identity.magic_links.create!

      expect(MagicLink.consume(magic_link.code, identity: identity, purpose: :sign_in)).to eq(magic_link)
      expect(MagicLink.exists?(magic_link.id)).to be(false)
      expect(MagicLink.consume(magic_link.code, identity: identity, purpose: :sign_in)).to be_nil
    end

    it "normalises whitespace and case before lookup" do
      magic_link = identity.magic_links.create!

      expect(MagicLink.consume("  #{magic_link.code.downcase}  ", identity: identity, purpose: :sign_in)).to eq(magic_link)
    end

    it "fails safely for malformed input" do
      identity.magic_links.create!

      expect(MagicLink.consume(nil, identity: identity, purpose: :sign_in)).to be_nil
      expect(MagicLink.consume("", identity: identity, purpose: :sign_in)).to be_nil
      expect(MagicLink.consume("../../etc/passwd", identity: identity, purpose: :sign_in)).to be_nil
      expect(MagicLink.consume("<script>alert(1)</script>", identity: identity, purpose: :sign_in)).to be_nil
    end

    it "does not consume a valid code issued to another identity" do
      other = create(:identity)
      magic_link = other.magic_links.create!

      expect(MagicLink.consume(magic_link.code, identity: identity, purpose: :sign_in)).to be_nil
      expect(magic_link.reload).to be_present
    end
  end

  describe ".cleanup" do
    it "deletes only stale links" do
      fresh = identity.magic_links.create!
      stale = identity.magic_links.create!(expires_at: 1.minute.ago)

      MagicLink.cleanup

      expect(MagicLink.exists?(fresh.id)).to be(true)
      expect(MagicLink.exists?(stale.id)).to be(false)
    end
  end
end
