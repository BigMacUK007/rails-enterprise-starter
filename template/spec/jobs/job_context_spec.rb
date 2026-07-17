require "rails_helper"

# Test-only jobs. They must be named constants so Active Job can serialise
# and deserialise them through the queue.
class T40SpecTenantReportJob < ApplicationJob
  requires_tenant!

  cattr_accessor :captured

  def perform
    self.class.captured = {
      account_id: Current.account&.id,
      identity_id: Current.identity&.id,
      correlation_id: Current.request_id
    }
  end
end

class T40SpecGlobalProbeJob < ApplicationJob
  cattr_accessor :captured

  def perform
    self.class.captured = { account_id: Current.account&.id }
  end
end

RSpec.describe T40::JobContext do
  before do
    T40SpecTenantReportJob.captured = nil
    T40SpecGlobalProbeJob.captured = nil
  end

  describe "requires_tenant!" do
    it "fails closed when enqueued without tenant context: the job never runs" do
      T40SpecTenantReportJob.perform_later

      expect { perform_enqueued_jobs }.to raise_error(T40::JobContext::MissingTenantContext)
      expect(T40SpecTenantReportJob.captured).to be_nil
    end

    it "surfaces the failure without retrying (re-running cannot supply the tenant)" do
      T40SpecTenantReportJob.perform_later

      expect { perform_enqueued_jobs }.to raise_error(T40::JobContext::MissingTenantContext)
      expect(enqueued_jobs).to be_empty
    end

    it "fails closed when the enqueued tenant no longer exists" do
      account = create(:account)
      Current.set(account: account) { T40SpecTenantReportJob.perform_later }
      account.destroy!

      expect { perform_enqueued_jobs }.to raise_error(T40::JobContext::MissingTenantContext)
      expect(T40SpecTenantReportJob.captured).to be_nil
    end
  end

  describe "context propagation" do
    it "carries tenant, actor and correlation context through the queue" do
      account = create(:account)
      identity = create(:identity)

      Current.set(account: account, identity: identity, request_id: "req-abc-123") do
        T40SpecTenantReportJob.perform_later
      end
      Current.reset

      perform_enqueued_jobs

      expect(T40SpecTenantReportJob.captured).to eq(
        account_id: account.id,
        identity_id: identity.id,
        correlation_id: "req-abc-123"
      )
    end

    it "does not leak job context into the caller" do
      account = create(:account)
      Current.set(account: account) { T40SpecTenantReportJob.perform_later }
      Current.reset

      perform_enqueued_jobs

      expect(Current.account).to be_nil
    end

    it "lets jobs without a tenant requirement run globally" do
      T40SpecGlobalProbeJob.perform_later

      perform_enqueued_jobs

      expect(T40SpecGlobalProbeJob.captured).to eq(account_id: nil)
    end
  end
end
