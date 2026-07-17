require "test_helper"

class EditEngineTest < Minitest::Test
  include T40StarterTest::Helpers

  ROUTES_EDIT_YAML = <<~YAML
    edits:
      - file: config/routes.rb
        section: routes
        anchor: "Rails.application.routes.draw do"
        block: |
          # >>> t40:starter routes >>>
          get "/ping", to: "ping#show"
          # <<< t40:starter routes <<<
      - file: Gemfile
        section: gems
        anchor: EOF
        block: |
          # >>> t40:starter gems >>>
          gem "example"
          # <<< t40:starter gems <<<
  YAML

  FRESH_ROUTES = <<~RUBY
    Rails.application.routes.draw do
      get "up" => "rails/health#show", as: :rails_health_check
    end
  RUBY

  def engine_in(dir)
    path = write_file(dir, "edits.yml", ROUTES_EDIT_YAML)
    T40Starter::EditEngine.new(path)
  end

  def test_insert_after_anchor_with_context_indentation
    with_tmpdir do |dir|
      write_file(dir, "config/routes.rb", FRESH_ROUTES)
      write_file(dir, "Gemfile", "source \"https://rubygems.org\"\n")
      engine = engine_in(dir)
      action = engine.actions_for(dir).first
      assert_equal :edit, action.status
      lines = action.content.lines
      assert_equal "Rails.application.routes.draw do\n", lines[0]
      assert_equal "  # >>> t40:starter routes >>>\n", lines[1]
      assert_equal "  get \"/ping\", to: \"ping#show\"\n", lines[2]
      assert_equal "  # <<< t40:starter routes <<<\n", lines[3]
      assert_equal "  get \"up\" => \"rails/health#show\", as: :rails_health_check\n", lines[4]
    end
  end

  def test_noop_when_block_already_present
    with_tmpdir do |dir|
      write_file(dir, "config/routes.rb", FRESH_ROUTES)
      write_file(dir, "Gemfile", "source \"https://rubygems.org\"\n")
      engine = engine_in(dir)
      engine.actions_for(dir).each do |action|
        File.write(File.join(dir, action.target), action.content)
      end
      engine.actions_for(dir).each do |action|
        assert_equal :noop, action.status, "expected #{action.target} to be a noop on second pass"
      end
    end
  end

  def test_replace_when_markers_present_but_content_differs
    with_tmpdir do |dir|
      drifted = <<~RUBY
        Rails.application.routes.draw do
          # >>> t40:starter routes >>>
          get "/old", to: "old#show"
          # <<< t40:starter routes <<<
        end
      RUBY
      write_file(dir, "config/routes.rb", drifted)
      write_file(dir, "Gemfile", "source \"https://rubygems.org\"\n")
      engine = engine_in(dir)
      action = engine.actions_for(dir).first
      assert_equal :edit, action.status
      assert_includes action.reason, "replace"
      assert_includes action.content, "get \"/ping\", to: \"ping#show\""
      refute_includes action.content, "/old"
      assert_equal 1, action.content.scan("# >>> t40:starter routes >>>").size
    end
  end

  def test_conflict_when_anchor_missing
    with_tmpdir do |dir|
      write_file(dir, "config/routes.rb", "# no routes block here\n")
      write_file(dir, "Gemfile", "source \"https://rubygems.org\"\n")
      engine = engine_in(dir)
      action = engine.actions_for(dir).first
      assert_equal :conflict, action.status
      assert_includes action.reason, "anchor not found"
    end
  end

  def test_conflict_when_target_file_missing
    with_tmpdir do |dir|
      write_file(dir, "Gemfile", "source \"https://rubygems.org\"\n")
      engine = engine_in(dir)
      action = engine.actions_for(dir).first
      assert_equal :conflict, action.status
      assert_includes action.reason, "target file missing"
    end
  end

  def test_conflict_when_only_one_marker_present
    with_tmpdir do |dir|
      broken = <<~RUBY
        Rails.application.routes.draw do
          # >>> t40:starter routes >>>
          get "/orphan", to: "orphan#show"
        end
      RUBY
      write_file(dir, "config/routes.rb", broken)
      write_file(dir, "Gemfile", "source \"https://rubygems.org\"\n")
      action = engine_in(dir).actions_for(dir).first
      assert_equal :conflict, action.status
      assert_includes action.reason, "malformed"
    end
  end

  def test_eof_append_keeps_block_unindented_and_is_idempotent
    with_tmpdir do |dir|
      write_file(dir, "config/routes.rb", FRESH_ROUTES)
      write_file(dir, "Gemfile", "source \"https://rubygems.org\"\ngem \"rails\"")
      engine = engine_in(dir)
      action = engine.actions_for(dir).last
      assert_equal :edit, action.status
      assert action.content.end_with?("# >>> t40:starter gems >>>\ngem \"example\"\n# <<< t40:starter gems <<<\n")
      assert_includes action.content, "gem \"rails\"\n# >>>"
      File.write(File.join(dir, "Gemfile"), action.content)
      assert_equal :noop, engine.actions_for(dir).last.status
    end
  end

  # The shipped edits.yml must apply cleanly to fresh-Rails-shaped files and
  # be idempotent. The file contents here are fabricated stand-ins, not the
  # real template (integration covers that).
  def test_shipped_edits_round_trip_on_fresh_rails_files
    with_tmpdir do |dir|
      build_rails_target(dir)
      engine = T40Starter::EditEngine.new(File.join(REPO_ROOT, "lib", "t40_starter", "edits.yml"))
      actions = engine.actions_for(dir)
      assert_equal 4, actions.size
      actions.each do |action|
        assert_equal :edit, action.status, "expected edit for #{action.target}, got #{action.status} (#{action.reason})"
        File.write(File.join(dir, action.target), action.content)
      end
      engine.actions_for(dir).each do |action|
        assert_equal :noop, action.status, "expected noop for #{action.target} after apply"
      end
      routes = File.read(File.join(dir, "config/routes.rb"))
      assert_includes routes, "  resource :session, only: %i[ new create destroy ] do\n"
      assert_includes routes, "  get \"/health/live\",  to: \"t40/health#live\"\n"
      controller = File.read(File.join(dir, "app/controllers/application_controller.rb"))
      assert_includes controller, "  include Authentication\n"
      assert_includes controller, "  include MaintenanceMode\n"
      job = File.read(File.join(dir, "app/jobs/application_job.rb"))
      assert_includes job, "  include T40::JobContext\n"
      gemfile = File.read(File.join(dir, "Gemfile"))
      assert_includes gemfile, "group :development, :test do\n  gem \"rspec-rails\"\n"
    end
  end
end
