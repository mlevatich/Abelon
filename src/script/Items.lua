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



si['igneashard-use'] = {
    ['ids'] = {'igneashard'},
    ['events'] = {
        say(1, 1, true,
            "Activate the ignea shard and regain 3 Ignea?"
        ),
        choice({
            {
                ['response'] = "Yes",
                ['events'] = {
                    say(1, 1, false,
                        "You grip the red stone tightly and focus your energy. \z
                         It begins to glow softly. You add the activated shard \z
                         to your supply."
                    )
                },
                ['result'] = {
                    ['do'] = function(g)
                        local p = g.player.sp
                        g.player:discard('igneashard')
                        p.ignea = math.min(p.ignea + 3, p.attributes['focus'])
                    end
                }
            },
            {
                ['response'] = "No",
                ['events'] = {},
                ['result'] = {}
            }
        })
    },
    ['result'] = {}
}
si['igneashard-present-kath'] = {
    ['ids'] = {'abelon', 'kath'},
    ['events'] = {
        face(1, 2),
        say(2, 1, true,
            "I see you happened on some natural Ignea! That's good news for all \z
             of us. Every little stone helps... hold on, are you offering it to me?"
        ),
        choice({
            {
                ['response'] = "Yes",
                ['events'] = {
                    say(2, 1, false,
                        "You must have enough for yourself, then. Well, I'll gladly \z
                         take it. And as ever, I'll make sure your trust in me is well-placed."
                    )
                },
                ['result'] = {
                    ['do'] = function(g)
                        local k = g:getSprite('kath')
                        g.player:discard('igneashard')
                        k.ignea = math.min(k.ignea + 3, k.attributes['focus'])
                    end
                }
            },
            {
                ['response'] = "No",
                ['events'] = {
                    say(2, 1, false,
                        "Ah. Sorry for getting ahead of myself. You'll make better \z
                         use of it, in any case."
                    )
                },
                ['result'] = {}
            }
        })
    },
    ['result'] = {}
}
si['igneashard-present-elaine'] = {
    ['ids'] = {'abelon', 'elaine'},
    ['events'] = {
        face(1, 2),
        say(2, 3, false,
            "That's... Ignea, isn't it, Sir Abelon? This is the first time \z
             I've ever needed to use it in a real fight. It's a beautiful stone..."
        ),
        say(2, 3, true,
            "Oh, but, I do know how to cast spells! I think. They taught us \z
             at the academy. So if you did share some Ignea with me, I could \z
             put it to use... Um... Are you sharing it?"
        ),
        choice({
            {
                ['response'] = "Yes",
                ['events'] = {
                    say(2, 1, false,
                        "Thank you, Sir Abelon! I won't let it go to waste, I \z
                         promise! I already have some ideas for spells."
                    )
                },
                ['result'] = {
                    ['do'] = function(g)
                        local e = g:getSprite('elaine')
                        g.player:discard('igneashard')
                        e.ignea = math.min(e.ignea + 3, e.attributes['focus'])
                    end
                }
            },
            {
                ['response'] = "No",
                ['events'] = {
                    say(2, 2, false,
                        "Oh... well, that's only right, isn't it. I'm the least \z
                         experienced person here, and there's only so much magic \z
                         to go around..."
                    )
                },
                ['result'] = {}
            }
        })
    },
    ['result'] = {}
}