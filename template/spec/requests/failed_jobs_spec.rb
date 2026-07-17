require "rails_helper"

RSpec.describe "Failed job operations", type: :request do
  FakeBackend = Struct.new(:entries, :replayed, keyword_init: true) do
    def failures = entries
    def backlog_age = 90
    def replay(id:, account:) = self.replayed = [ id, account.id ]
  end

  let(:admin) { create(:user, :admin) }
  let(:other_account) { create(:account) }
  let(:backend) do
    FakeBackend.new(entries: [
      T40::JobOperations::Failure.new(id: 1, job_class: "AccountActivityJob", error: "timeout",
        failed_at: Time.current, account_id: admin.account_id, attempts: 2),
      T40::JobOperations::Failure.new(id: 2, job_class: "OtherJob", error: "hidden",
        failed_at: Time.current, account_id: other_account.id, attempts: 2)
    ])
  end

  before { T40::JobOperations.backend = backend }
  after { T40::JobOperations.reset! }

  it "shows only tenant failures and backlog age to an authorised operator" do
    sign_in_as(admin.identity)

    get failed_jobs_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("AccountActivityJob")
    expect(response.body).not_to include("OtherJob", "hidden")
  end

  it "requires step-up before bounded replay" do
    sign_in_as(admin.identity)

    post replay_failed_job_path(1)
    expect(response).to have_http_status(:forbidden)
    expect(backend.replayed).to be_nil

    Session.order(:id).last.mark_step_up_verified!
    post replay_failed_job_path(1)

    expect(response).to redirect_to(failed_jobs_path)
    expect(backend.replayed).to eq([ "1", admin.account_id ])
    expect(AuditEvent.where(action: "job.replay", account: admin.account)).to exist
  end
end
