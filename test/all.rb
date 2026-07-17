# Runs the complete installer unit-test suite:
#
#   ruby -Ilib -Itest test/all.rb
#
# Pure Ruby + tmpdir fixtures — no Rails, no network, no real template/
# dependency (except the tolerant smoke test).
require_relative "manifest_test"
require_relative "edit_engine_test"
require_relative "registry_test"
require_relative "control_manifest_test"
require_relative "verifier_test"
require_relative "installer_test"
require_relative "cli_test"
require_relative "template_smoke_test"
