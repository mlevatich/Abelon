require 'src.script.Util'

s12 = {}

subscene_before_wolves = {
    lookAt(2, 1),
    say(2, 3, false, 
        "Lester woke up early and announced he was heading towards the ruins \z
         to start looking for the ritual site. I told him it was idiotic to go \z
         alone, of course, but he wasn't having it."
    ),
    say(2, 2, true, 
        "More likely is he didn't want to linger around camp with you here. \z
         I'm sure you're aware he's not exactly fond of you."
    ),
    choice({
        {
            ["guard"] = function(g) return true end,
            ["response"] = "An understatement",
            ['events'] = {
                say(2, 1, true, 
                    "Well, I can only assure you it wasn't my influence. He may be a \z
                     knight under my command, but I didn't teach him to disrespect you."
                ),
                choice({
                    {
                        ["guard"] = function(g) return true end,
                        ["response"] = "Naturally",
                        ['events'] = {
                            wait(0.5),
                            say(2, 2, false,
                                "Naturally..."
                            )
                        },
                        ['result'] = {

                        }
                    },
                    {
                        ["guard"] = function(g) return true end,
                        ["response"] = "I appreciate it",
                        ['events'] = {
                            say(2, 2, false, 
                                "You appreciate that I... haven't been slandering you behind your \z
                                 back."
                            ),
                            wait(1),
                            say(2, 2, false,
                                "I suppose I shouldn't be surprised your standards are low for such \z
                                 things."
                            )
                        },
                        ['result'] = {
                            ['impressions'] = {0, 1}
                        }
                    },
                    {
                        ["guard"] = function(g) return true end,
                        ["response"] = "So you're an admirer of mine?",
                        ['events'] = {
                            say(2, 3, false,
                                "Ha."
                            )
                        },
                        ['result'] = {
                            ['awareness'] = {0, 1}
                        }
                    }
                })
            },
            ['result'] = {

            }
        },
        {
            ["guard"] = function(g) return true end,
            ["response"] = "Is he not?",
            ['events'] = {
                say(2, 2, false, 
                    "Are you... Was that a joke, old man? We've heard nothing but dour \z
                     muttering and veiled insults from him ever since he was assigned to this \z
                     expedition."
                ),
                say(2, 3, true, 
                    "One would think he'd be honored to have been chosen to join us. But \z
                     having to take orders from Captain Abelon has ruined it for him, I suppose."
                ),
                choice({
                    {
                        ["guard"] = function(g) return true end,
                        ["response"] = "You sound resentful",
                        ['events'] = {
                            say(2, 1, false, 
                                "Yes, that I have to listen to his complaining. But don't mistake me - \z
                                 he's served under me for years, and we've been friends for even longer. It \z
                                 would be more odd if he didn't annoy me time and again."
                            ),
                            say(2, 1, false,
                                "He's a peerless warrior. Present company excluded, of course. But I'm \z
                                 grateful to have him along."
                            )
                        },
                        ['result'] = {

                        }
                    },
                    {
                        ["guard"] = function(g) return true end,
                        ["response"] = "He should count himself lucky",
                        ['events'] = {
                            say(2, 3, false,
                                "Hm. Does a knight ever consider himself lucky to be given a task of \z
                                 unparalleled danger? There's no guarantee that this ritual works, or that we even \z
                                 return alive... But I digress."
                            )
                        },
                        ['result'] = {

                        }
                    }
                })
            },
            ['result'] = {
                ['awareness'] = {0, 1}
            }
        },
        {
            ["guard"] = function(g) return true end,
            ["response"] = "He has no right",
            ['events'] = {
                say(2, 2, true, 
                    "I couldn't disagree more, Abelon. History will judge whether His \z
                     Majesty made the right decision, but what it put Lester's family through... \z
                     no one should have to endure that."
                ),
                choice({
                    {
                        ["guard"] = function(g) return true end,
                        ["response"] = "Yet he became a knight",
                        ['events'] = {
                            say(2, 3, false,
                                "On the condition that he would serve under me, and not you, yes. And \z
                                 he rather quickly became my best warrior. But one does wonder why he \z
                                 would volunteer to directly serve the King, after all that happened."
                            )
                        },
                        ['result'] = {

                        }
                    },
                    {
                        ["guard"] = function(g) return true end,
                        ["response"] = "Many have endured worse",
                        ['events'] = {
                            say(2, 3, false,
                                "And so will affairs in the city continue, until the shroud of Despair \z
                                 is lifted from Ebonach and monsters plague us no more. On that, at \z
                                 least, we will always agree."
                            )
                        },
                        ['result'] = {

                        }
                    }
                })
            },
            ['result'] = {
                ['impressions'] = {1, 0}
            }
        },
        {
            ["guard"] = function(g) return true end,
            ["response"] = "I can hardly blame him",
            ['events'] = {
                wait(1),
                say(2, 2, true, 
                    "I'm... surprised to hear you say that. You've not once seemed \z
                     apologetic about the whole affair in the entire time I've known you."
                ),
                choice({
                    {
                        ["guard"] = function(g) return true end,
                        ["response"] = "I'm not, but I understand his anger",
                        ['events'] = {
                            say(2, 2, false,
                                "Yes, it was... awful. For everyone involved. I know His Majesty felt \z
                                 it was necessary but... ah, it's not the time nor place to dwell on it."
                            )
                        },
                        ['result'] = {

                        }
                    },
                    {
                        ["guard"] = function(g) return true end,
                        ["response"] = "It was a mistake",
                        ['events'] = {
                            wait(1),
                            say(2, 3, false, 
                                "..."
                            ),
                            wait(1),
                            say(2, 3, false,
                                "Do you... actually mean that? By the goddess, it's like you've woken \z
                                 up a different person. I don't believe it... and I wonder how Lester \z
                                 would react..."
                            )
                        },
                        ['result'] = {
                            ['state'] = 'abelon-mistake',
                            ['impressions'] = {-1, 0},
                            ['awareness'] = {0, 1}
                        }
                    }
                })
            },
            ['result'] = {
                ['awareness'] = {0, 1}
            }
        }
    })
}

s12['battle'] = {
    ['ids'] = {'abelon', 'kath', 'wolf1', 'wolf2', 'wolf3', 'wolf4'},
    ['events'] = {
        blackout(),
        daytime(),
        wait(1),
        chaptercard(),
        -- TODO: combatReady(2),
        say(2, 0, false, 
            "Abelon, wake up. Quickly."
        ),
        say(2, 0, false, 
            "And fetch your scabbard."
        ),
        wait(1),
        say(2, 0, false,
            "Abelon?"
        ),
        fade(0.2),
        wait(4),
        focus(2, 100),
        say(2, 3, true, 
            "Can you sense it? They're hanging back for now, watching us. But \z
             they'll attack soon enough."
        ),
        choice({
            {
                ["guard"] = function(g) return true end,
                ["response"] = "Yes",
                ['events'] = {

                },
                ['result'] = {

                }
            },
            {
                ["guard"] = function(g) return true end,
                ["response"] = "What?",
                ['events'] = {
                    say(2, 3, false,
                        "Wolves, Abelon. Hurry and shake off whatever dreams you were having, \z
                         and draw your sword."
                    )
                },
                ['result'] = {

                }
            }
        }),
        focus(1, 100),
        waitForEvent('camera'),
        walk(false, 1, 52, 9, 'walk'),
        waitForEvent('walk'),
        -- TODO: combatReady(1),
        say(2, 2, true, 
            "Ach, this is exactly what I was afraid would happen. Can't Lester \z
             ever just sit still? Blasted fool."
        ),
        choice({
            {
                ["guard"] = function(g) return true end,
                ["response"] = "Where are they?",
                ['events'] = {
                    insertEvents(subscene_before_wolves)
                },
                ['result'] = {

                }
            },
            {
                ["guard"] = function(g) return true end,
                ["response"] = "Who are you?",
                ['events'] = {
                    lookAt(2, 1),
                    say(2, 3, false,
                        "What? Goddess, Abelon, wake yourself up already! You aren't old \z
                         enough to be getting senile yet! Here, you were asleep, so I'll fill you in."
                    ),
                    insertEvents(subscene_before_wolves)
                },
                ['result'] = {
                    ['impressions'] = {-1, 0},
                    ['awareness'] = {0, 1}
                }
            }
        }),
        wait(1),
        br(function(g) return not g.state['carried-elaine'] end, {
            say(2, 3, false,
                "In any case, since there was no swaying him, I had Shanti go with \z
                 him. Better that we move in pairs, in the event that... something exactly \z
                 like this should happen."
            )
        }),
        br(function(g) return g.state['carried-elaine'] end, {
            say(2, 3, false, 
                "In any case, since there was no swaying him, I had Shanti go with \z
                 him. She was dreadfully curious about this child you brought back to camp, \z
                 of course, but we'll have to discuss further when we rejoin them."
            ),
            say(2, 3, false,
                "I've healed her internal injuries, but she hasn't yet woken up. I \z
                 must say, I'm terribly interested in who she is as well. And how you came \z
                 to bring her here..."
            )
        }),
        lookDir(1, RIGHT),
        lookDir(2, RIGHT),
        teleport(4, 62, 9),
        lookAt(4,1),
        focus(4, 200),
        pan(-150, 0, 200),
        walk(false, 4, 56, 9, 'walk'),
        waitForEvent('walk'),
        wait(0.5),
        lookDir(2, LEFT),
        lookDir(1, LEFT),
        teleport(3, 41, 8),
        lookAt(3,1),
        focus(3, 200),
        pan(150, 0, 200),
        walk(false, 3, 46, 8, 'walk'),
        waitForEvent('walk'),
        wait(0.5),
        teleport(5, 47, 15),
        teleport(6, 48, 16),
        lookAt(5,1),
        lookAt(6,1),
        focus(5, 200),
        pan(0, -50, 200),
        waitForEvent('camera'),
        wait(1),
        focus(1, 200),
        waitForEvent('camera'),
        say(2, 3, false,
            "Time enough for talking later. Here they come."
        )
    },
    ['result'] = {
        ['do'] = function(g)
            local kath = g.sprites['kath']
            g.player:joinParty(kath)
            g:launchBattle()
        end
    }
}

s12['ally-turn-1'] = {
    ['ids'] = {'abelon', 'kath'},
    ['events'] = {
        focus(2, 170),
        say(2, 1, false,
            "Right, we'll do the usual song and dance then. The young upstart will \z
             take his orders from the grumpy old man."
        )
    },
    ['result'] = {
        ['do'] = function(g)
            g:startTutorial("Battle: Assists")
        end
    }
}

s12['enemy-turn-1'] = {
    ['ids'] = {'abelon', 'kath'},
    ['events'] = {
        focus(2, 170),
        say(2, 3, false, 
            "Watch yourself, Abelon!"
        )
    },
    ['result'] = {

    }
}

s12['select-kath'] = {
    ['ids'] = {'abelon', 'kath'},
    ['events'] = {
        focus(2, 170),
        introduce("kath"),
        say(2, 1, false,
            "Captain Kath of Lefellen, at your command!"
        )
    },
    ['result'] = {

    }
}

