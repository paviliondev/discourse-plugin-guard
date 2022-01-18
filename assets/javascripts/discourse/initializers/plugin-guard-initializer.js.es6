import { withPluginApi } from "discourse/lib/plugin-api";
import PluginGuard from "../models/plugin-guard";

export default {
  name: "plugin-guard",
  initialize() {
    withPluginApi("1.1.0", api => {
      api.modifyClass("route:admin-plugins", {
        afterModel() {
          return PluginGuard.registration().then(result => {
            this.set("pluginGuard", PluginGuard.create(result));
          });
        },

        setupController(controller, model) {
          model.set("pluginGuard", this.pluginGuard);
          controller.set("model", model);
        }
      });
    });
  }
}
