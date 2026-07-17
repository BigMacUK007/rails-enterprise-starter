# Helpers for asserting audit evidence around an action.
module AuditHelpers
  # Runs the block and asserts a new audit event with the given action (and
  # result) was recorded. Returns the newest matching event so callers can
  # make further assertions about its context.
  def expect_audit_event(action:, result: "success")
    existing_ids = AuditEvent.where(action: action).ids
    yield
    event = AuditEvent.where(action: action).where.not(id: existing_ids).order(:id).last
    expect(event).not_to be_nil, "expected an audit event #{action.inspect} to be recorded"
    expect(event.result).to eq(result)
    event
  end

  # Runs the block and asserts NO audit event with the given action appears.
  def expect_no_audit_event(action:, &block)
    expect(&block).not_to change { AuditEvent.where(action: action).count }
  end
end

RSpec.configure do |config|
  config.include AuditHelpers
end
