# frozen_string_literal: true

require_relative '../../../plugin_helper'

describe PluginGuard::PluginInstanceExtension do
  let(:incompatible_after_initialize_plugin) { "incompatible_after_initialize_plugin" }
  let(:incom_plugin_dir) { guard_plugin_dir(incompatible_after_initialize_plugin) }
  let(:incom_plugin_dir_incom_dir) { guard_plugin_dir(incompatible_after_initialize_plugin, compatible: false) }
  let(:compatible_plugin) { "compatible_plugin" }
  let(:com_plugin_dir) { guard_plugin_dir(compatible_plugin) }

  it "moves incompatible plugin to incompatible directory" do
    FileUtils.expects(:mv).with(
      incom_plugin_dir,
      incom_plugin_dir_incom_dir,
      force: true
    ).returns(stub_everything)

    plugin = load_plugin(incom_plugin_dir)
    plugin.activate!
    plugin.notify_after_initialize
  end
end
