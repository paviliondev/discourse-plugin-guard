import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import EmberObject from "@ember/object";

const PluginGuard = EmberObject.extend();
const basePath = "/admin/plugins/plugin-guard";

PluginGuard.reopenClass({
  authorize() {
    window.location.href = `${basePath}/authorize`;
  },

  registration() {
    return ajax(`${basePath}/registration`, {
      type: "GET",
    }).catch(popupAjaxError);
  },

  unregister() {
    return ajax(`${basePath}/registration`, {
      type: "DELETE",
    }).catch(popupAjaxError);
  }
});

export default PluginGuard;
