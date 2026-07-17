require "test_helper"

class CliTest < Minitest::Test
  include T40StarterTest::Helpers

  class TtyInput < StringIO
    def tty? = true
  end

  EDITS_YAML = <<~YAML
    edits:
      - file: config/routes.rb
        section: routes
        anchor: "Rails.application.routes.draw do"
        block: |
          # >>> t40:starter routes >>>
          get "/ping", to: "ping#show"
          # <<< t40:starter routes <<<
  YAML

  # Builds a fixture starter checkout + Rails-shaped target, points the CLI
  # at them via T40_STARTER_ROOT and disables bundle install for apply.
  def with_cli_fixture
    with_tmpdir do |starter|
      with_tmpdir do |target|
        build_starter_root(starter, edits: EDITS_YAML)
        write_file(starter, "template/config/t40/feature-flags.yml", "flags: {}\n")
        write_file(starter, "template/db/migrate/001_create_widgets.rb", "class CreateWidgets; end\n")
        build_rails_target(target)
        manifest_path = write_file(starter, "fixture-manifest.yml", valid_manifest_data.to_yaml)
        with_env("T40_STARTER_ROOT" => starter, "T40_SETUP_SKIP_BUNDLE" => "1") do
          yield starter, target, manifest_path
        end
      end
    end
  end

  def test_version_flag
    status, stdout, = run_cli([ "--version" ])
    assert_equal 0, status
    assert_equal T40Starter::VERSION, stdout.strip
  end

  def test_unknown_stage_is_a_usage_error
    status, _, stderr = run_cli([ "deploy" ])
    assert_equal 1, status
    assert_includes stderr, "unknown stage"
  end

  def test_missing_manifest_without_tty_is_an_error
    with_cli_fixture do |_starter, target, _manifest|
      status, _, stderr = run_cli([ "plan", "--target", target ])
      assert_equal 1, status
      assert_includes stderr, "no manifest given"
    end
  end

  def test_invalid_manifest_exits_one_with_clear_message
    with_cli_fixture do |starter, target, _manifest|
      bad = write_file(starter, "bad-manifest.yml", { "manifest_version" => 1 }.to_yaml)
      status, _, stderr = run_cli([ "plan", "--target", target, "--manifest", bad ])
      assert_equal 1, status
      assert_includes stderr, "manifest is invalid"
      assert_includes stderr, "project section is required"
    end
  end

  def test_plan_applies_nothing_and_emits_json
    with_cli_fixture do |_starter, target, manifest_path|
      before = snapshot(target)
      status, stdout, = run_cli([ "plan", "--target", target, "--manifest", manifest_path, "--json" ])
      assert_equal 0, status
      assert_equal before, snapshot(target), "plan must not modify the target"
      payload = JSON.parse(stdout)
      assert_equal "plan", payload["stage"]
      assert_operator payload["summary"]["create"], :>=, 2
      assert_equal 1, payload["summary"]["edit"]
      assert_equal 0, payload["summary"]["conflict"]
      statuses = payload["actions"].map { |action| action["status"] }.uniq.sort
      assert_equal %w[create edit], statuses
      assert payload["actions"].any? { |action| action["target"] == "t40-manifest.yml" && action["status"] == "create" }
    end
  end

  def test_interactive_preflight_does_not_write_the_answered_manifest
    with_cli_fixture do |_starter, target, _manifest_path|
      answers = "Interactive App\n" + ("\n" * 13)
      before = snapshot(target)
      status, stdout, = run_cli([ "preflight", "--target", target, "--json" ], stdin: TtyInput.new(answers))
      assert_equal 0, status, stdout
      assert_equal before, snapshot(target), "interactive preflight must not persist its answered manifest"
      refute File.exist?(File.join(target, "t40-manifest.yml"))
    end
  end

  def test_preflight_passes_on_rails_shaped_target
    with_cli_fixture do |_starter, target, manifest_path|
      status, stdout, = run_cli([ "preflight", "--target", target, "--manifest", manifest_path, "--json" ])
      payload = JSON.parse(stdout)
      assert_equal "preflight", payload["stage"]
      assert_equal "pass", payload["status"], "expected pass, checks: #{payload['checks'].inspect}"
      assert_equal 0, status
      names = payload["checks"].map { |check| check["name"] }
      %w[rails_application postgresql_adapter ruby_version bundler conflicts edit_targets modules git_status].each do |name|
        assert_includes names, name
      end
    end
  end

  def test_preflight_fails_closed_when_interface_only_module_selected
    with_cli_fixture do |starter, target, _manifest_path|
      write_module(starter, "scim", status: "interface_only")
      data = valid_manifest_data
      data["modules"]["scim"] = true
      manifest_path = write_file(starter, "scim-manifest.yml", data.to_yaml)
      status, stdout, = run_cli([ "preflight", "--target", target, "--manifest", manifest_path, "--json" ])
      assert_equal 2, status
      payload = JSON.parse(stdout)
      assert_equal "fail", payload["status"]
      modules_check = payload["checks"].find { |check| check["name"] == "modules" }
      assert_equal "fail", modules_check["status"]
      assert_includes modules_check["message"], "requires an approved, funded client requirement"
    end
  end

  def test_preflight_fails_on_non_rails_target
    with_cli_fixture do |_starter, _target, manifest_path|
      with_tmpdir do |not_rails|
        status, stdout, = run_cli([ "preflight", "--target", not_rails, "--manifest", manifest_path, "--json" ])
        assert_equal 2, status
        assert_equal "fail", JSON.parse(stdout)["status"]
      end
    end
  end

  def test_preflight_rejects_rails_8_0
    with_cli_fixture do |_starter, target, manifest_path|
      write_file(target, "Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "rails", "~> 8.0.0"
      RUBY
      status, stdout, = run_cli([ "preflight", "--target", target, "--manifest", manifest_path, "--json" ])
      assert_equal 2, status
      check = JSON.parse(stdout)["checks"].find { |entry| entry["name"] == "rails_application" }
      assert_equal "fail", check["status"]
      assert_includes check["message"], "8.1"
    end
  end

  def test_preflight_fails_closed_when_rails_version_cannot_be_determined
    with_cli_fixture do |_starter, target, manifest_path|
      write_file(target, "Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "rails"
      RUBY
      FileUtils.rm_f(File.join(target, "Gemfile.lock"))

      status, stdout, = run_cli([ "preflight", "--target", target, "--manifest", manifest_path, "--json" ])

      assert_equal 2, status
      check = JSON.parse(stdout)["checks"].find { |entry| entry["name"] == "rails_application" }
      assert_equal "fail", check["status"]
      assert_includes check["message"], "could not be determined"
    end
  end

  def test_apply_then_reapply_is_idempotent_through_the_cli
    with_cli_fixture do |_starter, target, manifest_path|
      status, stdout, = run_cli([ "apply", "--target", target, "--manifest", manifest_path, "--yes", "--json" ])
      assert_equal 0, status
      first = JSON.parse(stdout)
      assert_equal "applied", first["result"]
      assert first["control_manifest_written"]
      assert_equal valid_manifest_data, YAML.safe_load_file(File.join(target, "t40-manifest.yml"))

      before = snapshot(target)
      status, stdout, = run_cli([ "apply", "--target", target, "--manifest", manifest_path, "--yes", "--json" ])
      assert_equal 0, status
      second = JSON.parse(stdout)
      assert_equal "unchanged", second["result"]
      assert_empty second["changes"]
      assert_equal before, snapshot(target), "second apply must change nothing on disk"

      status, stdout, = run_cli([ "plan", "--target", target, "--manifest", manifest_path, "--json" ])
      assert_equal 0, status
      statuses = JSON.parse(stdout)["actions"].map { |action| action["status"] }.uniq.sort
      assert_empty statuses - %w[noop skip], "post-apply plan must be clean, got #{statuses.inspect}"
    end
  end

  def test_apply_runs_preflight_before_writing
    with_cli_fixture do |_starter, target, manifest_path|
      FileUtils.rm_f(File.join(target, "config", "database.yml"))
      before = snapshot(target)
      status, stdout, = run_cli([ "apply", "--target", target, "--manifest", manifest_path, "--yes", "--json" ])
      assert_equal 2, status
      assert_equal "fail", JSON.parse(stdout)["status"]
      assert_equal before, snapshot(target)
    end
  end

  def test_plan_exposes_a_manifest_change_before_apply_replaces_it
    with_cli_fixture do |starter, target, manifest_path|
      status, = run_cli([ "apply", "--target", target, "--manifest", manifest_path, "--yes", "--json" ])
      assert_equal 0, status

      changed = valid_manifest_data
      changed["project"]["name"] = "Changed Project"
      changed_path = write_file(starter, "changed-manifest.yml", changed.to_yaml)
      status, stdout, = run_cli([ "plan", "--target", target, "--manifest", changed_path, "--json" ])
      assert_equal 0, status
      action = JSON.parse(stdout)["actions"].find { |entry| entry["target"] == "t40-manifest.yml" }
      assert_equal "edit", action["status"]
      assert_includes action["reason"], "installation selection changed"
    end
  end

  def test_apply_conflict_exits_three_and_writes_nothing
    with_cli_fixture do |_starter, target, manifest_path|
      write_file(target, "config/t40/feature-flags.yml", "flags: { local: true }\n")
      before = snapshot(target)
      status, _, stderr = run_cli([ "apply", "--target", target, "--manifest", manifest_path, "--yes" ])
      assert_equal 3, status
      assert_includes stderr, "conflict"
      assert_equal before, snapshot(target)
    end
  end

  def test_report_requires_control_manifest
    with_cli_fixture do |_starter, target, manifest_path|
      status, _, stderr = run_cli([ "report", "--target", target, "--manifest", manifest_path ])
      assert_equal 1, status
      assert_includes stderr, "control manifest not found"
    end
  end

  def test_verify_fails_closed_before_checks_when_installation_evidence_is_missing
    with_cli_fixture do |_starter, target, manifest_path|
      before = snapshot(target)

      status, stdout, = run_cli([ "verify", "--target", target, "--manifest", manifest_path, "--json" ])

      assert_equal 4, status
      payload = JSON.parse(stdout)
      assert_equal "fail", payload["status"]
      assert_equal "installation_evidence", payload.fetch("checks").first["name"]
      assert_includes payload.fetch("checks").first["output_tail"], "run apply first"
      assert_equal before, snapshot(target), "a rejected verify must not create installation evidence"
    end
  end

  def test_report_renders_after_apply
    with_cli_fixture do |_starter, target, manifest_path|
      run_cli([ "apply", "--target", target, "--manifest", manifest_path, "--yes" ])
      status, stdout, = run_cli([ "report", "--target", target, "--manifest", manifest_path ])
      assert_equal 0, status
      assert_includes stdout, "install report"
      assert_includes stdout, "Deferred decisions"
      assert_includes stdout, "TEST-02"
    end
  end
end
