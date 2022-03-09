# frozen_string_literal: true

if ENV['SIMPLECOV']
  require 'simplecov'

  SimpleCov.start do
    root "plugins/discourse-plugin-guard"
    track_files "plugins/discourse-plugin-guard/**/*.rb"
    add_filter { |src| src.filename =~ /(\/spec\/|plugin\.rb)/ }
  end
end

def guard_fixture_dir
  "#{Rails.root}/plugins/discourse-plugin-guard/spec/fixtures"
end

def guard_plugin_dir(name, compatible: true)
  plugins_dir = compatible ? 'plugins' : 'plugins_incompatible'
  "#{guard_fixture_dir}/#{plugins_dir}/#{name}"
end

def load_plugin(plugin_dir)
  path = "#{plugin_dir}/plugin.rb"
  source = File.read(path)
  metadata = Plugin::Metadata.parse(source)
  plugin = Plugin::Instance.new(metadata, path)
  Discourse.plugins << plugin
  plugin
end

require 'rails_helper'
