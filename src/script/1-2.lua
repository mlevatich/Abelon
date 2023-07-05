require 'src.script.Util'

s12 = {}

before_wolves = {
    lookAt(2, 1),
    say(2, 3, false,
        "Lester woke up early and announced he was heading towards the ruins \z
         to start looking for the ritual site. I told him it was idiotic to \z
         go alone, of course, but he wasn't having it."
    ),
    say(2, 2, true,
        "More likely is he didn't want to linger around camp with you here. \z
         I'm sure you're aware he's not exactly fond of you."
    ),
    choice({
        {
            ['response'] = "An understatement",
            ['events'] = {
                say(2, 1, true,
                    "Well, I can only assure you it wasn't my influence. He \z
                     may be a knight under my command, but I didn't teach him \z
                     to disrespect you."
                ),
                choice({
                    {
                        ['response'] = "Naturally",
                        ['events'] = {
                            wait(0.5),
                            say(2, 2, false,
                                "Naturally..."
                            )
                        },
                        ['result'] = {}
                    },
                    {
                        ['response'] = "I appreciate it",
                        ['events'] = {
                            say(2, 2, false,
                                "You appreciate that I... haven't been slandering \z
                                 you behind your back."
                            ),
                            wait(1),
                            say(2, 3, false,
                                "I suppose I shouldn't be surprised your standards \z
                                 are low for such things."
                            )
                        },
                        ['result'] = {
                            ['impressions'] = {0, 1}
                        }
                    },
                    {
                        ['response'] = "So you're an admirer of mine?",
                        ['events'] = {
                            say(2, 1, false,
                                "Ha."
                            )
                        },
                        ['result'] = {
                            ['awareness'] = {0, 1}
                        }
                    }
                })
            },
            ['result'] = {}
        },
        {
            ['response'] = "Is he not?",
            ['events'] = {
                say(2, 1, false,
                    "Are you... Was that a joke, old man? We've heard nothing \z
                     but dour muttering and veiled insults from him ever since \z
                     he was assigned to this expedition."
                ),
                say(2, 2, true,
                    "One would think he'd be honored to have been chosen to \z
                     join us. But having to take orders from Captain Abelon \z
                     has ruined it for him, I suppose."
                ),
                choice({
                    {
                        ['response'] = "You sound resentful",
                        ['events'] = {
                            say(2, 1, false,
                                "Yes, that I have to listen to his complaining. \z
                                 But don't mistake me - he's served under me for \z
                                 years, and we've been friends for even longer. \z
                                 It would be more odd if he didn't annoy me time \z
                                 and again."
                            ),
                            say(2, 1, false,
                                "He's a peerless warrior. Present company \z
                                excluded, of course. But I'm grateful to have \z
                                him along."
                            )
                        },
                        ['result'] = {}
                    },
                    {
                        ['response'] = "He should count himself lucky",
                        ['events'] = {
                            say(2, 2, false,
                                "Hm. Does a knight ever consider himself lucky \z
                                 to be given a task of unparalleled danger? \z
                                 There's no guarantee that this ritual works, \z
                                 or that we even return alive... But I digress."
                            )
                        },
                        ['result'] = {}
                    }
                })
            },
            ['result'] = {
                ['awareness'] = {0, 1}
            }
        },
        {
            ['response'] = "He has no right",
            ['events'] = {
                say(2, 3, true,
                    "I couldn't disagree more, Abelon. History will judge whether \z
                     His Majesty made the right decision, but what it put Lester's \z
                     family through... no one should have to endure that."
                ),
                choice({
                    {
                        ['response'] = "Yet he became a knight",
                        ['events'] = {
                            say(2, 3, false,
                                "On the condition that he would serve under me, \z
                                 and not you, yes. And he rather quickly became \z
                                 my best warrior. But one does wonder why he \z
                                 would volunteer to directly serve the King, \z
                                 after all that happened."
                            )
                        },
                        ['result'] = {}
                    },
                    {
                        ['response'] = "Many have endured worse",
                        ['events'] = {
                            say(2, 3, false,
                                "And so will affairs in the city continue, until \z
                                 the shroud of Despair is lifted from Ebonach and \z
                                 monsters plague us no more. On that, at least, \z
                                 we will always agree."
                            )
                        },
                        ['result'] = {}
                    }
                })
            },
            ['result'] = {
                ['impressions'] = {1, 0}
            }
        },
        {
            ['response'] = "I can hardly blame him",
            ['events'] = {
                wait(1),
                say(2, 2, true,
                    "I'm... surprised to hear you say that. You've not once \z
                     seemed apologetic about the whole affair in all the years \z
                     since it happened."
                ),
                choice({
                    {
                        ['response'] = "I'm not, but I understand his anger",
                        ['events'] = {
                            say(2, 3, false,
                                "Yes, it was... awful. For everyone involved. \z
                                 I know His Majesty felt it was necessary but... \z
                                 ah, it's not the time nor place to dwell on it."
                            )
                        },
                        ['result'] = {}
                    },
                    {
                        ['response'] = "It was a mistake",
                        ['events'] = {
                            wait(1),
                            say(2, 3, false,
                                "..."
                            ),
                            wait(1),
                            say(2, 3, false,
                                "Do you... actually mean that? By the goddess, it's \z
                                 like you've woken up a different person. I don't \z
                                 believe it... and I wonder how Lester would react..."
                            )
                        },
                        ['result'] = {
                            ['impressions'] = {-1, 0},
                            ['awareness'] = {0, 1},
                            ['state'] = "abelon-mistake"
                        }
                    }
                })
            },
            ['result'] = {
                ['awareness'] = {0, 1}
            }
        }
    }),
}
s12['battle'] = {
    ['ids'] = {'abelon', 'kath', 'wolf1', 'wolf2', 'wolf3', 'alphawolf'},
    ['events'] = {
        blackout(),
        daytime(),
        wait(1),
        chaptercard(),
        -- TODO: combatReady(2),
        say(2, 0, false, "Abelon, wake up. Quickly."),
        say(2, 0, false, "And fetch your scabbard."),
        wait(1),
        say(2, 0, false, "Abelon?"),
        fade(0.2),
        wait(1),
        -- TODO: getUp(1),
        wait(3),
        focus(2, 100),
        say(2, 3, true,
            "Can you sense it? They're hanging back for now, watching us. \z
             But they'll attack soon enough."
        ),
        choice({
            {
                ['response'] = "Yes",
                ['events'] = {},
                ['result'] = {}
            },
            {
                ['response'] = "What?",
                ['events'] = {
                    say(2, 3, false,
                        "Wolves, Abelon. Hurry and shake off whatever dreams \z
                         you were having, and draw your sword."
                    )
                },
                ['result'] = {}
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
                ['response'] = "Where are they?",
                ['events'] = before_wolves,
                ['result'] = {}
            },
            {
                ['response'] = "Who are you?",
                ['events'] = {
                    lookAt(2, 1),
                    say(2, 3, false,
                        "What? Goddess, Abelon, wake yourself up already! You \z
                         aren't old enough to be getting senile yet! Here, you \z
                         were asleep, so I'll fill you in."
                    ),
                    insertEvents(before_wolves)
                },
                ['result'] = {
                    ['impressions'] = {-1, 0},
                    ['awareness'] = {0, 1}
                }
            }
        }),
        wait(1),
        brState('carried-elaine',
            {
                say(2, 2, false,
                    "In any case, since there was no swaying him, I had Shanti \z
                     go with him. She was dreadfully curious about this child you \z
                     brought back to camp, of course, but we'll have to discuss \z
                     further when we rejoin them."
                ),
                say(2, 1, false,
                    "I've healed her internal injuries, but she hasn't yet \z
                     woken up. I must say, I'm terribly interested in who she \z
                     is as well. And how you came to bring her here..."
                )
            },
            {
                say(2, 2, false,
                    "In any case, since there was no swaying him, I had Shanti go \z
                     with him. Better that we move in pairs, in the event that... \z
                     something exactly like this happens."
                )
            }
        ),
        lookDir(2, LEFT),
        -- TODO: wolves should teleport off camera and move in dramatically
        -- as the camera pans around
        teleport(3, 46, 8),
        lookAt(3,1),
        teleport(4, 56, 9),
        lookAt(4,1),
        teleport(5, 46, 16),
        lookAt(5,1),
        teleport(6, 47, 17),
        lookAt(6,1),
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
s12['select-kath'] = {
    ['ids'] = {'kath'},
    ['events'] = {
        focus(1, 170),
        introduce("kath"),
        say(1, 1, false,
            "Captain Kath of Lefellen, at your command!"
        )
    },
    ['result'] = {}
}
s12['select-abelon'] = {
    ['ids'] = {'kath'},
    ['events'] = {
        say(1, 3, false,
            "We ought to stay close if possible, so we can assist each other."
        ),
        say(1, 3, false,
            "We're surrounded, but we can't let them attack as a group... \z
             Best to strike quickly and finish off one of them to buy \z
             ourselves some space."
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
    ['result'] = {
        ['do'] = function(g)
            g:startTutorial("Battle: Assists")
        end
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
s12['enemy-turn-1'] = {
    ['ids'] = {'kath'},
    ['events'] = {
        focus(1, 170),
        say(1, 3, false,
            "Watch yourself, Abelon!"
        )
    },
    ['result'] = {}
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
s12['ally-turn-3'] = {
    ['ids'] = {'abelon', 'kath', 'elaine'},
    ['events'] = {
        brState('carried-elaine',
            {
                focus(3, 130),
                waitForEvent('camera'),
                say(3, 2, false, "Mmh..."),
                -- getUp(3),
                pan(0, 50, 100),
                waitForEvent('camera'),
                lookAt(2, 3),
                wait(0.5),
                lookAt(1, 2),
                say(2, 1, false, "About time she started coming to. Hm, I wonder..."),
                lookDir(3, LEFT),
                wait(0.3),
                lookDir(3, RIGHT),
                wait(0.3),
                lookDir(3, LEFT),
                wait(0.3),
                say(3, 2, false, "W-where am I? What's going on?"),
                say(2, 1, false, 
                    "Sensible questions, but we don't have time to answer them until \z
                     we've dealt with these wolves. What I want to know is, can \z
                     you help?"
                ),
                walk(false, 3, 53, 5, 'walk'),
                waitForEvent('walk'),
                lookAt(3, 2),
                say(3, 2, false, "Help? W-what?"),
                say(2, 1, false,
                    "You have a bow, and arrows. I assume you're familiar with \z
                     how to use them."
                ),
                wait(0.5),
                say(3, 2, true, "Bow and... Oh Goddess, you want me to fight? I..."),
                choice({
                    {
                        ['response'] = "Your assistance would be welcome",
                        ['events'] = {},
                        ['result'] = {}
                    },
                    {
                        ['response'] = "We can't trust her",
                        ['events'] = {
                            say(2, 2, false,
                                "What, you think she's our enemy? I have a hard \z
                                 time believing that, given the state you \z
                                 brought her in. I would expect more competence \z
                                 from a spy or traitor. Anyway, she's a child."
                            )
                        },
                        ['result'] = {
                            ['impressions'] = {1, 0, 0}
                        }
                    },
                    {
                        ['response'] = "Kath, she's a child",
                        ['events'] = {
                            say(2, 3, false,
                                "And what are you, her mother? All three of us \z
                                 are in danger, and child or not, she has a \z
                                 weapon."
                            )
                        },
                        ['result'] = {
                            ['impressions'] = {-1, 0, 0},
                            ['awareness'] = {0, 1, 0}
                        }
                    },
                    {
                        ['response'] = "...",
                        ['events'] = {},
                        ['result'] = {}
                    }

                }),
                wait(0.5),
                say(2, 1, false,
                    "Miss, if you fight, we'll protect you."
                ),
                focus(3, 100),
                walk(false, 3, 52, 5, 'walk'),
                waitForEvent('walk'),
                say(3, 2, false,
                    "I've never shot a w-wolf before. They're... Goddess, \z
                     they're terrifying up close... But..."
                ),
                wait(1),
                walk(false, 3, 52, 7, 'walk'),
                say(3, 3, false,
                    "...Ok. I can help. I'm ready."
                ),
                waitForEvent('walk'),
                focus(2, 150),
                say(2, 1, false,
                    "Look at that, Abelon! She's only just woken up, but she \z
                     has a knight's courage. Lucky us."
                ),
                wait(0.5),
                say(2, 3, false,
                    "Listen to me. Shoot them while they're circling one of us, \z
                     and go for the kill, or you'll risk drawing their \z
                     attention to you. We can parry their fangs - you can't."
                ),
                focus(3, 150),
                waitForEvent('camera'),
                -- combatReady(3),
                say(3, 3, false,
                    "R-right. Ok... Pretend it's a rabbit... Like shooting a \z
                     rabbit... Breathe deep..."
                )
            },
            {
                -- TODO
                -- Elaine teleports, looks left
                -- Camera pans right to elaine
                -- elaine walks left, pauses
                -- Elaine speaks
                -- Kath looks at Elaine
                -- Camera pans back to Kath
                -- Kath speaks
                -- Abelon faces Elaine
            }
        )
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
s12['demonic-spell'] = {
    ['ids'] = {'kath', 'abelon'},
    ['events'] = {
        focus(1, 170),
        face(1, 2),
        say(1, 3, true,
            "By Ignus, what the hell did you just do, Abelon? I've \z
             never seen such unbelievable magic!"
        ),
        choice({
            {
                ['response'] = "You haven't?",
                ['events'] = {
                    say(1, 1, false,
                        "No, I haven't, in all the countless battles I've \z
                         fought by your side. You aren't really trying to tell \z
                         me you've been conjuring hellfire all this time and I \z
                         just wasn't paying attention!"
                    )
                },
                ['result'] = {
                    ['awareness'] = {1}
                }
            },
            {
                ['response'] = "A useful spell I recently learned",
                ['events'] = {
                    wait(1),
                    say(1, 2, false,
                        "...You have a habit of understating things somewhat."
                    )
                },
                ['result'] = {}
            }
        }),
        wait(0.5),
        say(1, 1, false,
            "Well, I insist you teach me that incantation when we return to town."
        ),
        say(1, 1, false,
            "Oh, but don't waste your entire supply of Ignea on a mere few \z
             wolves. I expect we'll face many more battles before we return \z
             to Ebonach, and I can tell that was no cheap cantrip."
        )
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
s12['elaine-defeat'] = {
    ['ids'] = {'kath', 'elaine'},
    ['events'] = {
        focus(1, 170),
        wait(0.5),
        lookAt(1, 2),
        say(2, 2, false,
            "Ahhh!"
        ),
        say(1, 2, false,
            "No! We couldn't protect her..."
        )
    },
    ['result'] = {}
}
s12['turnlimit-defeat'] = {
    ['ids'] = {'kath', 'abelon'},
    ['events'] = {
        focus(1, 170),
        wait(0.5),
        lookAt(2, 1),
        say(1, 2, false,
            "We're losing daylight, and we've not even found the ruins we're \z
             looking for. And the longer we're out here, the more monsters will \z
             arrive... To say nothing of how Lester and Shanti fare..."
        ),
        say(1, 2, false,
            "...could it be this expedition has already failed?"
        )
    },
    ['result'] = {}
}
choices_carried_elaine = {
    {
        ['response'] = "The greatest knights?",
        ['events'] = {
            say(2, 1, true,
                "What, you disagree?"
            ),
            choice({
                {
                    ['response'] = "I suppose not",
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
                    ['response'] = "You aren't yet worthy of that title",
                    ['events'] = {
                        say(2, 1, false,
                            "Bah! Says the old man to the youngest Knight \z
                             Captain in the Kingdom's history. And it won't be \z
                             long before I finally best you in a proper duel, \z
                             either. Time is on my side, Abelon."
                        )
                    },
                    ['result'] = {}
                },
                {
                    ['response'] = "I'm not quite worthy of that title",
                    ['events'] = {
                        wait(1),
                        say(2, 2, false,
                            "...You can't really mean that, can you? If \z
                             there isn't a knight in Ebonach who can match \z
                             you in a duel, who exactly are you competing with?"
                        ),
                        say(2, 1, false,
                            "Unless you think the title of greatest demands a \z
                             winning personality. In which case, yes, you're \z
                             dead last."
                        )
                    },
                    ['result'] = {
                        ['impressions'] = {-1, 0, 0},
                        ['awareness'] = {0, 1, 0}
                    }
                }
            })
        },
        ['result'] = {}
    },
    {
        ['response'] = "...",
        ['events'] = {},
        ['result'] = {}
    }
}
choices_not_carried_elaine = addChoice(choices_carried_elaine, {
    ['response'] = "Kath, the girl",
    ['events'] = {
        say(2, 3, false,
            "Of course."
        )
    },
    ['result'] = {}
})
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
            "*Huff* Hah, it's over. Poor beasts. Someone should have told \z
             them they were picking a fight with the greatest knights in all \z
             the Kingdom!"
        ),
        focus(1, 100),
        brState('carried-elaine', 
            { choice(choices_carried_elaine) },
            { choice(choices_not_carried_elaine) }
        ),
        lookAt(2, 3),
        focus(3, 100),
        say(2, 3, false,
            "Now then..."
        )
    },
    ['result'] = {
        ['do'] = function(g) 
            g:healAll()
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



s12['kath'] = {
    ['ids'] = {'abelon', 'kath'},
    ['events'] = {
        face(1, 2),
        say(2, 1, false,
            "We've done it. Now it's time to find Lester and Shanti."
        )
    },
    ['result'] = {}
}



s12['elaine'] = {
    ['ids'] = {'abelon', 'elaine'},
    ['events'] = {
        face(1, 2),
        say(2, 1, false,
            "Thank you for rescuing me!"
        )
    },
    ['result'] = {}
}



s12['book'] = {
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
s12['book-callback'] = {
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