s12['select-abelon'] = {
    ['ids'] = {'abelon', 'kath'},
    ['events'] = {
        say(2, 3, false, 
            "We ought to stay close if possible, so we can assist each other."
        ),
        say(2, 3, false,
            "We're surrounded, but we can't let them attack as a group... Best to \z
             strike quickly and finish off one of them to buy ourselves some space."
        )
    },
    ['result'] = {

    }
}

s12['close-tutorial-1'] = {
    ['ids'] = {},
    ['events'] = {},
    ['result'] = {
        ['do'] = function(g)
            g:endTutorial()
        end
    }
}

s12['ally-turn-2'] = {
    ['ids'] = {},
    ['events'] = {},
    ['result'] = {
        ['do'] = function(g)
            g:startTutorial("Battle: Ignea")
        end
    }
}

s12['close-tutorial-2'] = {
    ['ids'] = {},
    ['events'] = {},
    ['result'] = {
        ['do'] = function(g)
            g:endTutorial()
        end
    }
}

s12['close-tutorial-3'] = {
    ['ids'] = {},
    ['events'] = {},
    ['result'] = {
        ['do'] = function(g)
            g:endTutorial()
        end
    }
}

s12['ally-turn-4'] = {
    ['ids'] = {},
    ['events'] = {},
    ['result'] = {
        ['do'] = function(g)
            g:startTutorial("Battle: Reminder")
        end
    }
}

s12['close-tutorial-4'] = {
    ['ids'] = {},
    ['events'] = {},
    ['result'] = {
        ['do'] = function(g)
            g.current_tutorial = nil
        end
    }
}

subscene_kath_defeat = {
    focus(2, 170),
    wait(0.5),
    lookAt(1, 2),
    say(2, 2, false,
        "Urgh. Damn, hurts........ But I refuse... to........"
    )
}

s12['kath-defeat'] = {
    ['ids'] = {'abelon', 'kath'},
    ['events'] = {
        insertEvents(subscene_kath_defeat)
    },
    ['result'] = {

    }
}

subscene_abelon_defeat = {
    focus(2, 170),
    wait(0.5),
    lookAt(2, 1),
    say(1, 2, false,
        "Abelon, no! NO!"
    )
}

s12['abelon-defeat'] = {
    ['ids'] = {'abelon', 'kath'},
    ['events'] = {
        insertEvents(subscene_abelon_defeat)
    },
    ['result'] = {

    }
}

s12['elaine-defeat'] = {
    ['ids'] = {'abelon', 'elaine', 'kath'},
    ['events'] = {
        focus(3, 170),
        wait(0.5),
        lookAt(3, 2),
        say(2, 2, false, 
            "Ahhh!"
        ),
        say(3, 2, false,
            "Damnit, no! We couldn't protect her..."
        )
    },
    ['result'] = {

    }
}

