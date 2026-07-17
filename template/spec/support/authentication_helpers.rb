# Request-spec sign-in through the real passwordless flow: request a code,
# read it from the database and submit it. Leaves the signed session cookie on
# the integration session, exactly as a browser would hold it.
module AuthenticationHelpers
  def sign_in_as(identity)
    post session_path, params: { email_address: identity.email_address }
    magic_link = identity.magic_links.order(:id).last
    post session_magic_link_path, params: { code: magic_link.code }
    identity
  end

  def sign_out
    delete session_path
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
end
