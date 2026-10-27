// The string tables of every language, flattened to "a.b.c" -> text.
import en from "../../locales/en.json";
import es from "../../locales/es.json";
import de from "../../locales/de.json";
import ko from "../../locales/ko.json";
import he from "../../locales/he.json";

function flatten(obj, prefix = "", out = {}) {
  for (const [k, v] of Object.entries(obj)) {
    if (k === "$name") continue;
    if (v !== null && typeof v === "object") flatten(v, `${prefix}${k}.`, out);
    else out[prefix + k] = v;
  }
  return out;
}

export default { en: flatten(en), es: flatten(es), de: flatten(de), ko: flatten(ko), he: flatten(he) };
