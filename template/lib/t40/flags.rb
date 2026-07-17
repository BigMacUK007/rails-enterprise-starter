require "yaml"

module T40
  # Temporary feature flags read from config/t40/feature-flags.yml. Flags are
  # NOT durable customer entitlements — see Account::Entitlements. Every flag
  # must declare a description, an owner, a removal_by date and a boolean
  # default; T40::Flags.validate! enforces this at boot.
  module Flags
    class InvalidFlag < StandardError; end

    class << self
      # Safe default: unknown or missing flags are always disabled.
      def enabled?(key)
        definition = flags[key.to_s]
        definition.is_a?(Hash) && definition["default"] == true
      end

      def validate!
        flags.each do |key, definition|
          unless definition.is_a?(Hash)
            raise InvalidFlag, "Flag #{key} must be a mapping with description, owner, removal_by and default"
          end

          %w[ description owner removal_by ].each do |field|
            if definition[field].blank?
              raise InvalidFlag, "Flag #{key} is missing #{field} in config/t40/feature-flags.yml"
            end
          end

          unless [ true, false ].include?(definition["default"])
            raise InvalidFlag, "Flag #{key} default must be true or false"
          end

          if removal_date(definition).nil?
            raise InvalidFlag, "Flag #{key} removal_by must be an ISO 8601 date (YYYY-MM-DD)"
          end
        end

        true
      end

      # Flags past their removal_by date: remove the flag and its code paths.
      def expired_flags
        flags.select { |_key, definition| removal_date(definition)&.past? }.keys
      end

      # Test/console helper: forces a re-read of the flags file.
      def reload!
        @flags = nil
      end

      private
        def flags
          return load_flags if Rails.env.development?

          @flags ||= load_flags
        end

        def load_flags
          path = Rails.root.join("config/t40/feature-flags.yml")
          return {} unless path.exist?

          data = YAML.safe_load_file(path, permitted_classes: [ Date ]) || {}
          data.fetch("flags", nil) || {}
        end

        def removal_date(definition)
          value = definition.is_a?(Hash) ? definition["removal_by"] : nil

          case value
          when Date then value
          when String then Date.iso8601(value)
          end
        rescue ArgumentError
          nil
        end
    end
  end
end
