require 'Util'
require 'Constants'

function addEvents(scene, e, at)
    for i = 1, #e do
        table.insert(scene.script['events'], at, e[#e + 1 - i])
    end
end

function br(test, t_events, f_events)
    return function(scene)
        local events = ite(test(scene.chapter), t_events, f_events)
        addEvents(scene, events, scene.event + 1)
    end
end

function brState(key, t_events, f_events)
    return function(scene)
        local events = ite(scene.chapter.state[key], t_events, f_events)
        addEvents(scene, events, scene.event + 1)
    end
end

function waitForText()
    return function(scene)
        if scene.text_state then
            scene.blocked_by = 'text'
        end
    end
end

function waitForEvent(label)
    return function(scene)
        if scene.active_events[label] then
            scene.blocked_by = label
        end
    end
end

function wait(seconds)
    return function(scene)
        scene.active_events['wait'] = seconds
        scene.blocked_by = 'wait'
    end
end

function pan(x, y, speed)
    return function(scene)
        scene.active_events['camera'] = true
        scene.cam_offset_x = x
        scene.cam_offset_y = y
        scene.cam_speed = speed
    end
end

function focus(p1, speed)
    return function(scene)
        scene.active_events['camera'] = true
        local sp = scene.participants[p1]
        scene.cam_lock = sp
        scene.cam_offset_x = 0
        scene.cam_offset_y = 0
        scene.cam_speed = speed
    end
end

function _walk(scene, pathing, sp, tx, ty, label)
    scene.active_events[label] = true
    local move_seq = {}
    if pathing then
        local pth = sp:djikstra(nil, nil, { ty, tx }, nil)
        for i = 1, #pth do
            table.insert(move_seq, function(d)
                return sp:walkToBehaviorGeneric(d, pth[i][2], pth[i][1], false)
            end)
        end
    else
        table.insert(move_seq, function(d)
            return sp:walkToBehaviorGeneric(d, tx, ty, false)
        end)
    end
    sp:behaviorSequence(move_seq, function() scene:release(label) end)
end

function walk(pathing, p1, tx, ty, label)
    return function(scene)
        _walk(scene, pathing, scene.participants[p1], tx, ty, label)
    end
end

function walkTo(pathing, p1, p2, side, label)
    return function(scene)
        local sp1 = scene.participants[p1]
        local sp2 = scene.participants[p2]
        local map = scene.chapter:getMap()
        local x, y = sp2:getPosition()
        local w, h = sp2:getDimensions()
        local sp2_tile = ite(pathing,
            map:tileAt(x + w/2, y + h/2), map:tileAtExact(x, y)
        )
        if not side then side = ite(sp1.x < sp2.x, LEFT, RIGHT) end
        _walk(scene, pathing, sp1, sp2_tile['x'] + side, sp2_tile['y'], label)
    end
end

function teleport(p1, tile_x, tile_y)
    return function(scene)
        local sp1 = scene.participants[p1]
        local m = scene.chapter:getMap()
        local x, y = m:tileToPixels(tile_x, tile_y)
        sp1:resetPosition(x, y)
        if not m:getSprite(sp1:getId()) then
            m:addSprite(sp1)
        end
    end
end

function choice(op)
    return function(scene)
        slect = function(s) return mapf(function(c) return c[s] end, op) end
        scene.text_state['choices'] = slect('response')
        scene.text_state['choice_result'] = slect('result')
        scene.text_state['choice_events'] = slect('events')
        scene.text_state['selection'] = 1
        scene.await_input = true
    end
end

function say(p1, portrait, requires_response, line)
    return function(scene)
        broken, new_length = splitByCharLimit(line, CHARS_PER_LINE)
        scene.text_state = {
            ['speaker'] = ite(p1, scene.participants[p1], nil),
            ['portrait'] = portrait,
            ['text'] = broken,
            ['length'] = new_length,
            ['cnum'] = 0,
            ['cweight'] = 0,
            ['timer'] = 0
        }
        scene.await_input = not requires_response
    end
end

function _lookAt(sp1, sp2)
    sp1:changeBehavior('idle')
    sp1.dir = ite(sp1.x >= sp2.x, LEFT, RIGHT)
end

function face(p1, p2)
    return function(scene)
        _lookAt(scene.participants[p1], scene.participants[p2])
        _lookAt(scene.participants[p2], scene.participants[p1])
    end
end

function lookAt(p1, p2)
    return function(scene)
        _lookAt(scene.participants[p1], scene.participants[p2])
    end
end

function lookDir(p1, dir)
    return function(scene)
        scene.participants[p1].dir = dir
    end
end

function blackout()
    return function(scene)
        scene.chapter.alpha = 0
    end
end

function fade(rate)
    return function(scene)
        scene.chapter.fade_rate = rate
    end
end

function chaptercard(title)
    return function(scene)
        scene.chapter:flash(title, 0.2)
    end
end

function introduce(name)
    return function(scene)
        scene.player:introduce(name)
    end
end

scripts = {

    ['1-1-entry'] = {
        ['ids'] = {'abelon'},
        ['events'] = {
            blackout(),
            wait(2),
            chaptercard("1-1"),
            say(1, 0, false, "..."),
            say(1, 0, false, "............"),
            say(1, 0, false, "...Perhaps I made a mistake somewhere."),
            say(1, 0, false, ".................."),
            say(1, 0, false, "..!"),
            fade(0.15),
            wait(7.5)
        },
        ['result'] = {}
    },

    ['1-1-battle'] = {
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
            ['do'] = function(c)
                c:launchBattle('1-1')
            end
        }
    },

    ['1-1-abelon-defeat'] = {
        ['ids'] = {},
        ['events'] = {},
        ['result'] = {}
    },

    ['1-1-turnlimit-defeat'] = {
        ['ids'] = {},
        ['events'] = {},
        ['result'] = {}
    },

    ['1-1-victory'] = {
        ['ids'] = {},
        ['events'] = {},
        ['result'] = {
            ['do'] = function(c) c:healAll() end
        }
    },

    ['1-2-select-kath'] = {
        ['ids'] = {'kath'},
        ['events'] = {
            focus(1, 170),
            introduce("kath"),
            say(1, 1, false,
                "Captain Kath of Ebonach, at your command!"
            )
        },
        ['result'] = {}
    },

    ['1-2-ally-turn-1'] = {
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
    },

    ['1-2-ally-turn-2'] = {
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
    },

    ['1-2-enemy-turn-1'] = {
        ['ids'] = {'kath'},
        ['events'] = {
            focus(1, 170),
            say(1, 3, false,
                "Here they come!"
            )
        },
        ['result'] = {}
    },

    ['1-2-abelon-demon'] = {
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
    },

    ['1-2-kath-defeat'] = {
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
    },

    ['1-2-abelon-defeat'] = {
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
    },

    ['1-2-turnlimit-defeat'] = {
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
    },

    ['1-2-victory'] = {
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
            br(function(c)
                local abelon = c.sprites['abelon']
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
            ['do'] = function(c) c:healAll() end
        }
    },

    ['medallion-use'] = {
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
    },

    ['elaine-interact-base'] = {
        ['ids'] = {'abelon', 'elaine'},
        ['events'] = {
            face(1, 2),
            introduce("elaine"),
            say(2, 1, false,
                "My name's Elaine. It's nice to meet you! Shall I join your \z
                 party?"
            )
        },
        ['result'] = {
            ['callback'] = 'elaine-interact-callback',
            ['do'] = function(c)
                local elaine = c.sprites['elaine']
                c.player:joinParty(elaine)
            end
        }
    },

    ['elaine-interact-callback'] = {
        ['ids'] = {'abelon', 'elaine'},
        ['events'] = {
            face(1, 2),
            say(2, 1, false,
                "I'm ready to go when you are!"
            )
        },
        ['result'] = {}
    },

    ['kath-interact-base'] = {
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
    },

    ['book-interact-base'] = {
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
            ['callback'] = 'book-interact-callback'
        }
    },

    ['book-interact-callback'] = {
        ['ids'] = {'abelon', 'book'},
        ['events'] = {
            lookAt(1, 2),
            say(2, 0, false,
                "On a second glance, it looks like there's another small book \z
                 beneath the first."
            )
        },
        ['result'] = {}
    },

    ['medallion-interact-base'] = {
        ['ids'] = {'abelon', 'medallion'},
        ['events'] = {
            lookAt(1, 2),
            introduce('medallion'),
            say(2, 1, true,
                "A silver medallion on a string lies on the ground, smeared with \z
                 dirt. The image of a round shield over a longsword is engraved \z
                 in the metal."
            ),
            choice({
                {
                    ['response'] = "Pick it up",
                    ['events'] = {
                        say(2, 1, false,
                            "You brush the dirt off of the medallion and place it \z
                             in your pack."
                        )
                    },
                    ['result'] = {
                        ['do'] = function(c)
                            local sp = c:getMap():dropSprite('medallion')
                            c.player:acquire(sp)
                        end
                    }
                },
                {
                    ['response'] = "Leave it",
                    ['events'] = {},
                    ['result'] = {}
                }
            })
        },
        ['result'] = {
            ['callback'] = 'medallion-interact-base-callback'
        }
    },

    ['medallion-interact-base-callback'] = {
        ['ids'] = {'abelon', 'medallion'},
        ['events'] = {
            lookAt(1, 2),
            say(2, 1, true,
                "The medallion shines among the twigs and leaves of the \z
                 forest floor."
            ),
            choice({
                {
                    ['response'] = "Pick it up",
                    ['events'] = {
                        say(2, 1, false,
                            "You brush the dirt off of the medallion and \z
                             place it in your pack."
                        )
                    },
                    ['result'] = {
                        ['do'] = function(c)
                            local sp = c:getMap():dropSprite('medallion')
                            c.player:acquire(sp)
                        end
                    }
                },
                {
                    ['response'] = "Leave it",
                    ['events'] = {},
                    ['result'] = {}
                }
            })
        },
        ['result'] = {}
    },

    ['medallion-present-kath'] = {
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
                    ['result'] = {
                        ['callback'] = 'medallion-present-kath-callback'
                    }
                },
                {
                    ['response'] = 'Yes',
                    ['events'] = {
                        say(2, 1, false,
                            "Well, how did it end up out here then? I've never \z
                             known you to be careless with your possessions."
                        )
                    },
                    ['result'] = {
                        ['callback'] = 'medallion-present-kath-callback'
                    }
                }
            })
        },
        ['result'] = {}
    },

    ['medallion-present-kath-callback'] = {
        ['ids'] = {'abelon', 'kath'},
        ['events'] = {
            face(1, 2),
            say(2, 1, false,
                "You're quite enchanted by that thing, aren't you?"
            )
        },
        ['result'] = {}
    },

    ['meet-kath'] = {
        ['ids'] = {'abelon', 'kath', 'wolf1', 'wolf2', 'wolf3'},
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
            ['do'] = function(c)
                local kath = c.sprites['kath']
                c.player:joinParty(kath)
                c:launchBattle('1-2')
            end
        }
    }
}
