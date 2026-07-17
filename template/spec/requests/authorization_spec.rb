require "rails_helper"

# Exercises the Authorization concern through an anonymous controller, so the
# generated application needs no real admin UI for these guarantees to hold.
# The cookie-decoding seam is stubbed; the genuine cookie path is covered by
# the authentication request and system specs.
RSpec.describe Authorization, type: :controller do
  controller(ApplicationController) do
    require_role :admin, only: :index

    def index
      render plain: "admin area"
    end

    def show
      authorize! :can_view_audit_log?
      render plain: "audit log"
    end
  end

  let(:account) { create(:account) }

  def sign_in_membership(user)
    sign_in_identity(user.identity)
  end

  def sign_in_identity(identity)
    session_record = identity.sessions.create!(user_agent: "RSpec", ip_address: "127.0.0.1")
    allow(controller).to receive(:find_session_by_cookie).and_return(session_record)
  end

  it "redirects unauthenticated requests to sign-in" do
    get :index

    expect(response).to redirect_to(new_session_path)
  end

  it "denies members an admin action and records audit evidence" do
    member = create(:user, :member, account: account)
    sign_in_membership(member)

    event = expect_audit_event(action: "authorization.denied", result: "denied") do
      get :index
    end

    expect_denied
    expect(response.body).to include("not authorised")
    expect(event.account).to eq(account)
    expect(event.identity).to eq(member.identity)
    expect(event.reason).to include("admin")
  end

  it "allows admins through the role gate" do
    admin = create(:user, :admin, account: account)
    sign_in_membership(admin)

    get :index

    expect(response).to have_http_status(:ok)
  end

  it "allows owners wherever admins are allowed" do
    owner = create(:user, :owner, account: account)
    sign_in_membership(owner)

    get :index

    expect(response).to have_http_status(:ok)
  end

  it "denies capability checks for members (default deny)" do
    member = create(:user, :member, account: account)
    sign_in_membership(member)

    get :show, params: { id: "1" }

    expect_denied_with_audit_event
  end

  it "allows capability checks for admins" do
    admin = create(:user, :admin, account: account)
    sign_in_membership(admin)

    get :show, params: { id: "1" }

    expect(response).to have_http_status(:ok)
  end

  it "denies authenticated identities with no active membership (no user resolves)" do
    sign_in_identity(create(:identity))

    get :index

    expect_denied
  end

  it "denies identities whose membership was deactivated" do
    member = create(:user, :admin, account: account)
    identity = member.identity
    sign_in_identity(identity)
    member.deactivate

    get :index

    expect_denied
  end
end
