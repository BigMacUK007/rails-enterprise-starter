# Fail-closed production boot checks. A misconfigured production process
# raises here rather than starting insecurely. The full list of required
# configuration references lives in config/t40/required-environment.yml —
# references only, never secret values.
if Rails.env.production?
  Rails.application.config.after_initialize do
    failures = []

    secret = begin
      Rails.application.secret_key_base
    rescue StandardError
      nil
    end
    if secret.blank? || secret.to_s.length < 32
      failures << "SECRET_KEY_BASE is missing or too short — set it via Rails credentials or your secret manager"
    end

    unless Rails.application.config.force_ssl
      failures << "config.force_ssl is disabled — production must enforce HTTPS"
    end

    mailer_config = Rails.application.config.action_mailer
    delivery_method = mailer_config.delivery_method || ActionMailer::Base.delivery_method
    if delivery_method.blank?
      failures << "Action Mailer delivery_method is not set — passwordless sign-in requires working mail delivery"
    elsif delivery_method.to_s == "smtp" && mailer_config.smtp_settings.blank?
      failures << "Action Mailer SMTP settings are absent — configure config.action_mailer.smtp_settings"
    end

    if failures.any?
      raise "T40 boot validation failed:\n" +
        failures.map { |failure| "  - #{failure}" }.join("\n") +
        "\nSee config/t40/required-environment.yml for the required configuration references."
    end

    unless defined?(SolidQueue::Job) && Rails.application.config.active_job.queue_adapter.to_s.include?("solid_queue")
      raise "T40 boot validation failed:\n  - Solid Queue is not installed and selected as the production Active Job adapter"
    end
  end
end
