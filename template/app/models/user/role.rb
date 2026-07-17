module User::Role
  extend ActiveSupport::Concern

  included do
    enum :role, %i[ owner admin member ].index_by(&:itself), scopes: false

    scope :owner, -> { where(active: true, role: :owner) }
    scope :admin, -> { where(active: true, role: %i[ owner admin ]) }
    scope :member, -> { where(active: true, role: :member) }
    scope :active, -> { where(active: true, role: %i[ owner admin member ]) }

    def admin?
      super || owner?
    end
  end

  def can_change?(other)
    (admin? && !other.owner?) || other == self
  end

  def can_administer?(other)
    admin? && !other.owner? && other != self
  end

  # Capability predicates: the server-side, default-deny authorisation
  # vocabulary. Controllers assert capabilities via authorize!(:capability);
  # hiding UI is a convenience only, never the authorisation boundary.
  # Owners satisfy admin? (see above), so owner capabilities are a superset
  # of admin capabilities.
  def can_manage_users?
    admin?
  end

  def can_manage_account?
    owner?
  end

  def can_export_data?
    admin?
  end

  def can_view_audit_log?
    admin?
  end

  def can_grant_support_access?
    owner?
  end

  def can_view_job_operations?
    admin?
  end

  def can_replay_jobs?
    admin?
  end
end
