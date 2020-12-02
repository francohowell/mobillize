require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module MobilizeUS
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2


    config.logger = ActiveSupport::Logger.new(STDOUT)
    # config.log_level = :info
    config.assets.quiet = true
    config.browser_validations = true
    config.active_job.queue_adapter = :sidekiq


    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    config.assets.paths << Rails.root.join('app/assets/files')

    config.assets.precompile += ['appviews.css', 'cssanimations.css', 'dashboards.css', 'forms.css', 'gallery.css', 'graphs.css', 'mailbox.css', 'miscellaneous.css', 'pages.css', 'tables.css', 'uielements.css', 'widgets.css', 'commerce.css', 'account.css', 'general.css', 'contacts.css', 'mgage.css', 'survey.css', 'keyword.css', 'blast.css', 'policy.css', 'multiform.css', 'addon.css']
    # JS
    config.assets.precompile += [ 'appviews.js', 'cssanimations.js', 'dashboards.js', 'forms.js', 'gallery.js', 'graphs.js', 'mailbox.js', 'miscellaneous.js', 'pages.js', 'tables.js', 'uielements.js', 'widgets.js', 'commerce.js', 'metrics.js', 'landing.js', 'account.js', 'general.js', 'contacts.js', 'mgage.js', 'survey.js', 'biomp.js', 'keyword.js', 'blast.js', 'policy.js', 'autocomplete.js' ]

    config.assets.precompile += [ 'MobilizeComms-CSVTemplate.csv' ]


  end
end
