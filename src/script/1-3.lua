require 'src.script.Util'

s13 = {}

s13['entry'] = {
    ['ids'] = {'abelon'},
    ['events'] = {
        blackout(),
        teleport(1, 27, 77.5, 'monastery-approach'),
        focus(1, 10000),
        pan(0, -3000, 10000),
        daytime(),
        chaptercard(),
        changeMusic('Canopied-Steps'),
        wait(1),
        fade(0.2),
        focus(1, 300),
        wait(8),
    },
    ['result'] = {
        ['do'] = function(g)
            g:getMap():blockExit('west-forest')
        end
    }
}

s13['battle'] = {
    ['ids'] = {'abelon', 'kath', 'elaine', 'wolf1', 'wolf2', 'wolf3', 'alphawolf1', 'alphawolf2'},
    ['events'] = {
        fadeoutMusic(),
        focus(1, 200),
        walk(false, 1, 22, 45, 'walk'),
        pan(0, -100, 100),
        lookDir(2, RIGHT),
        lookDir(3, RIGHT),
        teleport(2, 17, 53),
        br(function(g) return g.state['elaine-stays'] end, {
            teleport(3, 17, 55)
        }),
        walk(false, 2, 21, 46, 'walk1'),
        br(function(g) return g.state['elaine-stays'] end, {
            walk(false, 3, 20, 46, 'walk2')
        }),
        waitForEvent('walk'),
        lookDir(1, LEFT),
        say(2, 1, false, 
            "Abelon, why have you stopped? Did something catch your attention? Wait a minute..."
        ),
        waitForText(),
        waitForEvent('walk1'),
        br(function(g) return g.state['elaine-stays'] end, {
            waitForEvent('walk2')
        }),
        wait(0.5),
        changeMusic('Threat-Revealed', 28),
        lookDir(4, LEFT),
        lookDir(5, RIGHT),
        lookDir(6, LEFT),
        lookDir(7, LEFT),
        lookDir(8, RIGHT),
        teleport(6, 23, 38),
        lookDir(1, RIGHT),
        lookDir(2, RIGHT),
        lookDir(3, RIGHT),
        wait(0.5),
        walk(false, 6, 23, 40, 'walk'),
        teleport(7, 24, 38),
        wait(0.5),
        walk(false, 7, 24, 40, 'walk'),
        waitForEvent('walk'),
        wait(0.5),
        teleport(4, 28, 43),
        wait(0.5),
        teleport(5, 15, 45),
        lookDir(1, LEFT),
        wait(0.1),
        lookDir(2, LEFT),
        wait(0.1),
        lookDir(3, LEFT),
        wait(0.3),
        walk(false, 5, 17, 45, 'walk'),
        waitForEvent('walk'),
        wait(0.5),
        teleport(8, 19, 40),
        wait(0.5),
        combatReady(1),
        wait(1),
        br(function(g) return g.state['elaine-stays'] end, {
            say(3, 2, false,
                "...Eep..."
            )
        }),
        walk(false, 2, 23, 44, 'walk'),
        say(2, 3, false, 
            "Ah. This must be the den of the wolf pack that's been after us. I suppose \z
             we'll have to do away with them now. Better they found us than Lester and Shanti."
        ),
        waitForEvent('walk'),
        combatReady(2),
        br(function(g) return g.state['elaine-stays'] end, {
            walk(false, 3, 24, 46, 'walk')
        }),
        wait(0.5),
        br(function(g) return g.state['elaine-stays'] end, {
            say(2, 3, false, 
                "Elaine, I expect it will be one battle after another for as long as \z
                 you're with us. Are you ready?"
            ),
            waitForEvent('walk'),
            walk(false, 3, 24, 45, 'walk'),
            say(3, 3, false,
                "Ready as I'll ever be..."
            ),
            waitForEvent('walk'),
            combatReady(3),
            wait(1)
        })
    },
    ['result'] = {
        ['do'] = function(g)
            g:launchBattle()
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

s13['demonic-spell'] = {
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
    lookAt(1, 2),
    say(2, 2, false,
        "Urgh. Damn, hurts........ But I refuse... to........"
    )
}

s13['kath-defeat'] = {
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

s13['abelon-defeat'] = {
    ['ids'] = {'abelon', 'kath'},
    ['events'] = {
        insertEvents(subscene_abelon_defeat)
    },
    ['result'] = {

    }
}

s13['elaine-defeat'] = {
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

local subscene_turnlimit_defeat = {
    focus(2, 170),
    wait(0.5),
    lookAt(1, 2),
    say(2, 2, false, 
        "We're losing daylight, and we've not even found the ruins we're \z
         looking for. And the longer we're out here, the more monsters will arrive... \z
         To say nothing of how Lester and Shanti fare..."
    ),
    say(2, 2, false,
        "...could it be this expedition has already failed?"
    )
}

s13['turnlimit-defeat'] = {
    ['ids'] = {'abelon', 'kath'},
    ['events'] = {
        insertEvents(subscene_turnlimit_defeat)
    },
    ['result'] = {

    }
}

s13['victory'] = {
    ['ids'] = {'abelon', 'kath', 'elaine'},
    ['events'] = {
        combatExit(1),
        combatExit(2),
        br(function(g) return g.state['elaine-stays'] end, {
            combatExit(3)
        }),
        wait(1)
    },
    ['result'] = {
        ['do'] = function(g)
            local k = g.sprites['kath']
            local a = g.sprites['abelon']
            local e = g.sprites['elaine']
            local seen = find(g.player.old_tutorials, "Experience and skill learning")
            if (k.level > 8 or a.level > 8 or e.level > 3) and not seen then
                g:startTutorial("Experience and skill learning")
            end
        end
    }
}

s13['kath'] = {
    ['ids'] = {'abelon', 'kath'},
    ['events'] = {
        face(1, 2),
        say(2, 3, false,
            "The further north we travel, the more maze-like this forest becomes... I'm \z
             not the superstitious type, but I can't shake the feeling that the Red Mountain \z
             Valley is trying to hide its secrets from us."
        )
    },
    ['result'] = {}
}

s13['elaine'] = {
    ['ids'] = {'abelon', 'elaine'},
    ['events'] = {
        lookAt(1, 2),
        say(2, 2, false,
            "No more monsters, no more monsters, no more monsters..."
        ),
        wait(1),
        lookAt(2, 1),
        say(2, 2, false,
            "Ah! Oh, Sir Abelon. Sorry, I was... lost in thought."
        ),
        say(2, 2, false,
            "...You didn't hear any of that, did you?"
        )
    },
    ['result'] = {}
}

s13['golem-battle'] = {
    ['ids'] = {'abelon', 'kath', 'elaine', 'shanti', 'golem1', 'golem2', 'golem3'},
    ['events'] = {
        changeMusic('Threat-Revealed'),
        focus(1, 200),
        walk(false, 1, 60, 31, 'walk'),
        pan(-150, -60, 100),
        wait(2),
        teleport(2, 71, 32),
        br(function(g) return g.state['elaine-stays'] end, {
            teleport(3, 72, 30)
        }),
        walk(false, 2, 60, 32, 'walk1'),
        br(function(g) return g.state['elaine-stays'] end, {
            walk(false, 3, 60, 30, 'walk2')
        }),
        wait(3),
        say(2, 1, false, 
            "Shanti!"
        ),
        introduce('shanti'),
        say(4, 1, false, 
            "Captain Kath. Captain Abelon."
        ),
        say(2, 3, false, 
            "What's going on here? What are those things?"
        ),
        say(4, 3, false, 
            "They suddenly attacked me. Help me fend them off, and I can explain."
        ),
        br(function(g) return not g.state['elaine-stays'] end, {
            waitForEvent('walk1')
        }),
        br(function(g) return g.state['elaine-stays'] end, {
            waitForEvent('walk2')
        }),
        combatReady(1),
        combatReady(2),
        combatReady(3),
        combatReady(4),
        wait(1.5)
    },
    ['result'] = {
        ['do'] = function(g)
            local shanti = g.sprites['shanti']
            g.player:joinParty(shanti)
            g:launchBattle('golem-battle')
        end
    }
}

s13['golem-battle-ally-turn-1'] = {
    ['ids'] = {'shanti'},
    ['events'] = {
        focus(1, 170),
        say(1, 2, false,
            "They caught me off guard by rising up from underground. In my haste, I dropped my pack. \z
             It has all of my ignea. I'll need help retrieving it."
        )
    },
    ['result'] = {}
}

s13['golem-battle-demonic-spell'] = {
    ['ids'] = {'abelon', 'kath'},
    ['events'] = {
        insertEvents(subscene_demonic)
    },
    ['result'] = {
        ['state'] = 'kath-saw-spell'
    }
}

s13['golem-battle-turnlimit-defeat'] = {
    ['ids'] = {'abelon', 'kath'},
    ['events'] = {
        insertEvents(subscene_turnlimit_defeat)
    },
    ['result'] = {

    }
}

s13['golem-battle-kath-defeat'] = {
    ['ids'] = {'abelon', 'kath'},
    ['events'] = {
        insertEvents(subscene_kath_defeat)
    },
    ['result'] = {

    }
}

s13['golem-battle-abelon-defeat'] = {
    ['ids'] = {'abelon', 'kath'},
    ['events'] = {
        insertEvents(subscene_abelon_defeat)
    },
    ['result'] = {

    }
}

s13['golem-battle-elaine-defeat'] = {
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

s13['golem-battle-shanti-defeat'] = {
    ['ids'] = {'abelon', 'kath', 'shanti'},
    ['events'] = {
        focus(3, 170),
        wait(0.5),
        lookAt(2, 3),
        say(3, 3, false,
            "Tch..."
        ),
        say(2, 2, false,
            "Shanti? Hey, Shanti, answer me! Oh no..."
        )
    },
    ['result'] = {

    }
}

s13['golem-battle-victory'] = {
    ['ids'] = {'abelon', 'kath', 'elaine', 'shanti'},
    ['events'] = {
        combatExit(1),
        combatExit(2),
        br(function(g) return g.state['elaine-stays'] end, {
            combatExit(3)
        }),
        combatExit(4),
        wait(1)
    },
    ['result'] = {}
}

s13['shanti'] = {
    ['ids'] = {'abelon', 'shanti'},
    ['events'] = {
        face(1, 2),
        say(2, 1, false,
            "It's good to see you, Captain Abelon."
        )
    },
    ['result'] = {}
}