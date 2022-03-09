mkdir -p ${DISCOURSE_ROOT}/lib/plugin_guard
mkdir -p ${DISCOURSE_ROOT}/lib/plugin_guard/extensions
mkdir -p ${DISCOURSE_ROOT}/plugins_incompatible

ln -sf ${PLUGIN_GUARD_ROOT}/lib/plugin_guard.rb ${DISCOURSE_ROOT}/lib/plugin_guard.rb
ln -sf ${PLUGIN_GUARD_ROOT}/lib/plugin_guard/extensions/discourse.rb ${DISCOURSE_ROOT}/lib/plugin_guard/extensions/discourse.rb
ln -sf ${PLUGIN_GUARD_ROOT}/lib/plugin_guard/extensions/plugin_instance.rb ${DISCOURSE_ROOT}/lib/plugin_guard/extensions/plugin_instance.rb
ln -sf ${PLUGIN_GUARD_ROOT}/lib/plugin_guard/error.rb ${DISCOURSE_ROOT}/lib/plugin_guard/error.rb
ln -sf ${PLUGIN_GUARD_ROOT}/lib/plugin_guard/handler.rb ${DISCOURSE_ROOT}/lib/plugin_guard/handler.rb
ln -sf ${PLUGIN_GUARD_ROOT}/lib/plugin_guard/registration.rb ${DISCOURSE_ROOT}/lib/plugin_guard/registration.rb
ln -sf ${PLUGIN_GUARD_ROOT}/lib/plugin_guard/status.rb ${DISCOURSE_ROOT}/lib/plugin_guard/status.rb
ln -sf ${PLUGIN_GUARD_ROOT}/lib/plugin_guard/store.rb ${DISCOURSE_ROOT}/lib/plugin_guard/store.rb
ln -sf ${PLUGIN_GUARD_ROOT}/lib/tasks/plugin_guard.rake ${DISCOURSE_ROOT}/lib/tasks/plugin_guard.rake
ln -sf ${PLUGIN_GUARD_ROOT}/lib/plugin_initialization_guard.rb ${DISCOURSE_ROOT}/lib/plugin_initialization_guard.rb
