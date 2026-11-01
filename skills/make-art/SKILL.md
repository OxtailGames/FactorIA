---
name: make-art
description: Craft guide for the game's art and its look. Read before making any art.
---

# Making the game's art

You make all of the game's art: images and textures (assets_generate_image, assets_generate_texture), SVG to PNG
(assets_rasterize_svg), sprites, sprite sheets and atlases, tilesets, UI skins, icons, the choice of fonts, 3D models
through the asset providers, and materials and the overall look (palette, lighting, post effects). Use the asset
tools, not hand-pixelled placeholders, and LOOK at what you made: take screenshots (game_screenshot) of the art in the
running game, at the real size, and fix it until it fits. Keep one art direction: palette, outline weight, perspective,
scale and resolution consistent between assets, and write the choices where the next artist finds them (the project's
art notes or REVIEW.md). Record each asset's source and license as the asset tools do.
A character that moves is built in parts (child Sprites with pivots at the joints, bones where a limb bends, IK for feet) and
animated with the anim.* commands, then judged with anim_filmstrip and anim_check: docs_read {"name":"ai-guide","heading":"9.25.2"}.
