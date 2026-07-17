require "rails_helper"

RSpec.describe "Operable jobs" do
  let(:account) { create(:account) }

  it "requires every generated job example to declare bounded failure behaviour" do
    [ MagicLinkRequestJob, AccountActivityJob ].each do |job_class|
      expect(job_class.t40_timeout).to be_positive
      expect(job_class.t40_max_attempts).to be_between(1, 10)
    end
  end

  it "performs a retryable tenant side effect once for a stable idempotency key" do
    Current.set(account: account) do
      2.times { AccountActivityJob.perform_now(idempotency_key: "billing-day-42", action: "account.digest") }
    end

    expect(AuditEvent.where(account: account, action: "account.digest").count).to eq(1)
    expect(T40JobExecution.where(account: account, idempotency_key: "billing-day-42").count).to eq(1)
  end

  it "fails before the side effect when tenant context is absent" do
    expect {
      AccountActivityJob.perform_now(idempotency_key: "missing", action: "account.digest")
    }.to raise_error(T40::JobContext::MissingTenantContext)

    expect(AuditEvent.where(action: "account.digest")).to be_empty
  end
end
