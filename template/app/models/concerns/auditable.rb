module Auditable
  extend ActiveSupport::Concern

  included do
    after_create :log_create
    after_update :log_update
    after_destroy :log_destroy
  end

  private

  def log_create
    create_audit_log("create")
  end

  def log_update
    return if saved_changes.except("updated_at").empty?
    create_audit_log("update", saved_changes.except("updated_at"))
  end

  def log_destroy
    create_audit_log("destroy")
  end

  def create_audit_log(action, changes = nil)
    AuditLog.create!(
      user: Current.user,
      auditable: self,
      action: action,
      audit_changes: changes,
      ip_address: Current.ip_address
    )
  rescue StandardError => e
    Rails.logger.error("Failed to create audit log: #{e.message}")
  end
end
