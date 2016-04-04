module CleverTable
  class Engine < ::Rails::Engine
    isolate_namespace CleverTable

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_girl, dir: 'spec/factories'
    end

    initializer 'clever_table.assets.precompile_paths' do |app|
      app.config.assets.precompile += %w{ clever_table.js clever_table.css }
      app.config.assets.paths << root.join("app", "assets")
    end
  end
end
