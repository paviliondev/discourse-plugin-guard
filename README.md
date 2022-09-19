## Discourse Plugin Guard

Guards your Discourse against plugin issues.

Note that this plugin manually overrides files in the Discourse installation itself, before any other plugin is loaded. This is to ensure all plugin errors are caught and handled by this plugin without affecting the normal operation of Discourse. As long as you follow the steps outlined below when developing and deploying the plugin everything will work as expected.

### Installation

[Plugin is not yet ready for deployment on client servers]

### Development

Setup the following environment variables

```
PLUGIN_GUARD_ROOT: the root of paviliondev/discourse-plugin-guard
DISCOURSE_ROOT: the root of discourse/discourse
```

Use a development workflow that looks like this

1. Run ``bin/setup.sh`` to create the necessary folders and symlink the necessary files.

2. Perform development as normal.

3. When you've finished:

   - If you've added or removed files or folders in ``lib`` make sure ``bin/setup.sh`` and ``templates/plugin_guard.template.yml`` are updated accordingly.

   - Clean your ``discourse/discourse`` working tree.

### Deployment on Canary Servers

As well as being deployed on client servers, this plugin is deployed on the following "canary" servers:

- `tests-passed.discourse.pluginmanager.org`
- `stable.discourse.pluginmanager.org`

If you need to deploy updates to the plugin guard ssh into the relevant server and run ``discourse_update`` (see ``bin/update.sh``).

### Scheduled Rebuilds

The canary servers running this plugin use ``crontab`` to automatically rebuild and cleanup their docker containers on set schedules.

The cron jobs on both servers are

```
0 00 * * * /usr/local/bin/discourse_rebuild >>/tmp/cron_debug_log.log 2>&1
0 00 * * 1,3,5 /usr/local/bin/discourse_cleanup >>/tmp/cron_debug_log.log 2>&1
```

The templates for ``discourse_rebuild`` and ``discourse_cleanup`` are ``bin/rebuild.sh`` and ``bin/cleanup.sh``.

### External Monitoring

The cron jobs on the canary servers are monitored on cronitor.io. The [CronitorCLI](https://cronitor.io/docs/using-cronitor-cli) is installed on the servers, tracking the cron jobs mentioned above. If a job does not start, or it fails to complete, then an alert is sent to the Plugin Guardian category on the Plugin Manager server and assigned to a Plugin Guardian.
