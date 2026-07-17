require "rails_helper"

RSpec.describe "Single-account installation variant", type: :request do
  before do
    allow(T40::Installation).to receive(:single_account?).and_return(true)
  end

  let(:account) { create(:account, name: "Only account") }
  let(:membership) { create(:user, :admin, account: account) }
  let!(:widget) { TenantWidget.create!(account: account, name: "Only tenant record") }

  it "derives the only account from active membership without presenting a chooser" do
    post session_path, params: { email_address: membership.identity.email_address }
    post session_magic_link_path, params: { code: membership.identity.magic_links.last.code }

    expect(response).to redirect_to(root_url)

    get account_selection_path
    expect(response).to redirect_to(root_url)

    get t40_spec_widget_path(widget)
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["name"]).to eq("Only tenant record")
  end

  it "enforces one guarded account at the database boundary" do
    account

    expect {
      Account.create!(name: "Unauthorised second account")
    }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
