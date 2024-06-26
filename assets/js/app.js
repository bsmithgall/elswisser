// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";

import { ShareCaptureHook, shareCapture } from "./share-capture";
import { FlashHook } from "./flash";
import { ElchesserHook } from "./elchesser";

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: { ShareCaptureHook, FlashHook, ElchesserHook },
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;

window.addEventListener("elswisser:share-capture", async (el) => {
  await shareCapture({
    elId: el.target,
    onSuccess: () => {
      const flash = document.getElementById(el.detail.flash_id);
      if (flash) {
        flash.removeAttribute("hidden");
        flash.style = "";
      }
    },
  });
});

// register "Check all" functionality for multi-checkboxes
document.querySelectorAll('[data-selector="es:multicheckbox"]').forEach((el) =>
  el.addEventListener("click", (e) => {
    let on = e.target.checked;
    e.target
      .closest('[data-selector="es:multicheckbox-container"]')
      .querySelectorAll('input[type="checkbox"]')
      .forEach((input) => {
        input.checked = on;
      });
  }),
);
