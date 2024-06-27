require 'src.script.Util'

s14 = {}

s14['entry'] = {
    ['ids'] = {'abelon'},
    ['events'] = {
        blackout(),
        teleport(1, 100, 2, 'monastery-approach'),
        focus(1, 10000),
        evening(),
        chaptercard(),
        changeMusic('Canopied-Steps'),
        wait(1),
        fade(0.4),
        wait(3),
    },
    ['result'] = {
        ['do'] = function(g)
            g:getMap():blockExit('monastery-entrance') -- TODO: selectively block one side
        end
    }
}

s14['kath'] = {
    ['ids'] = {'abelon', 'kath'},
    ['events'] = {
        face(1, 2),
        say(2, 3, false,
            "It's getting to be evening... We've been apart from Lester nearly an entire day. How did he \z
             get so far ahead of us? The sheer irresponsibility of it..."
        )
    },
    ['result'] = {}
}

s14['elaine'] = {
    ['ids'] = {'abelon', 'elaine', 'shanti'},
    ['events'] = {
        lookAt(1, 2),
        lookAt(2, 3),
        say(2, 1, false,
            "Miss Shanti, um... How did you cast such amazing spells? Can you teach me?"
        )
    },
    ['result'] = {}
}

s14['shanti'] = {
    ['ids'] = {'abelon', 'shanti'},
    ['events'] = {
        lookAt(1, 2),
        say(2, 1, false,
            "But then, if that's true... yes, fascinating..."
        )
    },
    ['result'] = {}
}

s14['battle'] = {
    ['ids'] = {'abelon', 'kath', 'elaine', 'shanti', 'lester', 'wolf1', 'wolf2', 'wolf3', 'golem1', 'golem2'},
    ['events'] = {
        changeMusic('Threat-Revealed'),
        teleport(5, 41, 1, 'monastery-approach'),
        lookDir(5, LEFT),
        focus(5, 340),
        wait(1),
        walk(false, 1, 39, 14, 'walk'),
        walk(false, 5, 41, 5, 'walk1'),
        waitForEvent('walk1'),
        pan(0, -20, 170),
        wait(1),
        teleport(9, 38.6875, 1, 'monastery-approach'),
        lookDir(9, RIGHT),
        teleport(10, 42.6875, 1, 'monastery-approach'),
        lookDir(10, LEFT),
        walk(false, 9, 38.6875, 2.1875, 'walk1'),
        walk(false, 10, 42.6875, 2.1875, 'walk2'),
        waitForEvent('walk2'),
        wait(1),
        say(5, 2, false,
            "Damn things don't give up... What the hell did I do..."
        ),
        say(5, 2, false,
            "Gotta... Get away... Find Kath..."
        ),
        walk(false, 5, 41, 8, 'walk1'),
        waitForEvent('walk1'),
        wait(1),
        lookDir(6, RIGHT),
        teleport(6, 36, 10, 'monastery-approach'),
        wait(1),
        lookDir(7, LEFT),
        teleport(7, 44, 11, 'monastery-approach'),
        walk(false, 7, 41, 11, 'walk4'),
        wait(1),
        lookDir(8, LEFT),
        teleport(8, 45, 10, 'monastery-approach'),
        wait(1),
        say(5, 2, false,
            "Oh, for fuck's sake."
        ),
        lookDir(1, RIGHT),
        lookDir(2, RIGHT),
        lookDir(3, LEFT),
        lookDir(4, LEFT),
        teleport(2, 40, 14, 'monastery-approach'),
        teleport(3, 41, 14, 'monastery-approach'),
        teleport(4, 42, 13, 'monastery-approach'),
        pan(0, 50, 170),
        combatReady(1),
        combatReady(2),
        combatReady(3),
        combatReady(4),
        say(2, 3, false,
            "Lester!"
        ),
        introduce('lester'),
        say(5, 3, false,
            "Ah... About time."
        ),
        say(5, 3, false,
            "Kath... The entrance to the monastery is up ahead. I saw it. Then these... things came after me."
        ),
        wait(1),
        say(5, 3, false,
            "I'm spent. You handle the rest."
        ),
        wait(1),
        putOut(5),
        wait(0.5),
        say(2, 3, false,
            "Everyone, take up positions around Lester! Don't let the monsters get to him, he's injured!"
        ),
        walk(false, 2, 40, 12, 'walk'),
        waitForEvent('walk'),
        wait(0.5)
    },
    ['result'] = {
        ['do'] = function(g)
            lester = g.sprites['lester']
            g.player:joinParty(lester)
            g.current_scene = nil
            g.battle = Battle:new(g.player, g)
            g.battle.status['lester']['effects'] = {
                Effect:new(Buff:new('unconscious', 0, DEBUFF), math.huge),
                Effect:new(Buff:new('noheal', 0, DEBUFF), math.huge)
            }
            g.sprites['golem1'].health = 10
            g.sprites['golem2'].health = 20
            lester.health = 1
            lester:changeBehavior('down')
            g:saveBattle()
            g.battle:openBattleStartMenu()
        end
    }
}

