require "rails_helper"

RSpec.describe PrivacySubject do
  it "registers including models (Identity ships with a real implementation)" do
    expect(described_class.registered_models).to include(Identity)
  end

  it "registers named models when they include the concern" do
    klass = Class.new(ApplicationRecord) { self.table_name = "tenant_widgets" }
    stub_const("SpecPrivacyRecord", klass)
    SpecPrivacyRecord.include(PrivacySubject)

    expect(described_class.registered_models).to include(SpecPrivacyRecord)
  end

  it "forces implementations to be explicit" do
    subject_model = Class.new(ApplicationRecord) do
      self.table_name = "tenant_widgets"

      include PrivacySubject
    end
    instance = subject_model.new

    expect { instance.privacy_export }.to raise_error(NotImplementedError)
    expect { instance.privacy_erase! }.to raise_error(NotImplementedError)
  end
end
