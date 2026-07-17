class AccountActivityJob < ApplicationJob
  requires_tenant!
  queue_as :default
  job_policy timeout: 30.seconds, attempts: 5,
    retryable: [ ActiveRecord::Deadlocked, Timeout::Error ],
    discardable: [ ActiveJob::DeserializationError ]

  def perform(idempotency_key:, action:)
    T40JobExecution.perform_once!(account: Current.account, key: idempotency_key, job_class: self.class.name) do
      AuditEvent.record!(action: action, changes: { idempotency_key: idempotency_key })
      { "audit_recorded" => true }
    end
  end
end
