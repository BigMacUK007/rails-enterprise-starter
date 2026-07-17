# Use the Active Job test adapter everywhere so enqueued work (including
# magic-link emails) is captured, inspectable and never performed on a
# background thread that could escape the test transaction.
RSpec.configure do |config|
  config.include ActiveJob::TestHelper

  config.before do
    ActiveJob::Base.queue_adapter = :test
  end
end
