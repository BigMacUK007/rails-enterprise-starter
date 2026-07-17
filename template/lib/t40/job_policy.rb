require "timeout"

module T40
  # Required bounded-failure policy for generated job examples. Project jobs
  # should make the same four decisions explicitly rather than inheriting an
  # unbounded global retry policy.
  module JobPolicy
    extend ActiveSupport::Concern

    included do
      class_attribute :t40_timeout, :t40_max_attempts, instance_writer: false
      around_perform :within_t40_timeout, if: -> { t40_timeout.present? }
    end

    class_methods do
      def job_policy(timeout:, attempts:, retryable:, discardable:)
        raise ArgumentError, "timeout must be positive" unless timeout.to_f.positive?
        raise ArgumentError, "attempts must be between 1 and 10" unless (1..10).cover?(attempts)

        self.t40_timeout = timeout
        self.t40_max_attempts = attempts
        retry_on(*Array(retryable), wait: :polynomially_longer, attempts: attempts)
        Array(discardable).each { |error| discard_on(error) }
      end
    end

    private
      def within_t40_timeout(&block)
        Timeout.timeout(t40_timeout, &block)
      rescue StandardError => error
        T40::ErrorReporter.capture(error, context: { job_class: self.class.name, job_id: job_id })
        raise
      end
  end
end
