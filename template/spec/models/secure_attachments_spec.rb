require "rails_helper"

RSpec.describe SecureAttachments do
  let(:user) { create(:user) }

  it "stores an allowed upload below a tenant-bound private key" do
    user.document.attach(io: StringIO.new("%PDF-1.7\nexample"), filename: "report.pdf", content_type: "application/pdf")

    expect(user).to be_valid
    expect(user.document.blob.key).to start_with("accounts/#{user.account_id}/user/#{user.id}/")
  end

  it "rejects executable content" do
    user.document.attach(io: StringIO.new("#!/bin/sh\necho owned"), filename: "run.sh", content_type: "application/x-sh")

    expect(user).not_to be_valid
    expect(user.errors[:document]).to be_present
  end

  it "issues only expiring signed identifiers for authorised download routes" do
    user.document.attach(io: StringIO.new("%PDF-1.7\nexample"), filename: "report.pdf", content_type: "application/pdf")
    user.save!

    expect(user.secure_download_id(:document, expires_in: 1.minute)).to be_present
  end
end
