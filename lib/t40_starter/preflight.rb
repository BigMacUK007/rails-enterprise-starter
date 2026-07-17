require_relative "version"
require_relative "registry"
require_relative "edit_engine"
require_relative "shell"

module T40Starter
  # Non-destructive environment and conflict checks run before any change.
  # Each check reports pass, fail or warn with a message; any fail blocks
  # the workflow (exit code 2 at the CLI).
  class Preflight
    MINIMUM_RAILS = Gem::Version.new("8.1")
    MINIMUM_RUBY = Gem::Version.new("3.4")

    Check = Struct.new(:name, :status, :message, keyword_init: true) do
      def to_h
        { "name" => name, "status" => status.to_s, "message" => message }
      end
    end

    def initialize(manifest:, target:, starter_root: T40Starter.root, now: Time.now)
      @manifest = manifest
      @target = target
      @starter_root = starter_root
      @registry = Registry.new(manifest: manifest, target: target, starter_root: starter_root, now: now)
    end

    def checks
      @checks ||= [
        rails_application_check,
        postgresql_adapter_check,
        ruby_version_check,
        bundler_check,
        conflict_check,
        edit_targets_check,
        modules_check,
        git_status_check
      ]
    end

    def passed? = checks.none? { |check| check.status == :fail }

    private
      def rails_application_check
        gemfile = File.join(@target, "Gemfile")
        unless File.file?(gemfile)
          return fail_check("rails_application", "no Gemfile found in #{@target} — run inside a Rails application root")
        end
        unless File.read(gemfile).match?(/^\s*gem\s+["']rails["']/)
          return fail_check("rails_application", "Gemfile does not declare the rails gem — not a Rails application")
        end

        version = detected_rails_version
        if version.nil?
          fail_check("rails_application",
                     "rails gem present but version could not be determined; pin Rails >= #{MINIMUM_RAILS} or install the bundle")
        elsif version >= MINIMUM_RAILS
          pass_check("rails_application", "Rails #{version} detected")
        else
          fail_check("rails_application", "Rails #{version} is below the supported minimum #{MINIMUM_RAILS}")
        end
      end

      def detected_rails_version
        lockfile = File.join(@target, "Gemfile.lock")
        if File.file?(lockfile) && (match = File.read(lockfile).match(/^\s{4}rails \((\d+(?:\.\d+)+)/))
          return Gem::Version.new(match[1])
        end
        gemfile_match = File.read(File.join(@target, "Gemfile")).match(/gem\s+["']rails["'],\s*["'][^\d]*(\d+(?:\.\d+)+)["']/)
        gemfile_match && Gem::Version.new(gemfile_match[1])
      rescue ArgumentError
        nil
      end

      def postgresql_adapter_check
        database_yml = File.join(@target, "config", "database.yml")
        unless File.file?(database_yml)
          return fail_check("postgresql_adapter", "config/database.yml not found")
        end

        if File.read(database_yml).include?("postgresql")
          pass_check("postgresql_adapter", "postgresql adapter configured")
        else
          fail_check("postgresql_adapter", "config/database.yml does not use the postgresql adapter")
        end
      end

      def ruby_version_check
        current = Gem::Version.new(RUBY_VERSION)
        if current >= MINIMUM_RUBY
          pass_check("ruby_version", "Ruby #{RUBY_VERSION}")
        else
          fail_check("ruby_version", "Ruby #{RUBY_VERSION} is below the supported minimum #{MINIMUM_RUBY}")
        end
      end

      def bundler_check
        result = Shell.run("bundle", "-v", chdir: @target)
        if result[:success]
          pass_check("bundler", result[:output].strip)
        else
          fail_check("bundler", "bundler is not available on PATH (bundle -v failed)")
        end
      end

      def conflict_check
        conflicts = @registry.conflicts
        if conflicts.empty?
          pass_check("conflicts", "no conflicting files or edits detected")
        else
          details = conflicts.map { |action| "#{action.target} (#{action.reason})" }
          fail_check("conflicts", "#{conflicts.size} conflict(s): #{details.join('; ')}")
        end
      rescue Error => error
        fail_check("conflicts", error.message)
      end

      def edit_targets_check
        edits_path = @registry.edits_path
        return pass_check("edit_targets", "no marked edits defined") unless File.file?(edits_path)

        missing = EditEngine.new(edits_path).edits.map(&:file).uniq.reject do |file|
          File.file?(File.join(@target, file))
        end
        if missing.empty?
          pass_check("edit_targets", "all marked-edit target files present")
        else
          fail_check("edit_targets", "marked-edit target files missing: #{missing.join(', ')}")
        end
      rescue Error => error
        fail_check("edit_targets", error.message)
      end

      def modules_check
        errors = @registry.module_errors
        if errors.empty?
          selected = @manifest.selected_modules
          message = selected.empty? ? "no optional modules selected" : "selected modules installable: #{selected.join(', ')}"
          pass_check("modules", message)
        else
          fail_check("modules", errors.join("; "))
        end
      end

      # Warn only: installing into a dirty worktree is allowed, but the
      # operator should know the apply diff will mix with local changes.
      def git_status_check
        unless File.directory?(File.join(@target, ".git"))
          return pass_check("git_status", "target is not a git repository")
        end

        result = Shell.run("git", "status", "--porcelain", chdir: @target)
        if !result[:success]
          Check.new(name: "git_status", status: :warn, message: "git status unavailable: #{result[:output].strip}")
        elsif result[:output].strip.empty?
          pass_check("git_status", "git worktree clean")
        else
          Check.new(name: "git_status", status: :warn,
                    message: "git worktree has uncommitted changes — review the apply diff carefully")
        end
      end

      def pass_check(name, message)
        Check.new(name: name, status: :pass, message: message)
      end

      def fail_check(name, message)
        Check.new(name: name, status: :fail, message: message)
      end
  end
end
