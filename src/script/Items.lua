require 'src.script.Util'

sitems = {}

sitems['journal-use'] = {
    ['ids'] = {'abelon', 'journal'},
    ['events'] = {
        say(2, 1, true, 
            "You remove the small, leather-bound book from your pack."
        ),
        choice({
            {
                ["guard"] = function(g) return true end,
                ["response"] = "Read it",
                ['events'] = {
                    say(2, 1, false, 
                        "You remove the leather binding and attempt to read the journal, but \z
                         it will not open. There must be something else sealing it shut."
                    )
                },
                ['result'] = {

                }
            },
            {
                ["guard"] = function(g) return true end,
                ["response"] = "Put it away",
                ['events'] = {

                },
                ['result'] = {

                }
            }
        })
    },
    ['result'] = {

    }
}

sitems['scroll-use'] = {
    ['ids'] = {'abelon', 'scroll'},
    ['events'] = {
        say(2, 1, false, 
            "The ancient scroll is dense with information, but none of it is \z
             intelligible to you. You aren't sure how you might use it at the moment."
        )
    },
    ['result'] = {

    }
}

sitems['scroll-present-kath-callback'] = {
    ['ids'] = {'abelon', 'kath'},
    ['events'] = {
        say(2, 1, false, 
            "Don't you think you ought to keep that thing in your pack? It looks \z
             fragile enough to fall to pieces under the wind and sun."
        )
    },
    ['result'] = {

    }
}

sitems['scroll-present-kath'] = {
    ['ids'] = {'abelon', 'kath'},
    ['events'] = {
        say(2, 1, false, 
            "That's King Sinclair's ritual scroll, isn't it? The whole reason \z
             we're on this damn expedition... I must say, the thing's been nothing but a \z
             disappointment so far."
        ),
        say(2, 1, false, 
            "All that talk about 'heralding doom when the seal is broken', only \z
             for it to unfurl without so much as a fart after His Majesty took it from \z
             the vault!"
        ),
        say(2, 3, false, 
            "Why have you taken it out? Did you forget the instructions? The \z
             ritual site will be in a holy monastery along the road through the Red \z
             Mountain Valley."
        ),
        say(2, 2, false, 
            "Never mind that no one has even heard of this monastery. And it'll be \z
             little more than monster-infested ruins by now, if the rumors are true about \z
             the scroll's age."
        ),
        say(2, 3, false,
            "I've about had it with rituals and their strange prescriptions... But \z
             ach, orders are orders, so here we are."
        )
    },
    ['result'] = {
        ['callback'] = { 'scroll-present-kath-callback', true }
    }
}

sitems['medallion-use'] = {
    ['ids'] = {'abelon', 'medallion'},
    ['events'] = {
        say(2, 1, false, 
            "The medallion turns lazily as you hold it by the rope. You pull it \z
             over your head. The fraying rope itches the back of your neck, and the \z
             metal lump weighs on you like armor."
        ),
        say(2, 1, false, 
            "Who would wear this? You put it away."
        )
    },
    ['result'] = {

    }
}

sitems['medallion-present-kath-callback'] = {
    ['ids'] = {'abelon', 'kath'},
    ['events'] = {
        face(1, 2),
        say(2, 2, false, 
            "A medallion that isn't either of ours... We're the only ones who have \z
             come out here recently, right?"
        )
    },
    ['result'] = {

    }
}

sitems['medallion-present-kath'] = {
    ['ids'] = {'abelon', 'kath'},
    ['events'] = {
        face(1, 2),
        say(2, 3, false, 
            "A strung medallion? Now where have I seen that engraving before... \z
             Oh!"
        ),
        say(2, 1, false, 
            "It looks a lot like a piece one of my younger knights was fiddling with! \z
             I think he was borrowing time at the blacksmith's forge to work on it."
        ),
        say(2, 1, false, 
            "For a little encouragement, I told him to show it to me when he was \z
             finished with it, but he gave me this crestfallen look, and I never heard about \z
             it again from him."
        ),
        say(2, 1, false, 
            "It looks the same as it did then, so I suppose he never got around \z
             to..."
        ),
        wait(1.5),
        say(2, 2, true, 
            "...Ach. It was already finished, wasn't it?"
        ),
        choice({
            {
                ["guard"] = function(g) return true end,
                ["response"] = "Nice going",
                ['events'] = {
                    say(2, 1, false, 
                        "Oops. Ha ha."
                    )
                },
                ['result'] = {

                }
            },
            {
                ["guard"] = function(g) return true end,
                ["response"] = "I'd have said the same, the metalwork is awful",
                ['events'] = {
                    say(2, 1, false, 
                        "Poor kid. I wonder what he was intending to do with it."
                    )
                },
                ['result'] = {

                }
            }
        }),
        say(2, 2, false, 
            "More importantly, what would it be doing all the way out here? I know \z
             it's not yours, and I certainly didn't bring it..."
        )
    },
    ['result'] = {
        ['callback'] = { 'medallion-present-kath-callback', true }
    }
}

