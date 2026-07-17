# Validated Active Storage attachments:
#
#   class Identity < ApplicationRecord
#     include SecureAttachments
#
#     has_secure_attachment :avatar, content_types: %w[ image/png image/jpeg ], max_bytes: 5.megabytes
#   end
#
# Validates the declared content type (what the client claimed), the detected
# content type (identified from the file's bytes via Active Storage's Marcel
# integration) and the byte size whenever the attachment changes.
#
# Store uploads on a PRIVATE Active Storage service and generate short-lived
# signed URLs instead of exposing blobs publicly:
#
#   rails_blob_url(record.avatar, disposition: "attachment", expires_in: 5.minutes)
module SecureAttachments
  extend ActiveSupport::Concern

  class_methods do
    def has_secure_attachment(name, content_types:, max_bytes:)
      has_one_attached name

      validate do
        change = attachment_changes[name.to_s]
        next unless change.is_a?(ActiveStorage::Attached::Changes::CreateOne)

        blob = change.blob
        detected = blob.content_type # identified from content by Marcel
        declared = secure_attachment_declared_type(change.attachable) || detected

        if respond_to?(:account) && account.present? && blob.new_record?
          blob.key = T40::TenantContext.storage_key(filename: blob.filename, record: self, account: account)
        end

        unless content_types.include?(declared) && content_types.include?(detected)
          errors.add(name, "must be one of #{content_types.join(", ")}")
        end

        if blob.byte_size.to_i > max_bytes
          errors.add(name, "must be #{max_bytes} bytes or fewer")
        end
      end
    end
  end

  def secure_download_id(name, expires_in: 5.minutes)
    attachment = public_send(name)
    return unless attachment.attached?

    attachment.attachment.signed_id(purpose: "t40-private-download", expires_in: expires_in)
  end

  private
    def secure_attachment_declared_type(attachable)
      case attachable
      when Hash
        attachable[:content_type]
      else
        attachable.respond_to?(:content_type) ? attachable.content_type : nil
      end
    end
end
