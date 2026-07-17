require "rails_helper"

RSpec.describe "Tenant isolation", type: :request do
  let(:account_a) { create(:account) }
  let(:account_b) { create(:account) }
  let(:admin_a) { create(:user, :admin, account: account_a) }
  let!(:widget_a) { TenantWidget.create!(account: account_a, name: "Widget A") }
  let!(:widget_b) { TenantWidget.create!(account: account_b, name: "Widget B") }

  before { sign_in_as(admin_a.identity) }

  it "serves the current account's records" do
    get t40_spec_widget_path(widget_a)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["name"]).to eq("Widget A")
  end

  it "cannot read another account's record (404: existence is not revealed)" do
    get t40_spec_widget_path(widget_b)

    expect(response).to have_http_status(:not_found)
    expect(response.body).not_to include("Widget B")
  end

  it "cannot mutate another account's record" do
    patch t40_spec_widget_path(widget_b), params: { name: "hijacked" }

    expect(response).to have_http_status(:not_found)
    expect(widget_b.reload.name).to eq("Widget B")
  end

  it "can mutate its own account's record" do
    patch t40_spec_widget_path(widget_a), params: { name: "renamed" }

    expect(response).to have_http_status(:no_content)
    expect(widget_a.reload.name).to eq("renamed")
  end

  it "denies cross-account records at the authorisation layer even when a query forgets scoping" do
    event = expect_audit_event(action: "authorization.denied", result: "denied") do
      post export_t40_spec_widget_path(widget_b)
    end

    expect_denied
    expect(event.reason).to include("account")
    expect(widget_b.reload.name).to eq("Widget B")
  end

  it "allows exports inside the tenant boundary" do
    post export_t40_spec_widget_path(widget_a)

    expect(response).to have_http_status(:ok)
  end

  it "scopes queries with for_account at the model layer" do
    expect(TenantWidget.for_account(account_a)).to contain_exactly(widget_a)
    expect(TenantWidget.for_account(account_a).exists?(widget_b.id)).to be(false)
  end
end
