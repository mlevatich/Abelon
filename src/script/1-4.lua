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
            g:getMap():blockExit('me3')
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
        walk(false, 1, 39, 13, 'walk'),
        walk(false, 5, 41, 5, 'walk1'),
        waitForEvent('walk1'),
        pan(0, -30, 170),
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
            g.sprites['golem1'].health = 15
            g.sprites['golem2'].health = 40
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

s14['ally-turn-2'] = {
    ['ids'] = {'kath', 'elaine'},
    ['events'] = {
        br(function(g) return g.state['elaine-stays'] end, {
            focus(2, 170),
            say(2, 3, false,
                "Those stone monsters look like they're already hurt."
            ),
            say(1, 1, false,
                "Yes. I imagine Lester must have given them quite a fight before deciding to run. His pride \z
                 tends to get him into trouble..."
            ),
            say(2, 2, false,
                "By himself? But those things... They..."
            ),
            say(1, 1, false,
                "They're extremely powerful. But so is Lester. He's one of my knights, after all."
            ),
            say(1, 1, false,
                "You could say the most obnoxious thing about him is that he isn't all talk... However much \z
                 he loves to talk."
            ),
            say(2, 3, false,
                "One knight can do that? That's incredible..."
            )
        })
    },
    ['result'] = {}
}

s14['ally-turn-4'] = {
    ['ids'] = {'kath', 'wolf4', 'wolf5', 'wolf6', 'wolf7'},
    ['events'] = {
        lookDir(2, RIGHT),
        lookDir(3, RIGHT),
        lookDir(4, RIGHT),
        lookDir(5, RIGHT),
        teleport(2, 35, 6, 'monastery-approach'),
        focus(2, 170),
        wait(0.5),
        teleport(3, 35, 7, 'monastery-approach'),
        focus(3, 170),
        wait(0.5),
        teleport(4, 35, 8, 'monastery-approach'),
        focus(4, 170),
        wait(0.5),
        teleport(5, 35, 9, 'monastery-approach'),
        focus(5, 170),
        wait(0.5),
        focus(1, 170),
        say(1, 2, false,
            "Ach, even more wolves? I thought for sure we were clear of them..."
        )
    },
    ['result'] = {
        ['do'] = function(g)
            g.battle:joinBattle(g.sprites['wolf4'], ENEMY, 1, 4, 1)
            g.battle:joinBattle(g.sprites['wolf5'], ENEMY, 1, 5, 1)
            g.battle:joinBattle(g.sprites['wolf6'], ENEMY, 1, 6, 1)
            g.battle:joinBattle(g.sprites['wolf7'], ENEMY, 1, 7, 1)
        end
    }
}

s14['ally-turn-6'] = {
    ['ids'] = {'kath', 'wolf8', 'alphawolf1', 'wolf10', 'wolf11'},
    ['events'] = {
        lookDir(2, RIGHT),
        lookDir(3, RIGHT),
        lookDir(4, LEFT),
        lookDir(5, LEFT),
        teleport(2, 39, 15, 'monastery-approach'),
        focus(2, 170),
        wait(0.5),
        teleport(3, 40, 15, 'monastery-approach'),
        focus(3, 170),
        wait(0.5),
        teleport(4, 41, 15, 'monastery-approach'),
        focus(4, 170),
        wait(0.5),
        teleport(5, 42, 15, 'monastery-approach'),
        focus(5, 170),
        wait(0.5),
        focus(1, 170),
        say(1, 2, false,
            "Even more? I've never known a wolf pack to grow this large. Something's not right..."
        )
    },
    ['result'] = {
        ['do'] = function(g)
            g.battle:joinBattle(g.sprites['alphawolf1'], ENEMY, 6, 13, 1)
            g.battle:joinBattle(g.sprites['wolf8'], ENEMY, 5, 13, 1)
            g.battle:joinBattle(g.sprites['wolf10'], ENEMY, 7, 13, 1)
            g.battle:joinBattle(g.sprites['wolf11'], ENEMY, 8, 13, 1)
        end
    }
}

