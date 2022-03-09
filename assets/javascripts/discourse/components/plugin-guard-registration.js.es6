import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";
import PluginGuard from "../models/plugin-guard";
import { and, equal, not, readOnly } from "@ember/object/computed";

export default Component.extend({
  classNames: ["plugin-guard-registration"],
  registered: equal("registration.status", "registered"),
  userKey: not("registration.site_key"),
  canUnregister: and("registered", "userKey"),

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

  btnDisabled: readOnly("registration.site_key"),

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
