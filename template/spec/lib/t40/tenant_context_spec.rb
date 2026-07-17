require "rails_helper"

RSpec.describe T40::TenantContext do
  let(:account) { create(:account) }

  it "fails closed without tenant authority" do
    expect { described_class.cache_key("dashboard") }
      .to raise_error(T40::TenantContext::MissingAccount)
    expect { described_class.storage_key(filename: "report.pdf") }
      .to raise_error(T40::TenantContext::MissingAccount)
    expect { described_class.rate_limit_key(scope: "export", discriminator: "42") }
      .to raise_error(T40::TenantContext::MissingAccount)
  end

  it "names every context carrier with the current account" do
    Current.set(account: account) do
      expect(described_class.cache_key("dashboard")).to eq("account/#{account.id}/dashboard")
      expect(described_class.storage_key(filename: "../report.pdf"))
        .to eq("accounts/#{account.id}/unbound/report.pdf")
      expect(described_class.rate_limit_key(scope: "export", discriminator: "42"))
        .to eq("account:#{account.id}:export:42")
      expect(described_class.log_context).to eq(account_id: account.id)
    end
  end

  it "keeps two accounts' carrier values distinct" do
    other = create(:account)

    expect(described_class.cache_key("same", account: account))
      .not_to eq(described_class.cache_key("same", account: other))
  end
end
