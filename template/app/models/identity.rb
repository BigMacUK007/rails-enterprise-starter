class Identity < ApplicationRecord
  include Joinable
  include PrivacySubject

  has_many :magic_links, dependent: :destroy
  has_many :sessions, dependent: :destroy
  has_many :users, dependent: :nullify
  has_many :accounts, through: :users

  has_one_attached :avatar

  before_destroy :deactivate_users, prepend: true

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  normalizes :email_address, with: ->(value) { value.strip.downcase.presence }

  def send_magic_link(**attributes)
    attributes[:purpose] = attributes.delete(:for) if attributes.key?(:for)

    magic_links.create!(attributes).tap do
      MagicLinkRequestJob.perform_later(email_address)
    end
  end

  def privacy_export
    {
      "id" => id,
      "email_address" => email_address,
      "created_at" => created_at&.iso8601,
      "sessions" => sessions.order(:created_at).map do |session|
        {
          "created_at" => session.created_at&.iso8601,
          "last_active_at" => session.updated_at&.iso8601,
          "ip_address" => session.ip_address,
          "user_agent" => session.user_agent
        }
      end
    }
  end

  # Irreversible erasure for data-subject rights: anonymises the email
  # address, destroys sessions and magic links and records audit evidence.
  # Deliberately different from soft deletion (recoverability) — see
  # docs/privacy/subject-rights.md.
  def privacy_erase!
    transaction do
      sessions.destroy_all
      magic_links.destroy_all
      update!(email_address: "erased-#{id}@invalid.example")
      AuditEvent.record!(action: "privacy.erase", target: self)
    end
  end

  private
    def deactivate_users
      users.find_each(&:deactivate)
    end
end
