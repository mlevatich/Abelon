import sys
import pprint

# poor man's enums
event_types = [ "seq", "comment", "say", "callback", "set-flag", "pick-up", "discard", "reply", "br", "label", "goto" ]
emotions    = [ "hidden", "content", "serious", "worried" ]
signals     = [ "Event", "Set", "Gain", "Callback", "Discard", "Transition" ]

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
                assert l_indent - indent == 1
                addGeneric('seq', { 'events': [] })
                prev_events = (prev_events, events)
                events = events[-1]['args']['events']
                indent += 1
            while l_indent < indent:
                events = prev_events[1]
                prev_events = prev_events[0]
                indent -= 1
            assert indent == l_indent
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

                # -> indicates a result or choreography
                if l[:2] == "->":
                    signal = l[3:].split(':')[0].strip()
                    assert signal in signals
                    if signal == 'Callback':
                        addGeneric("callback", {})
                    elif signal == 'Event' or signal == 'Transition':
                        addComment(l[3:])
                    else:
                        val = l[3:].split(':')[1].strip()
                        if   signal == 'Set':     addGeneric("set-flag", { "flag": val })
                        elif signal == 'Gain':    addGeneric("pick-up",  { "sp":   val })
                        elif signal == 'Discard': addGeneric("discard",  { "sp":   val })

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
                        if participant not in scene["participants"]:
                            scene["participants"].append(participant)
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
                            if fs[0] not in scene["participants"]:
                                scene["participants"].append(fs[0])
                            conds.append({"sp": fs[0], "val": fs[2], "op": fs[1], "aware": len(fs) > 3})
                        elif c[0] == '!':
                            conds.append({"b": False, "flag": c[1:]})
                        else:
                            conds.append({"b": True, "flag": c})

                    addGeneric("br", {"conditions": conds})

                # Labels identify subscenes that may be referenced at multiple places in the script
                elif l[:6] == "-LABEL":
                    subscene_id = l.replace("-","").split()[1]
                    events.append({ "type": "label", "args": { "id": subscene_id }})

                # Jump to a subscene
                elif l[:5] == "-GOTO":
                    subscene_id = l.replace("-","").split()[1]
                    events.append({ "type": "goto", "args": { "id": subscene_id }})

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

