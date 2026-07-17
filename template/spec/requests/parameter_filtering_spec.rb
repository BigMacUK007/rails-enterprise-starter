require "rails_helper"

# Asserted through Rails configuration inspection rather than log scraping:
# the same filter_parameters config drives request logs, error reports and
# parameter inspection.
RSpec.describe "Parameter filtering" do
  let(:filters) { Rails.application.config.filter_parameters }

  it "filters Rails defaults and starter-added sensitive values from inspected parameters" do
    filter = ActiveSupport::ParameterFilter.new(filters)

    filtered = filter.filter(
      "code" => "ABC123",
      "password" => "hunter2",
      "secret" => "secret-value",
      "token" => "token-value",
      "magic_link" => "xyz",
      "cvv" => "123",
      "pan" => "4111111111111111",
      "national_insurance" => "QQ123456C",
      "date_of_birth" => "1990-01-01",
      "display_name" => "Jo"
    )

    %w[code password secret token magic_link cvv pan national_insurance date_of_birth].each do |key|
      expect(filtered[key]).to eq("[FILTERED]")
    end
    expect(filtered["display_name"]).to eq("Jo")
  end
end