local subscene_demonic = {
    focus(2, 170),
    face(2, 1),
    say(2, 3, true, 
        "By Ignus, what the hell did you just do, Abelon? I've never seen such \z
         unbelievable magic!"
    ),
    choice({
        {
            ["guard"] = function(g) return true end,
            ["response"] = "You haven't?",
            ['events'] = {
                say(2, 1, false,
                    "No, I haven't, in all the countless battles I've fought by your side. \z
                     You aren't really trying to tell me you've been conjuring hellfire all \z
                     this time and I just wasn't paying attention!"
                )
            },
            ['result'] = {
                ['awareness'] = {0, 1}
            }
        },
        {
            ["guard"] = function(g) return true end,
            ["response"] = "A useful spell I recently learned",
            ['events'] = {
                wait(1),
                say(2, 2, false,
                    "...You have a habit of understating things somewhat."
                )
            },
            ['result'] = {

            }
        }
    }),
    wait(0.5),
    say(2, 1, false, 
        "Well, I insist you teach me that incantation when we return to town."
    ),
    say(2, 1, false,
        "Oh, but don't waste your entire supply of Ignea on a mere few wolves. \z
         I expect we'll face many more battles before we return to Ebonach, and \z
         I can tell that was no cheap cantrip."
    )
}

s14['demonic-spell'] = {
    ['ids'] = {'abelon', 'kath'},
    ['events'] = {
        insertEvents(subscene_demonic)
    },
    ['result'] = {
        ['state'] = 'kath-saw-spell'
    }
}

local subscene_kath_defeat = {
    focus(2, 170),
    wait(0.5),
    say(2, 2, false,
        "Urgh. Damn, hurts........ But I refuse... to........"
    )
}

s14['kath-defeat'] = {
    ['ids'] = {'abelon', 'kath'},
    ['events'] = {
        insertEvents(subscene_kath_defeat)
    },
    ['result'] = {

    }
}

local subscene_abelon_defeat = {
    focus(2, 170),
    wait(0.5),
    lookAt(2, 1),
    say(2, 2, false,
        "Abelon, no! NO!"
    )
}

s14['abelon-defeat'] = {
    ['ids'] = {'abelon', 'kath'},
    ['events'] = {
        insertEvents(subscene_abelon_defeat)
    },
    ['result'] = {

    }
}

s14['elaine-defeat'] = {
    ['ids'] = {'abelon', 'elaine', 'kath'},
    ['events'] = {
        focus(3, 170),
        wait(0.5),
        lookAt(3, 2),
        say(2, 2, false,
            "Ahhh!"
        ),
        say(3, 2, false,
            "Elaine, no! Curses!"
        )
    },
    ['result'] = {

    }
}

s14['shanti-defeat'] = {
    ['ids'] = {'abelon', 'kath', 'shanti'},
    ['events'] = {
        focus(3, 170),
        wait(0.5),
        say(3, 3, false,
            "Tch..."
        ),
        lookAt(2, 3),
        say(2, 2, false,
            "Shanti? Hey, Shanti, answer me! Oh no..."
        )
    },
    ['result'] = {

    }
}

s14['lester-defeat'] = {
    ['ids'] = {'abelon', 'kath', 'lester'},
    ['events'] = {
        focus(3, 170),
        wait(0.5),
        lookAt(2, 3),
        say(2, 2, false,
            "No, Lester! Not you!"
        )
    },
    ['result'] = {

    }
}

s14['ally-turn-1'] = {
    ['ids'] = {'kath', 'shanti'},
    ['events'] = {
        focus(1, 170),
        say(1, 3, false,
            "We need to get close enough to Lester to check his wounds. They could be fatal... I can heal him \z
             with a spell, but not without knowing what his injuries are."
        ),
        focus(2, 170),
        say(2, 3, false,
            "Respectfully, Captain Kath, we may have our hands full just defending him."
        ),
        focus(1, 170),
        say(1, 3, false,
            "Maybe so, but there's no use defending a corpse. Abelon, give the order."
        )
    },
    ['result'] = {}
}

