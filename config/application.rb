require_relative 'boot'

require 'active_record/railtie'
require 'active_model/railtie'
require 'active_job/railtie'
require 'action_mailer/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Simulator
  class Application < Rails::Application
    config.load_defaults 5.1

    config.active_job.queue_adapter = :delayed_job

    config.middleware.delete "Rack::Sendfile"
    config.middleware.delete "ActionDispatch::Static"
    config.middleware.delete "Rack::Lock"
    config.middleware.delete "Rack::MethodOverride"
    config.middleware.delete "ActionDispatch::RequestId"
    config.middleware.delete "ActionDispatch::ShowExceptions"
    config.middleware.delete "WebConsole::Middleware"
    config.middleware.delete "ActionDispatch::RemoteIp"
    config.middleware.delete "ActionDispatch::Reloader"
    config.middleware.delete "ActionDispatch::Cookies"
    config.middleware.delete "ActionDispatch::Session::CookieStore"
    config.middleware.delete "ActionDispatch::Flash"
    config.middleware.delete "ActionDispatch::ParamsParser"
    config.middleware.delete "Rack::ConditionalGet"
    config.middleware.delete "Rack::Head"
    config.middleware.delete "Rack::ETag"

    config.action_mailer.perform_deliveries = true
    config.action_mailer.raise_delivery_errors = true
    config.action_mailer.default :charset => "utf-8"
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      :address              => "smtp.gmail.com",
      :port                 => 587,
      :domain               => 'agilendtreports.com',
      :user_name            => "kevin@agilendtreports.com",
      :password             => "Blackcougar0",
      :authentication       => 'plain',
      :enable_starttls_auto => true
    }
  end
end

Dir["lib/*.rb"].each {|file| require Rails.root.join(file) }

$logger = Logger.new(File.join(Rails.root, 'log', 'simulator.log'))

def out(type, value, debug = false)
  value = "#{type.upcase} - #{value}"
  puts(value)
  $logger.send((debug ? :debug : :info), value)
end