subscene_turnlimit_defeat = {
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

s12['turnlimit-defeat'] = {
    ['ids'] = {'abelon', 'kath'},
    ['events'] = {
        insertEvents(subscene_turnlimit_defeat)
    },
    ['result'] = {

    }
}

subscene_demonic = {
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

s12['demonic-spell'] = {
    ['ids'] = {'abelon', 'kath'},
    ['events'] = {
        insertEvents(subscene_demonic)
    },
    ['result'] = {
        ['state'] = 'kath-saw-spell'
    }
}

s12['ally-turn-3'] = {
    ['ids'] = {'abelon', 'elaine', 'kath'},
    ['events'] = {
        br(function(g) return g.state['carried-elaine'] end, {
            focus(2, 170),
            waitForEvent('camera'),
            getUp(2),
            say(2, 3, false, 
                "Mmh..."
            ),
            lookAt(3, 2),
            focus(3, 200),
            pan(0, -70, 200),
            waitForEvent('camera'),
            wait(0.5),
            lookAt(1, 3),
            say(3, 3, false, 
                "About time she started coming to. Hm, I wonder..."
            ),
            focus(2, 200),
            pan(0, 70, 200),
            waitForEvent('camera'),
            lookDir(2, LEFT),
            wait(0.3),
            lookDir(2, RIGHT),
            wait(0.3),
            lookDir(2, LEFT),
            wait(0.3),
            say(2, 2, false, 
                "W-where am I? What's going on?"
            ),
            say(3, 3, false, 
                "Sensible questions, but we don't have time to answer them until we've \z
                 dealt with these wolves. What I want to know is, can you help?"
            ),
            walk(false, 2, 53, 5, 'walk'),
            lookAt(2, 3),
            say(2, 2, false, 
                "Help? W-what?"
            ),
            say(3, 3, false, 
                "You have a bow, and arrows. I assume you're familiar with how to use \z
                 them."
            ),
            wait(0.5),
            say(2, 2, true, 
                "Bow and... Oh Goddess, you want me to fight? I..."
            ),
            choice({
                {
                    ["guard"] = function(g) return true end,
                    ["response"] = "Your assistance would be welcome",
                    ['events'] = {

                    },
                    ['result'] = {
                        ['impressions'] = {0, 1, 0}
                    }
                },
                {
                    ["guard"] = function(g) return true end,
                    ["response"] = "We can't trust her",
                    ['events'] = {
                        lookAt(3, 1),
                        say(3, 3, false,
                            "What, you think she's our enemy? I have a hard time believing that, \z
                             given the state you brought her in. I would expect more competence from a \z
                             spy or traitor."
                        )
                    },
                    ['result'] = {
                        ['impressions'] = {1, 0, 0}
                    }
                },
                {
                    ["guard"] = function(g) return true end,
                    ["response"] = "Kath, she's a child",
                    ['events'] = {
                        lookAt(3, 1),
                        say(3, 3, false,
                            "And what are you, her mother? All three of us are in danger, and \z
                             child or not, she has a weapon."
                        )
                    },
                    ['result'] = {
                        ['impressions'] = {-1, 0, 0},
                        ['awareness'] = {0, 0, 1}
                    }
                },
                {
                    ["guard"] = function(g) return true end,
                    ["response"] = "...",
                    ['events'] = {

                    },
                    ['result'] = {

                    }
                }
            }),
            wait(0.5),
            lookAt(3, 2),
            say(3, 3, false, 
                "Miss, if you fight, we'll protect you."
            ),
            waitForText(),
            focus(2, 200),
            walk(false, 2, 52, 5, 'walk'),
            waitForEvent('walk'),
            say(2, 2, false, 
                "I've never shot a w-wolf before. They're... Goddess, they're \z
                 terrifying up close... But..."
            ),
            wait(1),
            walk(false, 2, 52, 7, 'walk'),
            say(2, 3, false, 
                "...Ok. I can help. I'm ready."
            ),
            waitForEvent('walk'),
            focus(3, 200),
            say(3, 1, false, 
                "Look at that, Abelon! She's only just woken up, but she has a \z
                 knight's courage. Lucky us. What's your name, miss?"
            ),
            introduce('Elaine'),
            say(2, 3, false, "...Elaine."),
            wait(0.5),
            say(2, 3, false, "Wait, 'Abelon'? You just called him Abelon-"),
            say(3, 3, false, 
                "Listen to me, Elaine. Shoot them while they're circling one of us, and go for \z
                 the kill, or you'll risk drawing their attention to you. We can parry \z
                 their fangs - you can't."
            ),
            focus(2, 200),
            waitForEvent('camera'),
            -- combatReady(2),
            say(2, 3, false,
                "R-right. Ok... Pretend it's a rabbit... Like shooting a rabbit... \z
                 Breathe deep..."
            )
        }),
        br(function(g) return not g.state['carried-elaine'] end, {
            getUp(2),
            teleport(2, 71, 10),
            lookDir(2, LEFT),
            lookDir(1, RIGHT),
            lookDir(3, RIGHT),
            focus(2, 340),
            walk(false, 2, 63, 10, 'walk'),
            waitForEvent('walk'),
            say(2, 2, false, 
                "I'm sure it was... this way... ...What? Are they... fighting? They \z
                 must be the ones..."
            ),
            pan(-260, -40, 340),
            waitForEvent('camera'),
            say(3, 3, true, 
                "What the- Abelon! There's a person! A young girl, do you see her? By \z
                 the Goddess, what is she doing out here?"
            ),
            choice({
                {
                    ["guard"] = function(g) return true end,
                    ["response"] = "I came across her last night",
                    ['events'] = {
                        face(3, 1),
                        say(3, 2, true, 
                            "You what? Abelon, we're two days out from town! Did you not think it \z
                             was worth stopping to help her, or at least waking up the camp to inform \z
                             us?"
                        ),
                        choice({
                            {
                                ["guard"] = function(g) return true end,
                                ["response"] = "I assumed she was dead",
                                ['events'] = {
                                    say(3, 2, false,
                                        "A reasonable assumption this far from Ebonach, but given that she \z
                                         clearly isn't a rotting corpse, you might've at least checked..."
                                    )
                                },
                                ['result'] = {

                                }
                            },
                            {
                                ["guard"] = function(g) return true end,
                                ["response"] = "The King's graces do not extend past the city limits",
                                ['events'] = {
                                    say(3, 2, false,
                                        "I understand she's in violation of the Kingdom's laws, but isn't it \z
                                         more important that she's alone and clearly in need of help? Honestly, \z
                                         Abelon, I'll never understand you..."
                                    )
                                },
                                ['result'] = {
                                    ['impressions'] = {1, 0, -1}
                                }
                            }
                        })
                    },
                    ['result'] = {
                        ['state'] = 'kath-knows-found-elaine',
                        ['awareness'] = {0, 0, 1}
                    }
                },
                {
                    ["guard"] = function(g) return true end,
                    ["response"] = "Kath. Eyes on the enemy",
                    ['events'] = {
                        face(3, 1),
                        say(3, 2, false,
                            "Yes, of course, I'm just... the last thing I expected to see was \z
                             another person this deep in the forest..."
                        )
                    },
                    ['result'] = {
                        ['impressions'] = {1, 0, 0}
                    }
                }
            }),
            wait(1),
            say(3, 3, false,
                "Ach, we'll deal with her after the wolves are dead. Hopefully she \z
                 doesn't draw any attention to herself."
            )
        })
    },
    ['result'] = {
        ['do'] = function(g)
            g:startTutorial("Battle: Attributes")
            if g.state['carried-elaine'] then
                local elaine = g.sprites['elaine']
                g.player:joinParty(elaine)
                g.battle:joinBattle(elaine, ALLY, 7, 1)
            end
        end
    }
}

subscene_dont_know = {
    say(2, 2, true, 
        "You... don't know? Abelon, you aren't making any sense. What's going \z
         on here? Are you feeling alright?"
    ),
    choice({
        {
            ["guard"] = function(g) return true end,
            ["response"] = "...",
            ['events'] = {

            },
            ['result'] = {

            }
        },
        {
            ["guard"] = function(g) return true end,
            ["response"] = "...",
            ['events'] = {

            },
            ['result'] = {

            }
        },
        {
            ["guard"] = function(g) return true end,
            ["response"] = "...",
            ['events'] = {

            },
            ['result'] = {

            }
        }
    }),
    say(2, 2, false, 
        "I don't like the look you're giving me... Fine, I'll drop it. You've \z
         made me party to enough of your secrets and half-truths in the past, and \z
         they've always been for good reason."
    ),
    say(2, 2, false, 
        "But as much as I'm not fond of witholding information from our knights \z
         or our people, it stings even worse to be the one kept in the dark."
    ),
    say(2, 2, false,
        "...Goddess grant that one day you and King Sinclair trust me to the \z
         extent you trust each other."
    )
}

subscene_question_time = {
    say(2, 3, false,
        "Well, now that she's safe with us, I believe some questions are in \z
         order."
    )
}

subscene_tactically = {
    say(2, 3, false,
        "Thinking tactically, as always."
    )
}

subscene_question_time2 = {
    say(2, 3, false,
        "...Sigh. At least she's here now. I expect she's exhausted, but I'm \z
         sure you'd agree, Abelon, that some questions are in order."
    )
}

subscene_bye_elaine = {
    say(2, 3, false, 
        "Let me get you some of our rations. And a compass. Come have a look \z
         at this map."
    ),
    -- Event: Elaine and Kath move over to the campsite,
    say(2, 3, false, 
        "We're here, where Shanti's drawn a little campfire. We've gone off the \z
         main Lefally road, but if you walk southeast, you'll find a number of \z
         fallen trees. From there, you should see the path we cut through the brush."
    ),
    say(2, 3, false, 
        "If you follow that path southwest, you'll reach the Lefally road by \z
         afternoon. It's a straight shot south on that road to the north gate of Ebonach."
    ),
    say(2, 1, false, 
        "Shout down the guards, they'll let you in. After all, it sounds like you \z
         have a rather close friend among them."
    ),
    say(3, 2, false, 
        "..."
    ),
    say(2, 1, false, 
        "...Just a little joke! Anyway, keep your eyes open for wolves. They'll \z
         stalk you before going in for the attack. But if you notice them watching you \z
         and get yourself up a tall tree, they won't be able to reach."
    ),
    say(3, 3, false, 
        "...Ok. What about other monsters?"
    ),
    say(2, 2, false, 
        "...Ah."
    ),
    say(2, 3, false, 
        "Pray you don't run into any."
    ),
    say(3, 2, false, 
        "..."
    ),
    say(2, 3, false, 
        "I wish I had better advice for you. If it's any consolation, our band \z
         of four has seen nothing but wolves so far. There aren't many... other \z
         monsters this close to the Lefally road. Try not to dwell on it."
    ),
    say(2, 3, false, 
        "Here, put these in your pack. Best that you start moving now, while \z
         it's still early."
    ),
    say(3, 2, false, 
        "...Right. I think I have everything I need."
    ),
    say(2, 1, true, 
        "In a couple of days, you'll be home safe and sound."
    ),
    choice({
        {
            ["guard"] = function(g) return true end,
            ["response"] = "Best of luck",
            ['events'] = {

            },
            ['result'] = {
                ['impressions'] = {0, 1, 0}
            }
        },
        {
            ["guard"] = function(g) return true end,
            ["response"] = "Get on with it",
            ['events'] = {

            },
            ['result'] = {
                ['impressions'] = {1, -1, 0}
            }
        }
    }),
    say(3, 2, false, 
        "Sir Kath... Thank you. Goodbye."
    ),
    -- Event: Elaine leaves to the east,
    say(2, 2, false, 
        "..."
    ),
    say(2, 3, false,
        "...Time for us to be moving on as well."
    )
}

subscene_elaine_goes_home = {
    say(2, 2, false, 
        "...I see. I can't say I see your point of view, but if Elaine herself \z
         isn't sure, I'll defer to your judgement. Beyond the city walls, following \z
         your orders has saved me more than once, whether or not I agree with them."
    ),
    say(2, 3, false,
        "But Elaine, I won't let you go unprepared."
    ),
    insertEvents(subscene_bye_elaine)
}

subscene_welcome_elaine = {
    say(2, 1, false, 
        "It's decided. Elaine, you'll join us until we've achieved our goals \z
         in the valley and can go home."
    ),
    say(3, 3, false, 
        "Sir Kath, Sir Abelon, you've already done so much for me... I won't \z
         let you down."
    ),
    say(3, 2, false, 
        "Ah... So, what are those goals? Why are you both in the Red Mountain \z
         Valley? I didn't think the Knights of Ebonach ever went north anymore."
    ),
    say(3, 3, false, 
        "And you're the Knight Captains... Don't you usually have a lot of \z
         knights with you to order around?"
    ),
    say(2, 2, false, 
        "Did you not see the news of His Majesty's announcement? It was \z
         circulated all over the city, from what I understand."
    ),
    say(3, 2, false, 
        "My grandad, um... He doesn't... I mean, he told me not to listen to \z
         any... Uh..."
    ),
    say(2, 3, false, 
        "He told you that King Sinclair has lost his mind, and that you \z
         shouldn't trust the palace or the Knights of Ebonach?"
    ),
    say(3, 2, false, 
        "...Please, don't-"
    ),
    say(2, 1, false, 
        "It's perfectly alright. You have no idea, Elaine, how often Abelon \z
         and I hear similar remarks. We tell our knights to ignore them. Ach, I \z
         tell mine that, anyway."
    ),
    say(3, 2, false, 
        "I'm sorry..."
    ),
    say(2, 1, false, 
        "Since you haven't heard, it will take some time to explain. But we \z
         ought to be seeking out our other two traveling companions, my knight and \z
         good friend Lester, and our resident ignaeic scholar Shanti."
    ),
    say(2, 1, false,
        "They went north ahead of us towards our destination. I'll fill you in \z
         while we retrace their steps. Abelon, we'll leave on your command."
    )
}

subscene_elaine_decide = {
    choice({
        {
            ["guard"] = function(g) return true end,
            ["response"] = "It isn't worth the risk, she goes home",
            ['events'] = {
                insertEvents(subscene_elaine_goes_home)
            },
            ['result'] = {
                ['impressions'] = {1, -1, 0}
            }
        },
        {
            ["guard"] = function(g) return true end,
            ["response"] = "We'll take the risk, she comes with us",
            ['events'] = {
                insertEvents(subscene_welcome_elaine)
            },
            ['result'] = {
                ['impressions'] = {-1, 0, 1},
                ['state'] = 'elaine-stays'
            }
        }
    })
}

s12['victory'] = {
    ['ids'] = {'abelon', 'kath', 'elaine'},
    ['events'] = {
        focus(2, 170),
        waitForEvent('camera'),
        lookDir(2, RIGHT),
        wait(0.5),
        lookDir(2, LEFT),
        wait(0.5),
        lookDir(2, RIGHT),
        wait(1),
        lookAt(3,2),
        face(1,2),
        say(2, 1, true, 
            "*Huff* Hah, it's over. Poor beasts. Someone should have told them \z
             they were picking a fight with the greatest knights in all the Kingdom!"
        ),
        focus(1, 100),
        choice({
            {
                ["guard"] = function(g) return true end,
                ["response"] = "The greatest knights?",
                ['events'] = {
                    say(2, 1, true, 
                        "What, you disagree?"
                    ),
                    choice({
                        {
                            ["guard"] = function(g) return true end,
                            ["response"] = "I suppose not",
                            ['events'] = {
                                say(2, 1, false,
                                    "Precisely."
                                )
                            },
                            ['result'] = {
                                ['impressions'] = {0, 1, 0}
                            }
                        },
                        {
                            ["guard"] = function(g) return true end,
                            ["response"] = "You aren't yet worthy of that title",
                            ['events'] = {
                                say(2, 1, false,
                                    "Bah! Says the old man to the youngest Knight Captain in the Kingdom's \z
                                     history. And it won't be long before I finally best you in a proper duel, \z
                                     either. Time is on my side, Abelon."
                                )
                            },
                            ['result'] = {

                            }
                        },
                        {
                            ["guard"] = function(g) return true end,
                            ["response"] = "I'm not quite worthy of that title",
                            ['events'] = {
                                wait(1),
                                say(2, 2, false, 
                                    "...You can't really mean that, can you? If there isn't a knight in \z
                                     Ebonach who can match you in a duel, who exactly are you competing with?"
                                ),
                                say(2, 1, false,
                                    "Unless you think the title of 'greatest' demands a winning \z
                                     personality. In which case, yes, you're dead last."
                                )
                            },
                            ['result'] = {
                                ['impressions'] = {-1, 0, 0},
                                ['awareness'] = {0, 1, 0}
                            }
                        }
                    })
                },
                ['result'] = {

                }
            },
            {
                ["guard"] = function(g) return not g.state['carried-elaine'] end,
                ["response"] = "Kath, the girl",
                ['events'] = {
                    say(2, 3, false,
                        "Of course."
                    )
                },
                ['result'] = {

                }
            },
            {
                ["guard"] = function(g) return true end,
                ["response"] = "...",
                ['events'] = {

                },
                ['result'] = {

                }
            }
        }),
        lookAt(2, 3),
        focus(3, 100),
        say(2, 3, false, 
            "Now then..."
        ),
        -- TODO: choreograph this and all subscenes
        br(function(g) return g.state['carried-elaine'] end, {
            say(2, 1, false, 
                "That was fine work, Elaine. I'm impressed you kept your nerve, if \z
                 that was your first proper combat with monsters."
            ),
            say(3, 1, true, 
                "I... um..."
            ),
            choice({
                {
                    ["guard"] = function(g) return true end,
                    ["response"] = "You have a lot of explaining to do",
                    ['events'] = {
                        say(2, 3, false,
                            "Indeed she does, but hold off on the interrogation for a moment, old \z
                             man. I need to check her wounds. She was in quite a state when you brought \z
                             her here."
                        )
                    },
                    ['result'] = {
                        ['impressions'] = {1, 0, 0}
                    }
                },
                {
                    ["guard"] = function(g) return true end,
                    ["response"] = "Kath, check her injuries",
                    ['events'] = {
                        say(2, 1, false,
                            "As if I need you to remind me. She was in quite a state when you \z
                             brought her here."
                        )
                    },
                    ['result'] = {
                        ['impressions'] = {0, 1, 1}
                    }
                }
            })
        }),
        br(function(g) return not g.state['carried-elaine'] end, {
            say(2, 3, true, 
                "Excuse me, miss? Are you alright?"
            ),
            choice({
                {
                    ["guard"] = function(g) return true end,
                    ["response"] = "She's injured",
                    ['events'] = {

                    },
                    ['result'] = {
                        ['impressions'] = {0, 0, 1}
                    }
                },
                {
                    ["guard"] = function(g) return true end,
                    ["response"] = "Be careful, it might be a trap",
                    ['events'] = {
                        say(2, 3, false,
                            "I doubt it. Look at her, old man, she can barely stand. She needs our \z
                             help. And we need to know what she's doing miles into the valley, whether \z
                             or not you particularly care for her well-being."
                        )
                    },
                    ['result'] = {
                        ['impressions'] = {1, 0, 0}
                    }
                }
            }),
            say(3, 2, false, 
                "...Is it over? Are we safe?"
            ),
            say(2, 1, false, 
                "Yes, the monsters are gone. For now."
            ),
            say(3, 2, false, 
                "...Please, help me. I'm lost. If you have food, or medicine, I'll \z
                 find a way to repay you, I promise..."
            ),
            say(2, 1, false, 
                "Not to worry, I'm trained in healing magic. You're lucky to have \z
                 happened upon us. Come, sit at our camp. I'll get you some food as well. \z
                 What's your name?"
            ),
            say(3, 1, false, 
                "Oh... thank you. Thank you! I knew if I followed the tracks I would \z
                 find someone, and I did it! I'll be able to go home... I'm Elaine."
            ),
            say(3, 1, false, 
                "It's such a relief to see someone, after all this time... Wait. The \z
                 both of you, don't I know...?"
            ),
            say(3, 2, false, 
                "Oh. Oh goddess, you're-"
            ),
            say(2, 1, false,
                "Elaine, is it? Hold still for a moment, Elaine, I'm going to heal \z
                 some of your wounds. Thankfully none of them appear serious."
            )
        }),
        say(2, 3, false, 
            "...Right. 'For simple cuts and bruises, slowly guide a fist of \z
             thumb-sized stones over the length of the wound, while channeling power gently into \z
             the wrist and reading the listed incantation..."
        ),
        say(2, 3, true, 
            "...Replace with new stones when half depleted'. Hm, I wonder if I could \z
             recite all of the healing scripts from memory."
        ),
        choice({
            {
                ["guard"] = function(g) return true end,
                ["response"] = "Impressive recollection",
                ['events'] = {
                    say(2, 1, false, 
                        "On the topic of my memory, old man, I haven't forgotten my first battle \z
                         at the Southwall under your command, when you told the other knights,"
                    ),
                    say(2, 3, true, 
                        "'Kath ought to make an easy meal for the monsters - he won't notice his \z
                         head's being chewed off until he realizes he can't see his manuscript'."
                    ),
                    choice({
                        {
                            ["guard"] = function(g) return true end,
                            ["response"] = "And it was true, at the time",
                            ['events'] = {
                                say(2, 1, false,
                                    "Perhaps, perhaps not. But you won't deny it's serving me well now; \z
                                     even without any scripts handy, a little field healing for Elaine here is \z
                                     child's play."
                                )
                            },
                            ['result'] = {

                            }
                        },
                        {
                            ["guard"] = function(g) return true end,
                            ["response"] = "I said such a thing?",
                            ['events'] = {
                                say(2, 1, false,
                                    "You did, and everyone laughed themselves hoarse over it. I didn't \z
                                     mind that it was at my expense, of course. I suspect I only remember it \z
                                     because it was the first time I heard you make a joke about anything."
                                )
                            },
                            ['result'] = {
                                ['awareness'] = {0, 1, 0}
                            }
                        }
                    })
                },
                ['result'] = {
                    ['impressions'] = {0, 1, 0}
                }
            },
            {
                ["guard"] = function(g) return true end,
                ["response"] = "You learned something at the academy after all.",
                ['events'] = {
                    say(2, 1, false,
                        "Not so! Sitting at a desk never taught me a thing. Protecting the \z
                         farmers along the Southwall under your command was when it all started to \z
                         stick."
                    )
                },
                ['result'] = {

                }
            },
            {
                ["guard"] = function(g) return true end,
                ["response"] = "Are you just showing off?",
                ['events'] = {
                    say(2, 3, false,
                        "No, I'm trying to recall the particulars of one of a few hundred \z
                         ignaeic spellcasting methods pulled from twenty different manuscripts. Unless \z
                         you'd rather I make a mistake and set her on fire?"
                    )
                },
                ['result'] = {
                    ['impressions'] = {0, -1, 0}
                }
            },
            {
                ["guard"] = function(g) return true end,
                ["response"] = "...",
                ['events'] = {

                },
                ['result'] = {
                    ['impressions'] = {1, 0, 0}
                }
            }
        }),
        br(function(g) return g.state['carried-elaine'] end, {
            say(3, 3, false, 
                "Th-thank you. For taking care of me, and for saving me last night. \z
                 That wolf would have surely killed me... Fighting with you was the least I \z
                 could do. Even though I didn't help much..."
            ),
            say(2, 2, false, 
                "Hold on, what wolf? What exactly happened last night, old man? After I \z
                 woke you up for the second watch I slept straight through until morning."
            ),
            say(2, 1, true,
                "Imagine my surprise, waking up to an unconscious, injured girl in camp \z
                 with us!"
            )
        }),
        br(function(g) return not g.state['carried-elaine'] end, {
            say(3, 3, false, 
                "Th-thank you. For taking care of me, and for saving me last night. \z
                 That wolf would have surely killed me..."
            ),
            br(function(g) return not g.state['kath-knows-found-elaine'] end, {
                say(2, 2, true,
                    "Hold on, what wolf? Abelon, did something happen last night? After I \z
                     woke you up for the second watch I slept straight through until morning."
                )
            }),
            br(function(g) return g.state['kath-knows-found-elaine'] end, {
                say(2, 2, true,
                    "Hold on, what wolf? Abelon, you told me you saw her last night. What \z
                     exactly happened? After I woke you up for the second watch I slept straight \z
                     through until morning."
                )
            })
        }),
        choice({
            {
                ["guard"] = function(g) return true end,
                ["response"] = "I left camp for a clearing to the east",
                ['events'] = {
                    say(2, 2, true, 
                        "What? Abelon, you had the watch! I'm never one to doubt your \z
                         intuition, but you should have woken me. What could possibly have been so \z
                         urgent?"
                    ),
                    choice({
                        {
                            ["guard"] = function(g) return true end,
                            ["response"] = "A ritual, performed under the moonlight",
                            ['events'] = {
                                say(2, 2, true, 
                                    "For what purpose? And why didn't you tell us?"
                                ),
                                choice({
                                    {
                                        ["guard"] = function(g) return true end,
                                        ["response"] = "It granted knowledge of new combat spells",
                                        ['events'] = {
                                            br(function(g) return g.state['kath-saw-spell'] end, {
                                                say(2, 3, false, 
                                                    "Ah. Then that explains the destructive fire you unleashed upon those \z
                                                     poor wolves earlier. You burnt them to a crisp. Useful magic, no doubt."
                                                ),
                                                say(2, 2, true,
                                                    "But why didn't you tell us you were preparing such a ritual? We might \z
                                                     have helped."
                                                )
                                            }),
                                            br(function(g) return not g.state['kath-saw-spell'] end, {
                                                say(2, 3, true,
                                                    "New combat spells, hm? That does sound useful, but why didn't you \z
                                                     tell us you were preparing such a ritual? We might have helped."
                                                )
                                            }),
                                            choice({
                                                {
                                                    ["guard"] = function(g) return true end,
                                                    ["response"] = "Secrecy was a requirement",
                                                    ['events'] = {
                                                        say(2, 2, false, 
                                                            "A component of the ritual specifically required you not to discuss it \z
                                                             with anyone? That seems awfully... arbitrary."
                                                        ),
                                                        say(2, 2, false, 
                                                            "Then again, Shanti was just telling us yesterday about the month in \z
                                                             which she waited every day for a bird to land on her head, just to fulfill a \z
                                                             ritual's instructions..."
                                                        ),
                                                        say(2, 1, false,
                                                            "It's baffling magic, I don't mind saying. I'll stick to my simple \z
                                                             incantations. Hopefully the ritual our party is meant to perform at this supposed \z
                                                             monastery isn't so complicated."
                                                        )
                                                    },
                                                    ['result'] = {
                                                        ['impressions'] = {-1, 0, 0}
                                                    }
                                                },
                                                {
                                                    ["guard"] = function(g) return true end,
                                                    ["response"] = "I don't know",
                                                    ['events'] = {
                                                        insertEvents(subscene_dont_know)
                                                    },
                                                    ['result'] = {
                                                        ['impressions'] = {-2, -1, 0},
                                                        ['awareness'] = {0, 2, 0}
                                                    }
                                                }
                                            })
                                        },
                                        ['result'] = {

                                        }
                                    },
                                    {
                                        ["guard"] = function(g) return true end,
                                        ["response"] = "I don't know",
                                        ['events'] = {
                                            insertEvents(subscene_dont_know)
                                        },
                                        ['result'] = {
                                            ['impressions'] = {-2, -1, 0},
                                            ['awareness'] = {0, 2, 0}
                                        }
                                    }
                                }),
                                say(2, 3, false, 
                                    "In any case, I'm to presume on your way to the clearing you happened \z
                                     upon little Elaine here?"
                                ),
                                say(3, 3, false,
                                    "Yes, that must be why you found me... I wasn't anywhere near here. At \z
                                     least, I don't think so. I would have seen the light from the fire."
                                )
                            },
                            ['result'] = {
                                ['impressions'] = {-1, 0, 0}
                            }
                        },
                        {
                            ["guard"] = function(g) return true end,
                            ["response"] = "Someone was in danger",
                            ['events'] = {
                                say(2, 3, false, 
                                    "But... that clearing isn't even within earshot from here. Did you use \z
                                     some sort of spell of detection to survey the area? You ought to teach it \z
                                     to me, if so."
                                ),
                                say(3, 3, false,
                                    "That must be how you found me. You came to my rescue."
                                )
                            },
                            ['result'] = {
                                ['state'] = 'sensed-elaine',
                                ['impressions'] = {0, 0, 1}
                            }
                        }
                    })
                },
                ['result'] = {
                    ['impressions'] = {-1, 0, 0},
                    ['awareness'] = {0, 1, 0}
                }
            },
            {
                ["guard"] = function(g) return true end,
                ["response"] = "I sensed someone nearby",
                ['events'] = {
                    say(2, 2, true, 
                        "What? Abelon, you had the watch! I'm never one to doubt your \z
                         intuition, but you should have woken me. Did you really leave the camp \z
                         undefended?"
                    ),
                    choice({
                        {
                            ["guard"] = function(g) return true end,
                            ["response"] = "Only for a brief moment",
                            ['events'] = {
                                say(2, 2, false,
                                    "You would have cursed me with all of the air in your lungs had I done \z
                                     something so careless. It's unlike you..."
                                )
                            },
                            ['result'] = {
                                ['awareness'] = {0, 1, 0}
                            }
                        },
                        {
                            ["guard"] = function(g) return true end,
                            ["response"] = "She was in danger, it was urgent",
                            ['events'] = {
                                say(2, 3, false,
                                    "You were able to ascertain all that just sitting beside our dying \z
                                     campfire in the middle of the night?"
                                )
                            },
                            ['result'] = {
                                ['impressions'] = {0, 0, 1}
                            }
                        }
                    }),
                    say(2, 3, false, 
                        "She must have been nearly within sight of us. Or else you used some \z
                         spell of detection to survey the area? You ought to teach it to me, if so."
                    ),
                    say(3, 2, false,
                        "Um... I wasn't anywhere near here. At least, I don't think so. I \z
                         would have seen the light from the fire."
                    )
                },
                ['result'] = {
                    ['state'] = 'sensed-elaine'
                }
            }
        }),
        say(3, 2, false, 
            "It had just gotten dark... I was hungry and tired, I was looking for \z
             somewhere to rest. Then I saw... these red eyes, staring at me from the trees... \z
             I was so scared..."
        ),
        say(3, 2, false, 
            "I started running away, and I think it was chasing after me. I was \z
             looking behind me, searching for it, and then... I don't remember anything \z
             else. I woke up and I was here."
        ),
        say(2, 3, false, 
            "Perhaps you ran into a tree, or tripped, and the blow knocked you \z
             unconscious. That would explain the wounds on your head and face."
        ),
        br(function(g) return g.state['carried-elaine'] end, {
            say(3, 3, true,
                "Goddess, I've been an embarassment... Grandad would have my hide. \z
                 But, the wolf..."
            )
        }),
        br(function(g) return not g.state['carried-elaine'] end, {
            say(3, 3, true,
                "Goddess, I've been an embarassment... Grandad would have my hide. \z
                 But, when I woke up I saw a wolf near me, dead. You saved me, didn't you?"
            )
        }),
        choice({
            {
                ["guard"] = function(g) return not g.state['sensed-elaine'] end,
                ["response"] = "The wolf was blocking my path, so I killed it",
                ['events'] = {
                    br(function(g) return g.state['carried-elaine'] end, {
                        say(2, 1, false, 
                            "At least you had the good sense to bring her back to camp. Do you \z
                             remember some months ago, when we were stretched thin out beyond Ebonach's west \z
                             gate?"
                        ),
                        say(2, 1, true, 
                            "You fought bitterly against my carrying home a dying knight. Has your \z
                             heart softened since then?"
                        ),
                        choice({
                            {
                                ["guard"] = function(g) return true end,
                                ["response"] = "I'm not nearly as soft-hearted as you",
                                ['events'] = {
                                    say(2, 1, false, 
                                        "Ha! As it should be."
                                    ),
                                    insertEvents(subscene_question_time)
                                },
                                ['result'] = {
                                    ['impressions'] = {0, 1, 0}
                                }
                            },
                            {
                                ["guard"] = function(g) return true end,
                                ["response"] = "She's here because we need to question her",
                                ['events'] = {
                                    insertEvents(subscene_tactically)
                                },
                                ['result'] = {
                                    ['impressions'] = {1, 0, -1}
                                }
                            }
                        })
                    }),
                    br(function(g) return not g.state['carried-elaine'] end, {
                        say(2, 2, false, 
                            "Thank the Goddess she was able to reach our camp safely. I can't \z
                             fathom why you didn't bring her back, Abelon. She was unconscious and \z
                             defenseless!"
                        ),
                        insertEvents(subscene_question_time2)
                    })
                },
                ['result'] = {

                }
            },
            {
                ["guard"] = function(g) return g.state['sensed-elaine'] and not g.state['carried-elaine'] end,
                ["response"] = "I killed the wolf before it could attack you",
                ['events'] = {
                    say(2, 2, false, 
                        "And yet you didn't bother to bring her back to our camp, even though she \z
                         was still unconscious and defenseless."
                    ),
                    say(2, 2, false,
                        "Were you ever planning to raise this with our party? Were you expecting \z
                         her to simply find her way here unassisted?"
                    ),
                    insertEvents(subscene_question_time2)
                },
                ['result'] = {
                    ['impressions'] = {0, 0, 1},
                    ['awareness'] = {0, 1, 0}
                }
            },
            {
                ["guard"] = function(g) return g.state['carried-elaine'] end,
                ["response"] = "I killed the wolf and carried you here to safety",
                ['events'] = {
                    say(3, 3, false, 
                        "Thank you. Again. Thank you..."
                    ),
                    say(2, 1, false, 
                        "Why, your hard heart is beginning to soften after all, old man! It was \z
                         only some months ago, when we were stretched thin out beyond Ebonach's west \z
                         gate, that you fought bitterly against my carrying home a dying knight."
                    ),
                    say(2, 1, true, 
                        "Could it be that my heroism and effortless charisma are rubbing off on \z
                         you?"
                    ),
                    choice({
                        {
                            ["guard"] = function(g) return true end,
                            ["response"] = "Don't look so smug",
                            ['events'] = {

                            },
                            ['result'] = {
                                ['impressions'] = {0, 1, 0}
                            }
                        },
                        {
                            ["guard"] = function(g) return true end,
                            ["response"] = "...",
                            ['events'] = {

                            },
                            ['result'] = {

                            }
                        }
                    }),
                    insertEvents(subscene_question_time)
                },
                ['result'] = {
                    ['impressions'] = {0, 0, 1},
                    ['awareness'] = {0, 1, 0}
                }
            },
            {
                ["guard"] = function(g) return g.state['carried-elaine'] end,
                ["response"] = "I killed the wolf and brought you here to question you",
                ['events'] = {
                    insertEvents(subscene_tactically)
                },
                ['result'] = {
                    ['impressions'] = {1, 0, -1}
                }
            }
        }),
        say(2, 3, false, 
            "Elaine, you're a citizen of Ebonach, aren't you?"
        ),
        say(3, 3, false, 
            "Yes."
        ),
        say(2, 3, false, 
            "Then I take it you already know who we are."
        ),
        br(function(g) return g.state['carried-elaine'] end, {
            say(3, 3, false, 
                "...I thought I didn't, when I was just waking up. But you called him \z
                 Abelon. And I realized that I recognized you, both of you, I just... didn't \z
                 believe it."
            ),
            say(3, 3, false,
                "That I had been rescued by the two Knight Captains. I've only ever seen \z
                 either of you from a distance..."
            )
        }),
        br(function(g) return not g.state['carried-elaine'] end, {
            say(3, 3, false, 
                "...I thought I didn't, when I first saw you. But I've never seen anyone \z
                 fight so fiercely, and I realized that I recognized you, both of you, I \z
                 just... didn't believe it."
            ),
            say(3, 3, false,
                "That I had been found by the two Knight Captains. I've only ever seen \z
                 either of you from a distance..."
            )
        }),
        say(3, 2, false, 
            "Captain Kath, Sir... I hope that my, um, plain speech hasn't offended \z
             you in any way. And thank you, Sir Kath, for using your magic to heal me. \z
             Please forgive me for being a distraction from your, uh, quest. Or whatever."
        ),
        say(2, 1, false, 
            "Ha! I must admit, I don't mind the deferential treatment. If only \z
             Lester and Shanti were so enthusiastic... But Elaine, there's no need to \z
             fuss over your words-"
        ),
        say(3, 2, false, 
            "And Sir Abelon, please accept my gratitude. I didn't deserve to be \z
             saved by a famous knight. I didn't deserve to be saved at all, I know... I \z
             don't... I should have died. I should be dead. For being stupid."
        ),
        say(3, 2, false, 
            "But Captain Abelon, Sir, please, uh... I'm sorry..."
        ),
        say(3, 2, true, 
            "Will you spare my life? I... I just want to go home. I won't go out \z
             into the forest again, just please, let me go back home to my \z
             grandfather..."
        ),
        choice({
            {
                ["guard"] = function(g) return true end,
                ["response"] = "What? I saved you from that wolf, didn't I?",
                ['events'] = {
                    say(3, 2, false, 
                        "Yes, and I'll answer your questions, and uh... Then you'll know that I \z
                         was out in the forest without permission and it's against the law and I got \z
                         in your way and, and,"
                    ),
                    say(3, 2, false, 
                        "...grandad said if you get in Sir Abelon's way he'll probably... he'll \z
                         probably kill you, and I, I... *sob*"
                    ),
                    say(2, 2, false, 
                        "Sigh... You see, Abelon? This is what you've done to our reputation. \z
                         This poor girl is convinced you'll kill her in cold blood right after \z
                         saving her life."
                    ),
                    say(2, 3, false, 
                        "Every time His Majesty orders an execution in the name of 'safeguarding \z
                         the Kingdom', I have to go out into the streets smiling and waving and \z
                         giving candies to children,"
                    ),
                    say(2, 3, true, 
                        "just to convince our own public that the Knights of Ebonach do more than \z
                         go around chopping peoples' heads off!"
                    ),
                    choice({
                        {
                            ["guard"] = function(g) return true end,
                            ["response"] = "Nobody is forcing you",
                            ['events'] = {
                                say(2, 3, false, 
                                    "I'm forcing myself. I love this Kingdom, Abelon, and I know you do too, \z
                                     in your own twisted way. I became a knight to protect it."
                                ),
                                say(2, 3, false,
                                    "But I want more for it than survival. I want its people to be happy. You \z
                                     and King Sinclair don't seem to feel the same way, so it falls to me."
                                )
                            },
                            ['result'] = {

                            }
                        },
                        {
                            ["guard"] = function(g) return true end,
                            ["response"] = "That's absurd, I would never kill someone in Elaine's position",
                            ['events'] = {
                                say(2, 3, false,
                                    "You would never, except for all of the times you have. Either on His \z
                                     Majesty's orders or your own judgement."
                                )
                            },
                            ['result'] = {
                                ['impressions'] = {0, 1, 0},
                                ['awareness'] = {0, 1, 0}
                            }
                        }
                    }),
                    say(3, 2, false,
                        "I'm sorry. Sir Kath, Sir Abelon, I'm sorry. I was overwhelmed, is \z
                         all. But both of you... you're very different in person. From how I \z
                         imagined. Please, let me explain how I ended up here."
                    )
                },
                ['result'] = {
                    ['impressions'] = {0, 1, 1}
                }
            },
            {
                ["guard"] = function(g) return true end,
                ["response"] = "Stop blubbering and tell us why you're here",
                ['events'] = {
                    say(3, 2, false,
                        "R-right. Right."
                    )
                },
                ['result'] = {
                    ['impressions'] = {1, -1, -4}
                }
            }
        }),
        say(3, 2, false, 
            "My house is near the north gate of Ebonach. I... Sometimes I go into the \z
             valley with my bow and arrows. My grandad made them for me."
        ),
        say(3, 2, false, 
            "Meat is so expensive at the market, but there are rabbits just outside \z
             the walls, and my grandad... I mean, I know how to hunt and trap them."
        ),
        say(2, 3, false, 
            "..."
        ),
        say(3, 3, false, 
            "Yesterday was my little brother Charim's birthday, and I wanted to \z
             make him something special for dinner. So I went out..."
        ),
        say(2, 3, false, 
            "Sorry to interrupt, but how exactly are you leaving the city? Two of \z
             my men guard the north gate."
        ),
        say(3, 2, false, 
            "One of the knights there is... Um... We're friends. I go out at \z
             night, and he told me how to slip through without anyone noticing."
        ),
        say(2, 3, false, 
            "I'll have to have more than a few words with them..."
        ),
        say(3, 3, false, 
            "I went out, and I was checking my traps, and I saw a deer. I hardly ever \z
             see them anymore, they're so rare..."
        ),
        say(3, 3, false, 
            "I thought it would be so amazing if I could kill it, but I missed my \z
             first shot, and it ran away. When I went after it, I got lost."
        ),
        say(2, 3, false, 
            "Simply getting lost isn't enough to end up an entire two days' \z
             journey out from Ebonach."
        ),
        say(3, 3, false, 
            "Well, I couldn't retrace my steps, but I did find a path. And I saw that \z
             people had been walking on it recently. My gran... Uh, I know how to track \z
             animals."
        ),
        say(3, 3, false, 
            "I assumed the direction they were headed was back towards the city, \z
             since the valley is so dangerous..."
        ),
        say(2, 2, false, 
            "Ah. But in fact, those were our footsteps, headed directly into the \z
             heart of the forest. I take it you didn't have a compass to orient \z
             yourself. And the trees obscure the sun at most hours... Bad luck."
        ),
        say(3, 2, false, 
            "Eventually I realized I was getting further from town, but I was so \z
             hungry, and scared... it had already been a day, I... I had to sleep in a tree \z
             trunk in the dark..."
        ),
        say(3, 2, true, 
            "I thought if I could just catch up to the people walking on the path \z
             they could help me."
        ),
        choice({
            {
                ["guard"] = function(g) return true end,
                ["response"] = "It's remarkable you made it this far",
                ['events'] = {
                    say(2, 1, false,
                        "I have to agree."
                    )
                },
                ['result'] = {
                    ['impressions'] = {0, 0, 1}
                }
            },
            {
                ["guard"] = function(g) return true end,
                ["response"] = "You've broken several laws",
                ['events'] = {
                    say(3, 2, false, 
                        "I... I know..."
                    ),
                    say(2, 3, false,
                        "True enough. But we aren't exactly in a position to bring her to \z
                         justice, whatever the worth in doing so. More than her flagrant disrespect for \z
                         the law, I'm interested in her genuine talents."
                    )
                },
                ['result'] = {
                    ['impressions'] = {1, 0, 0}
                }
            },
            {
                ["guard"] = function(g) return true end,
                ["response"] = "What a ridiculous story",
                ['events'] = {
                    say(3, 3, false, 
                        "It's true! I'm not lying!"
                    ),
                    say(2, 3, false, 
                        "It does stretch credulity, Abelon, but I'm inclined to believe her. \z
                         Noticeable omissions regarding her grandfather aside..."
                    ),
                    say(3, 2, false, 
                        "Please, don't do anything to him! Hunting in the valley was allowed \z
                         when he was young, I know it was! He was just trying to keep me \z
                         entertained, I'm sure... What I did was my own fault."
                    ),
                    say(2, 1, false,
                        "Rest easy. Personally, I've no interest in lecturing a man three \z
                         times my age on the letter of the law. And I'll keep Abelon off his back. \z
                         I'm more curious about you, and your genuine talents."
                    )
                },
                ['result'] = {
                    ['impressions'] = {1, 0, -1}
                }
            }
        }),
        say(2, 3, false, 
            "Elaine, to make it here, for two days you've steered clear of \z
             monsters, tracked both humans and animals, and kept yourself fed."
        ),
        say(2, 3, false, 
            "What's more, you're proficient with a bow. And you aren't even a \z
             trained knight. How old are you?"
        ),
        say(3, 3, false, 
            "Seventeen."
        ),
        say(2, 3, true, 
            "Hm..."
        ),
        choice({
            {
                ["guard"] = function(g) return true end,
                ["response"] = "What are you plotting, Kath?",
                ['events'] = {

                },
                ['result'] = {

                }
            },
            {
                ["guard"] = function(g) return true end,
                ["response"] = "She's not coming with us",
                ['events'] = {
                    say(2, 2, false,
                        "Come on now, you haven't even heard my proposal yet!"
                    )
                },
                ['result'] = {
                    ['state'] = 'not-coming-with-us',
                    ['impressions'] = {0, -1, -1}
                }
            }
        }),
        say(2, 3, false, 
            "She's clearly capable. Enough that she wouldn't slow us down as a \z
             traveling companion. And she would be safer staying with us than trekking back \z
             to the city alone along the Lefally road."
        ),
        say(2, 3, false, 
            "I think we should bring her onto our expedition, find the monastery, \z
             and return home as a group after we finish with the ritual. That is, if \z
             she doesn't object."
        ),
        say(3, 2, true, 
            "That's... Um..."
        ),
        choice({
            {
                ["guard"] = function(g) return true end,
                ["response"] = "Out of the question, she's a liability",
                ['events'] = {

                },
                ['result'] = {
                    ['state'] = 'out-of-the-question',
                    ['impressions'] = {1, -1, -3}
                }
            },
            {
                ["guard"] = function(g) return true end,
                ["response"] = "We don't have enough rations or ignea",
                ['events'] = {

                },
                ['result'] = {
                    ['impressions'] = {0, 0, -1}
                }
            },
            {
                ["guard"] = function(g) return true end,
                ["response"] = "She'd be no safer with us",
                ['events'] = {

                },
                ['result'] = {
                    ['awareness'] = {0, 1, 0}
                }
            },
            {
                ["guard"] = function(g) return not g.state['not-coming-with-us'] and g:getSprite('elaine'):getImpression() > -2 end,
                ["response"] = "It merits discussion",
                ['events'] = {

                },
                ['result'] = {
                    ['state'] = 'merits-discussion',
                    ['impressions'] = {-1, 0, 1},
                    ['awareness'] = {0, 1, 0}
                }
            }
        }),
        say(3, 2, false, 
            "I..."
        ),
        br(function(g) return g:getSprite('elaine'):getImpression() < 0 end, {
            say(3, 2, false, 
                "...I'm sorry... Please, allow me to go back to Ebonach... I can find \z
                 my way along the path. All I need is some food to take with me, if you \z
                 can spare it. I want to go home."
            ),
            say(2, 2, false, 
                "Truly? Elaine, do you understand how lucky you were just to reach us \z
                 alive? Packs of wolves hunt all over the forest. And much worse."
            ),
            say(2, 2, false, 
                "There's a reason it's barred to citizens. You'll be alone for a full two \z
                 days, or longer if you run into trouble-"
            ),
            say(3, 2, false, 
                "Stop! ...I know it's dangerous. And I'm scared, but... Well, I can tell \z
                 when I'm not wanted."
            ),
            say(3, 3, false, 
                "I don't really understand what you're doing in the valley, but if \z
                 Captain Kath and Captain Abelon are both so far from the city, it must be \z
                 important."
            ),
            say(3, 2, false, 
                "You already went to the trouble of saving my life. I don't want to \z
                 cause any more problems, and Sir Abelon... you've made it clear that I \z
                 would, if I stayed."
            ),
            say(3, 2, false, 
                "Whatever punishment you have for me when you come back to Ebonach, I \z
                 accept it. Until then, I want to be with my family."
            ),
            say(2, 2, false, 
                "Ach... It doesn't sound like I'll be swaying you. But I won't let you \z
                 go unprepared."
            ),
            insertEvents(subscene_bye_elaine)
        }),
        br(function(g) return g:getSprite('elaine'):getImpression() > -1 and g:getSprite('elaine'):getImpression() < 6 end, {
            say(3, 2, false, 
                "...I'm just not sure. Fighting more monsters and getting further from \z
                 home, or going back alone... Both sound terrifying."
            ),
            say(3, 3, false, 
                "I'm already in debt to both of you, so I don't think it's my place to \z
                 decide. I'll do whatever you believe is best."
            ),
            say(2, 3, true, 
                "Personally, I think she'd be safe with us. And she can fight, with \z
                 that bow of hers. Abelon?"
            ),
            choice({
                {
                    ["guard"] = function(g) return g.state['out-of-the-question'] end,
                    ["response"] = "It isn't worth the risk, she goes home",
                    ['events'] = {
                        insertEvents(subscene_elaine_goes_home)
                    },
                    ['result'] = {

                    }
                },
                {
                    ["guard"] = function(g) return true end,
                    ["response"] = "How would we feed her?",
                    ['events'] = {
                        say(2, 3, false, 
                            "Well, Elaine, how did you feed yourself in the valley? You can't have \z
                             made it this far on just a full stomach."
                        ),
                        say(3, 3, false, 
                            "Berries, mostly. A lot of them grow around here. I didn't eat very much, \z
                             to be honest..."
                        ),
                        say(3, 3, false, 
                            "If I wasn't trying so hard to catch up with you, I would have shot a \z
                             rabbit and made a fire to cook it. I've done that a few times before."
                        ),
                        say(2, 1, true, 
                            "Sounds like you're plenty capable of earning your weight in rations, \z
                             then. So to speak. So long as there's a spare moment to forage..."
                        ),
                        insertEvents(subscene_elaine_decide)
                    },
                    ['result'] = {

                    }
                },
                {
                    ["guard"] = function(g) return true end,
                    ["response"] = "How would we keep her safe?",
                    ['events'] = {
                        br(function(g) return g.state['carried-elaine'] end, {
                            say(2, 3, false,
                                "The same way we just did, naturally. By fighting cautiously and \z
                                 giving her strict orders. Two things you're rather well known for, I might \z
                                 add."
                            )
                        }),
                        say(2, 1, false, 
                            "It's true we're ill-informed of the dangers that lie deeper in the \z
                             valley. But we're only a party of the three strongest knights in Ebonach, and \z
                             perhaps its most skilled mage."
                        ),
                        say(2, 1, false, 
                            "Do you really doubt our ability to keep one girl alive?"
                        ),
                        say(3, 3, true,
                            "...Wow."
                        ),
                        insertEvents(subscene_elaine_decide)
                    },
                    ['result'] = {
                        ['impressions'] = {0, 0, 1}
                    }
                },
                {
                    ["guard"] = function(g) return true end,
                    ["response"] = "How would she keep up with us?",
                    ['events'] = {
                        br(function(g) return g.state['carried-elaine'] end, {
                            say(2, 1, false, 
                                "You saw her fight just now. She has a knack for it, and the survival \z
                                 skills to match. Even if she's untrained, I don't think she'll hamper our \z
                                 progress."
                            ),
                            say(2, 3, false, 
                                "How about it, Elaine? At our next run-in with monsters, could you pull \z
                                 that off again?"
                            ),
                            say(3, 1, true,
                                "With you protecting me, Sir Kath, I could. I was scared at first, \z
                                 but... The wolves are easy targets. Easier than rabbits, anyway."
                            )
                        }),
                        br(function(g) return not g.state['carried-elaine'] end, {
                            say(2, 3, false, 
                                "Well, she did catch up to us on the road. So her stamina and survival \z
                                 skills aren't in question, at least. But she'd have to hold her own in a \z
                                 proper fight against monsters."
                            ),
                            say(2, 3, false, 
                                "What do you think, Elaine? You have a bow and arrows. Imagine you \z
                                 were fighting with us just now. Could you have kept out of reach of the \z
                                 wolves' fangs and taken a few shots at them?"
                            ),
                            say(3, 2, true, 
                                "...Oh Goddess. If... If a wolf ran for me, I don't know what I would \z
                                 do. But... they're much bigger than rabbits. If you distracted them, Sir \z
                                 Kath, I'm sure I could hit them."
                            ),
                            choice({
                                {
                                    ["guard"] = function(g) return true end,
                                    ["response"] = "Imagination isn't enough, real combat is different",
                                    ['events'] = {

                                    },
                                    ['result'] = {
                                        ['impressions'] = {1, 0, 0}
                                    }
                                },
                                {
                                    ["guard"] = function(g) return true end,
                                    ["response"] = "...",
                                    ['events'] = {
                                        say(2, 3, false,
                                            "Whether you'd keep your nerve in a real battle remains to be seen. \z
                                             Many knights don't."
                                        )
                                    },
                                    ['result'] = {

                                    }
                                }
                            }),
                            say(3, 3, false, 
                                "...I know what I must look like to you, Sir Kath, Sir Abelon. I've \z
                                 been scared, and confused, and desperate."
                            ),
                            say(3, 3, true,
                                "But I can handle myself. Except for your knights, I've been in the \z
                                 valley more than anyone. I'll fight, if you need me to."
                            )
                        }),
                        insertEvents(subscene_elaine_decide)
                    },
                    ['result'] = {

                    }
                },
                {
                    ["guard"] = function(g) return g.state['merits-discussion'] end,
                    ["response"] = "We'll take the risk, she comes with us",
                    ['events'] = {
                        insertEvents(subscene_welcome_elaine)
                    },
                    ['result'] = {
                        ['state'] = 'elaine-stays'
                    }
                }
            })
        }),
        br(function(g) return g:getSprite('elaine'):getImpression() > 5 end, {
            say(3, 3, false, 
                "I want to join you. The thought of going back to the city alone is... \z
                 It's too much. I feel safe here with you, Sir Kath and Sir Abelon. You've \z
                 looked out for me, and been considerate towards me."
            ),
            say(3, 3, false, 
                "...You're different from how I thought Knights of Ebonach would be."
            ),
            br(function(g) return g.state['carried-elaine'] end, {
                say(3, 1, false,
                    "And I won't slow you down! I can fight, you saw me fight! And, and... \z
                     I'll hunt for food for us! So that there's still enough for everyone! \z
                     Please, give me a chance."
                )
            }),
            br(function(g) return not g.state['carried-elaine'] end, {
                say(3, 1, false,
                    "And I won't slow you down! I can fight, I'm good with a bow, I \z
                     promise! And, and... I'll hunt for food for us! So that there's still enough \z
                     for everyone! Please, give me a chance."
                )
            }),
            say(2, 1, true, 
                "Well, now! Not just capable, but motivated! I dare say, far from a \z
                 liability, she'd make a useful ally. What do you make of it, Abelon?"
            ),
            choice({
                {
                    ["guard"] = function(g) return true end,
                    ["response"] = "I helped her. I didn't agree to have her tag along",
                    ['events'] = {
                        say(2, 3, true, 
                            "Maybe so, but what concerns have you raised that she doesn't have an \z
                             answer for?"
                        ),
                        choice({
                            {
                                ["guard"] = function(g) return true end,
                                ["response"] = "Slowing down our progress",
                                ['events'] = {
                                    say(3, 3, false,
                                        "If I make trouble for your mission, or quest, or whatever it is, you \z
                                         can leave me behind. But first, let me prove myself. When I shoot my bow, \z
                                         I never miss. Er, except for that deer I was chasing..."
                                    )
                                },
                                ['result'] = {
                                    ['state'] = 'elaine-stays'
                                }
                            },
                            {
                                ["guard"] = function(g) return true end,
                                ["response"] = "Our food supply",
                                ['events'] = {
                                    say(3, 3, false,
                                        "On my way here, I had to find food for two whole days. I know which \z
                                         plants are edible, and I know how to catch and cook rabbits. So long as \z
                                         there's a spare moment to forage, I can feed myself."
                                    )
                                },
                                ['result'] = {
                                    
                                }
                            },
                            {
                                ["guard"] = function(g) return true end,
                                ["response"] = "Our ignea supply",
                                ['events'] = {
                                    say(3, 2, false,
                                        "Erm... I've never used magic outside of the academy. You don't need \z
                                         to share any spellstone with me."
                                    )
                                },
                                ['result'] = {
                                }
                            },
                            {
                                ["guard"] = function(g) return true end,
                                ["response"] = "Her own safety",
                                ['events'] = {
                                    say(2, 1, false, 
                                        "It's true we're ill-informed of the dangers that lie deeper in the \z
                                         valley. But we're only a party of the three strongest knights in Ebonach, and \z
                                         perhaps its most skilled mage."
                                    ),
                                    say(2, 1, false, 
                                        "Do you really doubt our ability to keep one girl alive?"
                                    ),
                                    say(3, 3, false,
                                        "Wow..."
                                    )
                                },
                                ['result'] = {
                                    ['impressions'] = {0, 0, 1}
                                }
                            }
                        }),
                        say(2, 3, false, 
                            "I understand your hesitation, Abelon, but I think Elaine has made enough \z
                             of a case for herself."
                        ),
                        say(2, 3, false,
                            "I'm loathe to pull rank, but I'm a Knight Captain, same as you, and only \z
                             His Majesty can overrule me. You might be leader of the expedition, but I'm \z
                             making this call."
                        )
                    },
                    ['result'] = {
                        ['impressions'] = {0, 0, -1},
                        ['state'] = 'elaine-stays'
                    }
                },
                {
                    ["guard"] = function(g) return true end,
                    ["response"] = "...Fine",
                    ['events'] = {

                    },
                    ['result'] = {
                        ['impressions'] = {-1, 0, 0},
                        ['state'] = 'elaine-stays'
                    }
                },
                {
                    ["guard"] = function(g) return not g.state['out-of-the-question'] end,
                    ["response"] = "I'm convinced",
                    ['events'] = {

                    },
                    ['result'] = {
                        ['impressions'] = {-1, 1, 1},
                        ['state'] = 'elaine-stays'
                    }
                }
            }),
            insertEvents(subscene_welcome_elaine)
        })
    },
    ['result'] = {
        ['do'] = function(g)
            local k = g.sprites['kath']
            local a = g.sprites['abelon']
            local e = g.sprites['elaine']
            if k.level > 8 or a.level > 8 or e.level > 3 then
                g:startTutorial("Experience and skill learning")
            end
        end
    }
}

s12['close-tutorial-lvl'] = {
    ['ids'] = {},
    ['events'] = {},
    ['result'] = {
        ['do'] = function(g)
            g:endTutorial()
        end
    }
}

s12['igneashard'] = {
    ['ids'] = {'abelon', 'igneashard'},
    ['events'] = {
        lookAt(1, 2),
        introduce('igneashard'),
        say(2, 1, true, 
            "You happen upon a shard of ignea embedded in the ground."
        ),
        choice({
            {
                ["guard"] = function(g) return true end,
                ["response"] = "Take it",
                ['events'] = {
                    say(2, 1, false,
                        "You wrest the shard from the earth and brush away the dirt before \z
                         putting it in your pack."
                    )
                },
                ['result'] = {
                    ['do'] = function(g)
                        g.player:acquire(g:getMap():dropSprite('igneashard'))
                    end
                }
            },
            {
                ["guard"] = function(g) return true end,
                ["response"] = "Leave it",
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

subscene_read_book = {
    say(2, 1, false, 
        "The open, two-page spread is taken up entirely by a map hand-drawn in \z
         ink. It depicts a winding valley of trees vertically dividing two large \z
         mountain ranges."
    ),
    say(2, 1, false, 
        "Near the top of the page is a drawing of a city in the valley labeled \z
         'Lefellen'. The valley and mountains appear to extend further north past \z
         Lefellen, off the page."
    ),
    say(2, 1, false, 
        "To the south, the mountain ranges end and the valley of trees opens \z
         into a wide plain. At the mouth of the valley is depicted a larger, walled \z
         city. Printed next to the city is the label 'Ebonach'."
    ),
    say(2, 1, false, 
        "A river, originating from somewhere in the mountains, passes by \z
         Ebonach and flows out into the plains. By the river is written 'Ebon', and on \z
         the plains, 'Sonder'."
    ),
    say(2, 1, true, 
        "In the bottom corner of the two pages, a compass is drawn, and next \z
         to it, a title"
    ),
    choice({
        {
            ["guard"] = function(g) return true end,
            ["response"] = "Turn the page",
            ['events'] = {
                say(2, 1, false, 
                    "You turn over the thick parchment. This page is titled 'The Lefally \z
                     Road', and depicts a closer view of the forested valley. A road runs from \z
                     the top of the page to the bottom, embellished with guiding landmarks."
                ),
                say(2, 1, false, 
                    "A paper insert is included. It appears to be a rough copy of this \z
                     page, drawn more recently. On closer inspection, it includes a new path \z
                     branching east from the road and into the trees."
                ),
                say(2, 1, false,
                    "The eastern path ends in a depiction of a campfire, which has been \z
                     circled. Two similar campfire drawings have been added along the main road, \z
                     south of where the path diverges."
                )
            },
            ['result'] = {

            }
        },
        {
            ["guard"] = function(g) return true end,
            ["response"] = "Leave",
            ['events'] = {

            },
            ['result'] = {

            }
        }
    })
}

s12['book-callback'] = {
    ['ids'] = {'abelon', 'book'},
    ['events'] = {
        lookAt(1, 2),
        say(2, 1, true, 
            "The large book looks slightly out of place next to the many practical \z
             necessities strewn about the camp."
        ),
        choice({
            {
                ["guard"] = function(g) return true end,
                ["response"] = "Start reading",
                ['events'] = {
                    insertEvents(subscene_read_book)
                },
                ['result'] = {

                }
            },
            {
                ["guard"] = function(g) return true end,
                ["response"] = "Leave",
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

s12['book'] = {
    ['ids'] = {'abelon', 'book'},
    ['events'] = {
        lookAt(1, 2),
        introduce('book'),
        say(2, 1, true, 
            "A large book with sturdy but old pages lies open amidst the clutter \z
             of the campsite."
        ),
        choice({
            {
                ["guard"] = function(g) return true end,
                ["response"] = "Start reading",
                ['events'] = {
                    insertEvents(subscene_read_book)
                },
                ['result'] = {

                }
            },
            {
                ["guard"] = function(g) return true end,
                ["response"] = "Leave",
                ['events'] = {

                },
                ['result'] = {
                    ['callback'] = { 'book-callback', false }
                }
            }
        })
    },
    ['result'] = {

    }
}

s12['campfire'] = {
    ['ids'] = {'abelon', 'campfire'},
    ['events'] = {
        introduce('campfire'),
        say(2, 1, false,
            "The campfire has completely gone out."
        )
    },
    ['result'] = {

    }
}

s12['campbed'] = {
    ['ids'] = {'abelon', 'campbed'},
    ['events'] = {
        introduce('campbed'),
        say(2, 1, false,
            "Your camp bed. Kath will bring it along for you."
        )
    },
    ['result'] = {

    }
}

s12['kath-callback'] = {
    ['ids'] = {'abelon', 'kath', 'elaine'},
    ['events'] = {
        face(1, 2),
        say(2, 3, false,
            "I'll get packing my things. The sooner we reach Lester and Shanti, \z
             the safer we'll all be."
        )
    },
    ['result'] = {

    }
}

s12['kath'] = {
    ['ids'] = {'abelon', 'kath', 'elaine'},
    ['events'] = {
        face(1, 2),
        say(2, 3, false,
            "We're following the instructions of a dusty old ritual scroll, and \z
             it's led us deeper into the valley than anyone's been since I was born. I \z
             thought I was prepared for anything to happen."
        ),
        say(2, 3, false, 
            "But to run across another person, all the way out here! It's \z
             unbelievable. She's unbelievable, for tracking us this far."
        ),
        br(function(g) return g.state['elaine-stays'] end, {
            say(2, 1, true, 
                "I can't wait to see Lester's reaction. For once, maybe he'll be at a \z
                 loss for words... But I doubt it! Ha ha."
            ),
            choice({
                {
                    ["guard"] = function(g) return g.state['carried-elaine'] end,
                    ["response"] = "She knows her way around a fight",
                    ['events'] = {
                        say(2, 1, false,
                            "Shockingly, yes. Perhaps in lieu of punishing her, we can recruit her \z
                             to the knights when we return to Ebonach. I suspect she'd make a fine \z
                             soldier."
                        )
                    },
                    ['result'] = {
                        ['impressions'] = {0, 0, 1}
                    }
                },
                {
                    ["guard"] = function(g) return true end,
                    ["response"] = "You're confident she won't be a burden?",
                    ['events'] = {
                        say(2, 1, false,
                            "I have a good feeling about her, Abelon. She catches on quick - I \z
                             think she'll surprise us."
                        )
                    },
                    ['result'] = {
                        ['impressions'] = {1, 0, 0}
                    }
                },
                {
                    ["guard"] = function(g) return true end,
                    ["response"] = "Always ready with a pithy remark... Who does he get it from, I wonder?",
                    ['events'] = {
                        say(2, 1, false, 
                            "Don't make that face at me! I'm nothing but respectful towards our \z
                             knightly duties, and certainly towards my venerable senior in the role of \z
                             Knight Captain. Most of the time."
                        ),
                        say(2, 1, false,
                            "Listen, Lester and I have been best friends since we were children. \z
                             So take it from me... He's always been an ass. Ha ha ha!"
                        )
                    },
                    ['result'] = {
                        ['impressions'] = {0, 1, 0}
                    }
                }
            })
        }),
        br(function(g) return not g.state['elaine-stays'] end, {
            say(2, 2, false, 
                "It's true that we cleared out the threats along the path as we \z
                 traveled north, but I can't help but worry for her..."
            ),
            say(2, 2, true, 
                "She came all this way alone, in a dangerous and untamed forest, and \z
                 we've sent her right back into it."
            ),
            choice({
                {
                    ["guard"] = function(g) return true end,
                    ["response"] = "It was necessary for our mission",
                    ['events'] = {
                        wait(0.5),
                        say(2, 2, false,
                            "Was it? Why is it that I always feel uneasy, hearing those words from \z
                             you..."
                        )
                    },
                    ['result'] = {
                        ['impressions'] = {0, -1, 0}
                    }
                },
                {
                    ["guard"] = function(g) return true end,
                    ["response"] = "She seems resourceful, she'll manage",
                    ['events'] = {
                        say(2, 2, false,
                            "I hope you're right."
                        )
                    },
                    ['result'] = {

                    }
                }
            })
        }),
        wait(1),
        say(2, 3, false,
            "Let's not delay here any longer. The sooner we reach Lester and \z
             Shanti, the safer we'll all be."
        )
    },
    ['result'] = {
        ['callback'] = { 'kath-callback', false }
    }
}

s12['elaine-callback'] = {
    ['ids'] = {'abelon', 'elaine'},
    ['events'] = {
        face(1, 2),
        say(2, 1, false,
            "I'll stay close to you and Sir Kath. I won't be a burden, I promise!"
        )
    },
    ['result'] = {

    }
}

s12['elaine'] = {
    ['ids'] = {'abelon', 'elaine'},
    ['events'] = {
        face(1, 2),
        say(2, 3, true, 
            "Um, Sir Abelon? May I... May I say something?"
        ),
        choice({
            {
                ["guard"] = function(g) return true end,
                ["response"] = "Go ahead",
                ['events'] = {
                    say(2, 3, false, 
                        "When you were fighting those wolves earlier, they attacked from all \z
                         sides. But since the ground is a bit damp here, I can see some of their \z
                         tracks, and where they've been moving through the brush."
                    ),
                    say(2, 3, false, 
                        "I might be wrong, but I think they all came from that opening in the \z
                         trees west of us."
                    ),
                    say(2, 3, true, 
                        "In the academy, we're taught that monsters travel in packs... Are we \z
                         being attacked because we're near the home of a wolf pack over there?"
                    ),
                    choice({
                        {
                            ["guard"] = function(g) return true end,
                            ["response"] = "Yes, I noticed the same thing",
                            ['events'] = {
                                say(2, 2, true,
                                    "Oh, of course. I didn't mean to assume... I should have known you and \z
                                     Sir Kath would have already seen it..."
                                )
                            },
                            ['result'] = {
                                ['impressions'] = {1, 0}
                            }
                        },
                        {
                            ["guard"] = function(g) return true end,
                            ["response"] = "You were able to determine all of that?",
                            ['events'] = {
                                say(2, 3, true,
                                    "I-it's just a guess! And even if it's true, I don't know if there's \z
                                     anything we can do about it. I just thought you might want to know..."
                                )
                            },
                            ['result'] = {
                                ['impressions'] = {0, 1}
                            }
                        }
                    }),
                    choice({
                        {
                            ["guard"] = function(g) return true end,
                            ["response"] = "Thank you for bringing it up",
                            ['events'] = {
                                say(2, 1, false,
                                    "Yes, Sir Abelon!"
                                )
                            },
                            ['result'] = {
                                ['impressions'] = {0, 1}
                            }
                        },
                        {
                            ["guard"] = function(g) return true end,
                            ["response"] = "Let's move on",
                            ['events'] = {
                                say(2, 3, false,
                                    "Right."
                                )
                            },
                            ['result'] = {

                            }
                        }
                    })
                },
                ['result'] = {
                    ['callback'] = { 'elaine-callback', false }
                }
            },
            {
                ["guard"] = function(g) return true end,
                ["response"] = "Not now",
                ['events'] = {
                    say(2, 2, false,
                        "Of course, I'm sorry. For bothering you."
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

s12['wolf-den-battle'] = {
    ['ids'] = {'abelon', 'kath', 'elaine', 'wolf1', 'wolf2', 'wolf3', 'alphawolf1', 'alphawolf2'},
    ['events'] = {
        focus(1, 200),
        walk(false, 1, 16, 17, 'walk'),
        teleport(2, 28, 15),
        br(function(g) return g.state['elaine-stays'] end, {
            teleport(3, 31, 15)
        }),
        walk(false, 2, 16, 15, 'walk1'),
        br(function(g) return g.state['elaine-stays'] end, {
            walk(false, 3, 18, 15, 'walk2')
        }),
        waitForEvent('walk'),
        say(2, 1, false, 
            "Abelon, what have you found over here? I didn't realize there was \z
             anything of interest further west from our camp."
        ),
        waitForText(),
        waitForEvent('walk1'),
        br(function(g) return g.state['elaine-stays'] end, {
            waitForEvent('walk2')
        }),
        wait(0.5),
        lookDir(4, RIGHT),
        lookDir(5, RIGHT),
        lookDir(6, RIGHT),
        lookDir(7, RIGHT),
        lookDir(8, RIGHT),
        teleport(6, 11, 16),
        wait(0.5),
        teleport(7, 11, 15),
        wait(0.5),
        teleport(4, 14, 11),
        teleport(5, 16, 26),
        walk(false, 5, 16, 22, 'walk'),
        waitForEvent('walk'),
        wait(0.5),
        teleport(8, 11, 23),
        walk(false, 8, 11, 20, 'walk'),
        waitForEvent('walk'),
        wait(1),
        br(function(g) return g.state['elaine-stays'] end, {
            say(3, 2, false,
                "...Eep..."
            )
        }),
        walk(false, 2, 15, 16, 'walk'),
        say(2, 3, false, 
            "Ah. This must be the den of the wolf pack that's been after us. Doing \z
             away with them now will allow us to focus on finding the monastery."
        ),
        waitForEvent('walk'),
        br(function(g) return g.state['elaine-stays'] end, {
            walk(false, 3, 16, 15, 'walk')
        }),
        wait(0.5),
        br(function(g) return g.state['elaine-stays'] end, {
            say(2, 3, false, 
                "Elaine, I expect it will be one battle after another for as long as \z
                 you're with us. Are you ready?"
            ),
            waitForEvent('walk'),
            say(3, 3, false,
                "Ready as I'll ever be..."
            )
        })
    },
    ['result'] = {
        ['do'] = function(g)
            g:launchBattle('wolf-den')
        end
    }
}

s12['wolf-den-demonic-spell'] = {
    ['ids'] = {'abelon'},
    ['events'] = {
        insertEvents(subscene_demonic)
    },
    ['result'] = {
        ['state'] = 'kath-saw-spell'
    }
}

s12['wolf-den-kath-defeat'] = {
    ['ids'] = {'abelon'},
    ['events'] = {
        insertEvents(subscene_kath_defeat)
    },
    ['result'] = {

    }
}

s12['wolf-den-abelon-defeat'] = {
    ['ids'] = {'abelon'},
    ['events'] = {
        insertEvents(subscene_abelon_defeat)
    },
    ['result'] = {

    }
}

s12['wolf-den-elaine-defeat'] = {
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

s12['wolf-den-turnlimit-defeat'] = {
    ['ids'] = {'abelon'},
    ['events'] = {
        insertEvents(subscene_turnlimit_defeat)
    },
    ['result'] = {

    }
}

s12['wolf-den-victory'] = {
    ['ids'] = {'abelon'},
    ['events'] = {

    },
    ['result'] = {
        ['do'] = function(g)
            local k = g.sprites['kath']
            local a = g.sprites['abelon']
            local e = g.sprites['elaine']
            local seen = find(g.player.old_tutorials, "Experience and skill learning")
            if k.level > 8 or a.level > 8 or e.level > 3 then
                g:startTutorial("Experience and skill learning")
            end
        end
    }
}

s12['north-transition'] = {
    ['ids'] = {'abelon', 'kath', 'elaine', 'notice'},
    ['events'] = {
        face(2, 1),
        pan(0, 100, 200),
        say(2, 1, false, 
            "Go on ahead, Abelon. I'll be right behind you. I'm just packing up a \z
             few supplies."
        ),
        br(function(g) return g.state['elaine-stays'] end, {
            lookAt(3, 1),
            say(3, 3, false,
                "I'll go with you, Sir Abelon!"
            )
        }),
        say(2, 3, false, 
            "Keep an eye out for more of those worn-down stone markers in the \z
             ground. Shanti guessed that they would point towards whatever's left of this \z
             monastery we're after. It shouldn't take long for us to catch up with them."
        ),
        say(2, 2, false, 
            "Let's pray they haven't encountered any trouble of their own..."
        ),
        wait(1),
        say(4, 1, false,
            "Chapter 1-3 is still under construction. Feel free to explore the \z
             area or complete the optional challenge battle if you have not already. \z
             Thank you for playing this demo!"
        )
    },
    ['result'] = {

    }
}