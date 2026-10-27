# Chapter 4, "The old way": Haas at the wine rack admits the adit; the porter needs the cellar lantern and the lamp oil to open it.
# Entering the chapter sets know_cellar (the sketch in room C). The chapter advances when vale_found is set.

# ---------------------------------------------------------------------------------------------------------- Haas
c = conv("ch4_haas", "Haas in the cellar: the adit behind the third shelf. Needs item:cellar_lantern and item:lamp_oil to open. Ends with Vale found.")
c.route("start", ("vale_found", "done"), ("adit_open", "done"), ("adit_known", "ready"), ("survey_known", "greet_knows"), (None, "greet"))
c.line("greet", "haas", "Porter. You have read his sketch, then. Room C told you what I would not.", "confess")
c.line("greet_knows", "haas", "Porter. Mara told you about the stones, and the sketch told you where to look. Then there is no sense in my silence.", "confess")
c.line("confess", "haas", "Behind the third shelf is the old adit, the mine they cut before the lodge was built. Emil and I walled its mouth with a door and a latch eight years ago. I told Dr. Vale nothing. I thought it safer forgotten.", "why",
       fx=[S("adit_known")])
c.line("why", "haas", "Say what you think of me. I have said worse.",
       ch=[ch("reason", "Why hide it?", "reason"),
           ch("angry", "A man may be dying in there.", "angry"),
           ch("calm", "You could not have known he would go in.", "calm", fx=[A("trust")])])
c.line("reason", "haas", "Because Emil asked me, and Emil was my friend. Loyalty is a vice, but it is the only one I have kept.", "plan")
c.line("angry", "haas", "Then open it. Quickly. Do not preach.", "plan")
c.line("calm", "haas", "That is more than I deserve. Thank you.", "plan")
c.line("ready", "haas", "You are back. The latch is waiting.", "plan")
c.line("plan", "haas", "The latch falls from the dark side and cannot be lifted from there. A man needs a light and a lantern's worth of oil to go down and bring someone up.", END,
       ch=[ch("open", "Open it.", "descend", if_=["item:cellar_lantern", "item:lamp_oil", "fuse_fixed"], fx=[S("adit_open"), CS("adit_descent")]),
           ch("nolantern", "I have no lantern.", "hint_lantern", if_=["!item:cellar_lantern"]),
           ch("nooil", "I have no lamp oil.", "hint_oil", if_=["item:cellar_lantern", "!item:lamp_oil"]),
           ch("nopower", "The latch will not move.", "hint_power", if_=["item:cellar_lantern", "item:lamp_oil", "!fuse_fixed"])])
c.line("hint_lantern", "haas", "Emil kept a lantern in a cardboard box in the nook, by the far wall. Go and get it.", END)
c.line("hint_power", "haas", "The latch works from the cellar circuit, and the storm has killed the circuit. The fuse box is on the cellar wall. Emil kept wire in his library desk, and there is a spare cartridge in the other box in the kitchen corner. Then the order of the day's trains, if I remember how he set it.", END)
c.line("hint_oil", "haas", "The cook keeps a can in the box by the kitchen door. Hurry.", END)
c.line("descend", "narrator", "The third shelf swings in on a rusted hinge and a breath of cold comes out of the dark. You light the lantern. The adit runs down, wet and low.", "found")
c.line("found", "vale", "Down here! Who is it? Bless you; I have run out of matches and of good sense.", "found2")
c.line("found2", "vale", "The latch dropped behind me and I have been counting stones for six hours. Take this. Page forty, from the iron box under the first stone, exactly as the letter said.", "found3",
       fx=[S("page_recovered")])
c.line("found3", "haas", "Ansel. I am sorry.", "found4")
c.line("found4", "vale", "Captain. I will forgive you when I am warm.", "up")
c.line("up", "narrator", "You bring him up the steps into the lamplight. Outside, the wind has dropped. Dawn is not far.", END,
       fx=[S("vale_found"), CS("adit_rescue")])
c.line("done", "haas", "It is open and he is up. Go and see to him.", END)

# ---------------------------------------------------------------------------------------------------------- Mara
c = conv("ch4_mara", "Mara in the hall: the porter may tell her what he knows; telling her the truth earns trust.")
c.route("start", ("talked.mara.4", "again"), (None, "greet"))
c.line("greet", "mara", "You look like a man carrying something heavy. Is it about Vale?",
       ch=[ch("truth", "I know about the stones, Mrs. Lindqvist.", "truth", if_=["survey_known"], fx=[A("trust")]),
           ch("cellar", "I think he is in the cellar.", "cellar"),
           ch("nothing", "Nothing yet.", "nothing")])
c.line("truth", "mara", "Then you know why I could not say it. Say what you must, but find him first.", "bye")
c.line("cellar", "mara", "The cellar? Emil never let me past the second shelf. The door is not locked. Go.", "bye")
c.line("nothing", "mara", "Then hurry.", "bye")
c.line("bye", "mara", "I will be here, by the fire.", END, fx=[S("talked.mara.4")])
c.line("again", "mara", "I will be here, by the fire.", END)

# --------------------------------------------------------------------------------------------------------- Hedda
c = conv("ch4_hedda", "Hedda on the landing owns up to the letter if the porter has not already made her.")
c.route("start", ("hedda_letter", "known"), (None, "confess"))
c.line("confess", "hedda", "I wrote the letter. My father's farm went under the railway, and I wanted a man with a theodolite to ask a question.", "sorry")
c.line("sorry", "hedda", "I never meant to send him into the dark.", END, fx=[S("hedda_letter")])
c.line("known", "hedda", "I did what I could, and it was not enough. Bring him back.", END)

# -------------------------------------------------------------------------------------------------------- Tobias
c = conv("ch4_tobias", "Tobias at the stove: where the second can of lamp oil is. Also sets know_oil for a porter who skipped him in chapter 2.")
c.line("greet", "tobias", "If it is the cellar you are going to, you will want oil. There is a can in the box by the kitchen door.", "bread", fx=[S("know_oil")])
c.line("bread", "tobias", "And take the heel of the loaf for the doctor. A man comes out of the dark hungry.", END)

# --------------------------------------------------------------------------------------------------------- Lucian
c = conv("ch4_lucian", "Lucian at the foot of the stairs: he promises to keep his pencil in his pocket.")
c.route("start", ("talked.lucian.4", "again"), (None, "greet"))
c.line("greet", "lucian", "I will keep Mara company in the hall. If you find the page, my pencil stays in my pocket until you say.",
       ch=[ch("please", "Please do.", "thanks", fx=[A("trust")]),
           ch("later", "We will see.", "later")])
c.line("thanks", "lucian", "A promise. I have broken a few, but never one made to a man with a lantern.", END, fx=[S("talked.lucian.4")])
c.line("later", "lucian", "Fair enough. I shall be around.", END, fx=[S("talked.lucian.4")])
c.line("again", "lucian", "My pencil is in my pocket.", END)
