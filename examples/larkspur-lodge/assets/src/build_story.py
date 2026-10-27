#!/usr/bin/env python3
"""Builds the story data of Larkspur Lodge from the conversations in assets/src/story/ch1..ch5.py.

Run it from anywhere:  python3 -I assets/src/build_story.py

The source is the place to edit the story: the conversations (assets/src/story/chN.py), and below, the flags, chapters, endings,
cast, places and the interface strings. The script writes
  data/dialogue/ch1.json .. ch5.json   the dialogue tables (format larkspur.dialogue/1; ids and structure only, no text)
  data/story.json                      the flag registry, chapters, endings, cut-scenes and the places the cast stands at
  data/cast.json                       the six characters: body, tint, schedule, conversation per chapter
and merges the text into locales/en.json (the subtrees dlg, cast, chapter, ending and dialogue; every other key is kept).
Never edit the generated JSON by hand: `factoria call project.validate_dialogue` checks it, this script writes it.
Only the Python standard library is used.
"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
PROJECT = os.path.normpath(os.path.join(HERE, "..", ".."))

END = "@end"

# --------------------------------------------------------------------------------------------------------------- the DSL
CONVERSATIONS = {}  # conversation id -> Conv (in definition order)
STRINGS = {}  # locale key -> text


class Conv:
    def __init__(self, cid, doc):
        self.id = cid
        self.doc = doc
        self.start = None
        self.nodes = {}  # node id -> node dict (ordered)
        CONVERSATIONS[cid] = self

    def node_id(self, name):
        return "dlg.%s.%s" % (self.id, name)

    def target(self, to):
        return END if to == END else self.node_id(to)

    def _add(self, name, node):
        nid = self.node_id(name)
        assert nid not in self.nodes, "node %s defined twice" % nid
        self.nodes[nid] = node
        if self.start is None:
            self.start = nid
        return nid

    def line(self, name, speaker, text, nxt=None, ch=None, fx=None):
        """A line. `nxt` is a node name or END; lines with choices usually leave it out."""
        nid = self.node_id(name)
        node = {"speaker": speaker}
        if speaker not in ("narrator", "porter"):
            node["voice"] = "%s_%s_%s" % (speaker, self.id, name)
        if fx:
            node["effects"] = list(fx)
        if nxt is not None:
            node["next"] = self.target(nxt)
        if ch:
            node["choices"] = []
            for i, c in enumerate(ch):
                key = "%s_c%d" % (nid, i + 1)
                STRINGS[key] = c["text"]
                entry = {"id": c["id"], "text": key}
                if c["if"]:
                    entry["if"] = list(c["if"])
                if c["fx"]:
                    entry["effects"] = list(c["fx"])
                entry["next"] = self.target(c["to"])
                node["choices"].append(entry)
        STRINGS[nid] = text
        self._add(name, node)

    def route(self, name, *branches):
        """A silent branch list: (condition | [conditions] | None, target); the last branch has no condition."""
        out = []
        for cond, to in branches:
            b = {}
            if cond is not None:
                b["if"] = [cond] if isinstance(cond, str) else list(cond)
            b["to"] = self.target(to)
            out.append(b)
        self._add(name, {"route": out})


def conv(cid, doc):
    return Conv(cid, doc)


def ch(cid, text, to, if_=None, fx=None):
    return {"id": cid, "text": text, "to": to, "if": if_ or [], "fx": fx or []}


def S(flag, value=True):
    return {"set": flag} if value is True else {"set": flag, "value": value}


def A(flag, by=1):
    return {"add": flag} if by == 1 else {"add": flag, "by": by}


def G(item):
    return {"give": item}


def T(item):
    return {"take": item}


def CS(cid):
    return {"cutscene": cid}


# ---------------------------------------------------------------------------------------------------------- the registries
FLAGS = {
    "chapter": ("number", "The chapter the night is in (1 to 5). Set by scripts/chapters.js; read by scripts/cast.js to place the characters and by P3's clue logic."),
    "interviews": ("number", "How many of the four chapter 2 interviews were held. Added to by ch2_tobias, ch2_haas, ch2_lucian and ch2_mara; chapter 2 ends at 3."),
    "trust": ("number", "How much the household trusts the porter. Added to by kind choices (ch1_mara, ch2_haas, ch2_mara, ch3_mara, ch4_mara, ch4_haas, ch4_lucian); the 'quiet' ending needs 3, Haas gives his room key at 1."),
    "ending": ("string", "The ending reached: dawn, quiet or long. Set by the last line of ch5_vale; read by scripts/chapters.js, which shows the ending screen."),
    "storm_over": ("boolean", "The storm has stopped and the front door can be opened. Set by the chapter 5 entry; read by the front door and P3."),
    "intro_seen": ("boolean", "The opening cut-scene has played. Set by the cut-scene player (P4)."),
    "vale_missing": ("boolean", "The porter knows Dr. Vale is missing. Set by ch1_hedda; ends chapter 1."),
    "know_oil": ("boolean", "Clue: Dr. Vale took a lantern and lamp oil to the cellar. Set by ch2_tobias and ch4_tobias; read by ch3_tobias."),
    "know_cellar": ("boolean", "Clue: the cellar goes back further than its shelves. Set by ch2_haas and by the chapter 4 entry; P3 reads it to hint at the wine rack."),
    "know_page": ("boolean", "Clue: Dr. Vale came for a missing survey page. Set by ch2_lucian."),
    "know_argument": ("boolean", "Clue: Mara and Dr. Vale quarrelled at supper. Set by ch2_mara."),
    "hedda_letter": ("boolean", "Hedda owns up to the torn letter. Set by ch3_hedda (when shown the letter) and ch4_hedda; read by ch5_lucian."),
    "survey_known": ("boolean", "The porter understands the boundary stones and page forty. Set by ch3_mara (library) or ch3_lucian (room B); the 'dawn' ending needs it."),
    "adit_known": ("boolean", "Haas has admitted the adit behind the third wine shelf. Set by ch4_haas."),
    "adit_open": ("boolean", "The adit is open. Set by ch4_haas when the porter opens it with the lantern and the lamp oil."),
    "vale_found": ("boolean", "Dr. Vale was brought out of the adit. Set by ch4_haas; ends chapter 4."),
    "page_recovered": ("boolean", "Page forty of the survey is in the porter's hands. Set by ch4_haas."),
    "mara_hurt": ("boolean", "The porter accused Mara of wanting Dr. Vale gone. Set by ch2_mara; colour for P4."),
    "mara_kind": ("boolean", "The porter asked Mara how she was in the library. Set by ch3_mara so the kindness earns trust once."),
    "haas_room": ("boolean", "Haas lent the key to room D. Set by ch3_haas."),
    "cellar_box_taken": ("boolean", "The library key was taken from the cellar crate. Set by the item box p_cellar_box."),
    "lantern_taken": ("boolean", "The cellar lantern was taken from the nook crate. Set by the item box p_lantern_box."),
    "ledger_taken": ("boolean", "The guest ledger was taken from the library. Set by the item box p_ledger_box."),
    "kitchen_box_taken": ("boolean", "The lamp oil was taken from the kitchen box. Set by the item box p_kitchen_box."),
    "letter_taken": ("boolean", "The torn letter was taken from room B. Set by the item box p_letter_box."),
    "test_box_taken": ("boolean", "The test room's key box was emptied. Set by the item box in the test room."),
}

PREFIXES = {
    "open.": "A door the porter opened: open.<door id>, set by scripts/interactable.js. Chapter 3 ends on open.guest_door_c.",
    "talked.": "A conversation held once in a chapter: talked.<character>.<chapter>. Set by the story data so a repeat gives the short 'again' line.",
}

CHAPTERS = [
    {"id": 1, "advance": ["vale_missing"], "title": "The night shift",
     "intro": "Snow closed the pass at six. You have the keys, the stove and a house full of strangers until morning."},
    {"id": 2, "advance": ["interviews>=3"], "title": "Cold supper",
     "intro": "Dr. Vale's supper is still on the table and nobody wants to say why he left it."},
    {"id": 3, "advance": ["open.guest_door_c"], "title": "Room C",
     "intro": "A man's bag lies open behind a locked door. Whoever holds the key holds the first answer."},
    {"id": 4, "advance": ["vale_found"], "enter": [S("know_cellar")], "title": "The old way",
     "intro": "Behind the third shelf of the wine rack the cellar goes further than anyone admitted."},
    {"id": 5, "final": True, "enter": [S("storm_over")], "start": {"area": "ground", "spawn": "spawn_default"}, "title": "Dawn",
     "intro": "The wind has dropped. The pass will open within the hour, and then everyone has a story to tell."},
]

ENDINGS = {
    "dawn": ("The Truth at Dawn", "The truth is filed: the stones, the page and Mara's honesty. The Brandt land comes home, and the lodge learns to live without a lie."),
    "quiet": ("The Quiet Way", "The page burns and the lodge keeps its roof. Nobody is punished, and nobody is free of it."),
    "long": ("The Long Winter", "The Captain pays for a silence that was never only his. The lodge stands, and winter closes over everything."),
}

CUTSCENES = {
    "adit_descent": "The porter lights the lantern and goes down the adit behind the third wine shelf. Played by P4.",
    "adit_rescue": "The porter brings Dr. Vale up the steps into the lamplight. Played by P4.",
}

# Where the cast stands: name -> (area, x, z, yaw). Metres in the area's scene; yaw 0 faces -Z, 90 -X, 180 +Z, 270 +X.
PLACES = {
    "hall_center": ("ground", 15.0, 19.2, 180),
    "hall_lounge": ("ground", 11.8, 21.4, 45),
    "hall_radio": ("ground", 21.6, 20.8, 270),
    "hall_bear": ("ground", 19.6, 21.9, 0),
    "hall_east": ("ground", 19.8, 20.4, 90),
    "hall_stairs": ("ground", 9.8, 21.6, 270),
    "hall_vale": ("ground", 11.8, 21.0, 45),
    "stair_hall": ("ground", 4.8, 18.0, 270),
    "corridor_mid": ("ground", 16.5, 13.0, 180),
    "corridor_east": ("ground", 26.0, 13.2, 180),
    "kitchen_stove": ("ground", 27.6, 1.9, 0),
    "kitchen_island": ("ground", 26.4, 5.0, 180),
    "dining_head": ("ground", 17.5, 5.2, 180),
    "library_desk": ("ground", 5.6, 4.4, 270),
    "landing_hedda": ("upstairs", 7.0, 16.6, 90),
    "upstairs_c_door": ("upstairs", 21.6, 10.0, 90),
    "room_b": ("upstairs", 12.0, 4.6, 0),
    "cellar_rack": ("cellar", 18.0, 4.6, 270),
}

# id -> (name, body, tint, role, schedule by chapter). The conversation of chapter N is chN_<id> (talk is derived from it).
CAST = {
    "mara": ("Mara Lindqvist", "e", [1, 1, 1, 1], "The owner of the lodge, a widow.",
             {1: "hall_center", 2: "corridor_mid", 3: "library_desk", 4: "hall_center", 5: "hall_center"}),
    "hedda": ("Hedda Brandt", "e", [0.55, 0.55, 0.65, 1], "The housekeeper.",
              {1: "stair_hall", 2: "landing_hedda", 3: "upstairs_c_door", 4: "landing_hedda", 5: "hall_stairs"}),
    "tobias": ("Tobias Rowe", "a", [1, 0.82, 0.62, 1], "The cook.",
               {1: "kitchen_stove", 2: "kitchen_island", 3: "kitchen_island", 4: "kitchen_stove", 5: "hall_east"}),
    "haas": ("Captain Haas", "a", [1, 1, 1, 1], "A retired mountain guide, a guest every winter.",
             {1: "hall_lounge", 2: "hall_lounge", 3: "corridor_east", 4: "cellar_rack", 5: "hall_bear"}),
    "lucian": ("Lucian Arne", "f", [1, 1, 1, 1], "A journalist of the Valley Courier.",
               {1: "hall_radio", 2: "dining_head", 3: "room_b", 4: "stair_hall", 5: "hall_radio"}),
    "vale": ("Dr. Ansel Vale", "f", [0.6, 0.72, 1, 1], "A surveyor of the railway company, the missing guest.",
             {5: "hall_vale"}),
}

UI_STRINGS = {
    "dialogue": {
        "next": "Next",
        "log": "Log",
        "logTitle": "Conversation log",
        "close": "Close",
    },
    "chapter": {"label": "Chapter {n}"},
    "ending": {"label": "Ending", "menu": "Main menu"},
}

# ----------------------------------------------------------------------------------------------------- run the chapters
for n in range(1, 6):
    path = os.path.join(HERE, "story", "ch%d.py" % n)
    with open(path, encoding="utf-8") as f:
        code = compile(f.read(), path, "exec")
    exec(code, {"conv": conv, "ch": ch, "S": S, "A": A, "G": G, "T": T, "CS": CS, "END": END})


def chapter_of(cid):
    return int(cid[2])


def write_json(rel, data):
    path = os.path.join(PROJECT, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")


# data/dialogue/chN.json
for n in range(1, 6):
    table = {"format": "larkspur.dialogue/1", "conversations": {}}
    for cid, c in CONVERSATIONS.items():
        if chapter_of(cid) == n:
            table["conversations"][cid] = {"doc": c.doc, "start": c.start, "nodes": c.nodes}
    write_json("data/dialogue/ch%d.json" % n, table)

# data/story.json
story = {"format": "larkspur.story/1", "flags": {}, "flagPrefixes": PREFIXES, "chapters": [], "endings": {}, "cutscenes": {}, "places": {}}
for name, (kind, doc) in FLAGS.items():
    story["flags"][name] = {"type": kind, "doc": doc}
for c in CHAPTERS:
    entry = {"id": c["id"], "titleKey": "chapter.%d.title" % c["id"], "introKey": "chapter.%d.intro" % c["id"]}
    if c.get("final"):
        entry["final"] = True
    else:
        entry["advance"] = c["advance"]
    if c.get("enter"):
        entry["enter"] = c["enter"]
    if c.get("start"):
        entry["start"] = c["start"]  # where the porter is taken when the chapter begins (everybody gathers in the hall)
    story["chapters"].append(entry)
for eid in ENDINGS:
    story["endings"][eid] = {"titleKey": "ending.%s.title" % eid, "textKey": "ending.%s.text" % eid}
story["cutscenes"] = {k: {"doc": v} for k, v in CUTSCENES.items()}
for name, (area, x, z, yaw) in PLACES.items():
    story["places"][name] = {"area": area, "x": x, "z": z, "yaw": yaw}
write_json("data/story.json", story)

# data/cast.json
cast = {"format": "larkspur.cast/1", "characters": {}}
for cid, (name, body, tint, role, schedule) in CAST.items():
    talk = {}
    for chap in schedule:
        conv_id = "ch%d_%s" % (chap, cid)
        assert conv_id in CONVERSATIONS, "%s has no conversation %s" % (cid, conv_id)
        talk[str(chap)] = conv_id
    cast["characters"][cid] = {
        "nameKey": "cast.%s.name" % cid,
        "role": role,
        "body": body,
        "tint": tint,
        "schedule": {str(k): v for k, v in schedule.items()},
        "talk": talk,
    }
write_json("data/cast.json", cast)

# locales/en.json
loc_path = os.path.join(PROJECT, "locales", "en.json")
with open(loc_path, encoding="utf-8") as f:
    loc = json.load(f)
for key in ("dlg", "cast", "chapter", "ending", "dialogue"):
    loc.pop(key, None)


def put(tree, dotted, text):
    parts = dotted.split(".")
    for p in parts[:-1]:
        tree = tree.setdefault(p, {})
        assert isinstance(tree, dict), "locale key %s collides with a text" % dotted
    assert parts[-1] not in tree, "locale key %s twice" % dotted
    tree[parts[-1]] = text


fresh = {}
for key, text in STRINGS.items():
    put(fresh, key, text)
for cid, (name, *_rest) in CAST.items():
    put(fresh, "cast.%s.name" % cid, name)
put(fresh, "cast.porter.name", "Porter")
for c in CHAPTERS:
    put(fresh, "chapter.%d.title" % c["id"], c["title"])
    put(fresh, "chapter.%d.intro" % c["id"], c["intro"])
for eid, (title, text) in ENDINGS.items():
    put(fresh, "ending.%s.title" % eid, title)
    put(fresh, "ending.%s.text" % eid, text)
for group, table in UI_STRINGS.items():
    for k, v in table.items():
        put(fresh, "%s.%s" % (group, k), v)
for key in ("dlg", "cast", "chapter", "ending", "dialogue"):
    loc[key] = fresh[key]
with open(loc_path, "w", encoding="utf-8", newline="\n") as f:
    json.dump(loc, f, indent=2, ensure_ascii=False)
    f.write("\n")

print("story: %d conversations, %d strings, %d flags, %d places" % (len(CONVERSATIONS), len(STRINGS), len(FLAGS), len(PLACES)))
