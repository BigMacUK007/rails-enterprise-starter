module ActivityTracking
  extend ActiveSupport::Concern

  SKIP_CONTROLLERS = %w[
    rails/health
    active_storage/blobs
    active_storage/representations
    active_storage/disk
  ].freeze

  SKIP_ACTIONS = %w[
    admin/user_activities#index
    admin/user_activities#show
  ].freeze

  SANITIZED_PARAMS = %w[
    password
    password_confirmation
    current_password
    token
    reset_password_token
    _method
    authenticity_token
  ].freeze

  included do
    after_action :track_page_view, unless: :skip_tracking?
  end

  private

  def track_page_view
    return unless current_user

    UserActivity.create!(
      user: current_user,
      activity_type: :page_view,
      controller: controller_path,
      action: action_name,
      path: request.path,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      session_id: session.id.to_s,
      metadata: {
        params: sanitized_params,
        method: request.method
      }
    )
  rescue StandardError => e
    Rails.logger.error("Failed to track page view: #{e.message}")
  end

  def skip_tracking?
    return true if SKIP_CONTROLLERS.include?(controller_path)
    return true if SKIP_ACTIONS.include?("#{controller_path}##{action_name}")
    return true if request.path.start_with?("/assets", "/rails/active_storage")
    return true if request.xhr? && action_name == "index"
    return true if controller_path.start_with?("admin/")

    false
  end

  def sanitized_params
    params.to_unsafe_h.except(*SANITIZED_PARAMS).reject do |key, _|
      key.to_s.match?(/password|token|secret|key/i)
    end
  end

  def track_data_access(record_type, record)
    return unless current_user

    UserActivity.create!(
      user: current_user,
      activity_type: :data_access,
      controller: controller_path,
      action: action_name,
      path: request.path,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      session_id: session.id.to_s,
      metadata: {
        record_type: record_type.to_s,
        record_id: record.id,
        record_name: record.try(:unit_number) || record.try(:name) || record.try(:id)
      }
    )
  rescue StandardError => e
    Rails.logger.error("Failed to track data access: #{e.message}")
  end

  def track_search(query)
    return unless current_user

    UserActivity.create!(
      user: current_user,
      activity_type: :search,
      controller: controller_path,
      action: action_name,
      path: request.path,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      session_id: session.id.to_s,
      metadata: {
        search_query: query.to_s.truncate(200),
        filters: sanitized_params.except("search", "page", "controller", "action")
      }
    )
  rescue StandardError => e
    Rails.logger.error("Failed to track search: #{e.message}")
  end

  def track_export(export_type, record_count = nil)
    return unless current_user

    UserActivity.create!(
      user: current_user,
      activity_type: :export,
      controller: controller_path,
      action: action_name,
      path: request.path,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      session_id: session.id.to_s,
      metadata: {
        export_type: export_type.to_s,
        record_count: record_count,
        filters: sanitized_params.except("page", "controller", "action")
      }
    )
  rescue StandardError => e
    Rails.logger.error("Failed to track export: #{e.message}")
  end
end
