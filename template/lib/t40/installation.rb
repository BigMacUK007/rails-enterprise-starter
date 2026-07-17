module T40
  # Read-only runtime view of the installation choices persisted by the
  # starter. Tenant authority still comes from authenticated memberships;
  # this configuration only selects the installed operating mode.
  module Installation
    class << self
      def config
        @config ||= YAML.safe_load_file(Rails.root.join("config/t40/installation.yml")) || {}
      end

      def tenancy_mode = config.fetch("tenancy_mode", "multi_account")

      def single_account? = tenancy_mode == "single_account"

      def deployment_profile = config.fetch("deployment_profile", "standard")

      def high_assurance? = deployment_profile == "high_assurance"

      def starter_version = config.fetch("starter_version", "unknown")

      def data_risk?(key) = config.fetch("data_risk", {}).fetch(key.to_s, false) == true

      def reload! = @config = nil
    end
  end
end
