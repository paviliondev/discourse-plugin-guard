# frozen_string_literal: true

# name: compatible_plugin
# about: Compatbile plugin fixture
# version: 0.1.1
# authors: Angus McLeod
# contact_emails: angus@test.com
# url: https://github.com/paviliondev/discourse-compatible-plugin.git

module CompatiblePlugin
  NAMESPACE ||= 'compatible-plugin'

  class Engine < ::Rails::Engine
    engine_name CompatiblePlugin::NAMESPACE
    isolate_namespace CompatiblePlugin
  end
end
