module T40
  module LogRedactor
    FILTERED = "[FILTERED]"
    SENSITIVE_KEY = /(authorization|cookie|password|passcode|token|secret|api[_-]?key|magic[_-]?link|code)/i
    KEY_VALUE = /((?:authorization|cookie|password|passcode|token|secret|api[_-]?key|magic[_-]?link|code)\s*[=:]\s*)[^\s&,;]+/i
    BEARER = /(Bearer\s+)[A-Za-z0-9._~+\/-]+=*/i

    module_function

    def redact(value)
      case value
      when Hash
        value.each_with_object({}) do |(key, item), output|
          output[key] = key.to_s.match?(SENSITIVE_KEY) ? FILTERED : redact(item)
        end
      when Array
        value.map { |item| redact(item) }
      when String
        value.gsub(KEY_VALUE, "\\1#{FILTERED}").gsub(BEARER, "\\1#{FILTERED}")
      else
        value
      end
    end
  end
end
