# frozen_string_literal: true

PATH_WHITELIST ||= [
  'message-bus'
]

def file_exists(guard, directive, directive_path)
  paths = []

  if directive === 'require'
    paths.push("#{Rails.root}/app/assets/javascripts/#{directive_path}")
    paths.push("#{Rails.root}/vendor/assets/javascripts/#{directive_path}")
  elsif directive === 'require_tree'
    paths.push("#{guard.handler.plugin_dir}/assets/javascripts/#{directive_path[2..-1]}")
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
    if guard = PluginGuard.new("#{path}/#{dir}")
      begin
        guard.handler.precompiled_assets.each do |filename|
          pre_path = "#{guard.handler.plugin_dir}/assets/javascripts/#{filename}"

          unless File.exists?(pre_path)
            ## This will not prevent Discourse from working so we only warn
            guard.handle(message: "Asset path #{pre_path} does not exist.")
            next
          end

          File.read(pre_path).each_line do |line|
            if line.start_with?("//=")
              directive_parts = line.split(' ')
              directive_path = directive_parts.last.split('.')[0]
              directive = directive_parts[1]

              unless file_exists(guard, directive, directive_path)
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
