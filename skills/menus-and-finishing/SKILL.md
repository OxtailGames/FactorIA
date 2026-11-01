---
name: menus-and-finishing
description: Menu kit, options, pause, saves and the finishing path. Read when the game needs menus or nears release.
---

# Menus and finishing the game

a main menu, options, pause, saves, languages and accessibility are not in an empty project.
When the game needs them, `factoria call project.add_menu_kit` (MCP `project_add_menu_kit`; `parts` picks main-menu, options, pause, loading, ...) copies the kit and merges its texts into the locales (`factoria docs read menus` explains it), and `factoria docs read finishing` the ordered
path to a game ready for a store, with a checklist.
