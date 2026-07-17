require "test_helper"

class InstallerTest < Minitest::Test
  include T40StarterTest::Helpers

  EDITS_YAML = <<~YAML
    edits:
      - file: Gemfile
        section: gems
        anchor: EOF
        block: |
          # >>> t40:starter gems >>>
          gem "example"
          # <<< t40:starter gems <<<
  YAML

  def build_installer(starter, target, run_bundle_install: false, shell: T40Starter::Shell)
    T40Starter::Installer.new(
      manifest: build_manifest, target: target, starter_root: starter,
      io: StringIO.new, run_bundle_install: run_bundle_install, shell: shell
    )
  end

  def populate(starter, target)
    build_starter_root(starter, edits: EDITS_YAML)
    write_file(starter, "template/config/t40/feature-flags.yml", "flags: {}\n")
    write_file(starter, "template/db/migrate/001_create_widgets.rb", "class CreateWidgets; end\n")
    write_file(target, "Gemfile", "source \"https://rubygems.org\"\n")
  end

  def test_apply_writes_files_edits_and_control_manifest
    with_tmpdir do |starter|
      with_tmpdir do |target|
        populate(starter, target)
        result = build_installer(starter, target).apply
        refute_predicate result, :unchanged?
        assert result.control_manifest_written
        assert_equal "flags: {}\n", File.read(File.join(target, "config/t40/feature-flags.yml"))
        migration = Dir.glob(File.join(target, "db/migrate/*_create_widgets.rb"))
        assert_equal 1, migration.size
        assert_match(/\A\d{14}_create_widgets\.rb\z/, File.basename(migration.first))
        assert_includes File.read(File.join(target, "Gemfile")), "# >>> t40:starter gems >>>"
        assert File.file?(File.join(target, "config/t40/control-manifest.yml"))
        assert_equal build_manifest.to_h, YAML.safe_load_file(File.join(target, "t40-manifest.yml"))
        state = YAML.safe_load_file(File.join(target, "config/t40/install-state.yml"))
        assert_equal "installed_unverified", state["status"]
      end
    end
  end

  def test_reapply_makes_zero_changes
    with_tmpdir do |starter|
      with_tmpdir do |target|
        populate(starter, target)
        build_installer(starter, target).apply
        before = snapshot(target)
        result = build_installer(starter, target).apply
        assert_predicate result, :unchanged?
        assert_empty result.changed
        refute result.control_manifest_written
        assert_equal before, snapshot(target), "re-apply must not modify any file"
      end
    end
  end

  def test_unchanged_reapply_preserves_verified_installation_state
    with_tmpdir do |starter|
      with_tmpdir do |target|
        populate(starter, target)
        manifest = build_manifest
        build_installer(starter, target).apply
        T40Starter::InstallState.new(target: target, manifest: manifest).mark_verified
        before = snapshot(target)

        result = build_installer(starter, target).apply

        assert_predicate result, :unchanged?
        assert_equal before, snapshot(target), "an unchanged apply must not downgrade verified evidence"
        state = YAML.safe_load_file(File.join(target, "config/t40/install-state.yml"))
        assert_equal "installation_verified", state["status"]
      end
    end
  end

  def test_upgrade_preserves_project_change_when_starter_content_is_unchanged
    with_tmpdir do |starter|
      with_tmpdir do |target|
        populate(starter, target)
        build_installer(starter, target).apply
        path = File.join(target, "config/t40/feature-flags.yml")
        File.write(path, "flags:\n  project_flag: true\n")

        planner = T40Starter::Planner.new(manifest: build_manifest, target: target, starter_root: starter)
        action = planner.actions.find { |entry| entry.target == "config/t40/feature-flags.yml" }
        assert_equal :project_owned, action.status

        build_installer(starter, target).apply
        assert_equal "flags:\n  project_flag: true\n", File.read(path)
      end
    end
  end

  def test_upgrade_replaces_untouched_managed_content_and_reports_three_way_conflicts
    with_tmpdir do |starter|
      with_tmpdir do |target|
        populate(starter, target)
        build_installer(starter, target).apply
        target_path = File.join(target, "config/t40/feature-flags.yml")

        File.write(File.join(starter, "template/config/t40/feature-flags.yml"), "flags:\n  starter_v2: true\n")
        safe = T40Starter::Planner.new(manifest: build_manifest, target: target, starter_root: starter)
        assert_equal :edit, safe.actions.find { |entry| entry.target == "config/t40/feature-flags.yml" }.status
        build_installer(starter, target).apply
        assert_includes File.read(target_path), "starter_v2"

        File.write(target_path, "flags:\n  project: true\n")
        File.write(File.join(starter, "template/config/t40/feature-flags.yml"), "flags:\n  starter_v3: true\n")
        conflict = T40Starter::Planner.new(manifest: build_manifest, target: target, starter_root: starter)
          .actions.find { |entry| entry.target == "config/t40/feature-flags.yml" }
        assert_equal :conflict, conflict.status
        assert_includes conflict.reason, "both the project and starter changed"
      end
    end
  end

  def test_conflict_aborts_before_any_write
    with_tmpdir do |starter|
      with_tmpdir do |target|
        populate(starter, target)
        write_file(starter, "template/config/other.yml", "starter\n")
        write_file(target, "config/other.yml", "local drift\n")
        before = snapshot(target)
        error = assert_raises(T40Starter::Installer::ConflictError) do
          build_installer(starter, target).apply
        end
        assert_includes error.message, "config/other.yml"
        assert_equal before, snapshot(target), "a conflicting apply must write nothing at all"
        refute File.exist?(File.join(target, "config/t40/control-manifest.yml"))
      end
    end
  end

  def test_apply_refuses_interface_only_module_selection
    with_tmpdir do |starter|
      with_tmpdir do |target|
        populate(starter, target)
        write_module(starter, "saml", status: "interface_only")
        data = valid_manifest_data
        data["modules"]["saml"] = true
        installer = T40Starter::Installer.new(
          manifest: build_manifest(data), target: target, starter_root: starter,
          io: StringIO.new, run_bundle_install: false
        )
        error = assert_raises(T40Starter::Error) { installer.apply }
        assert_includes error.message, "interface only in this release"
      end
    end
  end

  def test_executable_bits_are_preserved
    with_tmpdir do |starter|
      with_tmpdir do |target|
        populate(starter, target)
        script = write_file(starter, "template/bin/example", "#!/usr/bin/env ruby\nputs :ok\n")
        File.chmod(0o755, script)
        build_installer(starter, target).apply
        assert File.executable?(File.join(target, "bin/example")), "template executable bit must survive the copy"
      end
    end
  end

  def test_planner_reports_all_skip_or_noop_after_apply
    with_tmpdir do |starter|
      with_tmpdir do |target|
        populate(starter, target)
        build_installer(starter, target).apply
        planner = T40Starter::Planner.new(manifest: build_manifest, target: target, starter_root: starter)
        statuses = planner.actions.map(&:status).uniq.sort
        assert_empty statuses - %i[noop skip], "second plan must contain only noop/skip, got #{statuses.inspect}"
        refute_predicate planner, :changes?
      end
    end
  end

  def test_bundle_failure_records_an_incomplete_install_that_can_be_resumed
    failing_shell = Object.new
    def failing_shell.run(*)
      { success: false, status: 23, output: "dependency resolution failed\n", duration: 0.01 }
    end

    passing_shell = Object.new
    def passing_shell.run(*)
      { success: true, status: 0, output: "bundle complete\n", duration: 0.01 }
    end

    with_tmpdir do |starter|
      with_tmpdir do |target|
        populate(starter, target)
        error = assert_raises(T40Starter::Installer::ApplyError) do
          build_installer(starter, target, run_bundle_install: true, shell: failing_shell).apply
        end
        assert_includes error.message, "dependency resolution failed"
        state_path = File.join(target, "config/t40/install-state.yml")
        state = YAML.safe_load_file(state_path)
        assert_equal "incomplete", state["status"]
        assert_equal "bundle_install", state["failed_stage"]
        assert_operator state["changed"].size, :>, 0

        result = build_installer(starter, target, run_bundle_install: true, shell: passing_shell).apply
        assert result.bundle_installed, "an incomplete install must retry dependency installation"
        resumed = YAML.safe_load_file(state_path)
        assert_equal "installed_unverified", resumed["status"]
      end
    end
  end

  def test_write_failure_records_completed_paths_and_safe_recovery
    with_tmpdir do |starter|
      with_tmpdir do |target|
        populate(starter, target)
        installer = build_installer(starter, target)
        original_write = installer.method(:write_action)
        writes = 0
        installer.define_singleton_method(:write_action) do |action|
          writes += 1
          raise Errno::ENOSPC, "acceptance disk full" if writes == 2

          original_write.call(action)
        end

        error = assert_raises(T40Starter::Installer::ApplyError) { installer.apply }

        assert_equal "write", error.failed_stage
        assert_includes error.message, "Safe recovery"
        state = YAML.safe_load_file(File.join(target, "config/t40/install-state.yml"))
        assert_equal "incomplete", state["status"]
        assert_equal "write", state["failed_stage"]
        assert_equal 1, state.fetch("changed").length
      end
    end
  end
end
