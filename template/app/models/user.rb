class User < ApplicationRecord
  include Role
  include SecureAttachments

  has_secure_attachment :document,
    content_types: %w[application/pdf image/png image/jpeg],
    max_bytes: 10.megabytes

  belongs_to :account
  belongs_to :identity, optional: true

  validates :name, presence: true

  scope :alphabetically, -> { order(:name) }

  def deactivate
    transaction do
      update! active: false, identity: nil
    end
  end

  def setup?
    name != identity&.email_address
  end
end
