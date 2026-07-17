require "rails_helper"

RSpec.describe "Audit evidence", type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, :admin, account: account) }
  let(:member) { create(:user, account: account) }
  let(:other_account) { create(:account) }

  before do
    Current.set(account: account) { AuditEvent.record!(action: "account.visible") }
    Current.set(account: other_account) { AuditEvent.record!(action: "account.hidden") }
  end

  it "lets an administrator inspect only the current account and audits access" do
    sign_in_as(admin.identity)

    expect_audit_event(action: "audit.view") { get audit_events_path }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("account.visible")
    expect(response.body).not_to include("account.hidden")
  end

  it "exports redacted current-account evidence and audits the export" do
    Current.set(account: account) do
      AuditEvent.record!(action: "account.secret", changes: { token: "top-secret", name: "visible" })
    end
    sign_in_as(admin.identity)

    expect_audit_event(action: "audit.export") { get export_audit_events_path(format: :csv) }

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/csv")
    expect(response.body).to include("[FILTERED]", "visible")
    expect(response.body).not_to include("top-secret", "account.hidden")
  end

  it "denies ordinary members" do
    sign_in_as(member.identity)

    get audit_events_path

    expect(response).to have_http_status(:forbidden)
  end

  it "rejects cross-account export at the model boundary" do
    Current.set(account: account) do
      expect { AuditEvent.export(account: other_account) }.to raise_error(Authorization::Denied)
    end
  end
end
