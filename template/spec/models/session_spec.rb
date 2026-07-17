require "rails_helper"

RSpec.describe Session do
  let(:identity) { create(:identity) }

  describe "lifetime constants" do
    it "limits inactivity to two weeks and absolute lifetime to twelve weeks" do
      expect(Session::INACTIVITY_TIMEOUT).to eq(2.weeks)
      expect(Session::ABSOLUTE_LIFETIME).to eq(12.weeks)
    end
  end

  describe "#expired?" do
    it "is not expired when recently active" do
      session = identity.sessions.create!

      expect(session).not_to be_expired
    end

    it "expires after the inactivity timeout" do
      session = identity.sessions.create!

      travel(Session::INACTIVITY_TIMEOUT + 1.day) do
        expect(session).to be_expired
      end
    end

    it "expires after the absolute lifetime even when continuously active" do
      session = identity.sessions.create!
      session.update_columns(created_at: (Session::ABSOLUTE_LIFETIME + 1.day).ago, updated_at: 1.hour.ago)

      expect(session.reload).to be_expired
    end
  end

  describe ".active" do
    it "excludes inactive and over-age sessions" do
      fresh = identity.sessions.create!
      inactive = identity.sessions.create!
      inactive.update_columns(updated_at: (Session::INACTIVITY_TIMEOUT + 1.day).ago)
      over_age = identity.sessions.create!
      over_age.update_columns(created_at: (Session::ABSOLUTE_LIFETIME + 1.day).ago)

      expect(Session.active).to include(fresh)
      expect(Session.active).not_to include(inactive)
      expect(Session.active).not_to include(over_age)
    end
  end

  describe "#touch_activity" do
    it "touches at most once per hour to avoid write storms" do
      session = identity.sessions.create!

      expect { session.touch_activity }.not_to change { session.reload.updated_at }

      travel(2.hours) do
        expect { session.touch_activity }.to change { session.reload.updated_at }
      end
    end
  end

  describe ".revoke_all_for" do
    it "destroys every session for the identity and records audit evidence" do
      2.times { identity.sessions.create! }

      event = expect_audit_event(action: "session.revoke_all") do
        Session.revoke_all_for(identity)
      end

      expect(identity.sessions.count).to eq(0)
      expect(event.target).to eq(identity)
    end
  end

  describe "step-up authentication" do
    it "fails closed until an approved mechanism marks the session" do
      session = identity.sessions.create!
      expect(session).not_to be_step_up_verified

      session.mark_step_up_verified!

      expect(session.reload).to be_step_up_verified
    end
  end
end
