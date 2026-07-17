module T40
  # Operational runtime switches used for incident containment.
  # See docs/operations/maintenance-mode.md.
  module Runtime
    class << self
      # Full maintenance: requests render a 503 maintenance page.
      # Enable via T40_MAINTENANCE=1 or by touching tmp/maintenance.txt.
      def maintenance?
        ENV["T40_MAINTENANCE"] == "1" || Rails.root.join("tmp/maintenance.txt").exist?
      end

      # Read-only: non-GET/HEAD requests are rejected with 503.
      def read_only?
        ENV["T40_READ_ONLY"] == "1"
      end

      def release
        ENV["RELEASE_SHA"] || ENV["KAMAL_VERSION"] || "unknown"
      end
    end
  end
end
