class T40::Ui::AuditHistory < T40::Ui::Base
  def initialize(events:)
    @events = events
  end

  def view_template
    flow(title: "Audit history", id: "audit-title") do
      p { link_to("Export CSV", export_audit_events_path(format: :csv)) }
      table do
        caption { "Most recent account events" }
        thead do
          tr do
            %w[Time Action Result Reason].each { |heading| th(scope: "col") { heading } }
          end
        end
        tbody do
          @events.each do |event|
            tr do
              td { event.occurred_at.iso8601 }
              td { event.action }
              td { event.result }
              td { event.reason.to_s }
            end
          end
        end
      end
    end
  end
end