s14['ally-turn-8'] = {
    ['ids'] = {'kath', 'wolf12', 'alphawolf3', 'wolf14', 'alphawolf2'},
    ['events'] = {
        lookDir(2, LEFT),
        lookDir(3, LEFT),
        lookDir(4, LEFT),
        lookDir(5, LEFT),
        teleport(2, 46, 6, 'monastery-approach'),
        focus(2, 170),
        wait(0.5),
        teleport(3, 46, 7, 'monastery-approach'),
        focus(3, 170),
        wait(0.5),
        teleport(4, 46, 8, 'monastery-approach'),
        focus(4, 170),
        wait(0.5),
        teleport(5, 46, 9, 'monastery-approach'),
        focus(5, 170),
        wait(0.5),
        focus(1, 170),
        say(1, 3, false,
            "Wolf packs stay out of each others' territory. Normally. Something is gathering them here... \z
             Could it be there is some force controlling the wolves?"
        ),
        say(1, 2, false,
            "Whatever the reason, we'll be overrun soon. Is it bad luck? Are we caught in the middle of something?"
        )
    },
    ['result'] = {
        ['do'] = function(g)
            g.battle:joinBattle(g.sprites['alphawolf2'], ENEMY, 12, 7, 1)
            g.battle:joinBattle(g.sprites['wolf14'], ENEMY, 12, 6, 1)
            g.battle:joinBattle(g.sprites['alphawolf3'], ENEMY, 12, 5, 1)
            g.battle:joinBattle(g.sprites['wolf12'], ENEMY, 12, 4, 1)
        end
    }
}

s14['ally-turn-9'] = {
    ['ids'] = {'kath', 'wolf16', 'wolf17', 'wolf18', 'wolf19'},
    ['events'] = {
        lookDir(2, RIGHT),
        lookDir(3, RIGHT),
        lookDir(4, LEFT),
        lookDir(5, LEFT),
        teleport(2, 37, 4, 'monastery-approach'),
        focus(2, 170),
        wait(0.5),
        teleport(3, 36, 5, 'monastery-approach'),
        focus(3, 170),
        wait(0.5),
        teleport(4, 46, 4, 'monastery-approach'),
        focus(4, 170),
        wait(0.5),
        teleport(5, 46, 5, 'monastery-approach'),
        focus(5, 170),
        wait(0.5)
    },
    ['result'] = {
        ['do'] = function(g)
            g.battle:joinBattle(g.sprites['wolf16'], ENEMY, 3, 2, 1)
            g.battle:joinBattle(g.sprites['wolf17'], ENEMY, 2, 3, 1)
            g.battle:joinBattle(g.sprites['wolf18'], ENEMY, 12, 2, 1)
            g.battle:joinBattle(g.sprites['wolf19'], ENEMY, 12, 3, 1)
        end
    }
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
                    stat['effects'][i] = Effect:new(Buff:new('injured', 0, DEBUFF), math.huge)
                    break
                end
            end
            g.sprites['lester']:gainExp(90)
        end
    }
}

