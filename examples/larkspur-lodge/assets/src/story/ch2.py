# Chapter 2, "Cold supper": four interviews, each leaves one clue flag; any three advance the chapter (interviews>=3).
# Tobias -> know_oil, Haas -> know_cellar, Lucian -> know_page, Mara -> know_argument. Hedda only adds colour.

# -------------------------------------------------------------------------------------------------------- Tobias
c = conv("ch2_tobias", "Tobias in the kitchen: Dr. Vale asked him for a lantern and lamp oil. Clue: know_oil.")
c.route("start", ("talked.tobias.2", "again"), (None, "greet"))
c.line("greet", "tobias", "You are asking about the doctor. Everybody is. Sit down; I sell nothing but facts.", "fact")
c.line("fact", "tobias", "He came into my kitchen at nine, polite as a bishop. He asked for a lantern and a can of lamp oil, and said his own lamp was giving trouble.",
       ch=[ch("why", "Did he say what for?", "why"),
           ch("gave", "Did you give them to him?", "gave"),
           ch("afraid", "Did he seem afraid?", "afraid")])
c.line("why", "tobias", "For the cellar. That is all he said. I thought he wanted to look over the wine.", "close")
c.line("gave", "tobias", "The oil, yes. One can. There is a second in the box by the door if you want it. The lantern I could not find; the house keeps its lanterns where it likes.", "close")
c.line("afraid", "tobias", "Afraid? No. Excited. Like a boy who has found the loose board in his father's attic.", "close")
c.line("close", "tobias", "That is all I know. The cellar, lamp oil, and a very happy man.", END,
       fx=[S("know_oil"), A("interviews"), S("talked.tobias.2")])
c.line("again", "tobias", "I have nothing to add. The cellar, lamp oil, a happy man. Ask somebody else.", END)

# ---------------------------------------------------------------------------------------------------------- Haas
c = conv("ch2_haas", "Captain Haas: Dr. Vale asked whether the cellar went back further than its shelves. Clue: know_cellar.")
c.route("start", ("talked.haas.2", "again"), (None, "greet"))
c.line("greet", "haas", "Vale. A careful man. He measured the yard before breakfast and the cellar after lunch. A man measures what he does not trust.", "cellar")
c.line("cellar", "haas", "He asked me whether the cellar went back further than the shelves. I told him no. He wrote that down.",
       ch=[ch("press", "Does it?", "deflect"),
           ch("trust", "I believe you, Captain.", "thanks", fx=[A("trust")]),
           ch("cold", "Wine shelves hide things.", "warn")])
c.line("deflect", "haas", "A cellar goes as far as its walls. Do not bend your mind round it.", "close")
c.line("thanks", "haas", "That is kind of you. Remember you said it.", "close")
c.line("warn", "haas", "Everything hides something. That is what shelves are for.", "close")
c.line("close", "haas", "Look at the cellar yourself if you must. Mind the third shelf of the wine rack; the wood is rotten.", END,
       fx=[S("know_cellar"), A("interviews"), S("talked.haas.2")])
c.line("again", "haas", "I have said what I know. The third shelf is rotten. Leave it at that.", END)

# --------------------------------------------------------------------------------------------------------- Lucian
c = conv("ch2_lucian", "Lucian at the dining table: Dr. Vale came for a missing page of an old survey. Clue: know_page.")
c.route("start", ("talked.lucian.2", "again"), (None, "greet"))
c.line("greet", "lucian", "Porter! Excellent. Vale's supper is still here, untouched. I find that eloquent.", "page")
c.line("page", "lucian", "Between us: Vale surveys land for the railway company. A survey of this valley was filed here eight years ago, and the county copy is missing a page. Page forty. He came to find the original.",
       ch=[ch("why", "Why does a page matter?", "why"),
           ch("who", "Who would hide a page?", "who"),
           ch("you", "And what do you get out of it?", "you")])
c.line("why", "lucian", "Page forty draws the line between this lodge and the railway's right of way. Move a line and you move a fortune.", "close")
c.line("who", "lucian", "Whoever gains from the line being where it is. A short list. It has one name and she owns the house.", "close")
c.line("you", "lucian", "A story. A good one. I am not ashamed of it.", "close")
c.line("close", "lucian", "Find Vale and you will find page forty, I would wager. Or the other way round.", END,
       fx=[S("know_page"), A("interviews"), S("talked.lucian.2")])
c.line("again", "lucian", "I have told you what I know. Page forty. Go and find it.", END)

# ---------------------------------------------------------------------------------------------------------- Mara
c = conv("ch2_mara", "Mara in the corridor: the quarrel at supper. Clue: know_argument. The kind reply earns trust.")
c.route("start", ("talked.mara.2", "again"), (None, "greet"))
c.line("greet", "mara", "You have spoken to Hedda, so you know Dr. Vale is gone.", "supper")
c.line("supper", "mara", "We quarrelled at supper. I will not pretend otherwise; the whole table heard. He asked for the 1911 survey, I said the lodge's copy was lost, and he called me a liar in front of my cook.",
       ch=[ch("kind", "That must have been hard.", "kind", fx=[A("trust")]),
           ch("blunt", "Were you lying?", "blunt"),
           ch("accuse", "You wanted him gone.", "accuse", fx=[S("mara_hurt")])])
c.line("kind", "mara", "It was. Thank you for noticing; most people notice the shouting.", "close")
c.line("blunt", "mara", "About the copy? I told him what I knew. My husband kept the papers and I never read them. I wish I had.", "close")
c.line("accuse", "mara", "I wanted him quiet. Not gone. Do not confuse the two, porter: one is a business and the other is a crime.", "close")
c.line("close", "mara", "Find him. Whatever he has found, I would rather it was found by someone I can talk to.", END,
       fx=[S("know_argument"), A("interviews"), S("talked.mara.2")])
c.line("again", "mara", "Find him, porter. That is all I ask.", END)

# --------------------------------------------------------------------------------------------------------- Hedda
c = conv("ch2_hedda", "Hedda on the landing: what she saw in room C. Colour only.")
c.line("greet", "hedda", "I looked through the keyhole of room C. His bag is open on the chair and his bed is made.", "think")
c.line("think", "hedda", "A man who leaves his bag open means to come back. So where is he?", "close")
c.line("close", "hedda", "Ask the others. Somebody in this house knows more than they say.", END)
