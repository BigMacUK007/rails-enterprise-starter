class MagicLinkRequestJob < ApplicationJob
  queue_as :mailers
  job_policy timeout: 15.seconds, attempts: 5,
    retryable: [ Timeout::Error ],
    discardable: [ ActiveJob::DeserializationError ]

  def perform(email_address)
    identity = Identity.find_by(email_address: email_address.to_s.strip.downcase)
    magic_link = identity&.magic_links&.active&.order(:id)&.last
    return unless magic_link

    MagicLinkMailer.sign_in_instructions(magic_link).deliver_now
  end
end
