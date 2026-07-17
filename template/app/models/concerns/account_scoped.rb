# Include in every tenant-owned model. Fails closed: records cannot be saved
# without an account, even if the association is later tweaked, and queries
# must be explicitly scoped with for_account.
#
# Deliberately NO default_scope — implicit tenant scoping hides tenancy bugs
# and breaks background and administrative access patterns. Controllers
# resolve Current.account from an authenticated membership (see
# AccountScoping) and pass it explicitly.
module AccountScoped
  extend ActiveSupport::Concern

  included do
    if respond_to?(:default_scopes) && default_scopes.any?
      raise ArgumentError, "#{name} must not combine default_scope with AccountScoped"
    end

    belongs_to :account

    validates :account_id, presence: true

    scope :for_account, ->(account) { where(account: account) }
  end
end