subscene_kath_request = {
    focus(2, 170),
    say(2, 3, false,
        "Everyone, if we buy enough space, I can heal him. We can't have him on death's door like this in the middle of \z
         a melee."
    ),
    focus(4, 170),
    say(4, 2, false,
        "That's exactly what makes this difficult, Captain Kath. We need your lance to keep the monsters away from \z
         Lester in the first place."
    ),
    say(4, 3, false,
        "You said it yourself. He'll make it through the battle just fine. We can heal him once we're out of danger."
    ),
    focus(2, 170),
    say(2, 2, false,
        "Ach, I know, I just... If there's an opening. If you see an opening, Abelon, give me the order."
    )
}

s14['check_Lester-kath'] = {
    ['ids'] = {'abelon', 'kath', 'elaine', 'shanti'},
    ['events'] = {
        focus(2, 170),
        say(2, 3, false,
            "Hang in there, Lester... Let's see... Burns all over, and a sliced up shoulder... Urgent, but not dire. \z
             And well within my capabilities."
        ),
        say(2, 1, false,
            "You're in quite the state, you damn fool, but you'll live. With my help, that is."
        ),
        insertEvents(subscene_kath_request)
    },
    ['result'] = {
        ['state'] = 'lester-checked',
        ['do'] = function(g)
            local stat = g.battle.status['lester']
            for i=1, #stat['effects'] do
                if stat['effects'][i].buff.attr == 'noheal' then
                    table.remove(stat['effects'], i)
                    break
                end
            end
        end
    }
}

s14['check_Lester-abelon'] = {
    ['ids'] = {'abelon', 'kath', 'elaine', 'shanti'},
    ['events'] = {
        focus(2, 170),
        say(2, 3, true,
            "Well, Abelon?"
        ),
        focus(1, 170),
        choice({
            {
                ["guard"] = function(g) return true end,
                ["response"] = "His left shoulder is slashed",
                ['events'] = {
                },
                ['result'] = {
                }
            },
            {
                ["guard"] = function(g) return true end,
                ["response"] = "His body is badly burnt",
                ['events'] = {
                },
                ['result'] = {
    
                }
            }
        }),
        focus(2, 170),
        say(2, 1, false,
            "Urgent, but not dire, then... I appreciate the help, Abelon. I know you'd rather swing a sword than \z
             play nurse for Lester."
        ),
        insertEvents(subscene_kath_request)
    },
    ['result'] = {
        ['state'] = 'lester-checked',
        ['do'] = function(g)
            local stat = g.battle.status['lester']
            for i=1, #stat['effects'] do
                if stat['effects'][i].buff.attr == 'noheal' then
                    table.remove(stat['effects'], i)
                    break
                end
            end
        end
    }
}

s14['check_Lester-shanti'] = {
    ['ids'] = {'abelon', 'kath', 'elaine', 'shanti'},
    ['events'] = {
        focus(2, 170),
        say(2, 3, false,
            "What does it look like, Shanti? Concisely."
        ),
        focus(4, 170),
        say(4, 3, false,
            "He's badly burned. From the ignaeic golems, I wager. They were summoning explosive shockwaves."
        ),
        say(4, 3, false,
            "And he's bleeding out from... a very large open wound on his left shoulder. He's lucky to still have his arm."
        ),
        focus(2, 170),
        say(2, 3, false,
            "Urgent, but not dire, by the sound of it... Thank you, Shanti."
        ),
        insertEvents(subscene_kath_request)
    },
    ['result'] = {
        ['state'] = 'lester-checked',
        ['do'] = function(g)
            local stat = g.battle.status['lester']
            for i=1, #stat['effects'] do
                if stat['effects'][i].buff.attr == 'noheal' then
                    table.remove(stat['effects'], i)
                    break
                end
            end
        end
    }
}

s14['check_Lester-elaine'] = {
    ['ids'] = {'abelon', 'kath', 'elaine', 'shanti'},
    ['events'] = {
        focus(2, 170),
        say(2, 3, false,
            "Well, Elaine? How is he faring? Can you tell me where he's wounded?"
        ),
        focus(3, 170),
        say(3, 2, false,
            "Um... His skin is covered in burns..."
        ),
        say(2, 3, false,
            "From the explosions of those stone golems, no doubt. Nothing I can't handle."
        ),
        say(3, 2, false,
            "His shoulder... Oh, goddess, that's a big one..."
        ),
        say(2, 3, false,
            "A gash? Which shoulder? Shouldn't be too hard to stitch up."
        ),
        say(3, 3, false,
            "The... The left. Also, he has a big scar on his face."
        ),
        say(2, 1, false,
            "Oh, that's an old one. You can ask him about it sometime... Right. \z
             Urgent injuries, but not dire, it seems. Thank you, Elaine."
        ),
        insertEvents(subscene_kath_request)
    },
    ['result'] = {
        ['state'] = 'lester-checked',
        ['do'] = function(g)
            local stat = g.battle.status['lester']
            for i=1, #stat['effects'] do
                if stat['effects'][i].buff.attr == 'noheal' then
                    table.remove(stat['effects'], i)
                    break
                end
            end
        end
    }
}

