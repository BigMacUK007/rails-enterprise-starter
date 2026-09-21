# Mail configuration for deployed environments.
#
# Passwordless sign-in is the only way into a T40 Client Environment, so mail
# is not a nice-to-have — if it stops, every user is locked out, including
# T40. config/initializers/t40_boot_validation.rb refuses to start a
# production process whose Action Mailer SMTP settings are absent, and this
# is what supplies them.
#
# Values come from the environment. See config/t40/required-environment.yml.
Rails.application.configure do
  app_host = ENV["APP_HOST"].presence

  if app_host
    uri = URI.parse(app_host)
    url_options = { host: uri.host, protocol: uri.scheme || "https" }
    url_options[:port] = uri.port unless uri.port.nil? || [ 80, 443 ].include?(uri.port)

    config.action_mailer.default_url_options = url_options
    config.action_controller.default_url_options = url_options
    Rails.application.routes.default_url_options = url_options
  end

  smtp_address = ENV["SMTP_ADDRESS"].presence

  next unless smtp_address

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  # A sign-in code that silently fails to send is worse than a visible error.
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.smtp_settings = {
    address: smtp_address,
    port: Integer(ENV.fetch("SMTP_PORT", 587)),
    user_name: ENV["SMTP_USERNAME"].presence,
    password: ENV["SMTP_PASSWORD"].presence,
    authentication: ENV.fetch("SMTP_AUTHENTICATION", "plain").to_sym,
    enable_starttls_auto: true,
    open_timeout: 10,
    read_timeout: 10
  }.compact
end
