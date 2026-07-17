require "rails_helper"

RSpec.describe "Authentication flow", type: :request do
  let(:identity) { create(:identity, email_address: "person@example.com") }

  describe "anti-enumeration" do
    it "responds identically for known and unknown email addresses" do
      identity

      post session_path, params: { email_address: "unknown@example.com" }
      unknown = { status: response.status, location: response.headers["Location"], body: response.body }

      post session_path, params: { email_address: identity.email_address }
      known = { status: response.status, location: response.headers["Location"], body: response.body }

      expect(unknown).to eq(known)
      expect(unknown[:location]).to end_with(session_magic_link_path)
    end

    it "uses the same delivery-job boundary while creating a link only for known identities" do
      identity

      before = MagicLink.count
      expect {
        post session_path, params: { email_address: "unknown@example.com" }
      }.to have_enqueued_job(MagicLinkRequestJob).with("unknown@example.com")
      expect(MagicLink.count).to eq(before)

      expect {
        post session_path, params: { email_address: identity.email_address }
      }.to have_enqueued_job(MagicLinkRequestJob).with(identity.email_address)
      expect(MagicLink.count).to eq(before + 1)
    end
  end

  describe "happy path" do
    it "signs in with a valid emailed code" do
      post session_path, params: { email_address: identity.email_address }
      expect(response).to redirect_to(session_magic_link_path)

      post session_magic_link_path, params: { code: identity.magic_links.last.code }
      expect(response).to redirect_to(root_url)

      get "/t40_spec/protected"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Protected area")
    end

    it "sets a hardened session cookie" do
      post session_path, params: { email_address: identity.email_address }
      post session_magic_link_path, params: { code: identity.magic_links.last.code }

      set_cookie = Array(response.headers["Set-Cookie"]).join("\n")
      expect(set_cookie).to match(/session_token=[^;]+/)
      expect(set_cookie).to match(/httponly/i)
      expect(set_cookie).to match(/samesite=lax/i)
    end

    it "signs out and cannot access protected pages afterwards" do
      sign_in_as(identity)

      delete session_path
      expect(response).to redirect_to(new_session_path)

      get "/t40_spec/protected"
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "failure paths" do
    it "rejects an expired code" do
      expired = identity.magic_links.create!(expires_at: 1.minute.ago)
      post session_path, params: { email_address: identity.email_address }

      post session_magic_link_path, params: { code: expired.code }

      expect(response).to redirect_to(session_magic_link_path)
      expect(flash[:alert]).to eq("Invalid code. Try again.")

      get "/t40_spec/protected"
      expect(response).to redirect_to(new_session_path)
    end

    it "rejects a reused code" do
      post session_path, params: { email_address: identity.email_address }
      code = identity.magic_links.last.code
      post session_magic_link_path, params: { code: code }
      delete session_path

      post session_path, params: { email_address: identity.email_address }
      post session_magic_link_path, params: { code: code }

      expect(response).to redirect_to(session_magic_link_path)
      expect(flash[:alert]).to eq("Invalid code. Try again.")
    end

    it "rejects malformed codes" do
      post session_path, params: { email_address: identity.email_address }

      post session_magic_link_path, params: { code: "<script>alert(1)</script>" }

      expect(response).to redirect_to(session_magic_link_path)
      expect(flash[:alert]).to eq("Invalid code. Try again.")
    end

    it "rejects a missing code outright" do
      post session_path, params: { email_address: identity.email_address }

      post session_magic_link_path, params: {}

      expect(response).to have_http_status(:bad_request)
    end

    it "rejects a missing email address outright" do
      post session_path, params: {}

      expect(response).to have_http_status(:bad_request)
    end

    it "requires a pending email address before accepting codes" do
      get session_magic_link_path

      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to eq("Enter your email address to sign in.")
    end

    it "rejects a valid code issued to a different email address" do
      other = create(:identity, email_address: "other@example.com")
      other_link = other.magic_links.create!

      post session_path, params: { email_address: identity.email_address }
      post session_magic_link_path, params: { code: other_link.code }

      expect(response).to redirect_to(session_magic_link_path)
      expect(flash[:alert]).to eq("Invalid code. Try again.")
      expect(other_link.reload).to be_present

      get "/t40_spec/protected"
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "rate limiting" do
    before do
      # The test environment uses the null cache store, whose counters never
      # accumulate, so Rails' rate limiter could never trip. Give the limiter
      # a real in-memory counter for these examples.
      counts = Hash.new(0)
      allow(Rails.cache).to receive(:increment) do |key, amount = 1, **_options|
        counts[key] += amount
      end
    end

    it "limits code requests and answers with an alert after 10 attempts" do
      10.times do
        post session_path, params: { email_address: identity.email_address }
        expect(response).to redirect_to(session_magic_link_path)
      end

      post session_path, params: { email_address: identity.email_address }

      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to eq("Try again later.")
      expect(identity.magic_links.count).to eq(10)
    end

    it "limits repeated code guessing and answers with an alert after 10 attempts" do
      post session_path, params: { email_address: identity.email_address }

      10.times do
        post session_magic_link_path, params: { code: "WRONG1" }
        expect(response).to redirect_to(session_magic_link_path)
        expect(flash[:alert]).to eq("Invalid code. Try again.")
      end

      post session_magic_link_path, params: { code: "WRONG1" }

      expect(response).to redirect_to(session_magic_link_path)
      expect(flash[:alert]).to eq("Try again in 15 minutes.")
    end
  end
end
