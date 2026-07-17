class T40::ActiveSessionsController < ApplicationController
  layout "public"

  def index
    @active_sessions = Current.identity.sessions.active.ordered
    render T40::Ui::ActiveSessions.new(sessions: @active_sessions)
  end

  def destroy
    active_session = Current.identity.sessions.find(params[:id])
    current = active_session == Current.session
    active_session.revoke!
    cookies.delete(:session_token) if current
    redirect_to(current ? new_session_path : active_sessions_path)
  end

  def destroy_all
    Session.revoke_all_for(Current.identity)
    cookies.delete(:session_token)
    redirect_to new_session_path
  end
end
