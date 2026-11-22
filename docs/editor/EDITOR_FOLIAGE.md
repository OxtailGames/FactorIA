Part of [EDITOR.md](../EDITOR.md): The foliage tool: a brush on the selected Foliage.

# Editor: foliage tool

## Foliage tool

View > Foliage tool opens a panel (a tab next to Inspector) and, while a mode is on and an entity with a `Foliage` component is selected, the
viewport paints on its terrain instead of selecting and moving: the gizmo is off and a click and drag is a brush stroke. It is the editor's
face of `foliage.paint`, `foliage.scatter` and `foliage.clear` (docs/BIG_WORLDS_TERRAIN.md, "Foliage commands"). The ground is the terrain of
the Foliage's `ScatterRule.terrain`, else the entity itself when it has a `Terrain3D` (a terrain with a Foliage on it), else its parent; a
Foliage with none says what to set. Edit mode only. Only one brush tool is on at a time (turning on a mode here turns the terrain tool off).

- **Add / Remove.** Add plants instances by the rules of the ScatterRule (slope, height, layers, spacing); Remove erases the ones inside the
  brush. Hold Ctrl while you stroke to do the other one.
- **Brush.** Radius in metres (`[` and `]` over the viewport), the density (the ScatterRule's, or its own slider in instances per square
  metre; an add stroke never puts two instances closer than half the average gap, so painting a spot twice does not stack them) and the mesh
  (every mesh of `Foliage.meshes`, or one: add plants only it, remove erases only it). A ring on the ground follows the relief: green for add,
  red for remove.
- **Scatter all** fills the whole Foliage from its ScatterRule (it replaces the instances there are) and **Clear** empties it; Clear asks first
  (the first click arms it, the second clears). Each is one undo step.
- **A stroke is one undo step.** The stamps are sent as a few `foliage.paint` pieces that share one step of the Foliage's history
  (`continueStroke`) and the release records one editor undo entry (`foliage.undo` on Ctrl+Z, `foliage.redo` on Ctrl+Shift+Z). Esc during a
  stroke takes it back and records nothing. A click that misses the terrain (the sky, another object) keeps the Foliage selected and the tool on.
- **What it costs.** Every piece rewrites the WHOLE instances file (52 MB at 2,000,000 instances), so the pieces are rate-limited: one every
  0.2 s, or every twice the time the last one took when that is longer, with what the mouse drew meanwhile going in the next one (up to 512
  stamps). A big Foliage paints in jumps a few times a second; the release sends what is left.
- **The history is bounded.** A Foliage keeps its last 64 edits / 128 MB, and all of them together 512 MB (the one edited longest ago clears
  first). When a step goes, the editor takes the undo rows of it out of the list and a toast says how many and names those limits. Editing the
  instances file or the Foliage's meshes outside the commands clears that Foliage's history the same way.
