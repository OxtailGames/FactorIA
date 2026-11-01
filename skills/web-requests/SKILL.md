---
name: web-requests
description: http.fetch and the allowed hosts. Read before the game uses the network.
---

# Web requests

`http.fetch(url, {method, headers, body, timeout})` talks to a server; the hosts go in factoria.json
`"network": {"hosts": ["api.example.com"], "purpose": "..."}` (https only, undeclared hosts throw), tests script the
answers with `game.platform.respond("http.fetch", ...)`, and a script that awaits it checks `scene.current` before
using the answer: `factoria docs read networking`. Tell the user the privacy policy must mention the server.

The full guide is `factoria docs read networking`.