s14['lester-healed'] = {
    ['ids'] = {'kath', 'lester', 'shanti', 'abelon'},
    ['events'] = {
        focus(2, 170),
        say(2, 2, false,
            "Urghhh..."
        ),
        say(1, 1, false,
            "Lester!"
        ),
        say(2, 3, false,
            "Kath... Huh, I'm in a lot less pain than I expected. Thanks for the healing, as usual. \z
             You already took care of the monsters?"
        ),
        say(1, 2, false,
            "Work in progress, I'm afraid. But it's good to see you conscious."
        ),
        say(2, 3, false,
            "What the hell are you doing healing me, then? Making sure I'm awake for the moment a wolf \z
             bites my head off? You've always had your priorities all screwed up."
        ),
        say(1, 3, false,
            "A lecture in priorities, from the knight who disobeyed his superiors and broke rank, not once, but \z
             twice today I'm told! May wonders never cease."
        ),
        say(2, 3, false,
            "Shut up. I found the damn monastery. I'd do it again, over sitting around listening to Shanti ramble \z
             about Ignea..."
        ),
        say(3, 3, false,
            "Hey!"
        ),
        say(1, 2, false,
            "You would have died if we had not arrived to rescue you at this exact moment."
        ),
        say(2, 3, false,
            "Yeah, probably. But you showed up. You always do."
        ),
        say(1, 1, false,
            "Thank Abelon. He gave the order to heal you."
        ),
        say(2, 3, false,
            "Yeah, good one."
        ),
        say(1, 1, false,
            "He did."
        ),
        say(2, 3, false,
            "Bullshit."
        ),
        say(1, 1, false,
            "It's true."
        ),
        say(2, 3, false,
            "What gives? The old bastard would sooner wait for the wolves to eat me... Unless he \z
             wanted to get me up and fighting again."
        ),
        focus(4, 170),
        say(2, 3, false,
            "Sorry to disappoint you, old man, but I still can't feel my shoulder! \z
             Can't swing a dagger, can't hardly stand up... I'm sitting this one out."
        ),
        focus(1, 170),
        say(1, 1, false,
            "Then sit back and watch. Maybe you'll learn a thing or two. Bladework, sorcery, discipline... \z
             So many areas with room for improvement."
        ),
        say(2, 3, false,
            "Fuck off."
        ),
        say(1, 1, false,
            "Ha ha!"
        )
    },
    ['result'] = {
        ['state'] = 'lester-healed',
        ['do'] = function(g)
            local stat = g.battle.status['lester']
            for i=1, #stat['effects'] do
                if stat['effects'][i].buff.attr == 'unconscious' then
                    stat['effects'][i] = Effect:new(Buff:new('stun', 0, DEBUFF), math.huge)
                    break
                end
            end
            g.sprites['lester']:gainExp(90)
        end
    }
}

s14['victory'] = {
    ['ids'] = {'abelon', 'kath', 'elaine', 'shanti', 'lester', 'wolf1', 'wolf2', 'wolf3', 'golem1', 'golem2'},
    ['events'] = {
        focus(1, 170),
        walk(true, 6, 40, 1, 'walk'),
        walk(true, 7, 41, 1, 'walk'),
        walk(true, 8, 42, 1, 'walk'),
        teleport(9, 1, 1, 'waiting-room'),
        teleport(10, 1, 1, 'waiting-room'),
        wait(2),
        focus(2, 170),
        say(2, 2, false,
            "They're... what are they doing?"
        ),
        wait(1),
        say(2, 2, false,
            "Why did the wolves suddenly lose interest in us? I've never seen that before."
        ),
        say(2, 3, false,
            "...Well I can't say I'm not grateful... I was about at my limit. Let's see to Lester."
        ),
        combatExit(1),
        combatExit(2),
        br(function(g) return g.state['elaine-stays'] end, {
            combatExit(3)
        }),
        combatExit(4),
        wait(1),
        teleport(6, 1, 1, 'waiting-room'),
        teleport(7, 1, 1, 'waiting-room'),
        teleport(8, 1, 1, 'waiting-room'),
        light(6),
        light(7),
        light(8),
        wait(0.5)
    },
    ['result'] = {

    }
}

s14['lester'] = {
    ['ids'] = {'abelon', 'lester'},
    ['events'] = {
        lookAt(1, 2),
        say(2, 1, false,
            "Urghh..."
        )
    },
    ['result'] = {}
}