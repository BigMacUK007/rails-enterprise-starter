require "rails_helper"

RSpec.describe AccountScoped do
  let(:account_a) { create(:account) }
  let(:account_b) { create(:account) }

  it "fails closed: records cannot be saved without an account" do
    widget = TenantWidget.new(name: "Orphan")

    expect(widget).not_to be_valid
    expect(widget.errors[:account_id]).to be_present
  end

  it "scopes queries explicitly with for_account" do
    widget_a = TenantWidget.create!(account: account_a, name: "A")
    widget_b = TenantWidget.create!(account: account_b, name: "B")

    expect(TenantWidget.for_account(account_a)).to contain_exactly(widget_a)
    expect(TenantWidget.for_account(account_b)).to contain_exactly(widget_b)
  end

  it "adds no default scope: tenant scoping must be explicit" do
    TenantWidget.create!(account: account_a, name: "A")
    TenantWidget.create!(account: account_b, name: "B")

    expect(TenantWidget.default_scopes).to be_empty
    expect(TenantWidget.count).to eq(2)
  end

  it "refuses to combine with default_scope" do
    conflicted = Class.new(ApplicationRecord) do
      self.table_name = "tenant_widgets"

      default_scope { where(deleted_at: nil) }
    end

    expect { conflicted.include(AccountScoped) }.to raise_error(ArgumentError, /default_scope/)
  end
end
