// prettier-ignore
{{flutter_js}}
// prettier-ignore
{{flutter_build_config}}

const appLoader = document.querySelector("#app-loader");
_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    appLoader.style.opacity = "0";
    await appRunner.runApp();
  },
});
