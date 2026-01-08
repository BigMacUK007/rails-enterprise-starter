module ApplicationHelper
  # Generates a sortable table header link
  # column: the database column to sort by
  # title: the display title for the header
  # options: additional options
  #   - default_direction: the default sort direction (:asc or :desc), defaults to :asc
  #   - class: additional CSS classes to add
  def sortable_header(column, title, options = {})
    default_direction = options[:default_direction] || :asc
    current_column = params[:sort_by]
    current_direction = params[:sort_dir]

    # Determine if this column is currently sorted
    is_sorted = current_column.to_s == column.to_s

    # Calculate the next direction
    if is_sorted
      next_direction = current_direction == "asc" ? "desc" : "asc"
    else
      next_direction = default_direction.to_s
    end

    # Build the sort indicator
    indicator = if is_sorted
      current_direction == "asc" ? "↑" : "↓"
    else
      ""
    end

    # Build link with current params preserved
    sort_params = request.query_parameters.merge(sort_by: column, sort_dir: next_direction)

    css_class = "sortable-header"
    css_class += " sortable-header--active" if is_sorted
    css_class += " #{options[:class]}" if options[:class].present?

    link_to sort_params, class: css_class, data: { turbo_frame: "_top" } do
      content_tag(:span, title, class: "sortable-header__text") +
      (indicator.present? ? content_tag(:span, indicator, class: "sortable-header__indicator") : "".html_safe)
    end
  end

  def render_status_badge(status)
    status_classes = {
      "valid_status" => "status-badge--positive",
      "expiring_soon" => "status-badge--warning",
      "expired" => "status-badge--negative",
      "not_required" => "status-badge--neutral"
    }

    status_labels = {
      "valid_status" => "Valid",
      "expiring_soon" => "Expiring Soon",
      "expired" => "Expired",
      "not_required" => "N/A"
    }

    css_class = status_classes[status.to_s] || "status-badge--neutral"
    label = status_labels[status.to_s] || status.to_s.humanize

    content_tag(:span, label, class: "status-badge #{css_class}")
  end

  def compliance_color_class(percentage)
    case percentage
    when 90..100 then "positive"
    when 70...90 then "warning"
    else "negative"
    end
  end
end
