import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";
import PluginGuard from "../models/plugin-guard";
import { equal } from "@ember/object/computed";

export default Component.extend({
  classNames: ["plugin-guard-registration"],
  registered: equal("registration.status", "registered"),

  @discourseComputed("registered")
  btnClass(registered) {
    return registered ? "ok" : "btn-primary";
  },

  @discourseComputed("registration.status")
  btnLabel(status) {
    return `plugin_guard.${status}.label`;
  },

  @discourseComputed("registration.status")
  btnTitle(status) {
    return `plugin_guard.${status}.title`;
  },

  @discourseComputed("registered")
  btnAction(registered) {
    return registered ? "showRegistration" : "register";
  },

  actions: {
    unregister() {
      this.set("unregistering", true);

      PluginGuard.unregister().finally(() => {
        this.set("unregistering", false);
      });
    },

    register() {
      PluginGuard.authorize();
    },

    showRegistration() {
      const serverUrl = this.registration.server_url;
      window.open(`${serverUrl}/my/plugins`, "_blank").focus();
    },
  },
});
