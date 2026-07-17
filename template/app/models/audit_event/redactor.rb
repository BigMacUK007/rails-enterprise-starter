# Deep-redacts change summaries before they are persisted on audit events.
# Keys matching Rails' filter_parameters patterns or the built-in sensitive
# key list are replaced with "[FILTERED]", long string values are truncated
# and the whole summary is capped at 4KB of JSON.
class AuditEvent::Redactor
  FILTERED = "[FILTERED]"
  TRUNCATED_KEY = "_truncated"
  SENSITIVE_KEYS = %w[ code token secret password key authorization cookie session ].freeze
  MAX_STRING_LENGTH = 500
  MAX_SUMMARY_BYTES = 4.kilobytes

  class << self
    def redact(hash)
      return {} unless hash.is_a?(Hash)

      cap_size(deep_redact(hash))
    end

    private
      def deep_redact(value)
        case value
        when Hash
          value.each_with_object({}) do |(key, nested), result|
            result[key.to_s] = sensitive_key?(key) ? FILTERED : deep_redact(nested)
          end
        when Array
          value.map { |element| deep_redact(element) }
        when String
          value.length > MAX_STRING_LENGTH ? value[0, MAX_STRING_LENGTH] : value
        else
          value
        end
      end

      def sensitive_key?(key)
        name = key.to_s.downcase

        SENSITIVE_KEYS.any? { |pattern| name.include?(pattern) } ||
          rails_filter_patterns.any? do |pattern|
            pattern.is_a?(Regexp) ? pattern.match?(key.to_s) : name.include?(pattern.to_s.downcase)
          end
      end

      def rails_filter_patterns
        return [] unless defined?(Rails) && Rails.application

        # Procs cannot be matched against a key name alone, so they are skipped.
        Rails.application.config.filter_parameters.reject { |pattern| pattern.respond_to?(:call) }
      end

      def cap_size(hash)
        capped = hash

        while json_size(capped) > MAX_SUMMARY_BYTES
          droppable = capped.keys - [ TRUNCATED_KEY ]
          break if droppable.empty?

          capped = capped.except(droppable.last).merge(TRUNCATED_KEY => true)
        end

        capped
      end

      def json_size(hash)
        hash.to_json.bytesize
      end
  end
end
