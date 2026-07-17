require "rails_helper"

RSpec.describe SoftDeletable do
  # Anonymous model on the tenant_widgets temporary table: soft deletion is a
  # cross-cutting convention, not tied to any shipped domain model.
  let(:model) do
    Class.new(ApplicationRecord) do
      self.table_name = "tenant_widgets"

      include SoftDeletable
    end
  end
  let(:account) { create(:account) }
  let(:record) { model.create!(account_id: account.id, name: "Disposable") }

  it "starts kept" do
    expect(record).not_to be_soft_deleted
    expect(model.kept).to include(record)
    expect(model.soft_deleted).not_to include(record)
  end

  it "soft deletes with audit evidence" do
    event = expect_audit_event(action: "tenant_widgets.soft_delete") do
      record.soft_delete!
    end

    expect(record.reload).to be_soft_deleted
    expect(model.kept).not_to include(record)
    expect(model.soft_deleted).to include(record)
    expect(event.target_id).to eq(record.id)
  end

  it "restores with audit evidence" do
    record.soft_delete!

    expect_audit_event(action: "tenant_widgets.restore") do
      record.restore!
    end

    expect(record.reload).not_to be_soft_deleted
    expect(model.kept).to include(record)
  end

  it "is recoverability, not erasure: the row still exists after soft deletion" do
    record.soft_delete!

    expect(model.exists?(record.id)).to be(true)
  end
end
