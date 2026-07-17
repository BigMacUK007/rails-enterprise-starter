require "test_helper"

class ManifestTest < Minitest::Test
  include T40StarterTest::Helpers

  def test_valid_core_manifest
    manifest = build_manifest
    assert_predicate manifest, :valid?
    assert_empty manifest.errors
    assert_equal "T40 Acceptance App", manifest.project_name
    assert_equal "t40-acceptance-app", manifest.identifier
    assert_equal "multi_account", manifest.tenancy_mode
    assert_equal "passwordless", manifest.authentication_mode
    assert_equal "standard", manifest.deployment_profile
    assert_empty manifest.selected_modules
  end

  def test_defaults_applied_when_optional_sections_missing
    data = valid_manifest_data
    data.delete("tenancy")
    data.delete("authentication")
    data.delete("modules")
    data.delete("deployment")
    manifest = build_manifest(data)
    assert_predicate manifest, :valid?
    assert_equal "multi_account", manifest.to_h["tenancy"]["mode"]
    assert_equal "passwordless", manifest.to_h["authentication"]["mode"]
    assert_equal "standard", manifest.to_h["deployment"]["profile"]
    T40Starter::Manifest::MODULE_NAMES.each do |mod|
      assert_equal false, manifest.to_h["modules"][mod], "module #{mod} should default to false"
    end
  end

  def test_unknown_top_level_key_is_rejected
    data = valid_manifest_data.merge("surprise" => true)
    manifest = build_manifest(data)
    refute_predicate manifest, :valid?
    assert_includes manifest.errors.join, "unknown top-level key: surprise"
  end

  def test_unknown_module_is_rejected_fail_closed
    data = valid_manifest_data
    data["modules"]["blockchain"] = true
    manifest = build_manifest(data)
    refute_predicate manifest, :valid?
    assert_includes manifest.errors.join, "unknown module: blockchain"
  end

  def test_non_boolean_module_value_is_rejected
    data = valid_manifest_data
    data["modules"]["api"] = "yes"
    manifest = build_manifest(data)
    refute_predicate manifest, :valid?
    assert_includes manifest.errors.join, "modules.api must be true or false"
  end

  def test_bad_tenancy_enum_is_rejected
    data = valid_manifest_data
    data["tenancy"]["mode"] = "multi_tenant"
    manifest = build_manifest(data)
    refute_predicate manifest, :valid?
    assert_includes manifest.errors.join, "tenancy.mode must be one of"
  end

  def test_non_passwordless_authentication_is_rejected
    data = valid_manifest_data
    data["authentication"]["mode"] = "devise"
    manifest = build_manifest(data)
    refute_predicate manifest, :valid?
    assert_includes manifest.errors.join, "authentication.mode must be one of: passwordless"
  end

  def test_bad_deployment_profile_is_rejected
    data = valid_manifest_data
    data["deployment"]["profile"] = "yolo"
    manifest = build_manifest(data)
    refute_predicate manifest, :valid?
  end

  def test_missing_data_risk_section_is_rejected
    data = valid_manifest_data
    data.delete("data_risk")
    manifest = build_manifest(data)
    refute_predicate manifest, :valid?
    assert_includes manifest.errors.join, "data_risk section is required"
  end

  def test_missing_single_data_risk_answer_is_rejected
    data = valid_manifest_data
    data["data_risk"].delete("children_data")
    manifest = build_manifest(data)
    refute_predicate manifest, :valid?
    assert_includes manifest.errors.join, "data_risk.children_data must be answered true or false"
  end

  def test_non_boolean_data_risk_answer_is_rejected
    data = valid_manifest_data
    data["data_risk"]["personal_data"] = "probably"
    manifest = build_manifest(data)
    refute_predicate manifest, :valid?
  end

  def test_passwordless_authentication_requires_personal_data_to_be_acknowledged
    data = valid_manifest_data
    data["data_risk"]["personal_data"] = false
    manifest = build_manifest(data)
    refute manifest.valid?
    assert_includes manifest.errors.join, "passwordless authentication processes an email address"
  end

  def test_bad_identifier_is_rejected
    [ "My App", "-leading", "UPPER", "" ].each do |identifier|
      data = valid_manifest_data
      data["project"]["identifier"] = identifier
      manifest = build_manifest(data)
      refute_predicate manifest, :valid?, "identifier #{identifier.inspect} should be invalid"
    end
  end

  def test_wrong_manifest_version_is_rejected
    data = valid_manifest_data.merge("manifest_version" => 2)
    manifest = build_manifest(data)
    refute_predicate manifest, :valid?
    assert_includes manifest.errors.join, "manifest_version must be the integer 1"
  end

  def test_sha256_is_deterministic_and_content_sensitive
    first = build_manifest.sha256
    second = build_manifest.sha256
    assert_equal first, second
    changed = valid_manifest_data
    changed["project"]["name"] = "Other"
    refute_equal first, build_manifest(changed).sha256
  end

  def test_load_raises_on_missing_file
    error = assert_raises(T40Starter::Error) { T40Starter::Manifest.load("/nonexistent/t40-manifest.yml") }
    assert_includes error.message, "manifest not found"
  end

  def test_load_raises_on_invalid_yaml
    with_tmpdir do |dir|
      path = write_file(dir, "t40-manifest.yml", "foo: [unclosed\n")
      assert_raises(T40Starter::Error) { T40Starter::Manifest.load(path) }
    end
  end

  def test_load_parses_core_manifest_file
    with_tmpdir do |dir|
      path = write_file(dir, "t40-manifest.yml", valid_manifest_data.to_yaml)
      manifest = T40Starter::Manifest.load(path)
      assert_predicate manifest, :valid?
      assert_equal build_manifest.sha256, manifest.sha256
    end
  end

  def test_interactive_builds_valid_manifest_from_answers
    answers = [ "My Client Portal", "", "", *Array.new(7, ""), "", "y", "n", "y" ].join("\n") + "\n"
    input = StringIO.new(answers)
    output = StringIO.new
    manifest = T40Starter::Manifest.interactive(input, output)
    assert_predicate manifest, :valid?
    assert_equal "My Client Portal", manifest.project_name
    assert_equal "my-client-portal", manifest.identifier
    assert_equal "multi_account", manifest.tenancy_mode
    assert_empty manifest.selected_modules
    expected_risk = {
      "personal_data" => true, "special_category_data" => true,
      "children_data" => false, "financial_data" => true
    }
    assert_equal expected_risk, manifest.data_risk
    assert_includes output.string, "Project name"
  end

  def test_interactive_module_selection_is_captured
    answers = [ "App", "", "single_account", "y", *Array.new(6, "n"), "", "", "", "" ].join("\n") + "\n"
    manifest = T40Starter::Manifest.interactive(StringIO.new(answers), StringIO.new)
    assert_predicate manifest, :valid?
    assert_equal "single_account", manifest.tenancy_mode
    assert_equal [ "oidc" ], manifest.selected_modules
  end

  def test_interactive_raises_when_input_ends
    assert_raises(T40Starter::Error) { T40Starter::Manifest.interactive(StringIO.new(""), StringIO.new) }
  end
end