sitems['medallion-present-elaine'] = {
    ['ids'] = {'abelon', 'elaine'},
    ['events'] = {
        face(1, 2),
        say(2, 1, true, 
            "Hey, that's mine! Oh, I thought it was lost for good! Sir Abelon, did \z
             you find it on the ground somewhere? May I have it?"
        ),
        choice({
            {
                ["guard"] = function(g) return true end,
                ["response"] = "Certainly",
                ['events'] = {
                    say(2, 1, false, 
                        "Thank you! I know it probably doesn't look like much. But it's \z
                         important to me. It was a gift."
                    )
                },
                ['result'] = {
                    ['impressions'] = {0, 2},
                    ['do'] = function(g)
                        g.player:discard('medallion')
                    end
                }
            },
            {
                ["guard"] = function(g) return true end,
                ["response"] = "You wear this? It looks uncomfortable",
                ['events'] = {
                    say(2, 1, true, 
                        "Ah... yes, it's not very comfortable to wear. Or convenient. But it's \z
                         important to me. It was a gift. May I have it back?"
                    ),
                    choice({
                        {
                            ["guard"] = function(g) return true end,
                            ["response"] = "Certainly",
                            ['events'] = {

                            },
                            ['result'] = {
                                ['impressions'] = {0, 2}
                            }
                        },
                        {
                            ["guard"] = function(g) return true end,
                            ["response"] = "Well, I've no use for it",
                            ['events'] = {

                            },
                            ['result'] = {
                                ['impressions'] = {0, 1}
                            }
                        }
                    }),
                    say(2, 1, false, 
                        "Thank you!"
                    )
                },
                ['result'] = {
                    ['do'] = function(g)
                        g.player:discard('medallion')
                    end
                }
            }
        })
    },
    ['result'] = {

    }
}

sitems['igneashard-use'] = {
    ['ids'] = {'abelon', 'igneashard'},
    ['events'] = {
        say(2, 1, true, 
            "Activate the ignea shard and regain 3 Ignea? You can also present it \z
             to an ally to restore their ignea."
        ),
        choice({
            {
                ["guard"] = function(g) return true end,
                ["response"] = "Yes",
                ['events'] = {
                    say(2, 1, false, 
                        "You grip the red stone tightly and focus your energy. It begins to \z
                         glow softly. You add the activated shard to your supply."
                    )
                },
                ['result'] = {
                    ['do'] = function(g)
                        g.player:discard('igneashard')
                        local p = g.player.sp
                        p.ignea = math.min(p.ignea + 3, p.attributes['focus'])
                    end
                }
            },
            {
                ["guard"] = function(g) return true end,
                ["response"] = "No",
                ['events'] = {

                },
                ['result'] = {

                }
            }
        })
    },
    ['result'] = {

    }
}

sitems['igneashard-present-kath'] = {
    ['ids'] = {'abelon', 'kath'},
    ['events'] = {
        face(1, 2),
        say(2, 1, true, 
            "I see you happened on some natural Ignea! That's good news for all of \z
             us. Every little stone helps... hold on, are you offering it to me?"
        ),
        choice({
            {
                ["guard"] = function(g) return true end,
                ["response"] = "Yes",
                ['events'] = {
                    say(2, 1, false, 
                        "You must have enough for yourself, then. Well, I'll gladly take it. \z
                         And as ever, I'll make sure your trust in me is well-placed."
                    )
                },
                ['result'] = {
                    ['do'] = function(g)
                        g.player:discard('igneashard')
                        local k = g:getSprite('kath')
                        k.ignea = math.min(k.ignea + 3, k.attributes['focus'])
                    end
                }
            },
            {
                ["guard"] = function(g) return true end,
                ["response"] = "No",
                ['events'] = {
                    say(2, 1, false, 
                        "Ah. Sorry for getting ahead of myself. You'll make better use of it, \z
                         in any case."
                    )
                },
                ['result'] = {

                }
            }
        })
    },
    ['result'] = {

    }
}

sitems['igneashard-present-elaine'] = {
    ['ids'] = {'abelon', 'elaine'},
    ['events'] = {
        face(1, 2),
        say(2, 1, false, 
            "That's... Ignea, isn't it, Sir Abelon? This is the first time I've \z
             ever needed to use it in a real fight. It's a beautiful stone..."
        ),
        say(2, 1, true, 
            "Oh, but, I do know how to cast spells! I think. They taught us at the \z
             academy. So if you did share some Ignea with me, I could put it to use... \z
             Um... Are you sharing it?"
        ),
        choice({
            {
                ["guard"] = function(g) return true end,
                ["response"] = "Yes",
                ['events'] = {
                    say(2, 1, false, 
                        "Thank you, Sir Abelon! I won't let it go to waste, I promise! I \z
                         already have some ideas for spells."
                    )
                },
                ['result'] = {
                    ['impressions'] = {0, 1},
                    ['do'] = function(g)
                        g.player:discard('igneashard')
                        local e = g:getSprite('elaine')
                        e.ignea = math.min(e.ignea + 3, e.attributes['focus'])
                    end
                }
            },
            {
                ["guard"] = function(g) return true end,
                ["response"] = "No",
                ['events'] = {
                    say(2, 2, false, 
                        "Oh... well, that's only right, isn't it. I'm the least experienced \z
                         person here, and there's only so much magic to go around..."
                    )
                },
                ['result'] = {

                }
            }
        })
    },
    ['result'] = {

    }
}