# frozen_string_literal: true

class ::PluginGuard::Handler
  attr_reader :plugin_name
  attr_accessor :plugin_dir

  def initialize(plugin_name, plugin_dir)
    @plugin_name = plugin_name.to_s
    @plugin_dir = plugin_dir.to_s
  end

  def perform(message, backtrace)
    clean_up_assets
    move_to_incompatible
    store_error(message, backtrace)
  end

  def precompiled_assets
    @precompiled_assets ||= begin
      block_start = false
      in_block = false
      result = []
      file = File.read("#{plugin_dir}/plugin.rb")

      file.each_line do |line|
        if line.include?("config.assets.precompile")
          block_start = true
          in_block = true
        end

        if in_block && line.include?(".js")
          result += line.scan(/[\w|\-|\_]*\.js.*$/)
        else
          if block_start
            block_start = false
          else
            in_block = false
          end
        end
      end

      result
    end
  end

  def move_to_incompatible
    move(PluginGuard.compatible_dir, PluginGuard.incompatible_dir)
  end

  def store_error(message, backtrace)
    PluginGuard::Store.set(
      @plugin_name,
      directory: @plugin_dir,
      status: PluginGuard::Status.status[:incompatible],
      message: message,
      backtrace: backtrace
    )
  end

  protected

  def move(from_dir, to_dir)
    dup_plugin_dir = plugin_dir.dup
    return unless File.exists?(dup_plugin_dir)
    move_to_dir = dup_plugin_dir.reverse.sub(from_dir.reverse, to_dir.reverse).reverse
    FileUtils.mv(plugin_dir, move_to_dir, force: true)
    @plugin_dir = move_to_dir
  end

  def clean_up_assets
    Discourse.plugins.reject! { |plugin| plugin.name == plugin_name }
    Rails.configuration.assets.paths.reject! { |path| path.include?(plugin_dir) }
    Rails.configuration.assets.precompile.reject! { |file| file.to_s.include?(plugin_name) }
    I18n.load_path.reject! { |file| file.include?(plugin_name) }
  end
end
