class T40::AttachmentsController < ApplicationController
  before_action :require_account!

  def show
    blob = ActiveStorage::Blob.find_signed!(params[:id], purpose: "t40-private-download")
    attachment = blob.attachments.detect do |candidate|
      candidate.record.respond_to?(:account_id) && candidate.record.account_id == Current.account.id
    end
    raise ActiveRecord::RecordNotFound unless attachment

    record = attachment.record
    authorize! :can_export_data?, record

    AuditEvent.record!(action: "attachment.download", target: record,
      changes: { attachment: attachment.name, blob_id: attachment.blob_id })
    redirect_to rails_blob_url(blob, disposition: "attachment", expires_in: 2.minutes),
      allow_other_host: true
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    raise ActiveRecord::RecordNotFound
  end
end
