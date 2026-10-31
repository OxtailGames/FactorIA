# Chapter 1, "The night shift": the porter meets the house. Mara and Hedda matter (Hedda's talk ends the chapter); the others set the scene.
# Run by assets/src/build_story.py, which gives this file the helpers conv, ch, S, A, G, T, CS, END and CHAPTER.

# ---------------------------------------------------------------------------------------------------------- Mara
c = conv("ch1_mara", "Mara in the hall, at the start of the night: the owner gives the porter his orders.")
c.route("start", ("talked.mara.1", "again"), (None, "greet"))
c.line("greet", "mara", "There you are. You must be the new night porter. Mara Lindqvist; the lodge is mine, and tonight's storm is nobody's fault.", "intro")
c.line("intro", "mara", "The pass closed at six. Until it opens we are six souls under this roof, and none of them in a good humour. Your work is the doors, the stove and the keys.",
       ch=[ch("start", "Where do I start?", "tip"),
           ch("worry", "Is something wrong?", "worry"),
           ch("promise", "I will keep everyone safe tonight.", "promise", fx=[A("trust")])])
c.line("tip", "mara", "Walk the house. Look at what you like, pick up what you find, and do not wake the guests.", "bye")
c.line("worry", "mara", "Wrong? A house full of strangers and a locked pass. That is the whole of it. Ask Hedda if you want more than that.", "bye")
c.line("promise", "mara", "Safe. That is a good word to begin a shift with. Hold on to it.", "bye")
c.line("bye", "mara", "Hedda is at the foot of the stairs, on the west side. Go and see her.", END, fx=[S("talked.mara.1")])
c.line("again", "mara", "Hedda is at the foot of the stairs. Go on.", END)

# --------------------------------------------------------------------------------------------------------- Hedda
c = conv("ch1_hedda", "Hedda at the foot of the stairs: she tells the porter that Dr. Vale is missing. Ends chapter 1.")
c.route("start", ("talked.hedda.1", "again"), (None, "greet"))
c.line("greet", "hedda", "The porter. Good. I have been up since four and I have nothing to give you but trouble.", "trouble")
c.line("trouble", "hedda", "Dr. Vale, room C. He went up after supper. I took his hot water at ten and the door was locked; he did not answer. At midnight, the same.",
       ch=[ch("asleep", "Maybe he is asleep.", "asleep"),
           ch("key", "Can we open the door?", "nokey"),
           ch("seen", "Has anyone seen him?", "seen")])
c.line("asleep", "hedda", "A sleeper snores. I know a snore. There is no sound in that room at all.", "conclude")
c.line("nokey", "hedda", "The key to room C is the guest's own, and the spare hangs on Mrs. Lindqvist's ring. She will not lend it until she must.", "conclude")
c.line("seen", "hedda", "He quarrelled with Mara at supper. Afterwards he stood a long while by the cellar door. After that, nobody saw him.", "conclude")
c.line("conclude", "hedda", "A man has vanished from a locked house in a snowstorm. Find him, porter.", END, fx=[S("vale_missing"), S("talked.hedda.1")])
c.line("again", "hedda", "Room C. Find him.", END)

# -------------------------------------------------------------------------------------------------------- Tobias
c = conv("ch1_tobias", "Tobias at the stove: soup, and the kitchen's view of the storm.")
c.line("greet", "tobias", "The night porter? Come in, you look half frozen. There is soup on the back of the stove.",
       ch=[ch("thanks", "Thank you.", "soup"),
           ch("busy", "Not now.", "busy")])
c.line("soup", "tobias", "Eight years I have cooked in this house and never seen the pass shut in November. Mind the pot, mind your feet.", END)
c.line("busy", "tobias", "Later, then. The soup keeps. So does the storm.", END)

# ---------------------------------------------------------------------------------------------------------- Haas
c = conv("ch1_haas", "Captain Haas by the lounge fire.")
c.line("greet", "haas", "Captain Haas, retired. Forty winters I guided people over that pass, and it still thinks it can surprise me.", "pass")
c.line("pass", "haas", "It will not open before morning. Nobody who left tonight is coming back.",
       ch=[ch("who", "Did anyone leave?", "who"),
           ch("wood", "I will bring more wood.", "wood")])
c.line("who", "haas", "Nobody could. That is the point of snow.", END)
c.line("wood", "haas", "A man who brings wood is a man I will like.", END)

# --------------------------------------------------------------------------------------------------------- Lucian
c = conv("ch1_lucian", "Lucian Arne by the radio.")
c.line("greet", "lucian", "Lucian Arne, the Valley Courier. Please tell me the radio works.",
       ch=[ch("hiss", "It only hisses.", "hiss"),
           ch("dispute", "What are you doing here?", "dispute")])
c.line("hiss", "lucian", "Of course it does. I came up for a story about a land dispute and got a blizzard instead.", END)
c.line("dispute", "lucian", "A story. Ask me tomorrow, when I am warm and you are less useful.", END)
