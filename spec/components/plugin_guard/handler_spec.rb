# frozen_string_literal: true

require_relative '../../plugin_helper'

describe PluginGuard::Handler do
  let(:incompatible_plugin) { "incompatible_plugin" }
  let(:incom_plugin_dir) { guard_plugin_dir(incompatible_plugin) }
  let(:incom_plugin_dir_incom_dir) { guard_plugin_dir(incompatible_plugin, compatible: false) }

  it "moves incompatible plugin to incompatible directory" do
    FileUtils.expects(:mv).with(
      incom_plugin_dir,
      incom_plugin_dir_incom_dir,
      force: true
    ).returns(stub_everything)

    handler = described_class.new(incompatible_plugin, incom_plugin_dir)
    handler.perform('Failed to load', 'backtrace')
  end

  it "removes plugin from discourse plugin list" do
    Discourse.plugins << Plugin::Instance.find_all("#{guard_fixture_dir}/plugins").first

    FileUtils.stubs(:mv)
    handler = described_class.new(incompatible_plugin, incom_plugin_dir)
    handler.perform('Failed to load', 'backtrace')

    expect(Discourse.plugins.any? { |p| p.metadata.name == incompatible_plugin }).to eq(false)
  end

  it "cleans up plugin assets" do
    Rails.application.config.assets.paths << "#{incom_plugin_dir}/assets/javascripts"
    Rails.application.config.assets.precompile += %w{ incompatible-asset.js }

    FileUtils.stubs(:mv)
    handler = described_class.new(incompatible_plugin, incom_plugin_dir)
    handler.perform('Failed to load', 'backtrace')

    expect(Rails.configuration.assets.paths.none? { |path| path.include?(incom_plugin_dir) }).to eq(true)
    expect(Rails.configuration.assets.precompile.none? { |path| path.to_s.include?(incom_plugin_dir) }).to eq(true)
  end
end
