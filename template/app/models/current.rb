class Current < ActiveSupport::CurrentAttributes
  attribute :session, :user, :identity, :account
  attribute :ip_address, :user_agent
  attribute :request_id, :impersonator

  def session=(value)
    super(value)
    self.identity = session.identity if value.present?
  end

  def identity=(identity)
    super(identity)
    self.user = identity.users.find_by(account: account) if identity.present? && account.present?
  end

  def account=(account)
    super(account)
    self.user = identity.users.find_by(account: account) if identity.present? && account.present?
  end
end
