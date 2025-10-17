require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"

Bundler.require(*Rails.groups)

module CustomerService
  class Application < Rails::Application
    config.load_defaults 8.0
    config.api_only = true

    config.active_job.queue_adapter = :solid_queue

    config.autoload_paths += %W(#{config.root}/app/adapters)
    config.autoload_lib(ignore: %w[assets tasks])

    config.time_zone = "America/Bogota"
    config.active_record.default_timezone = :local
  end
end
