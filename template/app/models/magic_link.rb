class MagicLink < ApplicationRecord
  CODE_LENGTH = 6
  EXPIRATION_TIME = 15.minutes

  belongs_to :identity

  enum :purpose, %w[ sign_in sign_up ], prefix: :for, default: :sign_in

  scope :active, -> { where(expires_at: Time.current...) }
  scope :stale, -> { where(expires_at: ..Time.current) }

  before_validation :generate_code, on: :create
  before_validation :set_expiration, on: :create

  validates :code, uniqueness: true, presence: true

  class << self
    def consume(code, identity:, purpose: :sign_in)
      return if identity.nil?

      transaction do
        link = active.where(identity: identity, purpose: purpose).lock.find_by(code: sanitize_code(code))
        link&.consume
      end
    end

    # Exercise the same cryptographic generator for unknown addresses without
    # persisting a credential that cannot belong to an identity.
    def decoy_code
      SecureRandom.alphanumeric(CODE_LENGTH).upcase
    end

    def cleanup
      stale.delete_all
    end

    private
      def sanitize_code(code)
        code.to_s.strip.upcase
      end
  end

  def consume
    destroy!
    self
  end

  private
    def generate_code
      self.code ||= loop do
        candidate = SecureRandom.alphanumeric(CODE_LENGTH).upcase
        break candidate unless self.class.exists?(code: candidate)
      end
    end

    def set_expiration
      self.expires_at ||= EXPIRATION_TIME.from_now
    end
end
