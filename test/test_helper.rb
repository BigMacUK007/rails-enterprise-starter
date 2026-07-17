$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "yaml"
require "json"
require "stringio"
require "erb"
require "t40_starter/cli"

module T40StarterTest
  # Shared tmpdir fixtures. Installer unit tests never touch the real
  # template/ directory — they build their own starter checkouts so the
  # tests stay valid while template content evolves.
  module Helpers
    REPO_ROOT = File.expand_path("..", __dir__)

    VALID_MANIFEST_DATA = {
      "manifest_version" => 1,
      "project" => { "name" => "T40 Acceptance App", "identifier" => "t40-acceptance-app" },
      "tenancy" => { "mode" => "multi_account" },
      "authentication" => { "mode" => "passwordless" },
      "modules" => {
        "oidc" => false, "saml" => false, "scim" => false, "rls" => false,
        "api" => false, "webhooks" => false, "ai" => false
      },
      "data_risk" => {
        "personal_data" => true, "special_category_data" => false,
        "children_data" => false, "financial_data" => false
      },
      "deployment" => { "profile" => "standard" }
    }.freeze

    FIXTURE_CONTROLS_YAML = <<~YAML.freeze
      controls:
        - id: TEST-01
          name: "Enabled control"
          category: authentication
          install_status: enabled
          evidence_checks: [rspec]
          reference: docs/one.md
        - id: TEST-02
          name: "Deferred control"
          category: backup
          install_status: deferred
          owner_default: project team
          production_gate: true
          reference: docs/two.md
        - id: TEST-03
          name: "Conditional control"
          category: ai
          install_status: conditional
          module: ai
          reference: modules/ai/MODULE.md
    YAML

    EMPTY_EDITS_YAML = "edits: []\n"

    def valid_manifest_data
      Marshal.load(Marshal.dump(VALID_MANIFEST_DATA))
    end

    def build_manifest(data = valid_manifest_data)
      T40Starter::Manifest.new(data)
    end

    def with_tmpdir(&block)
      Dir.mktmpdir("t40-starter-test-", &block)
    end

    # A minimal fake starter checkout: template/, modules/, lib/t40_starter/
    # with edits.yml and controls.yml.
    def build_starter_root(dir, edits: EMPTY_EDITS_YAML, controls: FIXTURE_CONTROLS_YAML)
      FileUtils.mkdir_p(File.join(dir, "template"))
      FileUtils.mkdir_p(File.join(dir, "modules"))
      FileUtils.mkdir_p(File.join(dir, "lib", "t40_starter"))
      File.write(File.join(dir, "lib", "t40_starter", "edits.yml"), edits)
      File.write(File.join(dir, "lib", "t40_starter", "controls.yml"), controls)
      write_file(dir, "template/docs/one.md", "# One\n")
      write_file(dir, "template/docs/two.md", "# Two\n")
      write_file(dir, "modules/ai/MODULE.md", "# AI\n")
      write_module(dir, "ai", status: "interface_only")
      dir
    end

    def write_file(root, relative, content)
      path = File.join(root, relative)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, content)
      path
    end

    def write_module(starter_root, name, status:)
      write_file(starter_root, File.join("modules", name, "module.yml"),
                 { "schema_version" => 1, "name" => name, "status" => status, "summary" => "test",
                   "requires_approved_scope" => true,
                   "conformance" => { "contract" => "MODULE.md", "required_checks" => [] } }.to_yaml)
      write_file(starter_root, File.join("modules", name, "MODULE.md"), "# #{name}\n")
    end

    # A target that passes the Rails-app shaped preflight checks.
    def build_rails_target(dir)
      write_file(dir, "Gemfile", <<~RUBY)
        source "https://rubygems.org"

        gem "rails", "~> 8.1.0"
      RUBY
      write_file(dir, "config/database.yml", <<~YAML)
        default: &default
          adapter: postgresql
        development:
          <<: *default
      YAML
      write_file(dir, "config/routes.rb", <<~RUBY)
        Rails.application.routes.draw do
          get "up" => "rails/health#show", as: :rails_health_check
        end
      RUBY
      write_file(dir, "app/controllers/application_controller.rb", <<~RUBY)
        class ApplicationController < ActionController::Base
          allow_browser versions: :modern
        end
      RUBY
      write_file(dir, "app/jobs/application_job.rb", <<~RUBY)
        class ApplicationJob < ActiveJob::Base
        end
      RUBY
      dir
    end

    # { relative path => file content } for every file below dir.
    def snapshot(dir)
      Dir.glob("**/*", File::FNM_DOTMATCH, base: dir).sort.each_with_object({}) do |relative, result|
        path = File.join(dir, relative)
        result[relative] = File.binread(path) if File.file?(path)
      end
    end

    def with_env(pairs)
      saved = pairs.keys.to_h { |key| [ key, ENV[key] ] }
      pairs.each { |key, value| ENV[key] = value }
      yield
    ensure
      saved.each { |key, value| ENV[key] = value }
    end

    def run_cli(argv, stdin: StringIO.new)
      stdout = StringIO.new
      stderr = StringIO.new
      status = T40Starter::CLI.run(argv, stdin: stdin, stdout: stdout, stderr: stderr)
      [ status, stdout.string, stderr.string ]
    end
  end
end
