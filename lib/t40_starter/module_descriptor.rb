require "yaml"

module T40Starter
  class ModuleDescriptor
    STATUSES = %w[available interface_only].freeze

    def self.validate_all(modules_dir)
      return [] unless Dir.exist?(modules_dir)

      module_dirs = Dir.children(modules_dir).sort.select { |name| File.directory?(File.join(modules_dir, name)) }
      module_dirs.flat_map { |name| new(name: name, modules_dir: modules_dir).errors }
    end

    attr_reader :name, :path

    def initialize(name:, modules_dir:)
      @name = name
      @root = File.join(modules_dir, name)
      @path = File.join(@root, "module.yml")
    end

    def data
      @data ||= File.file?(path) ? YAML.safe_load_file(path).to_h : {}
    rescue Psych::Exception => error
      @parse_error = error
      {}
    end

    def status = data["status"].to_s

    def errors
      return [ "module '#{name}' is missing modules/#{name}/module.yml" ] unless File.file?(path)
      data
      return [ "module '#{name}' descriptor is invalid YAML: #{@parse_error.message}" ] if @parse_error

      problems = []
      problems << "schema_version must be 1" unless data["schema_version"] == 1
      problems << "name must match directory '#{name}'" unless data["name"] == name
      problems << "status must be one of #{STATUSES.join(', ')}" unless STATUSES.include?(status)
      problems << "summary is required" if data["summary"].to_s.strip.empty?
      problems << "requires_approved_scope must be true or false" unless [ true, false ].include?(data["requires_approved_scope"])

      conformance = data["conformance"]
      if !conformance.is_a?(Hash)
        problems << "conformance mapping is required"
      else
        contract = conformance["contract"].to_s
        problems << "conformance.contract is required" if contract.empty?
        if !contract.empty? && !File.file?(File.join(@root, contract))
          problems << "conformance contract does not exist: modules/#{name}/#{contract}"
        end
        problems << "conformance.required_checks must be a list" unless conformance["required_checks"].is_a?(Array)
      end

      problems.map { |problem| "module '#{name}' descriptor: #{problem}" }
    end
  end
end