def convert(pyscript, chapter_independent):

    def mkResult(results, indent):
        header = '    ' * indent + "['result'] = {\n"
        footer = '\n' + '    ' * indent + '}'
        ind1 = '    ' * (indent + 1)
        ind2 = '    ' * (indent + 2)
        result_strs = []
        do_strs = []
        for r in results:
            if r['type'] == 'set':
                result_strs.append(ind1 + "['state'] = '{}'".format(r['flag']))
            if r['type'] == 'pick-up':
                do_strs.append("g.player:acquire(g:getMap():dropSprite('{}'))".format(r['sp'].lower()))
            if r['type'] == 'discard':
                do_strs.append("g.player:discard({})".format(r['sp'].lower()))
            if r['type'] == 'callback':
                f2 = "true" if chapter_independent else "false"
                result_strs.append(ind1 + "['callback'] = {{ '{}', {} }}".format(r['id'], f2))
            if r['type'] == 'imp':
                result_strs.append(ind1 + "['impressions'] = {{{}}}".format(", ".join(r['vals'])))
            if r['type'] == 'awa':
                result_strs.append(ind1 + "['awareness'] = {{{}}}".format(", ".join(r['vals'])))
        if len(do_strs) > 0:
            do_str_header = ind1 + "['do'] = function(g)\n" + ind2
            do_str_footer = '\n' + ind1 + "end"
            result_strs.append(do_str_header + "\n{}".format(ind2).join(do_strs) + do_str_footer)
        return header + ",\n".join(result_strs) + footer

    def mkComment(args, indent):
        return '    ' * indent + "-- " + args['comment_text']
    
    def mkSay(args, participants, needs_response, indent):
        ind = '    ' * indent
        ind1 = '    ' * (indent + 1)
        b = 'false, -- TODO: check if requires response (is there a choice() before the next say()?)'
        if needs_response == True:  b = 'true,'
        if needs_response == False: b = 'false,'
        sp = participants.index(args['speaker']) + 1
        emo = emotions.index(args['emotion'])
        text = args['dialogue']
        words = text.split()
        chars = 0
        starting_word = 0
        split_text = []
        for i in range(len(words)):
            chars += len(words[i]) + 1
            if chars > 70:
                split_text.append(words[starting_word:i])
                chars = 0
                starting_word = i
        split_text.append(words[starting_word:])
        if len(split_text) >= 5:
            print("WARN: text may be too long for dialogue box:\n" + text)
        text_lines = ind1 + '"' + " \\z\n{} ".format(ind1).join([" ".join(words) for words in split_text]) + '"'
        return '{}say({}, {}, {} \n{}\n{})'.format(ind, sp, emo, b, text_lines, ind)

    def mkJump(args, indent):
        return '    ' * indent + 'insertEvents({})'.format("subscene_{}".format(args['id'].lower()))
    
    def mkTest(conds):
        lua_conds = []
        for c in conds:
            if 'flag' in c:
                lua_conds.append("{}g.state['{}']".format("" if c['b'] else "not ", c['flag']))
            elif c['aware']:
                lua_conds.append("g:getSprite({}):getAwareness() {} {}".format(c['sp'].lower(), c['op'], c['val']))
            else:
                lua_conds.append("g:getSprite({}):getImpression() {} {}".format(c['sp'].lower(), c['op'], c['val']))
        lua_str = ' and '.join(lua_conds)
        return 'function(g) return {} end'.format(lua_str if lua_str != '' else 'true')
    
    def mkBr(args, event_concat, indent):
        ind = '    ' * indent
        return ind + 'br({}, {{\n{}\n'.format(mkTest(args['conditions']), event_concat) + ind + '})'
    
    # Terrible awful horrible function
    def mkChoice(sname, es, i, participants, label_results, indent):

        # assemble responses
        next = 0
        choices = []
        while True:
            t = es[i]['type']
            assert t == 'reply'
            choices.append(es[i]['args'])
            choices[-1]['events'] = []
            choices[-1]['prereqs'] = []
            if i - 1 >= 0 and es[i - 1]['type'] == 'br':
                choices[-1]['prereqs'] = es[i - 1]['args']['conditions']
            if i + 1 < len(es):
                if es[i + 1]['type'] == 'seq':
                    choices[-1]['events'] = es[i + 1]['args']['events']
                    if i + 2 < len(es) and es[i + 2]['type'] == 'reply':
                        i = i + 2
                    elif i + 3 < len(es) and es[i + 2]['type'] == 'br' and es[i + 3]['type'] == 'reply':
                        i = i + 3
                    else:
                        next = i + 1
                        break
                elif es[i + 1]['type'] == 'reply':
                    i = i + 1
                elif i + 2 < len(es) and es[i + 1]['type'] == 'br' and es[i + 2]['type'] == 'reply':
                    i = i + 2
                else:
                    next = i
                    break
            else:
                next = i
                break
        
        # to string
        frags = []
        ind1 = '    ' * (indent + 1)
        ind2 = '    ' * (indent + 2)
        choice_header = '    ' * indent + "choice({\n"
        choice_footer = '\n' + '    ' * indent + '})'
        choice_strs = []
        for c in choices:
            cs  = ind1 + '{\n'
            cs += ind2 + '["guard"] = {},\n'.format(mkTest(c['prereqs']))
            cs += ind2 + '["response"] = "{}",\n'.format(c['dialogue'])
            events_str, results, new_frags, label_results = mkEventsWrapper(sname, c['events'], participants, label_results, indent + 2)
            cs += events_str + ",\n"
            frags += new_frags
            imps = ["0"] * len(participants)
            any_imp = False
            for sp in c['impressions']:
                any_imp = True
                imp = str(c['impressions'][sp])
                imps[participants.index(sp)] = imp
            awas = ["0"] * len(participants)
            any_awa = False
            for sp in c['awareness']:
                any_awa = True
                awa = str(c['awareness'][sp])
                awas[participants.index(sp)] = awa
            if any_imp: results += [{ 'type': 'imp', 'vals': imps }]
            if any_awa: results += [{ 'type': 'awa', 'vals': awas }]
            cs += mkResult(results, indent + 2)
            cs += "\n" + ind1 + '}'
            choice_strs.append(cs)
        
        choice_str = choice_header + ",\n".join(choice_strs) + choice_footer
        return next, choice_str, frags, label_results
        
    def responseLookahead(es, i):
        while i < len(es):
            t = es[i]['type']
            if t == 'goto':     return None # inconclusive, we can't follow gotos
            if t == 'reply':    return True
            if t == 'say':      return False
            if t == 'seq':      return responseLookahead(es[i    ]['args']['events'], 0)
            if t == 'label':    return responseLookahead(es[i + 1]['args']['events'], 0)
            if t == 'callback': i += 1
            i += 1
        return False

    def mkEvents(sname, es, participants, label_results, indent):
        event_strs = []
        new_fragments = []
        results = []
        i = 0
        while i < len(es):
            ty = es[i]['type']
            args = es[i]['args']
            if ty == 'seq':
                event_concat, sub_res, sub_frags, label_results = mkEvents(sname, args['events'], participants, label_results, indent)
                results += sub_res
                new_fragments += sub_frags
                event_strs += event_concat
            elif ty == 'comment':
                event_strs.append(mkComment(args, indent + 1))
            elif ty == 'say':
                needs_response = responseLookahead(es, i + 1)
                event_strs.append(mkSay(args, participants, needs_response, indent + 1))
            elif ty == 'callback':
                assert es[i + 1]['type'] == 'seq'
                if sname[:-8] != 'callback':
                    cb_name = sname + '-callback'
                    cb_events = es[i + 1]['args']['events']
                    scene_frags, label_results = mkScene(cb_name, participants, cb_events, label_results)
                    new_fragments += scene_frags
                    results += [{ 'type': 'callback', 'id': cb_name }]
                else:
                    print("WARN: nested callback ignored: {}".format(sname + '-callback'))
                i += 1
            elif ty == 'set-flag':
                results += [{ 'type': 'set', 'flag': args['flag'] }]
            elif ty == 'pick-up':
                results += [{ 'type': 'pick-up', 'sp': args['sp'] }]
            elif ty == 'discard':
                results += [{ 'type': 'discard', 'sp': args['sp'] }]
            elif ty == 'reply':
                next, choice_str, sub_frags, label_results = mkChoice(sname, es, i, participants, label_results, indent + 1)
                new_fragments += sub_frags
                event_strs.append(choice_str)
                i = next
            elif ty == 'br':
                assert es[i + 1]['type'] == 'seq' or es[i + 1]['type'] == 'reply'
                if es[i + 1]['type'] == 'seq':
                    sub_events = es[i + 1]['args']['events']
                    event_concat, sub_res, sub_frags, label_results = mkEvents(sname, sub_events, participants, label_results, indent + 1)
                    results += sub_res
                    if len(sub_res) > 0:
                        print("WARN: results inside a br() are processed regardless of whether branch is taken:\n{}".format(str(sub_res)))
                    new_fragments += sub_frags
                    event_strs.append(mkBr(args, event_concat, indent + 1))
                    i += 1
            elif ty == 'label':
                assert es[i + 1]['type'] == 'seq'
                sub_events = es[i + 1]['args']['events']
                event_concat, sub_res, sub_frags, label_results = mkEvents(sname, sub_events, participants, label_results, 0)
                results += sub_res
                label_results[args['id'].lower()] = sub_res
                new_fragments += sub_frags
                new_fragments.append("subscene_{} = {{\n{}\n}}".format(args['id'].lower(), event_concat))
                event_strs.append(mkJump(args, indent + 1))
                i += 1
            elif ty == 'goto':
                event_strs.append(mkJump(args, indent + 1))
                assert args['id'].lower() in label_results
                results += label_results[args['id'].lower()]
            i += 1
        return (",\n".join(event_strs), results, new_fragments, label_results)

    def mkEventsWrapper(sname, es, participants, label_results, indent):
        header = '    ' * indent + "['events'] = {\n"
        footer = '\n' + '    ' * indent + '}'
        event_concat, results, new_fragments, label_results = mkEvents(sname, es, participants, label_results, indent)
        return (header + event_concat + footer, results, new_fragments, label_results)

    def mkScene(sname, participants, events, label_results):
        ids_str = "['ids'] = {{{}}}".format(", ".join(["'{}'".format(i.lower()) for i in participants]))
        events_str, results, new_fragments, label_results = mkEventsWrapper(sname, events, participants, label_results, 1)
        result_str = mkResult(results, 1)
        scene_str = "{}['{}'] = {{\n    {},\n{},\n{}\n}}".format(pyscript['name'], sname, ids_str, events_str, result_str)
        return (new_fragments + [scene_str], label_results)

    scenes = pyscript['scenes']
    fragments = []
    label_results = {}
    for s in scenes:
        new_fragments, label_results = mkScene(s['name'], s['participants'], s['events'], label_results)
        fragments.extend(new_fragments)

    header = "require 'src.script.Util'\n\n{} = {{}}\n\n".format(pyscript['name'])
    return header + "\n\n".join(fragments)

def main():

    # Read script file
    if len(sys.argv) != 3:
        print("Usage: python3 abelon/dev-utils/scripttool.py chapter chapter_independent(true/false)")
        exit(1)
    cname = sys.argv[1]
    chapter_independent = (sys.argv[2] == 'true')
    fname = "abelon/notes/script/{}.md".format(cname)
    with open(fname, 'r') as f: contents = f.read()

    # Parse string contents into a python data structure
    pyscript = parse(contents, cname)

    # pprint.PrettyPrinter(indent=1, width=150).pprint(pyscript)
    # exit(0)

    # Convert python struct to lua syntax
    luascript = convert(pyscript, chapter_independent)

    # Write script to lua file
    lua_fname = "abelon/src/script/{}-template.lua".format(cname)
    with open(lua_fname, 'w') as f: f.write(luascript)

if __name__ == "__main__":
    main()