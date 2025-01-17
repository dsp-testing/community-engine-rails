require "action_text/engine"
require "active_storage/engine"
require 'better_together/column_definitions'
require 'better_together/migration_helpers'
require 'devise/jwt'
require 'reform/rails'

module BetterTogether
  class Engine < ::Rails::Engine
    engine_name 'better_together'
    isolate_namespace BetterTogether

    config.autoload_paths << File.expand_path("lib/better_together", __dir__)

    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
      g.fixture_replacement :factory_bot, :dir => 'spec/factories'
      g.test_framework :rspec
    end

    config.before_initialize do
      require_dependency 'friendly_id'
      require_dependency 'mobility'
      require_dependency 'friendly_id/mobility'
      require_dependency 'jsonapi-resources'
      require_dependency 'pundit'
      require_dependency 'rack/cors'
    end

    config.action_mailer.default_url_options = {
      host: ENV.fetch('APP_HOST', 'localhost:3000'),
      locale: I18n.locale
    }

    rake_tasks do
      load 'tasks/better_together_tasks.rake'

      Rake::Task['db:seed'].enhance do
        begin
          Rake::Task['better_together:load_seed'].invoke
        rescue RuntimeError => e
          Rake::Task['app:better_together:load_seed'].invoke
        end
      end
    end
  end
end
