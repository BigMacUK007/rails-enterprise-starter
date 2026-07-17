module T40
  module ErrorReporter
    Event = Data.define(:error_class, :message, :backtrace, :context, :severity, :handled, :occurred_at)

    class LocalAdapter
      attr_reader :events

      def initialize
        @events = []
      end

      def capture(event)
        # An in-memory development/test sink. Production projects replace this
        # adapter; deliberately avoid logging here because Rails.error may be
        # subscribed to logging failures and recurse.
        events << event
      end
    end

    class RailsSubscriber
      def report(error, handled:, severity:, context:, source: nil)
        T40::ErrorReporter.capture(error, handled: handled, severity: severity,
          context: context.to_h.merge(source: source))
      end
    end

    class << self
      attr_writer :adapter

      def adapter
        @adapter ||= LocalAdapter.new
      end

      def capture(error, context: {}, severity: :error, handled: false)
        safe_context = T40::LogRedactor.redact(context.to_h.merge(
          request_id: current(:request_id),
          account_id: current(:account)&.id,
          identity_id: current(:identity)&.id,
          release: T40::Runtime.release
        ).compact)
        event = Event.new(
          error_class: error.class.name,
          message: T40::LogRedactor.redact(error.message.to_s),
          backtrace: Array(error.backtrace).first(20),
          context: safe_context,
          severity: severity.to_s,
          handled: handled,
          occurred_at: Time.current
        )
        adapter.capture(event)
        event
      end

      def reset!
        @adapter = nil
      end

      private
        def current(attribute)
          Current.public_send(attribute) if defined?(Current)
        rescue StandardError
          nil
        end
    end
  end
end
