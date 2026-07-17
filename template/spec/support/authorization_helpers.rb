# Assertion helpers for default-deny authorisation outcomes.
module AuthorizationHelpers
  # Asserts the last response was denied by the Authorization layer.
  def expect_denied
    expect(response).to have_http_status(:forbidden)
  end

  # Asserts denial plus the authorization.denied audit trail, returning the
  # audit event for further assertions.
  def expect_denied_with_audit_event
    expect_denied
    event = AuditEvent.where(action: "authorization.denied", result: "denied").order(:id).last
    expect(event).not_to be_nil, "expected an authorization.denied audit event to be recorded"
    event
  end
end

RSpec.configure do |config|
  config.include AuthorizationHelpers, type: :request
  config.include AuthorizationHelpers, type: :controller
end
