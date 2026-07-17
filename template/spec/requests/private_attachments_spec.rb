require "rails_helper"

RSpec.describe "Private attachments", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:other_admin) { create(:user, :admin) }

  before do
    admin.document.attach(io: StringIO.new("%PDF-1.7\nexample"), filename: "report.pdf", content_type: "application/pdf")
    admin.save!
  end

  it "requires a signed id, current-tenant authorisation and forces attachment disposition" do
    sign_in_as(admin.identity)

    get private_attachment_path(admin.secure_download_id(:document))

    expect(response).to have_http_status(:redirect)
    expect(response.location).to include("disposition=attachment")
    expect(AuditEvent.where(action: "attachment.download", account: admin.account)).to exist
  end

  it "does not reveal an attachment to another account" do
    sign_in_as(other_admin.identity)

    get private_attachment_path(admin.secure_download_id(:document))

    expect(response).to have_http_status(:not_found)
  end

  it "rejects unsigned identifiers" do
    sign_in_as(admin.identity)

    get private_attachment_path(admin.document.attachment.id)

    expect(response).to have_http_status(:not_found)
  end
end
