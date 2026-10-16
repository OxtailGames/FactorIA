// @ts-check
// The script the native-plugin checks add to a game (tools/cli/tests/plugin_test.py, the Android and iOS CI jobs): it
// calls the plugin "example" (platforms/plugin) and logs what it got, "probe add=3" and "probe info={...}", which the
// checks look for in the game's log. A wrong answer is a script error. With the prop quitAfter > 0 the game quits after
// that many frames.
import { Behaviour, plugins, fa, game } from "factoria";

export default class PluginProbe extends Behaviour {
  quitAfter = 0;
  frames = 0;

  onStart() {
    const sum = plugins.example.add(1, 2), info = fa.call("example.info", {});
    console.log(`probe add=${sum}`);
    console.log(`probe info=${JSON.stringify(info)}`);
    if (sum !== 3 || info.plugin !== "example") throw new Error(`probe: unexpected ${sum} ${JSON.stringify(info)}`);
  }

  onUpdate() {
    if (this.quitAfter > 0 && ++this.frames === this.quitAfter) game.quit();
  }
}
