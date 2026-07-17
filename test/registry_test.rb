require "test_helper"

class RegistryTest < Minitest::Test
  include T40StarterTest::Helpers

  FIXED_NOW = Time.utc(2026, 7, 16, 12, 0, 0)

  def build_registry(starter_root, target, manifest: build_manifest, now: FIXED_NOW)
    T40Starter::Registry.new(manifest: manifest, target: target, starter_root: starter_root, now: now)
  end

  def test_creates_missing_files_at_same_relative_path
    with_tmpdir do |starter|
      with_tmpdir do |target|
        build_starter_root(starter)
        write_file(starter, "template/config/t40/feature-flags.yml", "flags: {}\n")
        write_file(starter, "template/.rspec", "--require spec_helper\n")
        actions = build_registry(starter, target).actions
        targets = actions.map(&:target)
        assert_includes targets, "config/t40/feature-flags.yml"
        assert_includes targets, ".rspec", "dotfiles must be included in the glob"
        actions.each { |action| assert_equal :create, action.status }
        assert_equal "flags: {}\n", actions.find { |a| a.target.end_with?("feature-flags.yml") }.content
      end
    end
  end

  def test_skips_identical_and_conflicts_on_different_content
    with_tmpdir do |starter|
      with_tmpdir do |target|
        build_starter_root(starter)
        write_file(starter, "template/config/a.yml", "same\n")
        write_file(starter, "template/config/b.yml", "starter version\n")
        write_file(target, "config/a.yml", "same\n")
        write_file(target, "config/b.yml", "local drift\n")
        actions = build_registry(starter, target).actions
        assert_equal :skip, actions.find { |a| a.target == "config/a.yml" }.status
        conflict = actions.find { |a| a.target == "config/b.yml" }
        assert_equal :conflict, conflict.status
        assert_includes conflict.reason, "differs"
        assert_equal [ conflict ], build_registry(starter, target).conflicts
      end
    end
  end

  def test_renders_t40erb_with_manifest_and_starter_version
    with_tmpdir do |starter|
      with_tmpdir do |target|
        build_starter_root(starter)
        write_file(starter, "template/CLAUDE.md.t40erb",
                   "# <%= manifest[\"project\"][\"name\"] %> (starter <%= starter_version %>)\n" \
                   "Tenancy: <%= manifest[\"tenancy\"][\"mode\"] %>\n")
        action = build_registry(starter, target).actions.first
        assert_equal "CLAUDE.md", action.target, "the .t40erb suffix must be stripped"
        assert_equal :create, action.status
        assert_includes action.content, "# T40 Acceptance App (starter #{T40Starter::VERSION})"
        assert_includes action.content, "Tenancy: multi_account"
      end
    end
  end

  def test_renders_the_selected_tenancy_and_risk_profile_for_runtime_use
    with_tmpdir do |starter|
      with_tmpdir do |target|
        build_starter_root(starter)
        write_file(starter, "template/config/t40/installation.yml.t40erb", <<~ERB)
          tenancy_mode: <%= manifest.dig("tenancy", "mode") %>
          deployment_profile: <%= manifest.dig("deployment", "profile") %>
          data_risk:
          <% manifest.fetch("data_risk").each do |key, value| -%>
            <%= key %>: <%= value %>
          <% end -%>
        ERB
        data = valid_manifest_data
        data["tenancy"]["mode"] = "single_account"
        data["deployment"]["profile"] = "high_assurance"
        data["data_risk"]["financial_data"] = true
        action = build_registry(starter, target, manifest: build_manifest(data)).actions.find do |entry|
          entry.target == "config/t40/installation.yml"
        end
        rendered = YAML.safe_load(action.content)
        assert_equal "single_account", rendered["tenancy_mode"]
        assert_equal "high_assurance", rendered["deployment_profile"]
        assert_equal true, rendered.dig("data_risk", "financial_data")
      end
    end
  end

  def test_t40erb_render_failure_raises_clear_error
    with_tmpdir do |starter|
      with_tmpdir do |target|
        build_starter_root(starter)
        write_file(starter, "template/bad.md.t40erb", "<%= manifest.fetch(:nope) %>\n")
        error = assert_raises(T40Starter::Error) { build_registry(starter, target).actions }
        assert_includes error.message, "failed to render"
      end
    end
  end

  def test_migrations_get_strictly_increasing_timestamps_in_nnn_order
    with_tmpdir do |starter|
      with_tmpdir do |target|
        build_starter_root(starter)
        write_file(starter, "template/db/migrate/002_create_identities.rb", "class CreateIdentities; end\n")
        write_file(starter, "template/db/migrate/001_create_accounts.rb", "class CreateAccounts; end\n")
        write_file(starter, "template/db/migrate/010_create_audit_events.rb", "class CreateAuditEvents; end\n")
        actions = build_registry(starter, target).actions.select { |a| a.type == :migration }
        assert_equal [
          "db/migrate/20260716120000_create_accounts.rb",
          "db/migrate/20260716120001_create_identities.rb",
          "db/migrate/20260716120002_create_audit_events.rb"
        ], actions.map(&:target)
        actions.each { |action| assert_equal :create, action.status }
      end
    end
  end

  def test_migration_skipped_when_same_name_already_installed_with_any_timestamp
    with_tmpdir do |starter|
      with_tmpdir do |target|
        build_starter_root(starter)
        write_file(starter, "template/db/migrate/001_create_accounts.rb", "class CreateAccounts; end\n")
        write_file(starter, "template/db/migrate/002_create_identities.rb", "class CreateIdentities; end\n")
        write_file(target, "db/migrate/20250101000000_create_accounts.rb", "class CreateAccounts; end\n")
        actions = build_registry(starter, target).actions.select { |a| a.type == :migration }
        skipped = actions.find { |a| a.source == "db/migrate/001_create_accounts.rb" }
        assert_equal :skip, skipped.status
        assert_includes skipped.reason, "already present"
        created = actions.find { |a| a.source == "db/migrate/002_create_identities.rb" }
        assert_equal :create, created.status
      end
    end
  end

  def test_migration_with_similar_suffix_does_not_trigger_skip
    with_tmpdir do |starter|
      with_tmpdir do |target|
        build_starter_root(starter)
        write_file(starter, "template/db/migrate/001_create_accounts.rb", "class CreateAccounts; end\n")
        write_file(target, "db/migrate/20250101000000_recreate_accounts.rb", "class RecreateAccounts; end\n")
        action = build_registry(starter, target).actions.find { |a| a.type == :migration }
        assert_equal :create, action.status
      end
    end
  end

  def test_edit_actions_come_from_edits_yml
    with_tmpdir do |starter|
      with_tmpdir do |target|
        edits = <<~YAML
          edits:
            - file: Gemfile
              section: gems
              anchor: EOF
              block: |
                # >>> t40:starter gems >>>
                gem "example"
                # <<< t40:starter gems <<<
        YAML
        build_starter_root(starter, edits: edits)
        write_file(target, "Gemfile", "source \"https://rubygems.org\"\n")
        actions = build_registry(starter, target).actions
        edit = actions.find { |a| a.type == :edit }
        assert_equal "Gemfile", edit.target
        assert_equal :edit, edit.status
      end
    end
  end

  def test_module_errors_fail_closed_for_interface_only_and_missing_modules
    with_tmpdir do |starter|
      with_tmpdir do |target|
        build_starter_root(starter)
        write_module(starter, "oidc", status: "interface_only")
        write_module(starter, "api", status: "available")

        data = valid_manifest_data
        data["modules"]["oidc"] = true
        errors = build_registry(starter, target, manifest: build_manifest(data)).module_errors
        assert_equal 1, errors.size
        assert_includes errors.first, "oidc"
        assert_includes errors.first, "requires an approved, funded client requirement"
        assert_includes errors.first, "modules/oidc/MODULE.md"

        data = valid_manifest_data
        data["modules"]["api"] = true
        assert_empty build_registry(starter, target, manifest: build_manifest(data)).module_errors

        data = valid_manifest_data
        data["modules"]["webhooks"] = true
        errors = build_registry(starter, target, manifest: build_manifest(data)).module_errors
        assert_equal 1, errors.size
        assert_includes errors.first, "not part of this starter release"
      end
    end
  end

  def test_every_module_descriptor_and_conformance_contract_is_validated
    with_tmpdir do |starter|
      with_tmpdir do |target|
        build_starter_root(starter)
        write_file(starter, "modules/broken/module.yml", <<~YAML)
          schema_version: 1
          name: wrong-name
          status: available
          summary: Broken
          requires_approved_scope: true
          conformance:
            contract: missing.md
            required_checks: invalid
        YAML

        errors = build_registry(starter, target).module_errors
        assert errors.any? { |error| error.include?("name must match") }
        assert errors.any? { |error| error.include?("contract does not exist") }
        assert errors.any? { |error| error.include?("required_checks must be a list") }
      end
    end
  end

  def test_ds_store_files_are_ignored
    with_tmpdir do |starter|
      with_tmpdir do |target|
        build_starter_root(starter)
        write_file(starter, "template/.DS_Store", "junk")
        write_file(starter, "template/config/.DS_Store", "junk")
        actions = build_registry(starter, target).actions
        refute actions.any? { |action| action.source.to_s.include?(".DS_Store") }
      end
    end
  end
end
