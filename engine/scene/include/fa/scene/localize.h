// The localization pass: writes the string of each `key` into the text of the component that has it.
//   Text.key                                             -> Text.text
//   Button.key / Toggle.key / Slider.key / TextField.key -> Button.text / Toggle.label / Slider.label / TextField.placeholder
// A text is written only when it differs. A key that no string table has leaves the component's own text and logs one warning
// per key. The engine runs it after every scene load, every frame before drawing and on every language change; scripts that
// spawn entities run it for the new ones (docs/LOCALIZATION.md). Plural entries and {placeholders} need arguments, which a
// `key` field has none of: use i18n.t(key, args) from a script for those.
#pragma once

#include "fa/core/i18n.h"
#include "fa/scene/world.h"

namespace fa {

// One entity's Text and widget. Returns how many strings changed.
int localize_entity(World& world, Entity entity, const I18n& i18n);
// Every entity of the world, active or not (an inactive menu must already be right when it opens).
int localize_world(World& world, const I18n& i18n);

}  // namespace fa