s14['victory'] = {
    ['ids'] = {
        'abelon', 'kath', 'elaine', 'shanti', 'lester', 'wolf1', 'wolf2', 'wolf3', 'golem1', 'golem2',
        'wolf4', 'wolf5', 'wolf6', 'wolf7', 'wolf8', 'alphawolf1', 'wolf10', 'wolf11', 'wolf12', 'alphawolf3', 'wolf14',
        'alphawolf2', 'wolf16', 'wolf17', 'wolf18', 'wolf19'
    },
    ['events'] = {
        focus(1, 170),
        walk(true, 6, 40, 1, 'walk'),
        walk(true, 7, 41, 1, 'walk'),
        walk(true, 8, 42, 1, 'walk'),
        teleport(9, 1, 1, 'waiting-room'),
        teleport(10, 1, 1, 'waiting-room'),
        walk(true, 11, 40, 1, 'walk'),
        walk(true, 12, 41, 1, 'walk'),
        walk(true, 13, 42, 1, 'walk'),
        walk(true, 14, 40, 1, 'walk'),
        walk(true, 15, 41, 1, 'walk'),
        walk(true, 16, 42, 1, 'walk'),
        walk(true, 17, 40, 1, 'walk'),
        walk(true, 18, 41, 1, 'walk'),
        walk(true, 19, 42, 1, 'walk'),
        walk(true, 20, 40, 1, 'walk'),
        walk(true, 21, 41, 1, 'walk'),
        walk(true, 22, 42, 1, 'walk'),
        walk(true, 23, 40, 1, 'walk'),
        walk(true, 24, 41, 1, 'walk'),
        walk(true, 25, 42, 1, 'walk'),
        walk(true, 26, 40, 1, 'walk'),
        wait(2),
        focus(5, 170),
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
        teleport(11, 1, 1, 'waiting-room'),
        teleport(12, 1, 1, 'waiting-room'),
        teleport(13, 1, 1, 'waiting-room'),
        teleport(14, 1, 1, 'waiting-room'),
        teleport(15, 1, 1, 'waiting-room'),
        teleport(16, 1, 1, 'waiting-room'),
        teleport(17, 1, 1, 'waiting-room'),
        teleport(18, 1, 1, 'waiting-room'),
        teleport(19, 1, 1, 'waiting-room'),
        teleport(20, 1, 1, 'waiting-room'),
        teleport(21, 1, 1, 'waiting-room'),
        teleport(22, 1, 1, 'waiting-room'),
        teleport(23, 1, 1, 'waiting-room'),
        teleport(24, 1, 1, 'waiting-room'),
        teleport(25, 1, 1, 'waiting-room'),
        teleport(26, 1, 1, 'waiting-room'),
        light(6),
        light(7),
        light(8),
        light(11),
        light(12),
        light(13),
        light(14),
        light(15),
        light(16),
        light(17),
        light(18),
        light(19),
        light(20),
        light(21),
        light(22),
        light(23),
        light(24),
        light(25),
        light(26),
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

s14['final-battle'] = {
    ['ids'] = {'abelon', 'kath', 'elaine', 'shanti', 'lester', 'golem1', 'golem2', 'golem3'},
    ['events'] = {
        focus(1, 170),
        pan(0, -400, 340),
        changeMusic('Threat-Revealed'),
        -- TODO: party comes in, has a long discussion, chillin out while Shanti works.
        teleport(2, 1, 1, 'monastery-entrance'),
        br(function(g) return g.state['elaine-stays'] end, {
            teleport(3, 1, 1, 'monastery-entrance'),
            combatReady(3)
        }),
        teleport(4, 1, 1, 'monastery-entrance'),
        teleport(5, 1, 1, 'monastery-entrance'),
        combatReady(1),
        combatReady(2),
        combatReady(4),
        combatReady(5),
        wait(1.5)
    },
    ['result'] = {
        ['do'] = function(g)
            g.current_scene = nil
            g.battle = Battle:new(g.player, g, 'final-battle')
            g.battle.status['shanti']['effects'] = {
                Effect:new(Buff:new('busy', 0, DEBUFF), math.huge)
            }
            g:saveBattle()
            g.battle:openBattleStartMenu()
        end
    }
}

s14['final-battle-demonic-spell'] = {
    ['ids'] = {'abelon', 'kath'},
    ['events'] = {
        insertEvents(subscene_demonic)
    },
    ['result'] = {
        ['state'] = 'kath-saw-spell'
    }
}

s14['final-battle-kath-defeat'] = {
    ['ids'] = {'abelon', 'kath'},
    ['events'] = {
        insertEvents(subscene_kath_defeat)
    },
    ['result'] = {

    }
}

s14['final-battle-abelon-defeat'] = {
    ['ids'] = {'abelon', 'kath'},
    ['events'] = {
        insertEvents(subscene_abelon_defeat)
    },
    ['result'] = {

    }
}

s14['final-battle-elaine-defeat'] = {
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

s14['final-battle-shanti-defeat'] = {
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

s14['final-battle-lester-defeat'] = {
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

s14['final-battle-turnlimit-defeat'] = {
    ['ids'] = {'abelon', 'kath'},
    ['events'] = {
        focus(2, 170),
        wait(0.5),
        say(2, 2, false,
            "We aren't going to make it!"
        )
    },
    ['result'] = {

    }
}

s14['final-battle-abelon-escape'] = {
    ['ids'] = {'abelon'},
    ['events'] = {
        focus(1, 170),
        lookDir(1, LEFT),
        wait(0.5),
        unlockCamera(),
        teleport(1, 1, 1, 'monastery-entrance')
    },
    ['result'] = {}
}

s14['final-battle-kath-escape'] = {
    ['ids'] = {'kath'},
    ['events'] = {
        focus(1, 170),
        say(1, 2, false,
            "By Ignus, the creature earns its name. Those eyes..."
        ),
        say(1, 3, false,
            "...We'll have to lay low underground for some time. Goddess grant the ritual site is somewhere \z
             inside."
        ),
        wait(0.5),
        unlockCamera(),
        teleport(1, 1, 1, 'waiting-room')
    },
    ['result'] = {}
}

s14['final-battle-elaine-escape'] = {
    ['ids'] = {'elaine'},
    ['events'] = {
        focus(1, 170),
        say(1, 2, false,
            "Oh Goddess, I made it! I'm alive! I'm alive..."
        ),
        wait(0.5),
        unlockCamera(),
        teleport(1, 1, 1, 'waiting-room')
    },
    ['result'] = {}
}

s14['final-battle-shanti-escape'] = {
    ['ids'] = {'shanti'},
    ['events'] = {
        focus(1, 170),
        say(1, 3, false,
            "The magical golems, the ignaeic wards shielding the monastery... It's all so... Deliberate."
        ),
        say(1, 3, false,
            "Who are you? The ghost of some phenomenal sorcerer, desperate to bury your secrets?"
        ),
        say(1, 1, false,
            "Well, I'm as desperate to unearth them. Let us see if we're evenly matched."
        ),
        wait(0.5),
        unlockCamera(),
        teleport(1, 1, 1, 'waiting-room')
    },
    ['result'] = {}
}

s14['final-battle-lester-escape'] = {
    ['ids'] = {'lester'},
    ['events'] = {
        focus(1, 170),
        say(1, 3, false,
            "Kath, you bastard, why did you have to pick me for this expedition? We're all going to die \z
             in this valley..."
        ),
        say(1, 3, false,
            "But if it comes to that, I won't live my last moments taking orders from Sinclair's dog. \z
             I'll take him down with me, if I have to. The old man has it coming..."
        ),
        wait(0.5),
        unlockCamera(),
        teleport(1, 1, 1, 'waiting-room')
    },
    ['result'] = {}
}

s14['final-battle-ally-turn-4'] = {
    ['ids'] = {'abelon', 'kath', 'elaine', 'shanti', 'lester', 'terror1', 'wolf3', 'wolf4'},
    ['events'] = {
        teleport(6, 35.625, 33.1875, 'monastery-entrance'),
        teleport(7, 35, 34, 'monastery-entrance'),
        lookDir(7, RIGHT),
        teleport(8, 37, 34, 'monastery-entrance'),
        lookDir(8, LEFT)
    },
    ['result'] = {
        ['do'] = function(g)
            g.battle:joinBattle(g.sprites['terror1'], ENEMY, 6, 15, 1)
            g.battle:joinBattle(g.sprites['wolf3'], ENEMY, 5, 15, 1)
            g.battle:joinBattle(g.sprites['wolf4'], ENEMY, 7, 15, 1)
        end
    }
}

s14['final-battle-ally-turn-8'] = {
    ['ids'] = {
        'abelon', 'kath', 'elaine', 'shanti', 'lester',
        'terror2', 'terror3', 'golem4', 'golem5', 'golem6', 'golem7', 'golem8', 'golem9'
    },
    ['events'] = {
        teleport(6, 33.625, 33.1875, 'monastery-entrance'),
        lookDir(6, RIGHT),
        teleport(7, 37.625, 33.1875, 'monastery-entrance'),
        lookDir(7, LEFT),
        teleport(8, 29.6875 + 2, 18.1875 + 6, 'monastery-entrance'),
        teleport(9, 29.6875 + 2, 18.1875 + 4, 'monastery-entrance'),
        lookDir(8, RIGHT),
        lookDir(9, RIGHT),
        teleport(10, 29.6875 + 9, 18.1875 + 6, 'monastery-entrance'),
        teleport(11, 29.6875 + 9, 18.1875 + 4, 'monastery-entrance'),
        lookDir(10, LEFT),
        lookDir(11, LEFT),
        teleport(12, 29.6875 + 3, 18.1875 + 2, 'monastery-entrance'),
        teleport(13, 29.6875 + 8, 18.1875 + 2, 'monastery-entrance'),
        lookDir(12, RIGHT),
        lookDir(13, LEFT),
        focus(4, 170),
        say(4, 1, false,
            "Done!"
        ),
        say(2, 3, false,
            "Get to the basement!"
        )
    },
    ['result'] = {
        ['do'] = function(g)
            g.battle:joinBattle(g.sprites['terror2'], ENEMY, 4, 15, 1)
            g.battle:joinBattle(g.sprites['terror3'], ENEMY, 8, 15, 1)
            g.battle:joinBattle(g.sprites['golem4'], ENEMY, 2, 6, 1)
            g.battle:joinBattle(g.sprites['golem5'], ENEMY, 2, 4, 2)
            g.battle:joinBattle(g.sprites['golem6'], ENEMY, 9, 6, 1)
            g.battle:joinBattle(g.sprites['golem7'], ENEMY, 9, 4, 2)
            g.battle:joinBattle(g.sprites['golem8'], ENEMY, 3, 2, 1)
            g.battle:joinBattle(g.sprites['golem9'], ENEMY, 8, 2, 1)
            g.battle:addTiles({{ 1, 15 }, { 2, 15 }, { 3, 15 }, { 9, 15 }, { 10, 15 }})
            g.battle:addTiles({
                { 3, 1 }, { 4, 1 }, { 5, 1 }, { 6, 1 }, { 7, 1 }, { 8, 1 },
                { 2, 2 }, { 3, 2 }, { 4, 2 }, { 5, 2 }, { 6, 2 }, { 7, 2 }, { 8, 2 }, { 9, 2 },
                { 2, 3 }, { 3, 3 }, { 4, 3 }, { 5, 3 }, { 6, 3 }, { 7, 3 }, { 8, 3 }, { 9, 3 },
                { 2, 4 }, { 3, 4 }, { 4, 4 }, { 5, 4 }, { 6, 4 }, { 7, 4 }, { 8, 4 }, { 9, 4 },
                { 2, 5 }, { 3, 5 }, { 4, 5 }, { 5, 5 }, { 6, 5 }, { 7, 5 }, { 8, 5 }, { 9, 5 },
                { 2, 6 }, { 3, 6 }, { 4, 6 }, { 5, 6 }, { 6, 6 }, { 7, 6 }, { 8, 6 }, { 9, 6 }
            })
            local stat = g.battle.status['shanti']
            stat['acted'] = false
            for i=1, #stat['effects'] do
                if stat['effects'][i].buff.attr == 'busy' then
                    table.remove(stat['effects'], i)
                    break
                end
            end
        end
    }
}

s14['final-battle-victory'] = {
    ['ids'] = {'abelon'},
    ['events'] = {
        unlockCamera(),
        fade(-0.4),
        wait(3),
        fadeoutMusic(),
        wait(1),
        say(1, 0, false,
            "In spite of and because of your ignorance, this doomed expedition limps forward."
        ),
        wait(2),
        say(1, 0, false,
            "The monastery contains nothing of value, a truth you yourself must know."
        ),
        say(1, 0, false,
            "What is your aim, then? What is it you intend to show me?"
        ),
        wait(2),
        say(1, 0, false,
            "I was wrong about the girl. Astonishingly, she's nothing more than a lost idiot. \z
             It is a lucky stroke that she fights capably. Some idiots are useful."
        ),
        say(1, 0, false,
            "But I would not forsake the safety of my kingdom for a hundred such idiots. \z
             You seem to feel differently."
        ),
        wait(2),
        say(1, 0, false,
            "Yet it is irrelevant. Your hold weakens by the hour. Shortly, I will end this expedition."
        ),
        say(1, 0, false,
            "Though I have suffered you this insult, I will make one thing clear."
        ),
        wait(2),
        say(1, 0, false,
            "You are not Abelon."
        ),
        wait(2)
    },
    ['result'] = {
        ['do'] = function(g)
            g.signal = END_GAME
        end
    }
}