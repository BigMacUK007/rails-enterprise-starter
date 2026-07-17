require "fileutils"
require_relative "version"
require_relative "planner"
require_relative "control_manifest"
require_relative "install_state"
require_relative "shell"
require_relative "managed_files"

module T40Starter
  # Applies a computed plan to the target application.
  #
  # All-or-nothing per run: any conflict aborts before a single write (the
  # CLI maps ConflictError to exit code 3). Re-running with the same manifest
  # makes zero changes — identical files plan as :skip, present edit blocks
  # as :noop, and the control manifest is left untouched when it already
  # records the same starter version and manifest digest.
  class Installer
    class ConflictError < Error
      attr_reader :conflicts

      def initialize(conflicts)
        @conflicts = conflicts
        details = conflicts.map { |action| "  #{action.target}: #{action.reason}" }.join("\n")
        super("apply aborted before any write — #{conflicts.size} conflict(s):\n#{details}")
      end
    end

    class ApplyError < Error
      attr_reader :failed_stage, :changed

      def initialize(message, failed_stage:, changed:)
        @failed_stage = failed_stage
        @changed = changed
        super(message)
      end
    end

    Result = Struct.new(:changed, :control_manifest_written, :managed_files_written, :bundle_installed,
                        keyword_init: true) do
      def unchanged? = changed.empty? && !control_manifest_written && !managed_files_written && !bundle_installed
    end

    def initialize(manifest:, target:, starter_root: T40Starter.root, now: Time.now, io: $stdout,
                   run_bundle_install: true, shell: Shell)
      @manifest = manifest
      @target = target
      @starter_root = starter_root
      @now = now
      @io = io
      @run_bundle_install = run_bundle_install
      @shell = shell
    end

    def apply
      planner = Planner.new(manifest: @manifest, target: @target, starter_root: @starter_root, now: @now)
      module_errors = planner.module_errors
      raise Error, module_errors.join("\n") unless module_errors.empty?
      raise ConflictError, planner.conflicts unless planner.conflicts.empty?

      state = install_state
      changed = []
      completed_paths = []
      control_manifest_written = false
      managed_files_written = false
      begin
        planner.changes.each do |action|
          write_action(action)
          changed << action
          completed_paths << action.target
        end
        control_manifest_written = write_control_manifest
        completed_paths << ControlManifest::RELATIVE_PATH if control_manifest_written
        managed_files_written = ManagedFiles.new(target: @target).write(planner.actions)
        completed_paths << ManagedFiles::RELATIVE_PATH if managed_files_written
      rescue StandardError => error
        state.mark_incomplete(failed_stage: "write", changed: completed_paths, error: "#{error.class}: #{error.message}")
        raise ApplyError.new(
          "apply incomplete after #{completed_paths.size} completed write(s): #{error.class}: #{error.message}\n" \
          "Safe recovery: restore write capacity, inspect the recorded paths, then rerun apply with the same manifest.",
          failed_stage: "write", changed: completed_paths
        )
      end

      bundle_installed = false
      if @run_bundle_install && (changed.any? || state.incomplete?)
        begin
          run_bundle_install!
          bundle_installed = true
        rescue Error => error
          state.mark_incomplete(failed_stage: "bundle_install", changed: completed_paths, error: error.message)
          raise ApplyError.new(
            "apply incomplete after #{completed_paths.size} change(s): #{error.message}\n" \
            "Safe recovery: resolve the dependency error and rerun apply with the same manifest.",
            failed_stage: "bundle_install", changed: completed_paths
          )
        end
      end
      state.mark_installed(changed: completed_paths)
      Result.new(changed: changed, control_manifest_written: control_manifest_written,
                 managed_files_written: managed_files_written, bundle_installed: bundle_installed)
    end

    private
      def write_action(action)
        destination = File.join(@target, action.target)
        FileUtils.mkdir_p(File.dirname(destination))
        File.binwrite(destination, action.content)
        preserve_mode(action, destination)
      end

      # Copied files keep the template's permission bits (e.g. executables).
      def preserve_mode(action, destination)
        return if action.type == :edit

        source = File.join(@starter_root, "template", action.source.to_s)
        File.chmod(File.stat(source).mode & 0o777, destination) if File.file?(source)
      end

      def write_control_manifest
        ControlManifest.new(manifest: @manifest, starter_root: @starter_root, now: @now).write(@target)
      end

      def install_state
        @install_state ||= InstallState.new(target: @target, manifest: @manifest, now: @now)
      end

      def run_bundle_install!
        result = @shell.run("bundle", "install", chdir: @target, stream: @io)
        return if result[:success]

        tail = result[:output].lines.last(30).join
        raise Error, "bundle install failed in #{@target} (exit #{result[:status]}):\n#{tail}"
      end
  end
end
