require 'src.script.Util'

s11 = {}

s11['entry'] = {
    ['ids'] = {'abelon'},
    ['events'] = {
        blackout(),
        wait(1),
        chaptercard(),
        say(1, 0, false, 
            "..."
        ),
        say(1, 0, false, 
            "............"
        ),
        say(1, 0, false, 
            "...Perhaps I made a mistake somewhere."
        ),
        say(1, 0, false, 
            ".................."
        ),
        say(1, 0, false, 
            "..!"
        ),
        fade(0.2),
        wait(6)
    },
    ['result'] = {
        ['do'] = function(g)
            g:startTutorial("Navigating the world")
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
        combatReady(1),
        wait(1)
    },
    ['result'] = {
        ['do'] = function(g)
            g:launchBattle()
        end
    }
}

s11['abelon-defeat'] = {
    ['ids'] = {'abelon'},
    ['events'] = {
        
    },
    ['result'] = {

    }
}

s11['turnlimit-defeat'] = {
    ['ids'] = {'abelon'},
    ['events'] = {
        
    },
    ['result'] = {

    }
}

s11['victory'] = {
    ['ids'] = {'abelon'},
    ['events'] = {
        combatExit(1),
        wait(1)
    },
    ['result'] = {

    }
}

subscene_elaine_interact = {
    choice({
        {
            ["guard"] = function(g) return true end,
            ["response"] = "Leave her",
            ['events'] = {

            },
            ['result'] = {

            }
        },
        {
            ["guard"] = function(g) return true end,
            ["response"] = "Shake her",
            ['events'] = {
                say(2, 0, false, 
                    "You shake the girl gently, but she does not stir."
                )
            },
            ['result'] = {

            }
        },
        {
            ["guard"] = function(g) return not g.state['saw-camp'] end,
            ["response"] = "Carry her",
            ['events'] = {
                say(2, 0, false, 
                    "With her equipment and bag, the girl is heavy and unwieldy to carry. \z
                     You are not sure where you would take her to."
                )
            },
            ['result'] = {

            }
        },
        {
            ["guard"] = function(g) return g.state['saw-camp'] end,
            ["response"] = "Carry her to camp",
            ['events'] = {
                fade(-0.8),
                wait(1.5),
                teleport(2, 54, 5, 'west-forest'),
                teleport(1, 53, 5, 'west-forest'),
                lookAt(1, 2),
                focus(1, 3000),
                say(2, 0, false, 
                    "With effort, you hoist the limp girl and her belongings onto your \z
                     back."
                ),
                wait(1),
                fade(0.4),
                wait(2)
            },
            ['result'] = {
                ['state'] = 'carried-elaine',
                ['impressions'] = {0, 3}
            }
        }
    })
}

s11['elaine-callback'] = {
    ['ids'] = {'abelon', 'elaine'},
    ['events'] = {
        lookAt(1, 2),
        br(function(g) return not g.state['carried-elaine'] end, {
            say(2, 0, true,
                "The young girl is still motionless."
            ),
            insertEvents(subscene_elaine_interact)
        }),
        br(function(g) return g.state['carried-elaine'] end, {
            say(2, 0, false, 
                "The girl lies on her side, taking shallow breaths. She is \z
                 unconscious, but alive."
            )
        })
    },
    ['result'] = {

    }
}

s11['elaine'] = {
    ['ids'] = {'abelon', 'elaine'},
    ['events'] = {
        lookAt(1, 2),
        say(2, 0, true, 
            "It's a young girl with fair skin and fiery hair, facedown on the \z
             ground. She wears the garb of a hunter, with a bow and quiver slung on her \z
             back. She has only minor injuries, but isn't moving."
        ),
        insertEvents(subscene_elaine_interact)
    },
    ['result'] = {
        ['callback'] = { 'elaine-callback', false }
    }
}

s11['see-camp'] = {
    ['ids'] = {'abelon', 'campfire'},
    ['events'] = {
        lookDir(1, LEFT),
        focus(2, 100),
        waitForEvent('camera'),
        wait(2),
        focus(1, 100)
    },
    ['result'] = {
        ['state'] = 'saw-camp'
    }
}

s11['campfire'] = {
    ['ids'] = {'abelon', 'campfire'},
    ['events'] = {
        lookAt(1, 2),
        introduce('campfire'),
        say(2, 1, false, 
            "A campfire. The sticks are blackened, but hot coals still radiate \z
             light. It will die out before morning."
        )
    },
    ['result'] = {

    }
}

s11['book'] = {
    ['ids'] = {'abelon', 'book'},
    ['events'] = {
        lookAt(1, 2),
        introduce('book'),
        say(2, 1, false, 
            "A large book with sturdy but old pages lies open amidst the clutter \z
             of the campsite. It is too difficult to read in the faint moonlight."
        )
    },
    ['result'] = {

    }
}

