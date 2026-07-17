require "test_helper"

# The only test allowed to look at the real template/ directory: a cheap
# smoke check that the tree exists and every .t40erb template is valid ERB
# with syntactically valid embedded Ruby. Template content is authored
# separately and fully exercised by bin/acceptance, so this test skips
# cleanly while the tree is incomplete.
class TemplateSmokeTest < Minitest::Test
  include T40StarterTest::Helpers

  TEMPLATE_DIR = File.join(REPO_ROOT, "template")

  def test_template_exists_and_every_t40erb_parses
    skip "template/ not present yet (authored separately; covered by bin/acceptance)" unless Dir.exist?(TEMPLATE_DIR)

    erb_files = Dir.glob(File.join(TEMPLATE_DIR, "**", "*.t40erb"), File::FNM_DOTMATCH)
    erb_files.each do |path|
      source = ERB.new(File.read(path), trim_mode: "-").src
      RubyVM::InstructionSequence.compile(source)
    rescue SyntaxError => error
      flunk "#{path} contains invalid embedded Ruby: #{error.message}"
    end
    assert Dir.exist?(TEMPLATE_DIR)
  end

  def test_every_generated_migration_uses_the_supported_rails_version
    migrations = Dir.glob(File.join(TEMPLATE_DIR, "db", "migrate", "*.rb"))
    refute_empty migrations
    migrations.each do |path|
      assert_includes File.read(path), "ActiveRecord::Migration[8.1]", File.basename(path)
    end
  end

  def test_assurance_matrix_is_rendered_from_the_authoritative_catalogue
    with_tmpdir do |target|
      build_rails_target(target)
      manifest = build_manifest
      registry = T40Starter::Registry.new(manifest: manifest, target: target, starter_root: REPO_ROOT)
      action = registry.actions.find { |entry| entry.target == "docs/assurance/assurance-matrix.md" }
      refute_nil action
      matrix_ids = action.content.scan(/^\| ([A-Z]+-\d{2}) \|/).flatten
      expected_ids = T40Starter::ControlManifest.new(manifest: manifest, starter_root: REPO_ROOT)
                                                .build["controls"].map { |entry| entry["id"] }
      assert_equal expected_ids, matrix_ids
    end
  end

  def test_ci_dependencies_are_immutable_and_untrusted_prs_have_no_privileged_trigger
    workflows = Dir.glob(File.join(REPO_ROOT, "{.github,template/.github}", "workflows", "*.yml"))
    refute_empty workflows

    workflows.each do |path|
      content = File.read(path)
      refute_includes content, "pull_request_target:", path

      content.scan(/^\s*uses:\s*[^\s@]+@([^\s#]+)/).flatten.each do |reference|
        assert_match(/\A[0-9a-f]{40}\z/, reference, "#{path} has a floating action reference: #{reference}")
      end

      content.scan(/^\s*image:\s*(\S+)/).flatten.each do |image|
        assert_match(/@sha256:[0-9a-f]{64}\z/, image, "#{path} has a floating service image: #{image}")
      end
    end
  end
end
