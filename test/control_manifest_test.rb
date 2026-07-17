require "test_helper"

class ControlManifestTest < Minitest::Test
  include T40StarterTest::Helpers

  FIXED_NOW = Time.utc(2026, 7, 16, 12, 0, 0)
  ALLOWED_CATEGORIES = %w[
    authentication session tenancy authorisation audit privacy uploads headers
    jobs observability backup delivery incident accessibility ai
  ].freeze

  def build_control_manifest(starter_root, manifest: build_manifest)
    T40Starter::ControlManifest.new(manifest: manifest, starter_root: starter_root, now: FIXED_NOW)
  end

  def test_writes_schema_compliant_control_manifest
    with_tmpdir do |starter|
      with_tmpdir do |target|
        build_starter_root(starter)
        written = build_control_manifest(starter).write(target)
        assert written
        path = File.join(target, "config", "t40", "control-manifest.yml")
        assert File.file?(path)
        data = YAML.safe_load_file(path, permitted_classes: [ Date, Time ])
        assert_equal T40Starter::VERSION, data["starter_version"]
        assert_equal 1, data["manifest_version"]
        assert_equal build_manifest.sha256, data["manifest_sha256"]
        assert_equal "2026-07-16T12:00:00Z", data["installed_at"]
        assert_equal 3, data["controls"].size

        enabled = data["controls"].find { |control| control["id"] == "TEST-01" }
        assert_equal "enabled", enabled["status"]
        assert_nil enabled["owner"]
        assert_nil enabled["evidence"]
        assert_nil enabled["reason"]
        assert_equal "docs/one.md", enabled["reference"]

        deferred = data["controls"].find { |control| control["id"] == "TEST-02" }
        assert_equal "deferred", deferred["status"]
        assert_equal "project team", deferred["owner"]

        conditional = data["controls"].find { |control| control["id"] == "TEST-03" }
        assert_equal "not_applicable", conditional["status"]
        assert_equal "module ai not selected in the install manifest", conditional["reason"]
      end
    end
  end

  def test_conditional_control_enabled_when_module_selected
    with_tmpdir do |starter|
      with_tmpdir do |target|
        build_starter_root(starter)
        data = valid_manifest_data
        data["modules"]["ai"] = true
        build_control_manifest(starter, manifest: build_manifest(data)).write(target)
        written = YAML.safe_load_file(File.join(target, "config", "t40", "control-manifest.yml"))
        conditional = written["controls"].find { |control| control["id"] == "TEST-03" }
        assert_equal "enabled", conditional["status"]
        assert_nil conditional["reason"]
      end
    end
  end

  def test_rewrite_skipped_when_starter_version_and_manifest_unchanged
    with_tmpdir do |starter|
      with_tmpdir do |target|
        build_starter_root(starter)
        assert build_control_manifest(starter).write(target)
        path = File.join(target, "config", "t40", "control-manifest.yml")
        before = File.binread(path)
        refute build_control_manifest(starter).write(target), "unchanged install must not rewrite the control manifest"
        assert_equal before, File.binread(path)

        changed = valid_manifest_data
        changed["project"]["name"] = "Different"
        assert build_control_manifest(starter, manifest: build_manifest(changed)).write(target),
               "a different manifest digest must rewrite the control manifest"
      end
    end
  end

  def test_upgrade_reconciliation_preserves_project_owner_decision_and_valid_evidence
    with_tmpdir do |starter|
      with_tmpdir do |target|
        build_starter_root(starter)
        controls = build_control_manifest(starter)
        controls.write(target)
        path = File.join(target, "config/t40/control-manifest.yml")
        existing = YAML.safe_load_file(path)
        enabled = existing["controls"].find { |entry| entry["id"] == "TEST-01" }
        enabled["status"] = "verified"
        enabled["owner"] = "Ben"
        enabled["decision"] = "accepted"
        enabled["evidence"] = [ { "check" => "rspec", "status" => "pass", "verified_at" => "2026-07-16T12:00:00Z" } ]
        File.write(path, existing.to_yaml)

        changed = valid_manifest_data
        changed["project"]["name"] = "Upgraded"
        build_control_manifest(starter, manifest: build_manifest(changed)).write(target)
        upgraded = YAML.safe_load_file(path)["controls"].find { |entry| entry["id"] == "TEST-01" }

        assert_equal "verified", upgraded["status"]
        assert_equal "Ben", upgraded["owner"]
        assert_equal "accepted", upgraded["decision"]
        assert_equal "rspec", upgraded["evidence"].first["check"]
      end
    end
  end

  def test_attach_evidence_marks_only_controls_bound_to_passing_checks_verified
    with_tmpdir do |starter|
      with_tmpdir do |target|
        build_starter_root(starter)
        build_control_manifest(starter).write(target)
        checks = [ { "name" => "rspec", "status" => "pass", "duration" => 1.2 },
                   { "name" => "brakeman", "status" => "pass", "duration" => 0.4 } ]
        T40Starter::ControlManifest.attach_evidence(target: target, checks: checks,
                                                    at: Time.utc(2026, 7, 16, 12, 34, 56))
        data = YAML.safe_load_file(File.join(target, "config", "t40", "control-manifest.yml"))
        verified = data["controls"].find { |control| control["id"] == "TEST-01" }
        assert_equal "verified", verified["status"]
        assert_equal [ "rspec" ], verified["evidence"].map { |entry| entry["check"] }
        deferred = data["controls"].find { |control| control["id"] == "TEST-02" }
        assert_equal "deferred", deferred["status"]
        assert_nil deferred["evidence"]
        not_applicable = data["controls"].find { |control| control["id"] == "TEST-03" }
        assert_equal "not_applicable", not_applicable["status"]
      end
    end
  end

  def test_attach_evidence_raises_without_control_manifest
    with_tmpdir do |target|
      assert_raises(T40Starter::Error) do
        T40Starter::ControlManifest.attach_evidence(target: target, checks: [])
      end
    end
  end

  def test_generic_success_does_not_verify_a_control_without_an_evidence_binding
    with_tmpdir do |starter|
      with_tmpdir do |target|
        controls = <<~YAML
          controls:
            - id: TEST-10
              name: "Manual control"
              category: delivery
              install_status: enabled
              reference: docs/one.md
        YAML
        build_starter_root(starter, controls: controls)
        build_control_manifest(starter).write(target)
        T40Starter::ControlManifest.attach_evidence(
          target: target,
          checks: [ { "name" => "rspec", "status" => "pass" } ]
        )
        control = YAML.safe_load_file(File.join(target, "config/t40/control-manifest.yml"))["controls"].first
        assert_equal "enabled", control["status"]
        assert_nil control["evidence"]
      end
    end
  end

  def test_risk_and_profile_conditions_change_applicability
    controls = <<~YAML
      controls:
        - id: RISK-01
          name: "Special category safeguards"
          category: privacy
          install_status: deferred
          owner_default: project team
          applies_when:
            data_risk: special_category_data
          reference: docs/one.md
        - id: HIGH-01
          name: "High assurance provenance"
          category: delivery
          install_status: deferred
          owner_default: release owner
          applies_when:
            deployment_profile: high_assurance
          reference: docs/two.md
    YAML
    with_tmpdir do |starter|
      with_tmpdir do |target|
        build_starter_root(starter, controls: controls)
        standard = build_control_manifest(starter).build["controls"]
        assert_equal %w[not_applicable not_applicable], standard.map { |entry| entry["status"] }
        assert standard.all? { |entry| entry["reason"].to_s.include?("manifest") }

        data = valid_manifest_data
        data["data_risk"]["special_category_data"] = true
        data["deployment"]["profile"] = "high_assurance"
        selected = build_control_manifest(starter, manifest: build_manifest(data)).build["controls"]
        assert_equal %w[deferred deferred], selected.map { |entry| entry["status"] }
      end
    end
  end

  def test_catalogue_rejects_a_missing_reference
    controls = <<~YAML
      controls:
        - id: TEST-10
          name: "Broken reference"
          category: delivery
          install_status: enabled
          reference: docs/missing.md
    YAML
    with_tmpdir do |starter|
      build_starter_root(starter, controls: controls)
      error = assert_raises(T40Starter::Error) { build_control_manifest(starter).catalogue }
      assert_includes error.message, "docs/missing.md"
    end
  end

  # Guards the real shipped catalogue in lib/t40_starter/controls.yml.
  def test_shipped_catalogue_is_internally_consistent
    catalogue = T40Starter::ControlManifest.new(manifest: build_manifest, starter_root: REPO_ROOT).catalogue
    assert_operator catalogue.size, :>=, 35, "the contract requires roughly 35 controls"
    ids = catalogue.map { |control| control["id"] }
    assert_equal ids.uniq, ids, "control ids must be unique"
    catalogue.each do |control|
      id = control["id"]
      assert_match(/\A[A-Z]+-\d{2}\z/, id.to_s)
      refute control["name"].to_s.strip.empty?, "#{id}: name required"
      assert_includes ALLOWED_CATEGORIES, control["category"], "#{id}: unknown category"
      assert_includes %w[enabled deferred conditional], control["install_status"], "#{id}: bad install_status"
      if control["install_status"] == "deferred"
        refute control["owner_default"].to_s.strip.empty?, "#{id}: deferred control needs owner_default"
      end
      if control["install_status"] == "conditional"
        assert_includes T40Starter::Manifest::MODULE_NAMES, control["module"], "#{id}: conditional control needs a known module"
      end
      refute control["reference"].to_s.strip.empty?, "#{id}: reference required"
      Array(control["evidence_checks"]).each do |check|
        assert_includes T40Starter::Verifier::CHECK_NAMES, check, "#{id}: unknown evidence check"
      end
    end
  end

  def test_report_lists_deferred_controls_with_owner
    with_tmpdir do |starter|
      with_tmpdir do |target|
        build_starter_root(starter)
        build_control_manifest(starter).write(target)
        report = T40Starter::Report.new(target: target)
        rendered = report.render
        assert_includes rendered, "TEST-02"
        assert_includes rendered, "owner: project team"
        assert_includes rendered, "does not by itself provide"
        assert_equal 1, report.to_h["controls_summary"]["deferred"]
        refute report.to_h["readiness"]["production_ready"]
        assert_equal [ "TEST-02" ], report.to_h["readiness"]["blocking_controls"]
      end
    end
  end
end
