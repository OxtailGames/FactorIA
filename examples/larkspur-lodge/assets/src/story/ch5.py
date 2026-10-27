# Chapter 5, "Dawn": everyone is in the hall, Dr. Vale on the sofa with page forty. Talking to Vale ends the story with one of three endings:
#   dawn  (truth)  needs survey_known;  quiet (bury)  needs trust>=3;  long (accuse)  is always possible.
# The last node of each ending sets the `ending` flag; scripts/cast.js then shows the ending screen once the conversation is over.

# ---------------------------------------------------------------------------------------------------------- Vale
c = conv("ch5_vale", "Dr. Vale on the sofa: the finale. Offers the endings by the story so far.")
c.route("start", ("ending", "done"), (None, "greet"))
c.line("greet", "vale", "There he is, the man with the lantern. I owe you a bed, a breakfast and an explanation. First, the page.", "page")
c.line("page", "vale", "Page forty of the Ostrander survey, in the surveyor's own hand. The first stone stood at the foot of the cellar steps, not at the road.", "page2")
c.line("page2", "vale", "Eight years ago Emil Lindqvist moved the road stone to bend the right of way round the lodge, and buried the proof in the adit.", "ask")
c.line("ask", "vale", "My report goes to the railway and the land office by noon, unless someone shows me a better way. What do you say, porter?",
       ch=[ch("truth", "File it. The truth, all of it.", "truth_a", if_=["survey_known"]),
           ch("bury", "Mara has lost enough tonight. Leave her the lodge.", "bury_a", if_=["trust>=3"]),
           ch("accuse", "It was the Captain. He shut you in.", "accuse_a"),
           ch("wait", "Give me a moment.", "wait")])
c.line("wait", "vale", "Take your time. The sun cannot hurry for us.", "ask")
c.line("done", "vale", "Safe journey, porter. And thank you.", END)

# the truth
c.line("truth_a", "vale", "Then I file it as it is: the stones, the page, and Mrs. Lindqvist's honesty last night, which I will add in her favour.", "truth_route")
c.route("truth_route", ("trust>=3", "dawn_warm"), (None, "dawn_cold"))
c.line("dawn_warm", "narrator", "By spring the Brandt land is back under the Brandt name. Mara keeps the house and sells the orchard to pay for it, and Hedda opens the first shutters of the year herself.", "dawn_end")
c.line("dawn_cold", "narrator", "The report is filed. The lodge keeps its roof but loses the orchard and the road, and Mara speaks to nobody for a month. Hedda goes home to the Brandt land alone.", "dawn_end")
c.line("dawn_end", "narrator", "You stand at the front door as the pass opens. It is the first morning in eight years without a lie in the house.", END,
       fx=[S("ending", "dawn")])

# the quiet way
c.line("bury_a", "vale", "A page is only paper. If it burned in the lamp tonight, I could swear I never found it. Is that what you want?",
       ch=[ch("burn", "Burn it.", "bury_b"),
           ch("keep", "No. Not that.", "ask")])
c.line("bury_b", "narrator", "The page curls and goes black in the lamp. You drop the guest ledger and the torn letter in after it, and the flame is a long time dying.", "bury_c",
       fx=[T("guest_ledger"), T("torn_letter")])
c.line("bury_c", "narrator", "Vale files a report that calls the survey lost. Mara keeps the lodge. Hedda leaves at dawn and does not look back, and the porter keeps the keys and the silence.", "bury_end")
c.line("bury_end", "narrator", "Down in the cellar, behind the third shelf, a latch holds a little more firmly than before.", END,
       fx=[S("ending", "quiet")])

# the long winter
c.line("accuse_a", "vale", "The Captain? I heard no footsteps; the latch fell on its own. But he knew, and he said nothing. For a report, that is blame enough.", "accuse_b")
c.line("accuse_b", "haas", "I knew it would come to this. Go on, porter. Say it loud enough that the others hear.", "accuse_c")
c.line("accuse_c", "narrator", "The Captain leaves on the first sledge down. Vale's report names an old man's silence and says nothing of the stones. Mara thanks you in a voice with no warmth in it.", "accuse_end")
c.line("accuse_end", "narrator", "The lodge stands, the page goes back into a drawer, and winter closes over all of it.", END,
       fx=[S("ending", "long")])

# ---------------------------------------------------------------------------------------------------------- Mara
c = conv("ch5_mara", "Mara at the fire after the rescue.")
c.line("greet", "mara", "He is safe. I do not know whether to thank you or to hate you for it.",
       ch=[ch("later", "Thank me later.", "later"),
           ch("plan", "What will you do?", "plan")])
c.line("later", "mara", "I will. If there is a lodge to thank you in.", END)
c.line("plan", "mara", "Whatever the page says. I have been afraid of it for eight years, and there is relief in seeing it in lamplight.", END)

# --------------------------------------------------------------------------------------------------------- Hedda
c = conv("ch5_hedda", "Hedda in the hall after the rescue.")
c.line("greet", "hedda", "He is alive, then. I will leave at noon whatever is decided.", "close")
c.line("close", "hedda", "It was only ever that I wanted someone to look.", END)

# -------------------------------------------------------------------------------------------------------- Tobias
c = conv("ch5_tobias", "Tobias in the hall with the breakfast.")
c.line("greet", "tobias", "Breakfast in ten minutes for anyone with a clear conscience, which is nobody. Eat anyway.", END)

# ---------------------------------------------------------------------------------------------------------- Haas
c = conv("ch5_haas", "Haas in the hall: he will not argue with what the porter decides.")
c.line("greet", "haas", "I will not argue with what you decide. I have been wrong for eight years.", "close")
c.line("close", "haas", "Whatever it costs me, it was cheaper than a man's life.", END)

# --------------------------------------------------------------------------------------------------------- Lucian
c = conv("ch5_lucian", "Lucian in the hall: his pencil is out of his pocket again.")
c.route("start", ("hedda_letter", "letter"), (None, "greet"))
c.line("greet", "lucian", "Whatever you choose, remember that I was excellent company in a storm.", END)
c.line("letter", "lucian", "That letter was Hedda's, you know. I would not print her name. I would print everything else.", END)
