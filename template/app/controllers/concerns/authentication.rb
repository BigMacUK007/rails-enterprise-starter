module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
    helper_method :email_address_pending_authentication
  end

  class_methods do
    def require_unauthenticated_access(**options)
      allow_unauthenticated_access(**options)
      before_action :redirect_authenticated_user, **options
    end

    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
      before_action :resume_session, **options
    end
  end

  private
    def authenticated?
      Current.identity.present?
    end

    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      if session = find_session_by_cookie
        if session.expired?
          terminate_expired_session session
          nil
        else
          session.touch_activity
          set_current_session session
        end
      end
    end

    # Expired sessions (inactivity or absolute lifetime — see Session) are
    # destroyed and treated as unauthenticated.
    def terminate_expired_session(session)
      session.destroy
      cookies.delete(:session_token)
    end

    def find_session_by_cookie
      Session.find_signed(cookies.signed[:session_token])
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to new_session_path
    end

    def after_authentication_url
      destination = session.delete(:return_to_after_authenticating) || root_url
      if account_selection_required?
        session[:return_to_after_account_selection] = destination
        account_selection_url
      else
        destination
      end
    end

    def redirect_authenticated_user
      redirect_to root_url if authenticated?
    end

    def start_new_session_for(identity)
      reset_session_preserving_return_to
      identity.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        set_current_session session
      end
    end

    # Rotate the Rack session on authentication to prevent session fixation,
    # keeping the post-sign-in return location intact.
    def reset_session_preserving_return_to
      return_to = session[:return_to_after_authenticating]
      reset_session
      session[:return_to_after_authenticating] = return_to if return_to
    end

    def set_current_session(session)
      Current.session = session
      cookies.signed.permanent[:session_token] = { value: session.signed_id, httponly: true, same_site: :lax }
    end

    def terminate_session
      Current.session.destroy
      cookies.delete(:session_token)
    end

    def account_selection_required?
      !T40::Installation.single_account? && Current.identity&.users&.active&.count.to_i > 1
    end

    # Pending authentication cookie — tracks which email is being verified
    def set_pending_authentication_token(email_address, expires_at:)
      cookies.signed[:pending_authentication] = {
        value: email_address,
        expires: expires_at,
        httponly: true,
        same_site: :lax
      }
    end

    def email_address_pending_authentication
      cookies.signed[:pending_authentication]
    end

    def clear_pending_authentication_token
      cookies.delete(:pending_authentication)
    end
end
