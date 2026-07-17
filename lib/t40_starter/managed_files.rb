require "digest"
require "fileutils"
require "yaml"
require_relative "version"

module T40Starter
  # Records the exact starter-owned content installed into plain template
  # files. Upgrade planning can then preserve local changes when the starter
  # did not change, safely replace untouched managed files, and report a real
  # three-way conflict when both sides changed.
  class ManagedFiles
    RELATIVE_PATH = File.join("config", "t40", "managed-files.yml").freeze

    def initialize(target:)
      @target = target
    end

    def entry(path)
      data.fetch("files", {})[path]
    end

    def write(actions)
      entries = data.fetch("files", {}).dup
      actions.select { |action| action.type == :file }.each do |action|
        next if action.status == :project_owned

        destination = File.join(@target, action.target)
        next unless File.file?(destination) && action.content

        entries[action.target] = {
          "source_sha256" => digest(action.content),
          "installed_sha256" => digest(File.binread(destination))
        }
      end
      desired = {
        "schema_version" => 1,
        "starter_version" => T40Starter::VERSION,
        "files" => entries.sort.to_h
      }
      serialized = desired.to_yaml
      return false if File.file?(path) && File.binread(path) == serialized.b

      FileUtils.mkdir_p(File.dirname(path))
      File.binwrite(path, serialized)
      true
    end

    private
      def path
        File.join(@target, RELATIVE_PATH)
      end

      def data
        @data ||= if File.file?(path)
          YAML.safe_load_file(path).to_h
        else
          {}
        end
      rescue Psych::Exception
        {}
      end

      def digest(content)
        Digest::SHA256.hexdigest(content.to_s.b)
      end
  end
end
