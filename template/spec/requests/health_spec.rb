require "rails_helper"

RSpec.describe "Health endpoints", type: :request do
  describe "GET /health/live" do
    it "reports the process is up without authentication or configuration leakage" do
      get "/health/live"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("status" => "ok", "release" => T40::Runtime.release)
    end
  end

  describe "GET /health/ready" do
    it "reports readiness with per-dependency checks" do
      get "/health/ready"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["checks"]["db"]).to be(true)
      expect(body["checks"]).to have_key("queue")
      expect(%w[ ok degraded ]).to include(body["status"])
      expect(body).to have_key("release")
    end

    it "fails readiness when the database is unreachable" do
      allow_any_instance_of(T40::HealthController).to receive(:database_ready?).and_return(false)

      get "/health/ready"

      expect(response).to have_http_status(:service_unavailable)
      body = response.parsed_body
      expect(body["status"]).to eq("unavailable")
      expect(body["checks"]["db"]).to be(false)
    end

    it "degrades but stays ready when only the queue is quiet" do
      allow_any_instance_of(T40::HealthController).to receive(:queue_ready?).and_return(false)

      get "/health/ready"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["status"]).to eq("degraded")
    end
  end

  describe "safe degradation modes" do
    it "keeps health live during maintenance mode while other requests get 503" do
      allow(T40::Runtime).to receive(:maintenance?).and_return(true)

      get "/health/live"
      expect(response).to have_http_status(:ok)

      get new_session_path
      expect(response).to have_http_status(:service_unavailable)
    end

    it "blocks writes in read-only mode while reads continue" do
      allow(T40::Runtime).to receive(:read_only?).and_return(true)
      identity = create(:identity)

      expect {
        post session_path, params: { email_address: identity.email_address }
      }.not_to change(MagicLink, :count)
      expect(response).to have_http_status(:found)
      expect(flash[:alert]).to include("read-only")

      get new_session_path
      expect(response).to have_http_status(:ok)
    end
  end
end
