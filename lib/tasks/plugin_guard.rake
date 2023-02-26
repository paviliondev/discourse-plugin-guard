# frozen_string_literal: true

PATH_WHITELIST ||= [
  'message-bus'
]

def file_exists(plugin_dir, directive, directive_path)
  paths = []

  if directive === 'require'
    paths.push("#{Rails.root}/app/assets/javascripts/#{directive_path}")
    paths.push("#{Rails.root}/vendor/assets/javascripts/#{directive_path}")
  elsif directive === 'require_tree'
    paths.push("#{plugin_dir}/assets/javascripts/#{directive_path[2..-1]}")
  elsif directive === 'require_tree_discourse'
    paths.push("#{Rails.root}/app/assets/javascripts/#{directive_path}")
  end

  paths.any? { |path| (Dir.glob("#{path}.*").any? || Dir.exist?(path)) } || PATH_WHITELIST.include?(directive_path)
end

task 'assets:precompile:before' do
  ### Ensure all assets added to precompilation by plugins exist.
  ### If they don't, remove them from precompilation and move the plugin to incompatible directory.

  path = "#{Rails.root}/plugins"

  Dir.each_child(path) do |dir|
    guard = PluginGuard.new("#{path}/#{dir}")
    handler = guard.handler

    if handler
      begin
        handler.precompiled_assets.each do |filename|
          pre_path = "#{handler.plugin_dir}/assets/javascripts/#{filename}"

          unless File.exist?(pre_path)
            ## This will not prevent Discourse from working so we only warn
            guard.handle(message: "Asset path #{pre_path} does not exist.")
            next
          end

          File.read(pre_path).each_line do |line|
            if line.start_with?("//=")
              directive_parts = line.split(' ')
              directive_path = directive_parts.last.split('.')[0]
              directive = directive_parts[1]

              unless file_exists(handler.plugin_dir, directive, directive_path)
                raise PluginGuard::Error.new("Sprockets directive #{directive_path} does not exist.")
              end
            end
          end
        end
      rescue PluginGuard::Error => error
        guard.handle(message: error.message)
      end
    end
  end
end

task "plugin_guard:update_statuses" => [:environment] do |_, args|
  api_key = SiteSetting.plugin_manager_api_key
  unless api_key.present?
    puts "ERROR: `plugin_manager_api_key` site setting is not set"
    exit 1
  end

  plugins = PluginGuard::Status.all_plugins
  status = PluginGuard::Status.new(plugins)

  unless status.update
    puts status.errors.full_messages.join(", ")
    exit 1
  end

  puts "SUCCESS: Updated all registered plugins."
  exit 0
end
