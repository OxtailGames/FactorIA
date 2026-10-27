// Every language walks the key screens at 100 % and 200 % text, all in this one file and so with one engine and one
// glyph atlas (tests/helpers/lang_walk.js). The atlas grows and clears when the five scripts fill it, and the texts
// on screen lay out again (ENGINE_FEEDBACK LL/FB-0901).
import { walkLanguage } from "./helpers/lang_walk.js";

for (const lang of ["en", "es", "de", "ko", "he"]) walkLanguage(lang);
