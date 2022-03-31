# frozen_string_literal: true

class ::PluginGuard::Status
  attr_reader :plugins,
              :errors

  def initialize(plugins)
    @plugins = plugins
  end

  def errors
    @errors ||= ActiveModel::Errors.new(self)
  end

  def add_error(msg)
    errors.add(:base, msg) unless errors[:base].include?(msg)
  end

  def registration
    @registration ||= PluginGuard::Registration.get
  end

  def registered_plugins
    @plugins.select { |plugin| registration.plugins.include?(plugin[:name]) }
  end

  def fill_git_data
    @plugins.reduce([]) do |result, plugin|
      if plugin[:directory].present?
        sha = PluginGuard.run_shell_cmd('git rev-parse HEAD', chdir: plugin[:directory])
        branch = PluginGuard.run_shell_cmd('git rev-parse --abbrev-ref HEAD', chdir: plugin[:directory])

        if sha.present? && branch.present?
          result << plugin.except(:directory).merge(sha: sha, branch: branch)
        end
      end

      result
    end
  end

  def update
    add_error("Registration is not active.") unless registration.active?
    return false if errors.any?

    @plugins = registered_plugins
    add_error("No registered plugins.") unless @plugins.any?
    return false if errors.any?

    @plugins = fill_git_data
    add_error("Failed to add git data to plugins.") unless @plugins.any?
    return false if errors.any?

    header_key = registration.authorization.user_key? ? "User-Api-Key" : "Api-Key"
    response = Excon.post("#{PluginGuard.server_url}/plugin-manager/status.json",
      headers: {
        "#{header_key}" => registration.authorization.api_key,
        "Content-Type" => "application/json"
      },
      body: {
        domain: PluginGuard.client_domain,
        plugins: @plugins,
        discourse: {
          branch: Discourse.git_branch,
          sha: Discourse.git_version
        }
      }.to_json
    )

    unless response.status == 200
      add_error("Failed to post status to plugin manager: #{response.body.to_s}")
      return false
    end

    begin
      data = JSON.parse(response.body).deep_symbolize_keys
    rescue JSON::ParserError
      add_error("Failed to parse response body")
      return false
    end

    data[:success] == "OK"
  end

  def self.status
    @status ||= {
      unknown: 0,
      compatible: 1,
      incompatible: 2
    }
  end

  def self.all_plugins
    plugins = []

    PluginGuard.compatible_plugins.each do |instance|
      if PluginGuard::Registration.excluded_plugins.exclude?(instance.metadata.name)
        plugins << {
          name: instance.metadata.name,
          directory: File.dirname(instance.path).to_s,
          status: status[:compatible]
        }
      end
    end

    PluginGuard.incompatible_plugins.each do |instance|
      if PluginGuard::Registration.excluded_plugins.exclude?(instance.metadata.name)
        plugins << {
          name: instance.metadata.name,
          directory: File.dirname(instance.path).to_s,
          status: status[:incompatible]
        }
      end
    end

    plugins
  end
end
