# System specs default to rack_test: the starter's flows are server-rendered
# and need no JavaScript, and rack_test keeps the suite fast and dependency
# free. Switch individual specs to a browser driver only when they need one.
RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end
end
