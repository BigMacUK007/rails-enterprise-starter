require "yaml"
require "digest"
require_relative "version"

module T40Starter
  # Loads, validates and normalises `t40-manifest.yml` (manifest schema v1).
  #
  # Validation fails closed: unknown keys, unknown module names, bad enum
  # values and missing data-risk answers are all errors rather than silently
  # ignored input.
  class Manifest
    MODULE_NAMES = %w[oidc saml scim rls api webhooks ai].freeze
    TOP_LEVEL_KEYS = %w[manifest_version project tenancy authentication modules data_risk deployment].freeze
    PROJECT_KEYS = %w[name identifier].freeze
    TENANCY_MODES = %w[multi_account single_account].freeze
    AUTHENTICATION_MODES = %w[passwordless].freeze
    DEPLOYMENT_PROFILES = %w[standard high_assurance].freeze
    DATA_RISK_KEYS = %w[personal_data special_category_data children_data financial_data].freeze
    IDENTIFIER_PATTERN = /\A[a-z0-9][a-z0-9-]*\z/

    attr_reader :errors

    def self.load(path)
      raise Error, "manifest not found: #{path}" unless File.file?(path)

      data = begin
        YAML.safe_load_file(path)
      rescue Psych::Exception => error
        raise Error, "manifest is not valid YAML (#{path}): #{error.message}"
      end
      raise Error, "manifest is not a YAML mapping: #{path}" unless data.is_a?(Hash)

      new(data)
    end

    # Minimal interactive question flow. Reads answers from `io`, prompts on
    # `output`. The caller is responsible for writing the resulting manifest
    # to `t40-manifest.yml` in the target application.
    def self.interactive(io = $stdin, output = $stdout)
      output.puts "T40 Enterprise Application Starter #{VERSION}"
      output.puts "Answer a few questions to build t40-manifest.yml."
      name = prompt(io, output, "Project name")
      identifier = prompt(io, output, "Project identifier", default: derive_identifier(name))
      tenancy = prompt_choice(io, output, "Tenancy mode", TENANCY_MODES, default: "multi_account")
      modules = MODULE_NAMES.to_h do |mod|
        [ mod, prompt_boolean(io, output, "Enable #{mod} module (interface only in this release)?", default: false) ]
      end
      data_risk = {
        "personal_data" => prompt_boolean(io, output, "Will the application process personal data?", default: true),
        "special_category_data" => prompt_boolean(io, output, "Will it process special category data?", default: false),
        "children_data" => prompt_boolean(io, output, "Will it process children's data?", default: false),
        "financial_data" => prompt_boolean(io, output, "Will it process financial data?", default: false)
      }
      new(
        "manifest_version" => 1,
        "project" => { "name" => name, "identifier" => identifier },
        "tenancy" => { "mode" => tenancy },
        "authentication" => { "mode" => "passwordless" },
        "modules" => modules,
        "data_risk" => data_risk,
        "deployment" => { "profile" => "standard" }
      )
    end

    def self.derive_identifier(name)
      identifier = name.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
      identifier.empty? ? "my-app" : identifier
    end

    def self.prompt(io, output, question, default: nil)
      loop do
        output.print(default ? "#{question} [#{default}]: " : "#{question}: ")
        answer = read_answer(io)
        answer = default.to_s if answer.empty? && default
        return answer unless answer.empty?

        output.puts "A value is required."
      end
    end

    def self.prompt_choice(io, output, question, choices, default:)
      loop do
        output.print "#{question} (#{choices.join('/')}) [#{default}]: "
        answer = read_answer(io)
        answer = default if answer.empty?
        return answer if choices.include?(answer)

        output.puts "Please choose one of: #{choices.join(', ')}."
      end
    end

    def self.prompt_boolean(io, output, question, default:)
      hint = default ? "Y/n" : "y/N"
      loop do
        output.print "#{question} (#{hint}): "
        answer = read_answer(io).downcase
        return default if answer.empty?
        return true if %w[y yes true].include?(answer)
        return false if %w[n no false].include?(answer)

        output.puts "Please answer y or n."
      end
    end

    def self.read_answer(io)
      line = io.gets
      raise Error, "interactive input ended unexpectedly" if line.nil?

      line.strip
    end

    private_class_method :prompt, :prompt_choice, :prompt_boolean, :read_answer

    def initialize(data)
      @data = data.is_a?(Hash) ? data : {}
      @errors = validate(data)
    end

    def valid? = @errors.empty?

    def project_name = section("project")["name"].to_s

    def identifier = section("project")["identifier"].to_s

    def tenancy_mode = section("tenancy").fetch("mode", "multi_account")

    def authentication_mode = section("authentication").fetch("mode", "passwordless")

    def deployment_profile = section("deployment").fetch("profile", "standard")

    def modules
      MODULE_NAMES.to_h { |mod| [ mod, section("modules")[mod] == true ] }
    end

    def module_selected?(name) = modules[name.to_s] == true

    def selected_modules = MODULE_NAMES.select { |mod| module_selected?(mod) }

    def data_risk
      DATA_RISK_KEYS.to_h { |key| [ key, section("data_risk")[key] == true ] }
    end

    # Canonical normalised form with defaults applied. Key order is fixed so
    # the serialised manifest (and therefore sha256) is deterministic.
    def to_h
      {
        "manifest_version" => 1,
        "project" => { "name" => project_name, "identifier" => identifier },
        "tenancy" => { "mode" => tenancy_mode },
        "authentication" => { "mode" => authentication_mode },
        "modules" => modules,
        "data_risk" => data_risk,
        "deployment" => { "profile" => deployment_profile }
      }
    end

    def to_yaml = to_h.to_yaml

    def sha256 = Digest::SHA256.hexdigest(to_yaml)

    private
      def section(key)
        value = @data[key]
        value.is_a?(Hash) ? value : {}
      end

      def validate(data)
        return [ "manifest must be a YAML mapping" ] unless data.is_a?(Hash)

        errors = []
        (data.keys.map(&:to_s) - TOP_LEVEL_KEYS).each { |key| errors << "unknown top-level key: #{key}" }
        errors << "manifest_version must be the integer 1 (got #{data['manifest_version'].inspect})" unless data["manifest_version"] == 1
        errors.concat(validate_project(data))
        errors.concat(validate_enum(data, "tenancy", "mode", TENANCY_MODES))
        errors.concat(validate_enum(data, "authentication", "mode", AUTHENTICATION_MODES))
        errors.concat(validate_enum(data, "deployment", "profile", DEPLOYMENT_PROFILES))
        errors.concat(validate_modules(data))
        errors.concat(validate_data_risk(data))
        if data.dig("authentication", "mode").to_s == "passwordless" &&
           data.dig("data_risk", "personal_data") == false
          errors << "data_risk.personal_data must be true because passwordless authentication processes an email address"
        end
        errors
      end

      def validate_project(data)
        raw = data["project"]
        return [ "project section is required (name, identifier)" ] unless raw.is_a?(Hash)

        errors = []
        (raw.keys.map(&:to_s) - PROJECT_KEYS).each { |key| errors << "unknown project key: #{key}" }
        errors << "project.name must be a non-empty string" if raw["name"].to_s.strip.empty?
        unless raw["identifier"].to_s.match?(IDENTIFIER_PATTERN)
          errors << "project.identifier must match #{IDENTIFIER_PATTERN.inspect} (got #{raw['identifier'].inspect})"
        end
        errors
      end

      def validate_enum(data, section_name, key, allowed)
        raw = data[section_name]
        return [] if raw.nil?
        return [ "#{section_name} must be a mapping" ] unless raw.is_a?(Hash)

        errors = []
        (raw.keys.map(&:to_s) - [ key ]).each { |extra| errors << "unknown #{section_name} key: #{extra}" }
        value = raw[key]
        unless value.nil? || allowed.include?(value)
          errors << "#{section_name}.#{key} must be one of: #{allowed.join(', ')} (got #{value.inspect})"
        end
        errors
      end

      def validate_modules(data)
        raw = data["modules"]
        return [] if raw.nil?
        return [ "modules must be a mapping of module name to boolean" ] unless raw.is_a?(Hash)

        errors = []
        raw.each do |name, value|
          unless MODULE_NAMES.include?(name.to_s)
            errors << "unknown module: #{name} (known modules: #{MODULE_NAMES.join(', ')})"
            next
          end
          unless value == true || value == false
            errors << "modules.#{name} must be true or false (got #{value.inspect})"
          end
        end
        errors
      end

      def validate_data_risk(data)
        raw = data["data_risk"]
        unless raw.is_a?(Hash)
          return [ "data_risk section is required and must answer: #{DATA_RISK_KEYS.join(', ')}" ]
        end

        errors = []
        (raw.keys.map(&:to_s) - DATA_RISK_KEYS).each { |key| errors << "unknown data_risk key: #{key}" }
        DATA_RISK_KEYS.each do |key|
          value = raw[key]
          unless value == true || value == false
            errors << "data_risk.#{key} must be answered true or false (got #{value.inspect})"
          end
        end
        errors
      end
  end
end
