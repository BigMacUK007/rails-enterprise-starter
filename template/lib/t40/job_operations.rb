module T40
  # Replaceable boundary over the production queue backend. Controllers and
  # tests depend on this small interface rather than Solid Queue internals.
  module JobOperations
    Failure = Data.define(:id, :job_class, :error, :failed_at, :account_id, :attempts)

    class SolidQueueBackend
      def failures
        return [] unless defined?(SolidQueue::FailedExecution)

        SolidQueue::FailedExecution.includes(:job).order(created_at: :desc).limit(250).filter_map do |failure|
          payload = job_payload(failure.job)
          Failure.new(
            id: failure.id,
            job_class: payload["job_class"] || failure.job.class_name,
            error: failure.error.to_s.lines.first.to_s.strip,
            failed_at: failure.created_at,
            account_id: payload["t40_account_id"],
            attempts: payload["executions"].to_i
          )
        end
      end

      def backlog_age
        return 0 unless defined?(SolidQueue::ReadyExecution)

        oldest = SolidQueue::ReadyExecution.minimum(:created_at)
        oldest ? (Time.current - oldest).to_i : 0
      end

      def replay(id:, account:)
        failure = failures.find { |entry| entry.id.to_s == id.to_s }
        raise ActiveRecord::RecordNotFound unless failure
        raise Authorization::Denied, "Failed job belongs to another account" unless failure.account_id.to_i == account.id
        raise Authorization::Denied, "Failed job exhausted its replay bound" if failure.attempts >= 10

        record = SolidQueue::FailedExecution.find(failure.id)
        payload = job_payload(record.job)
        ActiveJob::Base.deserialize(payload).enqueue
        record.destroy!
      end

      private
        def job_payload(job)
          raw = job.arguments
          raw.is_a?(String) ? JSON.parse(raw) : raw.to_h
        rescue JSON::ParserError, NoMethodError
          {}
        end
    end

    class << self
      attr_writer :backend

      def backend
        @backend ||= SolidQueueBackend.new
      end

      def for_account(account)
        backend.failures.select { |failure| failure.account_id.to_i == account.id }
      end

      def backlog_age
        backend.backlog_age
      end

      def replay!(id:, account:)
        backend.replay(id: id, account: account).tap do
          AuditEvent.record!(action: "job.replay", changes: { failure_id: id })
        end
      end

      def reset!
        @backend = nil
      end
    end
  end
end
