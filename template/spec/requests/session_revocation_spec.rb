require "rails_helper"

RSpec.describe "Session revocation", type: :request do
  let(:identity) { create(:identity) }

  it "prevents a revoked session cookie from resuming" do
    sign_in_as(identity)
    get "/t40_spec/protected"
    expect(response).to have_http_status(:ok)

    identity.sessions.sole.destroy!

    get "/t40_spec/protected"
    expect(response).to redirect_to(new_session_path)
  end

  it "revokes every session for an identity at once, with audit evidence" do
    other_device = identity.sessions.create!(user_agent: "OtherDevice", ip_address: "203.0.113.9")
    sign_in_as(identity)

    event = expect_audit_event(action: "session.revoke_all") do
      Session.revoke_all_for(identity)
    end

    expect(identity.sessions.count).to eq(0)
    expect(Session.exists?(other_device.id)).to be(false)
    expect(event.target).to eq(identity)

    get "/t40_spec/protected"
    expect(response).to redirect_to(new_session_path)
  end

  it "prevents an expired session from resuming and destroys it" do
    sign_in_as(identity)
    session_record = identity.sessions.sole

    travel(Session::INACTIVITY_TIMEOUT + 1.day) do
      get "/t40_spec/protected"

      expect(response).to redirect_to(new_session_path)
      expect(Session.exists?(session_record.id)).to be(false)
    end
  end
end
