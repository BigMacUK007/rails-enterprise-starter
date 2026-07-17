# Durable, billing-backed account capabilities stored as a jsonb map of
# string keys to `true` values. Entitlements are deliberately separate from
# temporary feature flags (T40::Flags): flags have owners and removal dates,
# entitlements persist for the life of the commercial relationship.
module Account::Entitlements
  extend ActiveSupport::Concern

  def entitled?(key)
    entitlements[key.to_s] == true
  end

  def grant_entitlement!(key)
    transaction do
      update!(entitlements: entitlements.merge(key.to_s => true))
      AuditEvent.record!(action: "entitlement.grant", target: self, changes: { "entitlement" => key.to_s })
    end
  end

  def revoke_entitlement!(key)
    transaction do
      update!(entitlements: entitlements.except(key.to_s))
      AuditEvent.record!(action: "entitlement.revoke", target: self, changes: { "entitlement" => key.to_s })
    end
  end
end
