require "rails_helper"

RSpec.describe T40::Privacy do
  let(:account) { create(:account) }
  let(:identity) { create(:identity) }

  before { create(:user, account: account, identity: identity) }

  it "runs the export hook only under current tenant authority and audits it" do
    result = nil
    Current.set(account: account, identity: identity) do
      expect_audit_event(action: "privacy.export") do
        result = described_class.export_for(identity)
      end
    end

    expect(result).to include("email_address" => identity.email_address)
  end

  it "fails closed for cross-tenant operations" do
    other = create(:account)

    Current.set(account: account) do
      expect { described_class.export_for(identity, account: other) }
        .to raise_error(T40::Privacy::TenantMismatch)
    end
  end

  it "makes unimplemented project hooks explicit" do
    Current.set(account: account) do
      expect { described_class.restrict!(identity, reason: "request received") }
        .to raise_error(T40::Privacy::MissingHook, /privacy_restriction/)
    end
  end
end
