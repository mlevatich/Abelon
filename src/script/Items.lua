require 'src.script.Util'

si = {}



si['scroll-use'] = {
    ['ids'] = {'scroll'},
    ['events'] = {
        say(1, 1, false,
            "You attempt to read the scroll, but quickly give up. The words are \z
             organized as though imparting a set of instructions, but the language \z
             is indecipherable."
        )
    },
    ['result'] = {}
}



si['journal-use'] = {
    ['ids'] = {'journal'},
    ['events'] = {
        say(1, 1, false,
            "You remove the leather binding and attempt to read the journal, but \z
             it will not open. There must be something else sealing it shut."
        )
    },
    ['result'] = {}
}



si['medallion-use'] = {
    ['ids'] = {'medallion'},
    ['events'] = {
        say(1, 1, false,
            "The medallion turns lazily as you hold it by the rope. \z
             You pull it over your head. The fraying rope itches the back \z
             of your neck, and the metal lump weighs on you like armor."
        ),
        say(1, 1, false,
            "Who would wear this? You put it away."
        )
    },
    ['result'] = {}
}
si['medallion-present-kath'] = {
    ['ids'] = {'abelon', 'kath'},
    ['events'] = {
        face(1, 2),
        walkTo(false, 1, 2, nil, 'walk'),
        say(2, 1, true,
            "Oh. I see you picked up that medallion from the ground. Is that \z
             yours?"
        ),
        waitForEvent('walk'),
        face(1, 2),
        choice({
            {
                ['response'] = 'No',
                ['events'] = {
                    say(2, 1, false,
                        "Ah, planning to return it to its rightful owner when \z
                         we're back in town, then? How unexpectedly \z
                         considerate of you."
                    )
                },
                ['result'] = {}
            },
            {
                ['response'] = 'Yes',
                ['events'] = {
                    say(2, 1, false,
                        "Well, how did it end up out here then? I've never \z
                         known you to be careless with your possessions."
                    )
                },
                ['result'] = {}
            }
        })
    },
    ['result'] = {
        ['callback'] = { 'medallion-present-kath-callback', true }
    }
}
si['medallion-present-kath-callback'] = {
    ['ids'] = {'abelon', 'kath'},
    ['events'] = {
        face(1, 2),
        say(2, 1, false,
            "You're quite enchanted by that thing, aren't you?"
        )
    },
    ['result'] = {}
}