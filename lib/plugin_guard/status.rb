# frozen_string_literal: true

class ::PluginGuard::Status
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
    registration = PluginGuard::Registration.get
    return false unless registration.active?

    plugins = plugins.select { |plugin| registration.plugins.include?(plugin[:name]) }
    return false unless plugins.any?

    plugins = fill_git_data(plugins)
    return false unless plugins.any?

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

    return false unless response.status == 200

    begin
      data = JSON.parse(response.body).deep_symbolize_keys
    rescue JSON::ParserError
      return false
    end

    data[:success] == "OK"
  end
end
