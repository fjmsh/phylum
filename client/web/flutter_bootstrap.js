// prettier-ignore
{{flutter_js}}
// prettier-ignore
{{flutter_build_config}}

function removeLoader() {
  appLoader.style.opacity = "0";
  return new Promise((r) => setTimeout(r, 400));
}

const appLoader = document.querySelector("#app-loader");
_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
  },
});

if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker
      .register("phylum_app_worker.js", { scope: "/" })
      .then(
        (registration) => {},
        (err) => {
          console.error("ServiceWorker registration failed", err);
        },
      );
  });
}
