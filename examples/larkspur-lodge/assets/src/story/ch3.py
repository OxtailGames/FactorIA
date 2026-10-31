# Chapter 3, "Room C": get the key of room C (Hedda or Tobias), learn why the survey matters (Mara in the library or Lucian), open the door.
# The chapter advances when the door is opened (open.guest_door_c).

# --------------------------------------------------------------------------------------------------------- Hedda
c = conv("ch3_hedda", "Hedda at the door of room C holds the spare key. The torn letter, urgency or a threat each open her; 'please' does not.")
c.route("start", ("item:room_c_key", "again"), ("open.guest_door_c", "again"), ("talked.hedda.3", "again"), (None, "greet"))
c.line("greet", "hedda", "You are standing at room C. Do not tell me you want the key.", "ask")
c.line("ask", "hedda", "Mara gave me the spare at midnight and told me to keep it. I will hand it to whoever says the right thing.",
       ch=[ch("letter", "I found a torn letter in room B.", "letter", if_=["item:torn_letter"]),
           ch("urgent", "A man may be freezing in the dark.", "urgent"),
           ch("threat", "Give me the key or I tell Mara you hid it.", "threat"),
           ch("please", "Please.", "please")])
c.line("letter", "hedda", "So Lucian kept it. I wrote that for the newspaper and for the doctor, two copies. Yes, I wrote 'do not trust the owner'. Is Mara kind to me? Always. Is she honest? Ask her about the boundary stones.", "letter2",
       fx=[S("hedda_letter")])
c.line("letter2", "hedda", "I did not mean any harm to come of it. I wanted a man with a measuring chain to ask the right question.", "give")
c.line("urgent", "hedda", "Yes. That is why I am still up. All right.", "give")
c.line("threat", "hedda", "Tell her. She knows I would never keep a key from a man who needed it. Here.", "give")
c.line("please", "hedda", "That is not good enough and not bad enough. Come back with a reason.", END)
c.line("give", "hedda", "Take it. If he is in there, bring him to me.", END, fx=[G("room_c_key"), S("talked.hedda.3")])
c.line("again", "hedda", "You have the key. Use it.", END)

# -------------------------------------------------------------------------------------------------------- Tobias
c = conv("ch3_tobias", "Tobias knows where the pantry spare of the room C key hangs. The oil clue, or a kindness, wins it.")
c.route("start", ("item:room_c_key", "again"), ("open.guest_door_c", "again"), ("talked.tobias.3", "again"), (None, "greet"))
c.line("greet", "tobias", "The doctor again? You have the face of a man who wants a key.", "key")
c.line("key", "tobias", "The spare of room C hangs in my pantry. Mrs. Lindqvist thinks I do not know. What do you offer me?",
       ch=[ch("oil", "You gave him lamp oil at nine. If he is hurt, the kitchen is part of it.", "oil", if_=["know_oil"]),
           ch("owed", "I am the porter. I am owed the key.", "owed"),
           ch("idea", "I will tell her it was my idea.", "idea")])
c.line("oil", "tobias", "Ha. You have been listening. Take it.", "give")
c.line("owed", "tobias", "Porter or bishop, you stand by my pot and not by my pantry. Ask somebody else.", END)
c.line("idea", "tobias", "That would be generous and foolish. Take it.", "give")
c.line("give", "tobias", "It is on the hook behind the flour. Bring it back unbroken.", END, fx=[G("room_c_key"), S("talked.tobias.3")])
c.line("again", "tobias", "You have what you came for. Go on.", END)

# ---------------------------------------------------------------------------------------------------------- Mara
c = conv("ch3_mara", "Mara in the library (needs the library key): the boundary stones. Sets survey_known; a kind question earns trust once.")
c.route("start", ("talked.mara.3", "again"), (None, "greet"))
c.line("greet", "mara", "You found the library. I have not been in here since my husband's funeral.", "desk")
c.line("desk", "mara", "This was Emil's desk. Ledgers, a letter opener, and a drawer I have never had the courage to open.",
       ch=[ch("ledger", "I have the guest ledger.", "ledger", if_=["item:guest_ledger"]),
           ch("stones", "Tell me about the boundary stones.", "stones"),
           ch("fine", "Are you all right?", "fine", if_=["!mara_kind"], fx=[S("mara_kind"), A("trust")])])
c.line("fine", "mara", "Not yet. Ask me a better question.", "desk")
c.line("ledger", "mara", "That is his clerk's hand. Look: three men from the railway office stayed one night each, eight years ago. The first stayed three. Emil paid for that silence.", "confess")
c.line("stones", "mara", "Emil moved two of them in the spring after the railway first came asking. He told me it was drainage. I believed him until Dr. Vale said 'right of way' at supper.", "confess")
c.line("confess", "mara", "Page forty would show where the stones stood in 1911. If it shows what I fear, the lower field, the orchard and the road belong to the railway, and the Brandt farm was taken to make room for nothing.", "bye")
c.line("bye", "mara", "Now you know what I could not say at supper. Find the doctor, and then find the page.", END, fx=[S("survey_known"), S("talked.mara.3")])
c.line("again", "mara", "I have told you everything I know. Find the doctor.", END)

# ---------------------------------------------------------------------------------------------------------- Haas
c = conv("ch3_haas", "Haas in the east corridor: his room key is a reward for the trust the porter has earned (trust>=1).")
c.route("start", ("talked.haas.3", "again"), (None, "greet"))
c.line("greet", "haas", "Porter. You go up and down these stairs like a man who has lost a button.",
       ch=[ch("room", "May I search your room, Captain?", "room", if_=["trust>=1"]),
           ch("midnight", "Where were you at midnight?", "midnight"),
           ch("nothing", "Nothing, Captain.", "nothing")])
c.line("room", "haas", "Room D. The key is in my pocket. There is nothing there but old maps; take it if it settles your mind.", "gave",
       fx=[G("room_d_key"), S("haas_room")])
c.line("gave", "haas", "Do not thank me. A key is a small thing to lend a man who asks plainly.", END, fx=[S("talked.haas.3")])
c.line("midnight", "haas", "Here, at the east end, listening to the storm. A habit of old guides.", END, fx=[S("talked.haas.3")])
c.line("nothing", "haas", "Then go and do it somewhere else.", END)
c.line("again", "haas", "I have said my piece.", END)

# --------------------------------------------------------------------------------------------------------- Lucian
c = conv("ch3_lucian", "Lucian in room B (the door is shut, not locked): the second way to learn the survey story. Sets survey_known.")
c.route("start", ("talked.lucian.3", "again"), (None, "greet"))
c.line("greet", "lucian", "Come in, come in. You have come about the stones; I can see it in your boots.", "stones")
c.line("stones", "lucian", "Emil Lindqvist moved two boundary stones eight years ago, so the railway's right of way would bend round the lodge and through Brandt's farm. Vale suspected it. I can prove nothing without page forty.",
       ch=[ch("print", "Will you print it?", "print"),
           ch("spare", "Spare the widow.", "spare")])
c.line("print", "lucian", "If the page exists, I will. Whoever it hurts.", END, fx=[S("survey_known"), S("talked.lucian.3")])
c.line("spare", "lucian", "Sparing is for people with other jobs.", END, fx=[S("survey_known"), S("talked.lucian.3")])
c.line("again", "lucian", "Find the page, porter, and bring it to me before you bring it to anyone else.", END)
