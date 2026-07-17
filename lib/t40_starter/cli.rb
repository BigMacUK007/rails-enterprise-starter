require "optparse"
require "json"
require "fileutils"
require_relative "version"
require_relative "manifest"
require_relative "registry"
require_relative "preflight"
require_relative "planner"
require_relative "installer"
require_relative "verifier"
require_relative "control_manifest"
require_relative "install_state"
require_relative "report"

module T40Starter
  # Command-line entry point for bin/setup-enterprise.
  #
  #   bin/setup-enterprise [STAGE] [options]
  #
  #   STAGE    preflight | plan | apply | verify | report
  #            (no stage runs the full workflow: preflight -> plan ->
  #             confirm (interactive only) -> apply -> verify -> report)
  #
  #   --manifest PATH   non-interactive manifest (required outside a TTY)
  #   --target DIR      target application root (default ".")
  #   --json            machine-readable stage output on stdout
  #   --yes             skip the interactive confirmation
  #   --version         print the starter version
  #
  # Exit codes: 0 success, 1 usage/manifest error, 2 preflight failure,
  # 3 apply conflict, 4 verify failure.
  class CLI
    STAGES = %w[preflight plan apply verify report].freeze

    EXIT_OK = 0
    EXIT_USAGE = 1
    EXIT_PREFLIGHT = 2
    EXIT_CONFLICT = 3
    EXIT_VERIFY = 4
    EXIT_APPLY = 5

    def self.run(argv, stdin: $stdin, stdout: $stdout, stderr: $stderr)
      new(argv, stdin: stdin, stdout: stdout, stderr: stderr).run
    end

    def initialize(argv, stdin:, stdout:, stderr:)
      @argv = argv.dup
      @stdin = stdin
      @stdout = stdout
      @stderr = stderr
      @options = { target: ".", manifest: nil, json: false, yes: false }
      @interactive = false
      @now = Time.now
    end

    def run
      remaining = parser.parse(@argv)
      return EXIT_OK if @print_help
      if @print_version
        @stdout.puts T40Starter::VERSION
        return EXIT_OK
      end

      stage = remaining.shift
      return usage_error("unexpected arguments: #{remaining.join(' ')}") unless remaining.empty?
      if stage && !STAGES.include?(stage)
        return usage_error("unknown stage #{stage.inspect} — expected one of: #{STAGES.join(', ')}")
      end
      return usage_error("target directory not found: #{@options[:target]}") unless Dir.exist?(@options[:target])

      @target = File.expand_path(@options[:target])

      case stage
      when nil then full_flow
      when "preflight" then stage_preflight
      when "plan" then stage_plan
      when "apply" then stage_apply
      when "verify" then stage_verify
      when "report" then stage_report
      end
    rescue OptionParser::ParseError => error
      usage_error(error.message)
    rescue Installer::ConflictError => error
      @stderr.puts error.message
      EXIT_CONFLICT
    rescue Installer::ApplyError => error
      if json?
        emit("stage" => "apply", "status" => "incomplete", "failed_stage" => error.failed_stage,
             "changed" => error.changed, "error" => error.message)
      else
        @stderr.puts error.message
      end
      EXIT_APPLY
    rescue Error => error
      @stderr.puts "error: #{error.message}"
      EXIT_USAGE
    end

    private
      def parser
        @parser ||= OptionParser.new do |opts|
          opts.banner = "Usage: bin/setup-enterprise [STAGE] [options]\n" \
                        "  STAGE: #{STAGES.join(' | ')} (omit for the full workflow)"
          opts.on("--manifest PATH", "Path to t40-manifest.yml (non-interactive)") { |path| @options[:manifest] = path }
          opts.on("--target DIR", "Target application root (default: .)") { |dir| @options[:target] = dir }
          opts.on("--json", "Machine-readable stage output on stdout") { @options[:json] = true }
          opts.on("--yes", "Skip the interactive confirmation") { @options[:yes] = true }
          opts.on("--version", "Print the starter version") { @print_version = true }
          opts.on("-h", "--help", "Show this help") do
            @stdout.puts opts
            @print_help = true
          end
        end
      end

      # The starter root is normally the checkout containing this file;
      # T40_STARTER_ROOT exists so tests can point the CLI at a fixture tree.
      def starter_root
        ENV["T40_STARTER_ROOT"] || T40Starter.root
      end

      def json? = @options[:json]

      def info(message)
        (json? ? @stderr : @stdout).puts(message)
      end

      def emit(payload)
        @stdout.puts JSON.pretty_generate(payload)
      end

      # --- manifest resolution ------------------------------------------------

      def manifest
        @manifest ||= begin
          resolved = resolve_manifest
          unless resolved.valid?
            raise Error, "manifest is invalid:\n  - #{resolved.errors.join("\n  - ")}"
          end
          resolved
        end
      end

      def resolve_manifest
        if @options[:manifest]
          Manifest.load(@options[:manifest])
        elsif File.file?(target_manifest_path)
          info "Using existing manifest: #{target_manifest_path}"
          Manifest.load(target_manifest_path)
        elsif @stdin.respond_to?(:tty?) && @stdin.tty?
          @interactive = true
          Manifest.interactive(@stdin, @stdout)
        else
          raise Error, "no manifest given — pass --manifest PATH (or create #{target_manifest_path}); " \
                       "interactive mode needs a terminal"
        end
      end

      def target_manifest_path
        File.join(@target, "t40-manifest.yml")
      end

      # --- stages ---------------------------------------------------------------

      def stage_preflight
        preflight = build_preflight
        checks = preflight.checks
        if json?
          emit("stage" => "preflight", "status" => preflight.passed? ? "pass" : "fail",
               "checks" => checks.map(&:to_h))
        else
          @stdout.puts "Preflight — #{@target}"
          checks.each do |check|
            @stdout.puts format("  %-8s %-20s %s", check.status.to_s.upcase, check.name, check.message)
          end
          @stdout.puts(preflight.passed? ? "Preflight passed." : "Preflight FAILED — fix the failures above and re-run.")
        end
        preflight.passed? ? EXIT_OK : EXIT_PREFLIGHT
      end

      def stage_plan
        return EXIT_PREFLIGHT unless guard_modules!

        planner = build_planner
        if json?
          emit("stage" => "plan", "target" => @target, "starter_version" => T40Starter::VERSION,
               "summary" => planner.summary, "actions" => planner.actions.map(&:to_h))
        else
          @stdout.puts "Plan — #{@target} (nothing is applied by this stage)"
          planner.actions.each do |action|
            line = format("  %-9s %s", action.status, action.target)
            line += "  (#{action.reason})" if action.reason
            @stdout.puts line
          end
          summary = planner.summary.map { |status, count| "#{count} #{status}" }.join(", ")
          @stdout.puts "Summary: #{summary}."
        end
        EXIT_OK
      end

      def stage_apply
        return emit_preflight_failure if apply_preflight_failures.any?
        return EXIT_PREFLIGHT unless guard_modules!

        installer = Installer.new(
          manifest: manifest, target: @target, starter_root: starter_root, now: @now,
          io: json? ? nil : @stdout, run_bundle_install: run_bundle_install?
        )
        result = installer.apply
        @apply_result = result
        if json?
          emit("stage" => "apply",
               "result" => result.unchanged? ? "unchanged" : "applied",
               "changes" => result.changed.map(&:target),
               "control_manifest_written" => result.control_manifest_written,
               "managed_files_written" => result.managed_files_written,
               "bundle_installed" => result.bundle_installed)
        elsif result.unchanged?
          @stdout.puts "No changes required — the target already matches this starter version and manifest."
        else
          @stdout.puts "Applied #{result.changed.size} change(s):"
          result.changed.each { |action| @stdout.puts "  #{action.status}  #{action.target}" }
          @stdout.puts "Control manifest written: config/t40/control-manifest.yml" if result.control_manifest_written
        end
        EXIT_OK
      end

      def stage_verify
        missing = verification_prerequisites.reject { |path| File.file?(File.join(@target, path)) }
        return reject_unapplied_verify(missing) if missing.any?

        verifier = Verifier.new(target: @target, io: json? ? @stderr : @stdout, stream: true)
        results = verifier.run
        @verify_results = results
        if verifier.passed? && File.file?(File.join(@target, ControlManifest::RELATIVE_PATH))
          ControlManifest.attach_evidence(target: @target, checks: results.map(&:to_h), at: @now)
          InstallState.new(target: @target, manifest: manifest, now: @now).mark_verified
          info "Verification evidence recorded in config/t40/control-manifest.yml"
        elsif !verifier.passed?
          state = InstallState.new(target: @target, manifest: manifest, now: @now)
          if state.exists?
            failures = results.select { |result| result.status == "fail" }.map(&:name)
            state.mark_incomplete(failed_stage: "verify", changed: state.data["changed"],
                                  error: "failed checks: #{failures.join(', ')}")
          end
        end
        if json?
          emit("stage" => "verify", "status" => verifier.passed? ? "pass" : "fail",
               "checks" => results.map(&:to_h))
        else
          @stdout.puts "Verify — #{@target}"
          results.each do |result|
            @stdout.puts format("  %-14s %-5s %8.2fs", result.name, result.status, result.duration)
            @stdout.puts result.output_tail.to_s.gsub(/^/, "    ") if result.status == "fail" && result.output_tail
          end
          @stdout.puts(verifier.passed? ? "Verification passed." : "Verification FAILED.")
        end
        verifier.passed? ? EXIT_OK : EXIT_VERIFY
      end

      def verification_prerequisites
        [ "t40-manifest.yml", ControlManifest::RELATIVE_PATH, InstallState::RELATIVE_PATH ]
      end

      def reject_unapplied_verify(missing)
        message = "installation evidence missing: #{missing.join(', ')}; run apply first"
        result = Verifier::Result.new(
          name: "installation_evidence", status: "fail", duration: 0.0,
          output_tail: message, control_ids: []
        )
        @verify_results = [ result ]
        if json?
          emit("stage" => "verify", "status" => "fail", "checks" => [ result.to_h ])
        else
          @stdout.puts "Verify — #{@target}"
          @stdout.puts "  installation_evidence fail"
          @stdout.puts "    #{message}"
          @stdout.puts "Verification FAILED."
        end
        EXIT_VERIFY
      end

      def stage_report
        report = Report.new(target: @target, applied_actions: @apply_result&.changed, verify_results: @verify_results)
        if json?
          emit(report.to_h)
        else
          @stdout.puts report.render
        end
        EXIT_OK
      end

      # --- full workflow -------------------------------------------------------

      def full_flow
        code = stage_preflight
        return code unless code == EXIT_OK

        code = stage_plan
        return code unless code == EXIT_OK

        if @interactive && !@options[:yes]
          unless confirm?
            info "Aborted before apply — no changes made."
            return EXIT_OK
          end
        end

        code = stage_apply
        return code unless code == EXIT_OK

        code = stage_verify
        return code unless code == EXIT_OK

        stage_report
      end

      def confirm?
        @stdout.print "Apply these changes to #{@target}? [y/N]: "
        answer = @stdin.gets.to_s.strip.downcase
        %w[y yes].include?(answer)
      end

      # Selecting an interface-only module must stop every mutating path,
      # not just the preflight stage (fail closed).
      def guard_modules!
        errors = Registry.new(manifest: manifest, target: @target, starter_root: starter_root, now: @now).module_errors
        return true if errors.empty?

        errors.each { |message| @stderr.puts "error: #{message}" }
        false
      end

      def build_planner
        Planner.new(manifest: manifest, target: @target, starter_root: starter_root, now: @now)
      end

      def build_preflight
        @preflight ||= Preflight.new(manifest: manifest, target: @target, starter_root: starter_root, now: @now)
      end

      def emit_preflight_failure
        checks = build_preflight.checks
        if json?
          emit("stage" => "preflight", "status" => "fail", "checks" => checks.map(&:to_h))
        else
          @stderr.puts "Apply blocked by preflight failures:"
          checks.select { |check| check.status == :fail }.each do |check|
            @stderr.puts "  #{check.name}: #{check.message}"
          end
        end
        EXIT_PREFLIGHT
      end

      # File/edit conflicts retain the documented apply-conflict exit code and
      # detailed all-or-nothing error from Installer. Every environmental
      # prerequisite still blocks before Installer can write.
      def apply_preflight_failures
        build_preflight.checks.select do |check|
          check.status == :fail && !%w[conflicts edit_targets].include?(check.name)
        end
      end

      # T40_SETUP_SKIP_BUNDLE=1 lets tests exercise apply without a network
      # or a real bundle; normal runs always bundle install after changes.
      def run_bundle_install?
        ENV["T40_SETUP_SKIP_BUNDLE"] != "1"
      end

      def usage_error(message)
        @stderr.puts "error: #{message}"
        @stderr.puts parser
        EXIT_USAGE
      end
  end
end
