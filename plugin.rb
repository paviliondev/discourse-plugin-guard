# frozen_string_literal: true
# name: discourse-plugin-guard
# about: Guards your Discourse against plugin issues
# version: 0.1.1
# authors: Angus McLeod
# url: https://github.com/paviliondev/discourse-plugin-guard.git

if Rails.env.test?
  %w(
    ../lib/plugin_guard.rb
    ../lib/plugin_guard/extensions/discourse.rb
    ../lib/plugin_guard/extensions/plugin_instance.rb
  ).each do |path|
    load File.expand_path(path, __FILE__)
  end

  FileUtils.mv('../lib/plugin_initialization_guard.rb', '../../../lib/plugin_initialization_guard.rb', force: true)
end
