require_relative "version"
require_relative "registry"

module T40Starter
  # Produces the ordered action list for a run. The plan stage prints this
  # and applies nothing; Installer executes the same plan.
  class Planner
    STATUS_ORDER = %i[conflict create edit project_owned skip noop].freeze

    def initialize(manifest:, target:, starter_root: T40Starter.root, now: Time.now)
      @registry = Registry.new(manifest: manifest, target: target, starter_root: starter_root, now: now)
    end

    def actions
      @actions ||= @registry.actions.sort_by { |action| [ STATUS_ORDER.index(action.status) || STATUS_ORDER.size, action.target.to_s ] }
    end

    def conflicts = actions.select(&:conflict?)

    def changes = actions.select(&:change?)

    def changes? = changes.any?

    def module_errors = @registry.module_errors

    def summary
      counts = Hash.new(0)
      actions.each { |action| counts[action.status.to_s] += 1 }
      %w[create edit project_owned skip noop conflict].to_h { |status| [ status, counts[status] ] }
    end
  end
end
