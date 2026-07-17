class T40JobExecution < ApplicationRecord
  include AccountScoped

  validates :idempotency_key, :job_class, presence: true
  validates :state, inclusion: { in: %w[running completed] }

  class << self
    # The claim and database side effect share one transaction. A retry sees
    # the completed claim and returns its result; a failure rolls both back.
    def perform_once!(account:, key:, job_class:)
      transaction do
        execution = create!(account: account, idempotency_key: key, job_class: job_class)
        result = yield
        execution.update!(state: "completed", completed_at: Time.current, result: result)
        result
      end
    rescue ActiveRecord::RecordNotUnique
      find_by!(account: account, idempotency_key: key).result
    end
  end
end
