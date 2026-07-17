require "time"
require "yaml"
require "date"
require_relative "version"
require_relative "shell"

module T40Starter
  # Runs the verification battery inside the target application. Any failed
  # check maps to exit code 4 at the CLI. bundler-audit is retried without
  # --update so a network failure downgrades to a warning instead of masking
  # (or faking) a vulnerability finding.
  class Verifier
    OUTPUT_TAIL_LINES = 40

    Result = Struct.new(:name, :status, :duration, :output_tail, :control_ids, keyword_init: true) do
      def to_h
        { "name" => name, "status" => status, "duration" => duration,
          "output_tail" => output_tail, "control_ids" => control_ids }.compact
      end
    end

    CHECKS = [
      { name: "db:prepare", command: %w[bin/rails db:prepare] },
      { name: "eager_load", command: [ "bin/rails", "runner", "Rails.application.eager_load!" ] },
      { name: "rspec", command: %w[bundle exec rspec] },
      { name: "rubocop", command: %w[bundle exec rubocop --no-color] },
      { name: "brakeman", command: %w[bundle exec brakeman -q --no-pager --exit-on-warn] }
    ].freeze
    CHECK_NAMES = (CHECKS.map { |check| check[:name] } + [ "bundler-audit" ]).freeze

    def initialize(target:, io: $stdout, stream: true, shell: Shell)
      @target = target
      @io = io
      @stream = stream
      @shell = shell
    end

    def run
      @results ||= CHECKS.map { |check| run_check(check[:name], check[:command]) } + [ bundler_audit_check ]
    end

    def results = @results || run

    def passed? = results.none? { |result| result.status == "fail" }

    # One-line evidence string recorded against verified controls.
    def evidence_summary(at: Time.now)
      details = results.map do |result|
        note = result.name == "rspec" ? rspec_summary : nil
        note ? "#{result.name} #{result.status} (#{note})" : "#{result.name} #{result.status}"
      end
      "verified #{at.getutc.iso8601} by bin/setup-enterprise: #{details.join('; ')}"
    end

    private
      def run_check(name, command)
        announce(name, command)
        shell_result = @shell.run(*command, chdir: @target, stream: @stream ? @io : nil)
        capture_rspec_output(name, shell_result)
        Result.new(
          name: name,
          status: shell_result[:success] ? "pass" : "fail",
          duration: shell_result[:duration],
          output_tail: shell_result[:success] ? nil : tail(shell_result[:output]),
          control_ids: control_ids_for(name)
        )
      end

      def bundler_audit_check
        name = "bundler-audit"
        announce(name, %w[bundle exec bundler-audit check --update])
        with_update = @shell.run("bundle", "exec", "bundler-audit", "check", "--update",
                                 chdir: @target, stream: @stream ? @io : nil)
        if with_update[:success]
          return Result.new(name: name, status: "pass", duration: with_update[:duration],
                            control_ids: control_ids_for(name))
        end

        # --update needs the network; retry against the local advisory
        # database before treating the failure as real.
        offline = @shell.run("bundle", "exec", "bundler-audit", "check",
                             chdir: @target, stream: @stream ? @io : nil)
        duration = (with_update[:duration] + offline[:duration]).round(2)
        if offline[:success]
          Result.new(name: name, status: "warn", duration: duration, control_ids: control_ids_for(name),
                     output_tail: "advisory database update failed (network?); local database check passed")
        else
          Result.new(name: name, status: "fail", duration: duration, output_tail: tail(offline[:output]),
                     control_ids: control_ids_for(name))
        end
      end

      def capture_rspec_output(name, shell_result)
        @rspec_output = shell_result[:output] if name == "rspec"
      end

      def rspec_summary
        @rspec_output&.[](/\d+ examples?, \d+ failures?[^\n]*/)
      end

      def announce(name, command)
        @io&.puts("verify: #{name} — #{command.join(' ')}") if @stream
      end

      def tail(output)
        output.to_s.lines.last(OUTPUT_TAIL_LINES).join
      end

      def control_ids_for(check_name)
        path = File.join(@target, "config", "t40", "control-manifest.yml")
        return [] unless File.file?(path)

        data = YAML.safe_load_file(path, permitted_classes: [ Date, Time ]) || {}
        Array(data["controls"]).select do |control|
          Array(control["evidence_checks"]).include?(check_name)
        end.map { |control| control["id"] }
      rescue Psych::Exception
        []
      end
  end
end
