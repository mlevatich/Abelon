import sys
import pprint

# poor man's enums
event_types = [ "comment", "say", "callback", "set-flag", "reply", "br", "label", "goto" ]
emotions    = [ "hidden", "content", "serious", "worried" ]

def parse(contents, cname):

    # setup
    script = {}
    script['name'] = "s" + cname.replace("-", "")
    script['scenes'] = []
    lines = contents.splitlines()

    # scene state flags
    scene = None
    events = None
    prev_events = None
    in_dialogue = False
    indent = 0

    # helpers
    def addGeneric(ty, args):
        assert ty in event_types
        events.append({ "type": ty, "args": args })
    def addComment(l):
        addGeneric("comment", { "comment_text": l })
    def addSay(s, e, d):
        addGeneric("say", { "speaker": s, "emotion": e, "dialogue": d })

    # parse loop
    for raw in lines:
        l = raw.rstrip()
        if l:

            # When indentation level changes, we enter or exit a sublist of events
            l_indent = (len(l) - len(l.lstrip())) // 4
            if l_indent > indent:
                events.append([])
                prev_events = (prev_events, events)
                events = events[-1]
            if l_indent < indent:
                events = prev_events[1]
                prev_events = prev_events[0]
            indent = l_indent
            l = l.strip()

            # If starting a new scene, save the last one and reset the scene state
            if l[:2] == "##":
                assert not in_dialogue and indent == 0
                if scene: script['scenes'].append(scene)
                scene = { "name": l[3:], "participants": ["Abelon"], "events": [] }
                events = scene["events"]
                prev_events = None
                in_dialogue = False
                indent = 0
                continue

            # Signaling enter or exit of dialogue
            if l[:3] == "```":
                in_dialogue = not in_dialogue
                continue

            # If in a dialogue segment, process events, choices, and talking
            if in_dialogue:

                # -> indicates something happens
                if l[:2] == "->":
                    signal = l[3:].split(':')[0]
                    if signal == 'Callback':
                        addGeneric("callback", {})
                    elif signal == 'Set':
                        addGeneric("set-flag", { "flag": l[3:].split(':')[1].strip() })
                    else:
                        addComment(l[3:])

                # A: indicates an option the player can reply with
                elif l[:2] == "A:":
                    reply = l[3:].split('(')[0].strip()
                    changes = []
                    if len(l.split('(')) > 1:
                        changes = l.split('(')[1].replace(')',"").split(",")
                    imp = {}
                    awa = {}
                    for change in changes:
                        participant = change.strip().split()[0]
                        delta = change.strip().split()[1]
                        if delta[-1] == 'a': awa[participant] = int(delta[:-1])
                        else:                imp[participant] = int(delta)
                    addGeneric("reply", {"dialogue": reply, "impressions": imp, "awareness": awa})

                # Asterisks indicate a branch
                elif l[0] == "*":
                    s = l.replace("*","")
                    assert s[:2] == "If"
                    str_conds = s[3:].split(',')
                    conds = []
                    for c_raw in str_conds:
                        c = c_raw.strip()
                        if c[0] == '#':
                            fs = c[1:].split()
                            assert fs[1] in [">", "<"]
                            conds.append({"sp": fs[0], "val": int(fs[2]), "op": fs[1], "aware": len(fs) > 3})
                        elif c[0] == '!':
                            conds.append({"b": False, "flag": c[1:]})
                        else:
                            conds.append({"b": True, "flag": c})

                    addGeneric("br", {"conditions": conds})

                # Labels identify subscenes that may be referenced at multiple places in the script
                elif l[:6] == "-LABEL":
                    subscene_id = l.replace("-","").split()[1]
                    events.append({ "e_type": "label", "contents": { "id": subscene_id }})

                # Jump to a subscene
                elif l[:5] == "-GOTO":
                    subscene_id = l.replace("-","").split()[1]
                    events.append({ "e_type": "goto", "contents": { "id": subscene_id }})

                # If none of the above, someone is saying something
                else:
                    speaker = l.split(':')[0]
                    sp_name = speaker.split('(')[0].strip()
                    emotion = "content"
                    if sp_name != speaker:
                        emotion = l.split('(')[1].split(')')[0]
                    dialogue = l.split(':')[1][1:]

                    assert emotion in emotions
                    if sp_name not in scene["participants"] and sp_name != '_':
                        scene["participants"].append(sp_name)
                    addSay(sp_name, emotion, dialogue)

            # If not in a dialogue segment, the line is processed as a comment
            elif scene:
                addComment(l)

    script['scenes'].append(scene)
    return script

def convert(pyscript, cname):
    return ""

def main():

    # Read script file
    if len(sys.argv) != 2:
        print("Usage: python3 abelon/dev-utils/scripttool.py chapter")
        exit(1)
    cname = sys.argv[1]
    fname = "abelon/notes/script/{}.md".format(cname)
    with open(fname, 'r') as f: contents = f.read()

    # Parse string contents into a python data structure
    pyscript = parse(contents, cname)

    pprint.PrettyPrinter(indent=4, width=118).pprint(pyscript)
    exit(0)

    # Convert python struct to lua syntax
    luascript = convert(pyscript, cname)

    # Write script to lua file
    lua_fname = "abelon/src/script/{}-template.lua".format(cname)
    with open(lua_fname, 'w') as f: f.write(luascript)

if __name__ == "__main__":
    main()