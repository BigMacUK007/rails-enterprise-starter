# Structured JSON logs in production only — development and test keep the
# default human-readable logs.
#
# Each log line is a single JSON object:
#   {time, level, env, release, request_id, account_id, identity_id,
#    progname, message}
#
# Correlation values are read from Current (set per-request by the
# AccountScoping concern and per-job by T40::JobContext) with a defined?
# guard so logging is safe before the application code is loaded.
class T40JsonLogFormatter < ::Logger::Formatter
  RELEASE = ENV["RELEASE_SHA"] || ENV["KAMAL_VERSION"] || "unknown"

  def call(severity, time, progname, message)
    payload = {
      time: time.utc.iso8601(3),
      level: severity,
      env: Rails.env,
      release: RELEASE,
      request_id: current_value(:request_id),
      account_id: current_value(:account)&.id,
      identity_id: current_value(:identity)&.id,
      progname: progname,
      message: T40::LogRedactor.redact(msg2str(message))
    }
    "#{payload.compact.to_json}\n"
  end

  private
    def current_value(attribute)
      return nil unless defined?(Current)

      Current.public_send(attribute)
    rescue StandardError
      nil
    end
end

if Rails.env.production?
  Rails.application.config.after_initialize do
    formatter = T40JsonLogFormatter.new
    # Keep compatibility with config.log_tags / Rails.logger.tagged.
    formatter.extend(ActiveSupport::TaggedLogging::Formatter) if defined?(ActiveSupport::TaggedLogging::Formatter)
    Rails.logger.formatter = formatter if Rails.logger
  end
end

Rails.application.config.after_initialize do
  Rails.error.subscribe(T40::ErrorReporter::RailsSubscriber.new) if Rails.error.respond_to?(:subscribe)
end