s11['kath'] = {
    ['ids'] = {'abelon', 'kath'},
    ['events'] = {
        lookAt(1, 2),
        say(2, 0, false, 
            "A well-built man sleeps in the camp bed. His hand extends out of the \z
             bed and rests on a long spear, but a serene expression is just visible on \z
             his face, half-obscured by a tumble of thick black hair."
        )
    },
    ['result'] = {

    }
}

s11['lester'] = {
    ['ids'] = {'abelon', 'lester'},
    ['events'] = {
        lookAt(1, 2),
        say(2, 0, false, 
            "A pale man with blonde hair sleeps with a furrowed brow. He shifts in \z
             his camp bed, occasionally muttering something unintelligible."
        )
    },
    ['result'] = {

    }
}

s11['shanti'] = {
    ['ids'] = {'abelon', 'shanti'},
    ['events'] = {
        lookAt(1, 2),
        say(2, 0, false, 
            "A dark-skinned woman, the oldest of the three by some margin. Her \z
             breathing is steady and rhythmic, and her face betrays nothing but the peace of \z
             deep sleep."
        )
    },
    ['result'] = {

    }
}

subscene_sleep = {
    fade(-0.4),
    wait(3),
    teleport(3, 1, 1, 'north-forest'),
    teleport(4, 1, 1, 'north-forest'),
    teleport(5, 1, 1, 'north-forest'),
    teleport(6, 1, 1, 'north-forest'),
    teleport(7, 1, 1, 'north-forest'),
    teleport(1, 52, 6),
    lookDir(1, LEFT),
    say(1, 0, false, 
        "What is...?"
    ),
    say(1, 0, false, 
        "...Need... I can't..."
    ),
    fadeoutMusic(),
    wait(2)
}

s11['campbed-callback'] = {
    ['ids'] = {'abelon', 'campbed', 'lester', 'shanti', 'campbed-used1', 'campbed-used2', 'campbed-used3'},
    ['events'] = {
        lookAt(1 ,2),
        say(2, 1, true, 
            "The camp bed is still open. It doesn't appear anyone else will be \z
             using it."
        ),
        choice({
            {
                ["guard"] = function(g) return true end,
                ["response"] = "Continue looking around",
                ['events'] = {

                },
                ['result'] = {

                }
            },
            {
                ["guard"] = function(g) return true end,
                ["response"] = "Go to sleep",
                ['events'] = {
                    insertEvents(subscene_sleep)
                },
                ['result'] = {
                    ['state'] = 'finish-1-1'
                }
            }
        })
    },
    ['result'] = {
        ['do'] = function(g)
            if g.state['finish-1-1'] then
                g:nextChapter()
            end
        end
    }
}

s11['campbed'] = {
    ['ids'] = {'abelon', 'campbed', 'lester', 'shanti', 'campbed-used1', 'campbed-used2', 'campbed-used3'},
    ['events'] = {
        lookAt(1 ,2),
        introduce('campbed'),
        say(2, 1, true,
            "An open camp bed. The exterior is made from leather, and the insides \z
             are filled with a soft material. It looks rather well-worn."
        ),
        choice({
            {
                ["guard"] = function(g) return true end,
                ["response"] = "Continue looking around",
                ['events'] = {

                },
                ['result'] = {
                    ['callback'] = { 'campbed-callback', false }
                }
            },
            {
                ["guard"] = function(g) return true end,
                ["response"] = "Go to sleep",
                ['events'] = {
                    insertEvents(subscene_sleep)
                },
                ['result'] = {
                    ['state'] = 'finish-1-1'
                }
            },
            {
                ["guard"] = function(g) return not g.state['carried-elaine'] end,
                ["response"] = "Kill them",
                ['events'] = {
                    mute(),
                    walk(false, 1, 51.3, 6.3, 'walk'),
                    waitForEvent('walk'),
                    walk(false, 1, 54, 8, 'walk'),
                    waitForEvent('walk'),
                    lookDir(1, RIGHT),
                    wait(1),
                    combatReady(1),
                    wait(1),
                    blackout(),
                    wait(1.5),
                    say(1, 0, false, 
                        "I see... Then I was overly concerned."
                    ),
                    say(1, 0, false, 
                        "That is a relief."
                    ),
                    wait(2)
                },
                ['result'] = {
                    ['state'] = 'finish-1-1-bad'
                }
            }
        })
    },
    ['result'] = {
        ['do'] = function(g)
            if g.state['finish-1-1'] then
                g:nextChapter()
            elseif g.state['finish-1-1-bad'] then
                os.exit()
            end
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