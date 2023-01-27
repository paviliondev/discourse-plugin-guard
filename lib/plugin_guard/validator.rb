# frozen_string_literal: true

class ValidatorError < StandardError
end

class PluginGuard::Validator
  attr_reader :plugin_name

  def initialize(plugin_name)
    @plugin_name
  end

  # based on methods in discourse/lib/theme_javascript_compiler.rb
  def validate_assets(plugin_instance)
    root_path = "#{File.dirname(plugin_instance.path)}/assets/javascripts"

    plugin_instance.each_globbed_asset do |path, is_dir|
      next if is_dir || !path.include?('plugins')

      if path =~ DiscoursePluginRegistry::JS_REGEX
        content = File.read(path)
        logical_path = path.split(root_path).last.delete_prefix("/")

        begin
          DiscourseJsProcessor::Transpiler.new.perform(content, root_path, logical_path).strip
        rescue MiniRacer::RuntimeError => ex
          raise ValidatorError.new ex.message
        end
      end

      if path =~ DiscoursePluginRegistry::HANDLEBARS_REGEX
        content = File.read(path)

        begin
          ::Barber::Ember::Precompiler.new.compile(content)
        rescue ::Barber::PrecompilerError => e
          raise ValidatorError.new e.instance_variable_get(:@error)
        end
      end
    end
  end
end
