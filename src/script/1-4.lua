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
            g:launchBattle()
            -- TODO: lower health of golems and lester, incapacitate lester
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

s14['turnlimit-defeat'] = {
    ['ids'] = {'abelon', 'kath'},
    ['events'] = {
        focus(2, 170),
        wait(0.5),
        lookAt(1, 2),
        say(2, 2, false, 
            "At this rate, Lester isn't going to make it..."
        )
    },
    ['result'] = {

    }
}

s14['victory'] = {
    ['ids'] = {'abelon', 'kath', 'elaine', 'shanti', 'lester'},
    ['events'] = {
        focus(1, 170),
        combatExit(1),
        combatExit(2),
        br(function(g) return g.state['elaine-stays'] end, {
            combatExit(3)
        }),
        combatExit(4),
        wait(1.5)
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