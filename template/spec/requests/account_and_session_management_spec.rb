require "rails_helper"

RSpec.describe "Account and session management", type: :request do
  let(:identity) { create(:identity, email_address: "person@example.com") }
  let(:account_a) { create(:account, name: "Alpha") }
  let(:account_b) { create(:account, name: "Beta") }
  let!(:membership_a) { create(:user, :admin, identity: identity, account: account_a) }
  let!(:membership_b) { create(:user, identity: identity, account: account_b) }

  it "requires a multi-account identity to choose an active membership" do
    post session_path, params: { email_address: identity.email_address }
    post session_magic_link_path, params: { code: identity.magic_links.last.code }

    expect(response).to redirect_to(account_selection_path)
    get account_selection_path
    expect(response.body).to include("Alpha", "Beta")

    patch account_selection_path, params: { account_id: account_a.id }
    expect(response).to redirect_to(root_url)

    get "/t40_spec/protected"
    expect(response).to have_http_status(:ok)
  end

  it "rejects a forged account selection" do
    outsider = create(:account, name: "Outsider")
    post session_path, params: { email_address: identity.email_address }
    post session_magic_link_path, params: { code: identity.magic_links.last.code }

    patch account_selection_path, params: { account_id: outsider.id }

    expect(response).to have_http_status(:forbidden)
  end

  it "lists and revokes only the current identity's sessions" do
    sign_in_as(identity)
    current = identity.sessions.order(:id).last
    other = identity.sessions.create!(user_agent: "Lost laptop", ip_address: "203.0.113.4")
    foreign = create(:identity).sessions.create!

    get active_sessions_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Lost laptop")

    delete active_session_path(other)
    expect(response).to redirect_to(active_sessions_path)
    expect(Session.exists?(other.id)).to be(false)
    expect(Session.exists?(current.id)).to be(true)

    delete active_session_path(foreign)
    expect(response).to have_http_status(:not_found)
  end

  it "globally signs out every session with audit evidence" do
    sign_in_as(identity)
    identity.sessions.create!(user_agent: "Other device")

    expect_audit_event(action: "session.revoke_all") do
      delete all_active_sessions_path
    end

    expect(response).to redirect_to(new_session_path)
    expect(identity.sessions.reload).to be_empty
  end
end
