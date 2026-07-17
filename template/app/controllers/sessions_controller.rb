class SessionsController < ApplicationController
  require_unauthenticated_access except: :destroy
  rate_limit to: 10, within: 3.minutes, only: :create, with: :rate_limit_exceeded

  layout "public"

  def new
    render T40::Ui::SignIn.new
  end

  def create
    if identity = Identity.find_by(email_address: email_address)
      send_magic_link(identity)
    else
      request_decoy_magic_link
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end

  private
    def email_address
      params.expect(:email_address)
    end

    def send_magic_link(identity)
      magic_link = identity.send_magic_link
      set_pending_authentication_token identity.email_address, expires_at: magic_link.expires_at
      redirect_to session_magic_link_path
    end

    def request_decoy_magic_link
      MagicLink.decoy_code
      MagicLinkRequestJob.perform_later(email_address.to_s.strip.downcase)
      set_pending_authentication_token email_address, expires_at: MagicLink::EXPIRATION_TIME.from_now
      redirect_to session_magic_link_path
    end

    def rate_limit_exceeded
      redirect_to new_session_path, alert: "Try again later."
    end
end
