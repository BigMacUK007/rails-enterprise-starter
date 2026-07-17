require "rails_helper"

RSpec.describe "Security headers", type: :request do
  before { get new_session_path }

  it "ships a Content Security Policy in report-only rollout mode" do
    csp = response.headers["Content-Security-Policy-Report-Only"]

    expect(csp).to include("default-src 'self'")
    expect(csp).to include("frame-ancestors 'none'")
    expect(csp).to include("base-uri 'self'")
    expect(csp).to include("form-action 'self'")
    expect(response.headers["Content-Security-Policy"]).to be_nil
  end

  it "prevents MIME sniffing" do
    expect(response.headers["X-Content-Type-Options"]).to eq("nosniff")
  end

  it "denies framing" do
    expect(response.headers["X-Frame-Options"]).to eq("DENY")
  end

  it "restricts referrer leakage" do
    expect(response.headers["Referrer-Policy"]).to eq("strict-origin-when-cross-origin")
  end

  it "locks down powerful browser features" do
    permissions = response.headers["Permissions-Policy"]

    expect(permissions).to include("camera=()")
    expect(permissions).to include("microphone=()")
    expect(permissions).to include("geolocation=()")
  end

  it "exposes no permissive cross-origin surface in the core application" do
    expect(response.headers["Access-Control-Allow-Origin"]).to be_nil
    expect(response.headers["Access-Control-Allow-Credentials"]).to be_nil
  end
end
