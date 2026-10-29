#!/bin/sh
# Bakes assets/art/shockwave.png (and its `sheet` entry in assets.json) from art/shockwave.anim.js. Run from the project folder
# with the factoria CLI on the PATH; the same call again gives the same bytes (the recipe is in the provenance of assets.json).
set -e
factoria call --project . assets.animate_svg '{"path":"assets/art/shockwave.png","source":"art/shockwave.anim.js","frameWidth":96,"frameHeight":96,"padding":2,"overwrite":true,"seed":7,"pivot":[0.5,0.5],"clips":[{"name":"pop","frames":8,"fps":24,"loop":false},{"name":"boom","frames":12,"fps":20,"loop":false,"params":{"sparks":10}}]}'
