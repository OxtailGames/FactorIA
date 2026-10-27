#!/usr/bin/env python3
"""Builds the cut-scenes of Larkspur Lodge: the opening, one lead-in per later chapter, the descent into the adit and the rescue,
and the three endings.

Run it from anywhere:  python3 -I assets/src/build_cutscenes.py

The cut-scenes are written here (a timeline of steps per cut-scene: see the README, "Cut-scenes (P4)") and the script writes
  data/cutscenes/<id>.cutscene.json   one file per cut-scene (format larkspur.cutscene/1)
  data/cutscenes/voice_script.json    every spoken line: clip id, speaker, text, the file it goes to (for assets.generate_voice)
and merges the captions and cards into locales/en.json under "cutscene" (every other key is kept).
Never edit the generated JSON by hand: `factoria call project.validate_cutscenes` checks it, this script writes it.
A new cut-scene file must also be imported in scripts/cutscene_data.js (the engine cannot list a folder: FB-0005) and listed in
CUTSCENES of assets/src/build_story.py (the registry of data/story.json).
Only the Python standard library is used.
"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
PROJECT = os.path.normpath(os.path.join(HERE, "..", ".."))

CUTSCENES = {}  # id -> dict
STRINGS = {}  # locale key -> text
VOICE = []  # [{ id, speaker, text, cutscene }]


class Scene:
    def __init__(self, cid, doc, duration, area=None, room="hall", actors=None, end=None, skippable=True):
        self.id = cid
        self.n = 0
        self.cards = 0
        self.data = {
            "format": "larkspur.cutscene/1",
            "id": cid,
            "doc": doc,
            "duration": duration,
            "room": room,
            "skippable": skippable,
            "actors": actors or {},
            "timeline": [],
            "end": end or {},
        }
        if area:
            self.data["area"] = area
        CUTSCENES[cid] = self.data

    def add(self, at, do, **kw):
        step = {"at": at, "do": do}
        step.update(kw)
        self.data["timeline"].append(step)

    def fade(self, at, to, seconds):
        self.add(at, "fade", to=to, seconds=seconds)

    def camera(self, at, pos, look, seconds, ease="inOut", space="world"):
        self.add(at, "camera", pos=pos, look=look, seconds=seconds, ease=ease, space=space)

    def move(self, at, actor, to, seconds, yaw=None, clip="walk"):
        kw = {"actor": actor, "to": to, "seconds": seconds, "clip": clip}
        if yaw is not None:
            kw["yaw"] = yaw
        self.add(at, "move", **kw)

    def face(self, at, actor, yaw=None, toward=None):
        kw = {"actor": actor}
        if toward is not None:
            kw["toward"] = toward
        else:
            kw["yaw"] = yaw
        self.add(at, "face", **kw)

    def anim(self, at, actor, clip):
        self.add(at, "anim", actor=actor, clip=clip)

    def say(self, at, speaker, text, seconds):
        """A caption with a voice line. The voice clip id is <cut-scene>_<nn>; the text is the locale string cutscene.<id>.line<nn>."""
        self.n += 1
        nn = "%02d" % self.n
        key = "cutscene.%s.line%s" % (self.id, nn)
        clip = "%s_%s" % (self.id, nn)
        STRINGS[key] = text
        VOICE.append({"id": clip, "speaker": speaker or "narrator", "text": text, "cutscene": self.id})
        step = {"at": at, "do": "caption", "key": key, "seconds": seconds, "voice": clip}
        if speaker:
            step["speaker"] = speaker
        self.data["timeline"].append(step)

    def card(self, at, text, seconds):
        self.cards += 1
        key = "cutscene.%s.card%d" % (self.id, self.cards)
        STRINGS[key] = text
        self.add(at, "card", key=key, seconds=seconds)

    def set(self, at, *effects):
        self.add(at, "set", effects=list(effects))


# ----------------------------------------------------------------------------------------------------------------- hall
# The hall: x 9 to 23, z 17 to 23.4. The porter arrives at (15, 21.6) looking north (-Z); Mara stands at (15, 19.2), Haas at
# (11.8, 21.4), Lucian at (21.6, 20.8) in chapter 1. Yaw 0 faces -Z, 90 -X, 180 +Z, 270 +X.
s = Scene(
    "intro",
    "The opening: the hall at eleven at night, the storm outside, the porter coming in out of the snow. Plays once, when the first area of a new game starts (flag intro_seen).",
    22,
    area="ground",
    room="hall",
    actors={
        "porter": {"as": "porter", "start": [15.0, 23.0, 0], "keep": True},
        "mara": {"as": "npc", "cast": "mara"},
        "haas": {"as": "npc", "cast": "haas"},
        "lucian": {"as": "npc", "cast": "lucian"},
    },
    end={"fade": 0, "set": [{"set": "intro_seen"}]},
)
s.fade(0, 1, 0)
s.camera(0, [9.4, 2.6, 17.3], [16.0, 1.0, 21.2], 0)
s.fade(0.4, 0, 2.2)
s.camera(0.4, [12.8, 2.5, 17.3], [16.2, 1.0, 21.4], 9.5, ease="inOut")
s.say(0.8, "", "Larkspur Lodge. Eleven at night, and the storm has taken the road, the telephone and most of the good humour.", 6.5)
s.move(3.2, "porter", [15.0, 21.6], 3.4, yaw=0)
s.face(3.0, "lucian", toward="porter")
s.say(7.6, "mara", "Close the door, porter, you are letting the whole mountain in.", 4.2)
s.anim(7.6, "mara", "emote-yes")
s.camera(10.2, [20.2, 2.5, 17.4], [14.2, 1.0, 20.4], 4.5, ease="inOut")
s.face(11.0, "mara", toward="porter")
s.say(12.2, "haas", "The pass is shut till morning. Nobody comes, nobody goes.", 4.5)
s.camera(16.0, [19.6, 2.6, 23.0], [14.6, 1.0, 20.0], 5.0, ease="out")
s.say(17.0, "", "You have the keys, the stove and a house full of strangers until dawn.", 4.5)
s.add(21.0, "hold")

# ------------------------------------------------------------------------------------------------ lead-ins to chapters 2 to 4
# Played on a black screen while the cast is placed again; the chapter card follows by itself (scripts/chapters.js). They name no
# place, so they play wherever the porter stands.
s = Scene("chapter_2", "Lead-in to chapter 2, Cold supper: a card and a narrated line on a black screen.", 11, room="hall", end={"fade": 1})
s.fade(0, 1, 0)
s.card(0.4, "Midnight", 3.6)
s.say(1.8, "", "The supper went cold on the long table. Dr. Vale's chair was still pushed back, as if he meant to return.", 7.0)

s = Scene("chapter_3", "Lead-in to chapter 3, Room C: a card and a narrated line on a black screen.", 11, room="hall", end={"fade": 1})
s.fade(0, 1, 0)
s.card(0.4, "One in the morning", 3.6)
s.say(1.8, "", "A locked door on the upstairs landing, and a house that has stopped pretending to sleep.", 6.5)

s = Scene("chapter_4", "Lead-in to chapter 4, The old way: a card and a narrated line on a black screen.", 11, room="cellar", end={"fade": 1})
s.fade(0, 1, 0)
s.card(0.4, "Three in the morning", 3.6)
s.say(1.8, "", "The wind found one note it liked and kept it. Below the kitchen, the old way waited behind the wine.", 7.0)

s = Scene(
    "chapter_5",
    "Lead-in to chapter 5, Dawn: the hall as the wind drops, the camera finding Dr. Vale on the sofa. Plays in the hall, where chapter 5 begins.",
    19,
    area="ground",
    room="hall",
    actors={"porter": {"as": "porter"}, "vale": {"as": "npc", "cast": "vale"}, "mara": {"as": "npc", "cast": "mara"}},
    end={"fade": 1},
)
s.fade(0, 1, 0)
s.camera(0, [22.0, 2.6, 17.6], [14.5, 1.0, 21.0], 0)
s.card(0.4, "Dawn", 3.2)
s.fade(2.4, 0, 2.0)
s.say(2.6, "", "The wind drops all at once, like a breath let go. The windows go from black to grey.", 6.0)
s.camera(2.6, [18.0, 2.5, 17.3], [12.4, 1.0, 21.2], 10.0, ease="inOut")
s.say(9.0, "vale", "Is it quiet, or have I gone deaf in that hole?", 4.0)
s.face(9.0, "vale", toward="porter")
s.say(13.2, "mara", "It is quiet, Ansel. Sit. You have a great deal to tell us.", 4.5)
s.fade(17.4, 1, 1.4)
s.add(18.8, "hold")

# ------------------------------------------------------------------------------------------------------------------ cellar
# The cellar: the wine rack at (18.5, 2.5); in chapter 4 Captain Haas waits at (18, 4.6). The adit opens behind the third shelf.
s = Scene(
    "adit_descent",
    "The porter lights the lantern and goes down the adit behind the third wine shelf. Asked by ch4_haas when the porter has the lantern and the oil; ends on a black screen, the conversation goes on in the dark.",
    13,
    area="cellar",
    room="cellar",
    actors={"porter": {"as": "porter", "keep": True}, "haas": {"as": "npc", "cast": "haas"}},
    end={"fade": 1},
)
s.camera(0, [14.2, 2.0, 7.2], [18.2, 1.0, 3.6], 0)
s.camera(0.2, [15.4, 1.8, 6.8], [18.4, 1.0, 3.2], 6.0, ease="inOut")
s.face(0.2, "haas", toward="porter")
s.say(0.6, "haas", "The third shelf turns on a hinge nobody has oiled in thirty years. Put your shoulder to it.", 5.4)
s.move(2.0, "porter", [18.4, 3.9], 3.4, yaw=0)
s.say(6.4, "", "The rack swings inward with a sound like a long breath, and the lantern shows a stair going down.", 5.2)
s.fade(10.6, 1, 2.0)
s.add(12.6, "hold")

s = Scene(
    "adit_rescue",
    "The porter brings Dr. Vale up the steps into the lamplight. Asked by the last line of ch4_haas; starts on the black screen the descent left.",
    14,
    area="cellar",
    room="cellar",
    actors={
        "porter": {"as": "porter", "keep": True},
        "haas": {"as": "npc", "cast": "haas"},
        "vale": {"as": "extra", "cast": "vale", "start": [18.4, 2.7], "yaw": 180},
    },
    end={"fade": 0},
)
s.fade(0, 1, 0)
s.camera(0, [15.4, 2.0, 6.6], [18.4, 1.1, 3.4], 0)
s.move(0, "porter", [18.4, 3.5], 0, yaw=180)
s.fade(0.4, 0, 1.6)
s.move(1.0, "vale", [18.4, 3.9], 2.2, yaw=180)
s.say(1.2, "", "Dr. Vale comes up the steps one at a time, the lamp in the porter's hand and the page forty in his coat.", 6.0)
s.move(3.4, "vale", [17.0, 5.6], 3.4, yaw=90)
s.move(3.6, "porter", [17.8, 5.2], 3.0, yaw=90)
s.camera(3.0, [14.6, 1.8, 7.8], [17.2, 1.2, 5.0], 6.0, ease="inOut")
s.say(7.4, "haas", "Easy, doctor. Easy. You are out now.", 3.6)
s.say(11.2, "vale", "Thirty years, Haas. And it was still exactly where we left it.", 2.8)

# --------------------------------------------------------------------------------------------------------------- endings
# They play in the hall (chapter 5 ends there), on the black screen scripts/chapters.js leaves, and end black: the ending screen follows.
def ending_scene(cid, doc, lines, cam_from, cam_to, look_from, look_to):
    s = Scene(
        cid,
        doc,
        17,
        area="ground",
        room="hall",
        actors={"porter": {"as": "porter"}, "vale": {"as": "npc", "cast": "vale"}, "mara": {"as": "npc", "cast": "mara"}, "haas": {"as": "npc", "cast": "haas"}},
        end={"fade": 1},
    )
    s.fade(0, 1, 0)
    s.camera(0, cam_from, look_from, 0)
    s.fade(0.4, 0, 1.8)
    s.camera(0.4, cam_to, look_to, 12.5, ease="inOut")
    for at, who, text, secs in lines:
        s.say(at, who, text, secs)
    s.fade(14.6, 1, 1.8)
    s.add(16.4, "hold")


ending_scene(
    "ending_dawn",
    "The 'dawn' ending: the truth is told in the hall as the first car comes down the pass.",
    [
        (1.0, "", "At eight the pass opened and the first car came down out of the white.", 4.4),
        (5.8, "mara", "I should have told you all of it years ago. The stones, the page, all of it.", 4.8),
        (10.8, "vale", "The survey will say it for us. It always did.", 3.4),
    ],
    [22.0, 2.6, 17.6], [17.6, 2.5, 17.3], [14.5, 1.0, 21.0], [12.6, 1.0, 21.0],
)
ending_scene(
    "ending_quiet",
    "The 'quiet' ending: the page goes into the hall stove and the lodge keeps its roof.",
    [
        (1.0, "", "The page curled in the stove and was gone before anyone found the words to stop it.", 4.6),
        (6.0, "mara", "Thank you. I will not forget what that cost you.", 4.0),
        (10.6, "haas", "Nobody is punished tonight. That is not the same as nobody being free.", 3.8),
    ],
    [9.6, 2.6, 18.0], [10.0, 2.5, 22.8], [15.5, 1.0, 20.8], [15.5, 1.0, 20.6],
)
ending_scene(
    "ending_long",
    "The 'long' ending: the Captain takes the blame in the hall and winter closes over the lodge.",
    [
        (1.0, "", "No car came down in the morning. The snow had other plans for the Brandt road.", 4.6),
        (6.0, "haas", "It was my silence. Let the Captain pay for it, and let the rest of you go in peace.", 4.8),
        (11.0, "mara", "Peace. Is that what you call it?", 3.0),
    ],
    [22.2, 2.6, 22.9], [22.2, 2.5, 18.2], [15.5, 1.0, 20.8], [16.5, 1.0, 20.6],
)

# ----------------------------------------------------------------------------------------------------------- the interface
STRINGS["cutscene.skip"] = "Skip"
STRINGS["cutscene.hint"] = "{key} to skip"

VOICES = {
    "doc": "The provider voice of each speaker, for assets.generate_voice (OpenAI voice names; pass them as `voice`). The narrator has one too.",
    "narrator": "ash",
    "mara": "nova",
    "hedda": "shimmer",
    "tobias": "onyx",
    "haas": "echo",
    "lucian": "fable",
    "vale": "alloy",
}


def write_json(rel, data):
    path = os.path.join(PROJECT, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")


for cid, data in CUTSCENES.items():
    # Steps in time order; "hold" only marks that nothing happens until the end.
    data["timeline"] = sorted(data["timeline"], key=lambda t: t["at"])
    data["timeline"] = [t for t in data["timeline"] if t["do"] != "hold"]
    write_json("data/cutscenes/%s.cutscene.json" % cid, data)

write_json("data/cutscenes/voice_script.json", {
    "format": "larkspur.voice_script/1",
    "doc": "Every spoken line of the cut-scenes, written by assets/src/build_cutscenes.py. Make a clip with assets.generate_voice {text, path: 'assets/voice/<id>.mp3', voice: voices[speaker]}, then add it to data/cutscenes/voice.json with its length in seconds.",
    "voices": VOICES,
    "lines": [{"id": v["id"], "speaker": v["speaker"], "cutscene": v["cutscene"], "text": v["text"], "path": "assets/voice/%s.mp3" % v["id"]} for v in VOICE],
})

loc_path = os.path.join(PROJECT, "locales", "en.json")
with open(loc_path, encoding="utf-8") as f:
    loc = json.load(f)
fresh = {}
for key, text in STRINGS.items():
    parts = key.split(".")
    tree = fresh
    for p in parts[:-1]:
        tree = tree.setdefault(p, {})
    tree[parts[-1]] = text
loc["cutscene"] = fresh["cutscene"]
with open(loc_path, "w", encoding="utf-8", newline="\n") as f:
    json.dump(loc, f, indent=2, ensure_ascii=False)
    f.write("\n")

print("cutscenes: %d files, %d voice lines, %d strings" % (len(CUTSCENES), len(VOICE), len(STRINGS)))
