require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module BundleLocalCacheTravisBetaTest
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2
    config.autoloader = :classic

    # bin/rails console
    # pp ActiveSupport::Dependencies.autoload_paths

    # Add additional load paths for your own custom dirs
    config.autoload_paths << Rails.root.join('app', 'services').to_s
    config.autoload_paths << Rails.root.join('app', 'services', 'concerns').to_s
    config.autoload_paths << Rails.root.join('app', 'inputs').to_s
    config.autoload_paths << Rails.root.join('app', 'inputs', 'concerns').to_s
    config.autoload_paths << Rails.root.join('app', 'validators').to_s
    config.autoload_paths << Rails.root.join('app', 'validators', 'concerns').to_s

    config.autoload_paths << Rails.root.join('lib')

    # Otherwise directory outside of ./app are not autoloaded
    # See railties/lib/rails/engine/configuration.rb
    # => https://github.com/rails/rails/blob/dd5a49c14082b559355b1f4d8bc5b686e8f67e3f/railties/lib/rails/engine/configuration.rb#L38-L73
    config.paths.add("lib", eager_load: true)

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Use the lowest log level to ensure availability of diagnostic information
    # when problems arise.
    config.log_level = :debug

    # Prepend all log lines with the following tags.
    config.log_tags = [ :request_id ]

    # Use default logging formatter so that PID and timestamp are not suppressed.
    config.log_formatter = ::Logger::Formatter.new

    # Use a different logger for distributed setups.
    # require 'syslog/logger'
    # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new 'app-name')

    if ENV["RAILS_LOG_TO_STDOUT"].present?
      logger           = ActiveSupport::Logger.new(STDOUT)
      logger.formatter = config.log_formatter
      config.logger    = ActiveSupport::TaggedLogging.new(logger)
    end

    config.active_record.schema_format = :sql
  end
end
