require 'src.script.Util'

s12 = {}



s12['battle'] = {
    ['ids'] = {'abelon', 'kath', 'bigwolf', 'smallwolf1', 'smallwolf2'},
    ['events'] = {
        lookAt(2, 1),
        focus(2, 200),
        pan(-200, 0, 100),
        waitForEvent('camera'),
        say(2, 3, false,
            "Abelon! At last!"
        ),
        lookAt(1, 2),
        walk(true, 2, 29, 15, 'walk'),
        focus(1, 50),
        say(2, 3, false,
            "By Ignus, what are you doing out here? The knights are pinned at \z
             the north gate, to the man, and suddenly you disappear! Come, we \z
             must return to the fight."
        ),
        say(2, 3, false,
            "Without our steel, the beasts might finally break through to the \z
            gilded district... ach, we'd all be in for it then."
        ),
        waitForEvent('walk'),
        wait(0.3),
        say(2, 2, false,
            "Wait, your arm. You're wounded. Let me see that."
        ),
        walkTo(false, 2, 1, RIGHT, 'walk'),
        waitForEvent('walk'),
        lookAt(2, 1),
        wait(1),
        walk(false, 2, 28, 15, 'walk'),
        waitForEvent('walk'),
        lookAt(2, 1),
        teleport(3, 41, 11),
        teleport(4, 42, 15),
        teleport(5, 40, 14),
        lookAt(3, 1),
        lookAt(4, 1),
        lookAt(5, 1),
        say(2, 3, true,
            "I'll have none of your usual protests about bandages and such, \z
             that sword arm of yours is well worth my ignea. Did one of the \z
             wolves follow you here? Did you kill it?"
        ),
        choice({
            {
                ['response'] = "Who are you?",
                ['events'] = {
                    say(2, 2, false,
                        "...What? Please tell me this is a jest, Abelon..."
                    ),
                    say(2, 3, false,
                        "Whatever's happened to you here, it's of less \z
                         importance than the battle at the gate. Come, we \z
                         must reinforce our soldiers immediately!"
                    )
                },
                ['result'] = {
                    ['awareness'] = {0, 2}
                }
            },
            {
                ['response'] = "No, I'm alone",
                ['events'] = {
                    say(2, 2, false,
                        "You're..."
                    ),
                    wait(0.2),
                    lookDir(2, RIGHT),
                    wait(0.5),
                    lookDir(2, LEFT),
                    wait(1),
                    say(2, 2, true,
                        "Well, what got your arm then? Hold on, what's all \z
                         that behind you?"
                    ),
                    choice({
                        {
                            ['response'] = "A ritual",
                            ['events'] = {
                                say(2, 2, false,
                                    "That sign in the earth is your work, \z
                                     then? Which explains your arm, but... a \z
                                     blood rite, Abelon?"
                                ),
                                say(2, 3, false,
                                    "I've only ever heard of them in \z
                                     stories... The kinds of stories that \z
                                     don't end well."
                                ),
                                say(2, 3, false,
                                    "Whatever you've done, I dearly hope it \z
                                     will help us live to see daylight."
                                ),
                                say(2, 3, false,
                                    "We've wasted too much time talking \z
                                     already. If you're not in danger here, \z
                                     we need to reinforce our soldiers, \z
                                     immediately. Come on!"
                                )
                            },
                            ['result'] = {
                                ['state'] = "mentioned-blood-rite"
                            }
                        },
                        {
                            ['response'] = "I don't know",
                            ['events'] = {
                                say(2, 3, false,
                                    "Hm, well I don't remember seeing it when \z
                                     I was last on salvage to the Ash... but \z
                                     it's a curiosity for another time."
                                ),
                                say(2, 3, false,
                                    "If you're not in danger here, we need to \z
                                     reinforce our soldiers, immediately. \z
                                     Come on!"
                                )
                            },
                            ['result'] = {
                                ['awareness'] = {0, 1}
                            }
                        }
                    })
                },
                ['result'] = {}
            }
        }),
        walk(true, 2, 33, 15, 'walk'),
        waitForEvent('walk'),
        wait(0.5),
        say(2, 2, true,
            "Ah. They must have followed me here. I'm sorry, Abelon."
        ),
        waitForText(),
        wait(0.5),
        focus(2, 100),
        pan(100, -50, 100),
        wait(1),
        walk(false, 1, 32, 14, 'walk'),
        waitForEvent('camera'),
        waitForEvent('walk'),
        choice({
            {
                ['response'] = "Nothing we can't handle",
                ['events'] = {
                    say(2, 1, false,
                        "Now there's the grizzled old knight I remember! You \z
                         had me worried for a moment. Let's finish them off \z
                         quickly so we can reach the knights!"
                    )
                },
                ['result'] = {
                    ['impressions'] = {0, 1}
                }
            },
            {
                ['response'] = "You shouldn't have come, then",
                ['events'] = {
                    say(2, 3, false,
                        "Well, a word of warning before running off might \z
                         have accomplished as much! I suppose if I had \z
                         vanished in the middle of a battle,"
                    ),
                    say(2, 3, false,
                        "you wouldn't have spared me a second thought, then. \z
                         Cold and calculating to the last, our veteran \z
                         captain is..."
                    ),
                    say(2, 3, false,
                        "Let's finish these beasts off quickly, so we can \z
                         reach the knights."
                    )
                },
                ['result'] = {
                    ['impressions'] = {0, -2}
                }
            }
        })
    },
    ['result'] = {
        ['do'] = function(g)
            local kath = g.sprites['kath']
            g.player:joinParty(kath)
            g:launchBattle()
        end
    }
}
s12['select-kath'] = {
    ['ids'] = {'kath'},
    ['events'] = {
        focus(1, 170),
        introduce("kath"),
        say(1, 1, false,
            "Captain Kath of Ebonach, at your command!"
        )
    },
    ['result'] = {}
}
s12['ally-turn-1'] = {
    ['ids'] = {'kath'},
    ['events'] = {
        focus(1, 170),
        say(1, 1, false,
            "Right, let's do the usual song and dance, then. The young \z
             upstart will take his orders from the grumpy \z
             old man."
        )
    },
    ['result'] = {}
}
s12['ally-turn-2'] = {
    ['ids'] = {'kath'},
    ['events'] = {
        brState('kath-saw-spell', {}, {
            focus(1, 170),
            say(1, 3, false,
                "Let's only use as much ignea as we need to. I shouldn't have \z
                 to remind you, we've nowhere to reignite here in the forest, \z
                 and we'll need as much power as we can spare when we return \z
                 to the gates."
            )
        })
    },
    ['result'] = {}
}
s12['enemy-turn-1'] = {
    ['ids'] = {'kath'},
    ['events'] = {
        focus(1, 170),
        say(1, 3, false,
            "Here they come!"
        )
    },
    ['result'] = {}
}
s12['abelon-demon'] = {
    ['ids'] = {'kath'},
    ['events'] = {
        brState('kath-saw-spell', {}, {
            focus(1, 170),
            say(1, 3, true,
                "By Ignus, what the hell did you just do, Abelon? I've \z
                 never seen such unbelievable magic!"
            ),
            choice({
                {
                    ['response'] = "A reward from the blood rite",
                    ['events'] = {
                        say(1, 1, false,
                            "Amazing... perhaps your little detour was worth \z
                             the trouble after all."
                        )
                    },
                    ['result'] = {
                        ['impressions'] = {1}
                    }
                },
                {
                    ['response'] = "A secret spell of mine",
                    ['events'] = {
                        say(1, 3, false,
                            "Oh really? I seem to recall a great many dire \z
                             situations which this 'secret spell' of yours \z
                             would have resolved in short order. But you've \z
                             never been one for sharing, have you..."
                        )
                    },
                    ['result'] = {
                        ['impressions'] = {-1}
                    }
                }
            }),
            say(1, 3, false,
                "Do save your ignea for our reunion with the knights, though. \z
                 I suspect we'll need that spell again when the real fight \z
                 begins, and even I can tell that unholy fire was no cheap \z
                 cantrip."
            )
        })
    },
    ['result'] = {
        ['state'] = 'kath-saw-spell'
    }
}
s12['kath-defeat'] = {
    ['ids'] = {'kath', 'abelon'},
    ['events'] = {
        focus(1, 170),
        wait(0.5),
        lookAt(2, 1),
        say(1, 2, false,
            "Urgh. Damn, hurts........ But I refuse... to........"
        )
    },
    ['result'] = {}
}
s12['abelon-defeat'] = {
    ['ids'] = {'kath', 'abelon'},
    ['events'] = {
        focus(1, 170),
        wait(0.5),
        lookAt(1, 2),
        say(1, 2, false,
            "Abelon, no! NO!"
        )
    },
    ['result'] = {}
}
s12['turnlimit-defeat'] = {
    ['ids'] = {'kath', 'abelon'},
    ['events'] = {
        focus(1, 170),
        wait(0.5),
        lookDir(1, RIGHT),
        lookAt(2, 1),
        say(1, 2, false,
            "Damn, we've lost too much time here already, we'll never \z
             make it to the north gate in time! It's all over..."
        )
    },
    ['result'] = {}
}
s12['victory'] = {
    ['ids'] = {'abelon', 'kath'},
    ['events'] = {
        wait(0.5),
        face(1, 2),
        focus(1, 100),
        say(2, 1, true,
            "*huff* *huff* Ach, they aren't so tough when it's just a \z
             couple of the bastards."
        ),
        walk(true, 2, 42, 12, 'walk'),
        waitForEvent('walk'),
        face(1, 2),
        walkTo(true, 1, 2, LEFT, 'walk'),
        choice({
            {
                ['response'] = "Nice bladework",
                ['events'] = {
                    say(2, 1, false,
                        "Why, a compliment? From you? I must have really \z
                         outdone myself this time, or else you took a \z
                         blow to the head."
                    )
                },
                ['result'] = {
                    ['awareness'] = {0, 1},
                    ['impressions'] = {0, 1}
                }
            },
            {
                ['response'] = "They didn't stand a chance",
                ['events'] = {
                    say(2, 3, false,
                        "No indeed, they didn't. I don't envy anyone or \z
                         anything at the wrong end of your sword."
                    )
                },
                ['result'] = {}
            }
        }),
        br(function(g)
            local abelon = g.sprites['abelon']
            return abelon.health == (abelon.attributes['endurance'] * 2)
        end, {
            say(2, 1, false,
                "And not a scratch on you! Your skills never fail to \z
                 impress, truly."
            )
        },
        {
            say(2, 3, false,
                "Let me see your wounds."
            )
        }),
        waitForEvent('walk'),
        face(1, 2),
        wait(1),
        focus(2, 100),
        say(2, 1, false,
            "Now then, thankfully you didn't wander off too far from the \z
             fighting. The north gate is just ahead to the east, first \z
             right turn on this path."
        ),
        say(2, 3, false,
            "We'll have to keep an eye out for more wolves - I'll follow \z
             behind you and watch our back."
        ),
        walk(true, 2, 43, 10, 'walk'),
        waitForEvent('walk'),
        lookDir(2, RIGHT),
        wait(0.5),
        say(2, 3, false,
            "But look here. This trail of blood came dribbling from that \z
             wolf's mouth... he must have gotten to something before he \z
             found us."
        ),
        say(2, 3, false,
            "It could be someone wounded and in need of help, but \z
             following it will lead us away from Ebonach and lose us \z
             time... damn!"
        ),
        focus(1, 100),
        waitForEvent('camera')
    },
    ['result'] = {
        ['do'] = function(g) g:healAll() end
    }
}



s12['kath'] = {
    ['ids'] = {'abelon', 'kath'},
    ['events'] = {
        face(1, 2),
        say(2, 2, false,
            "The decision's yours, Abelon. We don't have time to discuss. \z
             Ach, but if all of this blood does belong to a person, I'm \z
             certain abandoning them is as good as a death sentence..."
        )
    },
    ['result'] = {}
}