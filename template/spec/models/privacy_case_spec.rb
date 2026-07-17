require "rails_helper"

RSpec.describe PrivacyCase do
  let(:account) { create(:account) }
  let(:identity) { create(:identity) }
  let(:privacy_case) { described_class.create!(account: account, identity: identity, kind: "complaint") }

  it "records the complete complaint workflow as tenant audit evidence" do
    Current.set(account: account, identity: identity) do
      %w[acknowledged investigating in_progress completed].each do |state|
        expect_audit_event(action: "privacy_case.#{state}") do
          privacy_case.transition_to!(state, outcome: ("resolved" if state == "completed"))
        end
      end
    end

    expect(privacy_case.reload.state).to eq("completed")
    expect(privacy_case.acknowledged_at).to be_present
    expect(privacy_case.completed_at).to be_present
    expect(privacy_case.outcome).to eq("resolved")
  end

  it "rejects skipped workflow states" do
    expect { privacy_case.transition_to!("completed") }.to raise_error(ArgumentError)
  end

  it "cannot be read through another account scope" do
    other = create(:account)

    expect(described_class.for_account(other).find_by(id: privacy_case.id)).to be_nil
  end
end
