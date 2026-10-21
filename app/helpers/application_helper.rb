module ApplicationHelper
  include Pagy::Frontend

  def severity_badge(severity)
    colors = {
      "info" => "badge-info",
      "warning" => "badge-warning",
      "error" => "badge-error",
      "critical" => "badge-critical"
    }
    tag.span(severity.upcase, class: "badge #{colors[severity]}")
  end

  def category_label(category)
    category&.titleize || "Unknown"
  end

  def time_ago_brief(time)
    return "N/A" unless time
    distance = Time.current - time
    case distance
    when 0..59 then "#{distance.to_i}s ago"
    when 60..3599 then "#{(distance / 60).to_i}m ago"
    when 3600..86399 then "#{(distance / 3600).to_i}h ago"
    else "#{(distance / 86400).to_i}d ago"
    end
  end
end
