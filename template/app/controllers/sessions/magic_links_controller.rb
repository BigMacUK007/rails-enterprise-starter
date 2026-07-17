class Sessions::MagicLinksController < ApplicationController
  require_unauthenticated_access
  rate_limit to: 10, within: 15.minutes, only: :create, with: :rate_limit_exceeded
  before_action :ensure_pending_authentication

  layout "public"

  def show
    render T40::Ui::MagicLinkEntry.new(email_address: email_address_pending_authentication)
  end

  def create
    identity = Identity.find_by(email_address: email_address_pending_authentication)
    if magic_link = MagicLink.consume(code, identity: identity, purpose: :sign_in)
      sign_in magic_link
    else
      invalid_code
    end
  end

  private
    def ensure_pending_authentication
      unless email_address_pending_authentication.present?
        redirect_to new_session_path, alert: "Enter your email address to sign in."
      end
    end

    def code
      params.expect(:code)
    end

    def sign_in(magic_link)
      clear_pending_authentication_token
      start_new_session_for magic_link.identity
      redirect_to after_authentication_url
    end

    def invalid_code
      redirect_to session_magic_link_path, alert: "Invalid code. Try again."
    end

    def rate_limit_exceeded
      redirect_to session_magic_link_path, alert: "Try again in 15 minutes."
    end
end
