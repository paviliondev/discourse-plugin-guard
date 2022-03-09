# frozen_string_literal: true

class ::PluginGuard::Status
  cattr_accessor :errors

  def self.status
    Enum.new(
      unknown: 0,
      compatible: 1,
      incompatible: 2
    )
  end

  def self.get_sha(plugin_dir)
    PluginGuard.run_shell_cmd('git rev-parse HEAD', chdir: plugin_dir)
  end

  def self.get_branch(plugin_dir)
    PluginGuard.run_shell_cmd('git rev-parse --abbrev-ref HEAD', chdir: plugin_dir)
  end

  def self.fill_git_data(plugins)
    plugins.reduce([]) do |result, plugin|
      if plugin[:directory].present?
        sha = get_sha(plugin[:directory])
        branch = get_branch(plugin[:directory])

        if sha.present? && branch.present?
          result << plugin.except(:directory).merge(sha: sha, branch: branch)
        end
      end

      result
    end
  end

  def self.update(plugins)
    errors = []

    registration = PluginGuard::Registration.get
    unless registration.active?
      errors << "Registration is not active"
      return false
    end

    plugins = plugins.select { |plugin| registration.plugins.include?(plugin[:name]) }
    unless plugins.any?
      errors << "No plugins are registered."
      return false
    end

    plugins = fill_git_data(plugins)
    unless plugins.any?
      errors << "Failed to add git data to plugins."
      return false
    end

    header_key = registration.authorization.user_key? ? "User-Api-Key" : "Api-Key"

    response = Excon.post("#{PluginGuard.server_url}/plugin-manager/status",
      headers: {
        "#{header_key}" => registration.authorization.api_key,
        "Content-Type" => "application/json"
      },
      body: {
        domain: PluginGuard.client_domain,
        plugins: plugins,
        discourse: {
          branch: Discourse.git_branch,
          sha: Discourse.git_version
        }
      }.to_json
    )

    unless response.status == 200
      errors << "Failed to post status to plugin manager: #{response.body.to_s}"
      return false
    end

    begin
      data = JSON.parse(response.body).deep_symbolize_keys
    rescue JSON::ParserError
      errors << "Failed to parse response body"
      return false
    end

    data[:success] == "OK"
  end

  def self.update_all
    plugins = []

    Plugin::Instance.find_all("#{PluginGuard.root_dir}#{PluginGuard.compatible_dir}").each do |instance|
      if PluginGuard::Registration.registrable_plugins.include?(instance.metadata.name)
        plugins << {
          name: instance.metadata.name,
          directory: File.dirname(instance.path).to_s,
          status: PluginGuard::Status.status[:compatible]
        }
      end
    end

    Plugin::Instance.find_all("#{PluginGuard.root_dir}#{PluginGuard.incompatible_dir}").each do |instance|
      if PluginGuard::Registration.registrable_plugins.include?(instance.metadata.name)
        plugins << {
          name: instance.metadata.name,
          directory: File.dirname(instance.path).to_s,
          status: PluginGuard::Status.status[:incompatible]
        }
      end
    end

    update(plugins)
  end
end
