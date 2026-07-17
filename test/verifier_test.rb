require "test_helper"

class VerifierTest < Minitest::Test
  include T40StarterTest::Helpers

  def test_checks_report_only_the_control_ids_bound_to_them
    shell = Object.new
    def shell.run(*_command, **_options)
      { success: true, status: 0, output: "12 examples, 0 failures\n", duration: 0.01 }
    end

    with_tmpdir do |starter|
      with_tmpdir do |target|
        build_starter_root(starter)
        T40Starter::ControlManifest.new(manifest: build_manifest, starter_root: starter).write(target)
        verifier = T40Starter::Verifier.new(target: target, io: StringIO.new, stream: false, shell: shell)
        results = verifier.run
        assert_predicate verifier, :passed?
        assert_equal [ "TEST-01" ], results.find { |result| result.name == "rspec" }.control_ids
        assert_empty results.find { |result| result.name == "db:prepare" }.control_ids
      end
    end
  end
end
