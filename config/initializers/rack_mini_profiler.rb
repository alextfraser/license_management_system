if Rails.env.development?
  require "rack-mini-profiler"

  # Initialize Rack::MiniProfiler
  Rack::MiniProfiler.config.tap do |config|
    # Show speed badge on every page
    config.enabled = true

    # Position of the badge (top-left, top-right, bottom-left, bottom-right)
    config.position = "bottom-right"

    # Skip profiling for certain paths (optional)
    # config.skip_paths = ['/admin']

    # Enable memory profiling
    config.enable_advanced_debugging_tools = true

    # Show SQL queries and highlight N+1 queries
    config.enable_hotwire_turbo_drive_support = true
  end
end
