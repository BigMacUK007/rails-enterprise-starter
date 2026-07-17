require "csv"

class T40::AuditEventsController < ApplicationController
  layout "public"
  before_action :require_account!
  require_role :admin

  def index
    authorize! :can_view_audit_log?
    @audit_events = AuditEvent.for_authorized_access(account: Current.account).limit(250)
    render T40::Ui::AuditHistory.new(events: @audit_events)
  end

  def export
    authorize! :can_export_data?
    rows = AuditEvent.export(account: Current.account)
    keys = AuditEvent.new.to_export.keys
    csv = CSV.generate do |output|
      output << keys
      rows.each { |row| output << keys.map { |key| row[key].is_a?(Hash) ? row[key].to_json : row[key] } }
    end

    send_data csv, filename: "audit-events-#{Current.account.id}-#{Date.current.iso8601}.csv",
      type: "text/csv", disposition: "attachment"
  end
end
