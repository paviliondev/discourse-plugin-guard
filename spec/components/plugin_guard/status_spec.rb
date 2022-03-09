# frozen_string_literal: true

require_relative '../../plugin_helper'

describe PluginGuard::Status do
  fab!(:user) { Fabricate(:user) }
  let(:compatible_plugin) { "compatible_plugin" }
  let(:incompatible_plugin) { "incompatible_plugin" }
  let(:incom_after_init_plugin) { "incompatible_after_initialize_plugin" }
  let(:incom_plugin_dir) { guard_plugin_dir(incompatible_plugin) }
  let(:com_plugin_dir) { guard_plugin_dir(compatible_plugin) }
  let(:incom_after_init_plugin_dir) { guard_plugin_dir(incom_after_init_plugin) }
  let(:incom_plugin_dir_incom_dir) { guard_plugin_dir(incompatible_plugin, compatible: false) }
  let(:plugin_sha) { "d5f7a1dbe5fcd9513aebad188e677a89fe955d86" }
  let(:new_plugin_sha) { "36e7163d164fe7ecf02928c42255412edda544f4" }
  let(:plugin_branch) { "main" }
  let(:discourse_url) { "https://github.com/discourse/discourse" }
  let(:discourse_sha) { "eb2e3b510de9295d1ed91919d2df0dc800364689" }

  before do
    api_key = ApiKey.create!(user_id: user.id, created_by_id: -1)
    SiteSetting.plugin_manager_api_key = api_key
  end

  def request_headers
    {
      'Api-Key' => SiteSetting.plugin_manager_api_key,
      'Content-Type' => 'application/json',
      'Host' => PluginGuard.server_domain
    }
  end

  it "updates a plugin's status" do
    Discourse.expects(:git_branch).returns(discourse_branch)
    Discourse.expects(:git_version).returns(discourse_sha)

    load_plugin(incom_plugin_dir)
    Open3.expects(:capture3).with("git rev-parse HEAD", chdir: incom_plugin_dir_incom_dir).returns(plugin_sha).at_least_once
    Open3.expects(:capture3).with("git rev-parse --abbrev-ref HEAD", chdir: incom_plugin_dir_incom_dir).returns(plugin_branch).at_least_once

    PluginGuard::Authorization.set_site_api_key(SiteSetting.plugin_manager_api_key, validate: false)
    PluginGuard::Registration.update!

    message = "#{compatible_plugin.titleize} broke"
    backtrace = "broken at line 123"

    request_body = {
      domain: PluginGuard.client_domain,
      plugins: [
        {
          name: incompatible_plugin,
          status: PluginGuard::Status.status[:incompatible],
          message: message,
          backtrace: backtrace,
          sha: plugin_sha,
          branch: plugin_branch,
        }
      ],
      discourse: {
        branch: discourse_branch,
        sha: discourse_sha
      }
    }

    stub_request(:post, "#{PluginGuard.server_url}/plugin-manager/status").with(
      body: request_body.to_json,
      headers: request_headers
    ).to_return(
      status: 200,
      body: { success: 'OK' }.to_json,
      headers: {}
    )

    plugins = [
      {
        name: incompatible_plugin,
        directory: incom_plugin_dir_incom_dir,
        status: PluginManager::Plugin::Status.statuses[:incompatible],
        message: message,
        backtrace: backtrace
      }
    ]
    described_class.update(plugins)

    expect(WebMock).to have_requested(:post, "#{PluginGuard.server_url}/plugin-manager/status").with(
      headers: request_headers,
      body: request_body.to_json
    )
  end

  it "updates all plugin statuses" do
    Discourse.expects(:git_branch).returns(discourse_branch)
    Discourse.expects(:git_version).returns(discourse_sha)

    load_plugin(com_plugin_dir)
    Open3.expects(:capture3).with("git rev-parse HEAD", chdir: com_plugin_dir).returns(plugin_sha).at_least_once
    Open3.expects(:capture3).with("git rev-parse --abbrev-ref HEAD", chdir: com_plugin_dir).returns(plugin_branch).at_least_once

    load_plugin(incom_plugin_dir)
    Open3.expects(:capture3).with("git rev-parse HEAD", chdir: incom_plugin_dir).returns(plugin_sha).at_least_once
    Open3.expects(:capture3).with("git rev-parse --abbrev-ref HEAD", chdir: incom_plugin_dir).returns(plugin_branch).at_least_once

    load_plugin(incom_after_init_plugin_dir)
    Open3.expects(:capture3).with("git rev-parse HEAD", chdir: incom_after_init_plugin_dir).returns(plugin_sha).at_least_once
    Open3.expects(:capture3).with("git rev-parse --abbrev-ref HEAD", chdir: incom_after_init_plugin_dir).returns(plugin_branch).at_least_once

    PluginGuard::Authorization.set_site_api_key(SiteSetting.plugin_manager_api_key, validate: false)
    PluginGuard::Registration.update!

    request_body = {
      domain: PluginGuard.client_domain,
      plugins: [
        {
          name: compatible_plugin,
          status: PluginGuard::Status.status[:compatible],
          sha: plugin_sha,
          branch: plugin_branch,
        },
        {
          name: incom_after_init_plugin,
          status: PluginGuard::Status.status[:compatible],
          sha: plugin_sha,
          branch: plugin_branch,
        },
        {
          name: incompatible_plugin,
          status: PluginGuard::Status.status[:compatible],
          sha: plugin_sha,
          branch: plugin_branch,
        }
      ],
      discourse: {
        branch: discourse_branch,
        sha: discourse_sha
      }
    }

    stub_request(:post, "#{PluginGuard.server_url}/plugin-manager/status").with(
      body: request_body.to_json,
      headers: request_headers
    ).to_return(
      status: 200,
      body: { success: 'OK' }.to_json,
      headers: {}
    )

    described_class.update_all

    expect(WebMock).to have_requested(:post, "#{PluginGuard.server_url}/plugin-manager/status").with(
      headers: request_headers,
      body: request_body.to_json
    )
  end
end
