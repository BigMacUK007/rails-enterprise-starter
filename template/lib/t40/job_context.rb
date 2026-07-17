module T40
  # Carries tenant, actor and correlation context from Current into Active
  # Job payloads and restores it on the worker, so audit events and logs
  # written from jobs carry the same context as the request that enqueued
  # them.
  #
  # Retry/discard guidance: this concern sets NO retry_on/discard_on
  # defaults. Each job class declares its own timeout, retry_on, discard_on
  # and maximum-attempt behaviour. MissingTenantContext fails closed and the
  # job goes to failed/discarded — do NOT retry_on it: re-running cannot
  # supply the missing tenant.
  module JobContext
    extend ActiveSupport::Concern

    class MissingTenantContext < StandardError; end

    included do
      class_attribute :t40_requires_tenant, instance_writer: false, default: false

      around_perform :with_t40_context
    end

    class_methods do
      # Declares that this job MUST run with tenant context. The job raises
      # T40::JobContext::MissingTenantContext when no account is present.
      def requires_tenant!
        self.t40_requires_tenant = true
      end
    end

    def serialize
      super.merge(
        "t40_account_id" => @t40_account_id || Current.account&.id,
        "t40_identity_id" => @t40_identity_id || Current.identity&.id,
        "t40_correlation_id" => @t40_correlation_id || Current.request_id
      )
    end

    def deserialize(job_data)
      super
      @t40_account_id = job_data["t40_account_id"]
      @t40_identity_id = job_data["t40_identity_id"]
      @t40_correlation_id = job_data["t40_correlation_id"]
    end

    private
      def with_t40_context(&block)
        account_id = @t40_account_id || Current.account&.id
        identity_id = @t40_identity_id || Current.identity&.id
        correlation_id = @t40_correlation_id || Current.request_id

        account = account_id && Account.find_by(id: account_id)

        if t40_requires_tenant && account.nil?
          raise MissingTenantContext, "#{self.class.name} requires tenant context but no account was provided"
        end

        identity = identity_id && Identity.find_by(id: identity_id)

        Current.set(account: account, identity: identity, request_id: correlation_id, &block)
      end
  end
end
