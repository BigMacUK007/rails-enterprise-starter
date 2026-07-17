# Browser security headers for every response.
#
# The Content Security Policy starts in REPORT-ONLY mode so existing pages and
# integrations can be tuned against real traffic without breakage. Once the
# report stream is clean, set T40_CSP_ENFORCE=1 to enforce the policy.
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.script_src :self
    policy.style_src :self, :unsafe_inline # inline styles used by importmap-era views
    policy.img_src :self, :data
    policy.frame_ancestors :none
    policy.base_uri :self
    policy.form_action :self
  end

  config.content_security_policy_report_only = ENV["T40_CSP_ENFORCE"] != "1"
end

Rails.application.config.action_dispatch.default_headers.merge!(
  "X-Frame-Options" => "DENY",
  "X-Content-Type-Options" => "nosniff",
  "Referrer-Policy" => "strict-origin-when-cross-origin",
  "Permissions-Policy" => "camera=(), microphone=(), geolocation=()"
)
