require 'src.script.Util'

s11 = {}



s11['entry'] = {
    ['ids'] = {'abelon'},
    ['events'] = {
        blackout(),
        wait(1),
        chaptercard(),
        say(1, 0, false, "..."),
        say(1, 0, false, "............"),
        say(1, 0, false, "...Perhaps I made a mistake somewhere."),
        say(1, 0, false, ".................."),
        say(1, 0, false, "..!"),
        fade(0.2),
        wait(6)
    },
    ['result'] = {
        ['do'] = function(g)
            g:startTutorial("Navigating the world")
        end
    }
}



s11['close-tutorial-1'] = {
    ['ids'] = {},
    ['events'] = {},
    ['result'] = {
        ['do'] = function(g)
            g:endTutorial()
        end
    }
}



s11['battle'] = {
    ['ids'] = {'abelon', 'wolf1'},
    ['events'] = {
        lookAt(1, 2),
        focus(2, 100),
        pan(50, 0, 100),
        wait(0.5),
        walk(false, 1, 42, 11, 'walk'),
        waitForEvent('walk'),
        lookAt(1, 2),
        wait(1),
        lookAt(2, 1),
        wait(1),
        walk(false, 2, 39, 11, 'walk'),
        waitForEvent('walk'),
        wait(1)
    },
    ['result'] = {
        ['do'] = function(g)
            g:launchBattle()
        end
    }
}
s11['ally-turn-1'] = {
    ['ids'] = {},
    ['events'] = {},
    ['result'] = {
        ['do'] = function(g)
            g:startTutorial("Battle: The basics")
        end
    }
}
s11['close-tutorial2'] = {
    ['ids'] = {},
    ['events'] = {},
    ['result'] = {
        ['do'] = function(g)
            g:endTutorial()
        end
    }
}
s11['ally-turn-2'] = {
    ['ids'] = {},
    ['events'] = {},
    ['result'] = {
        ['do'] = function(g)
            g:startTutorial("Battle: Turns")
        end
    }
}
s11['close-tutorial3'] = {
    ['ids'] = {},
    ['events'] = {},
    ['result'] = {
        ['do'] = function(g)
            g:endTutorial()
        end
    }
}
s11['abelon-defeat'] = {
    ['ids'] = {},
    ['events'] = {},
    ['result'] = {}
}
s11['turnlimit-defeat'] = {
    ['ids'] = {},
    ['events'] = {},
    ['result'] = {}
}
s11['victory'] = {
    ['ids'] = {},
    ['events'] = {},
    ['result'] = {}
}



local medallion_choice = choice({
    {
        ['response'] = "Pick it up",
        ['events'] = {
            say(2, 1, false,
                "You brush the dirt off of the medallion and place it \z
                 in your pack."
            )
        },
        ['result'] = {
            ['do'] = function(g)
                local sp = g:getMap():dropSprite('medallion')
                g.player:acquire(sp)
            end
        }
    },
    {
        ['response'] = "Leave it",
        ['events'] = {},
        ['result'] = {}
    }
})
s11['medallion'] = {
    ['ids'] = {'abelon', 'medallion'},
    ['events'] = {
        lookAt(1, 2),
        introduce('medallion'),
        say(2, 1, true,
            "On the ground is a silver medallion, strung with a thin rope and \z
             smeared with dirt. The image of a round shield over a longsword is \z
             engraved in the metal."
        ),
        medallion_choice
    },
    ['result'] = {
        ['callback'] = { 'medallion-callback' }
    }
}
s11['medallion-callback'] = {
    ['ids'] = {'abelon', 'medallion'},
    ['events'] = {
        lookAt(1, 2),
        say(2, 1, true,
            "The medallion glimmers on the forest floor, reflecting faint moonlight."
        ),
        medallion_choice
    },
    ['result'] = {}
}



local elaine_choices_no_carry = {
    {
        ['response'] = "Shake her",
        ['events'] = {
            say(2, 0, false,
                "You shake the girl gently, but she does not stir."
            )
        },
        ['result'] = {}
    },
    {
        ['response'] = "Leave her",
        ['events'] = {},
        ['result'] = {}
    }
}
local elaine_choices_saw_camp = addChoice(elaine_choices_no_carry, {
    ['response'] = "Carry her to camp",
    ['events'] = {
        say(2, 0, true,
            "With effort, you hoist the limp girl and her belongings onto \z
                your back."
        )
    },
    ['result'] = {
        ['state'] = "carried-elaine",
        ['do'] = function(g)
            -- TODO: Teleport Abelon and Elaine to camp
        end
    }
})
local elaine_choices_no_camp = addChoice(elaine_choices_no_carry, {
    ['response'] = "Carry her",
    ['events'] = {
        say(2, 0, false,
            "With her equipment and bag, the girl is heavy and \z
             unwieldy to carry. You are not sure where you would \z
             take her to."
        )
    },
    ['result'] = {}
})
local elaine_choices = brState('saw-camp',
    { choice(elaine_choices_saw_camp) },
    { choice(elaine_choices_no_camp) }
)
s11['elaine'] = {
    ['ids'] = {'abelon', 'elaine'},
    ['events'] = {
        say(2, 0, true,
            "It's a young girl with fair skin and fiery hair, facedown on \z
             the ground. She wears the garb of a hunter, with a bow and \z
             quiver slung on her back. She has no visible injuries, but \z
             isn't moving."
        ),
        elaine_choices
    },
    ['result'] = {
        ['callback'] = { 'elaine-callback' }
    }
}
s11['elaine-callback'] = {
    ['ids'] = {'abelon', 'elaine'},
    ['events'] = {
        brState('carried-elaine',
            {
                say(2, 0, false,
                    "The girl lies on her side, taking shallow breaths. \z
                     She is unconscious, but alive."
                )
            },
            {
                say(2, 0, true,
                    "The young girl is still motionless."
                ),
                elaine_choices
            }
        )
    },
    ['result'] = {}
}



s11['book'] = {
    ['ids'] = {'abelon', 'book'},
    ['events'] = {
        lookAt(1, 2),
        introduce('book'),
        say(2, 0, false,
            "An open book lies on the ground, full of strange drawings and \z
             hastily scrawled paragraphs. The writing is faded and barely \z
             legible,"
        ),
        say(2, 0, false,
            "and the pages practically crumble to dust at the slightest touch."
        )
    },
    ['result'] = {
        ['callback'] = { 'book-callback' }
    }
}
s11['book-callback'] = {
    ['ids'] = {'abelon', 'book'},
    ['events'] = {
        lookAt(1, 2),
        say(2, 0, false,
            "On a second glance, it looks like there's another small book \z
             beneath the first."
        )
    },
    ['result'] = {}
}