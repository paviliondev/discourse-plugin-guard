# frozen_string_literal: true

class ::PluginGuard
  NAMESPACE ||= 'plugin-guard'

  attr_reader :metadata,
              :handler

  def initialize(plugin_dir)
    return false unless File.exists?("#{plugin_dir}/plugin.rb")
    @metadata = ::Plugin::Metadata.parse(File.read("#{plugin_dir}/plugin.rb"))
    plugin_name = @metadata.name
    return false if ::Plugin::Metadata::OFFICIAL_PLUGINS.include?(plugin_name)
    @handler = ::PluginGuard::Handler.new(plugin_name, plugin_dir)
  end

  def present?
    handler.present?
  end

  def handle(message: '', backtrace: '')
    @handler.perform(message, backtrace)
  end

  def self.compatible_dir
    'plugins'
  end

  def self.incompatible_dir
    'plugins_incompatible'
  end

  def self.root_dir
    Rails.root
  end

  def self.client_domain
    Rails.env.development? ? "localhost:4200" : Discourse.current_hostname
  end

  def self.server_domain
    Rails.env.development? ? "localhost:4200" : "plugins.discourse.pavilion.tech"
  end

  def self.protocol
    Rails.env.development? ? "http" : "https"
  end

  def self.server_url
    "#{PluginGuard.protocol}://#{PluginGuard.server_domain}"
  end

  def self.client_url
    "#{PluginGuard.protocol}://#{PluginGuard.client_domain}"
  end
end

require_relative 'plugin_guard/error.rb'
require_relative 'plugin_guard/handler.rb'
require_relative 'plugin_guard/store.rb'
