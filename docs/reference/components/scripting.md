[Back to the index](../README.md)

# Components: Scripting

## Script

Attaches JavaScript behaviour to the entity. `path` is an ES module whose default export is a class extending Behaviour (see docs/SCRIPTING.md).

| Field | Type | Default | Description |
|---|---|---|---|
| `path` | asset (script) | `""` | Project-relative path of the script, e.g. "scripts/player.js". |
| `props` | json | `{}` | JSON object of tunable values assigned onto the behaviour instance (this.speed = props.speed) before onStart. Lets one script serve many entities with different settings. |
| `enabled` | bool | `true` | false = the script receives no callbacks. |

