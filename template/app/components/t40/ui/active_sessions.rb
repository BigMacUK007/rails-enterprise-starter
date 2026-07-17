class T40::Ui::ActiveSessions < T40::Ui::Base
  def initialize(sessions:)
    @sessions = sessions
  end

  def view_template
    flow(title: "Active sessions", id: "sessions-title") do
      ul(class: "card-list") do
        @sessions.each do |active_session|
          li do
            strong { active_session.user_agent.presence || "Unknown device" }
            span { "Last active #{time_ago_in_words(active_session.updated_at)} ago" }
            button_to("Revoke", active_session_path(active_session), method: :delete,
              class: "button button--danger")
          end
        end
      end
      button_to("Sign out everywhere", all_active_sessions_path, method: :delete,
        class: "button button--danger")
    end
  end
end
