require 'Util'
require 'Constants'

function switchScriptFor(sp_id, new_id)
    scripts[sp_id] = scripts[new_id]
end

function addEvents(scene, e, at)
    for i = 1, #e do
        table.insert(scene.script['events'], at, e[#e + 1 - i])
    end
end

function br(test, args, t_events, f_events)
    return function(scene)
        local vars = {}
        getI = function(p) return scene.participants[p]:getImpression() end
        getA = function(p) return scene.participants[p]:getAwareness() end
        for i = 1, #args do
            vars[i] = ite(args[i][2] == 'i', getI(args[i][1]), getA(args[i][1]))
        end
        local events = ite(test(unpack(vars)), t_events, f_events)
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

function walk(p1, tile_x, tile_y, label, first)
    return function(scene)
        scene.active_events[label] = true
        local sp = scene.participants[p1]
        sp:addBehaviors({
            ['walkTo'] = sp:walkToBehaviorGeneric(
                scene,
                tile_x,
                tile_y,
                label,
                first
            )
        })
        sp:changeBehavior('walkTo')
    end
end

function walkTo(p1, p2, label, first)
    return function(scene)
        local sp1 = scene.participants[p1]
        local sp2 = scene.participants[p2]
        local map = scene.chapter:getMap()
        local x, y = sp2:getPosition()
        local sp2_tile = map:tileAtExact(x, y)
        local offset = ite(sp1.x > sp2.x, 1.2, -1.2)
        local tile_x = sp2_tile['x'] + offset
        local tile_y = sp2_tile['y']

        scene.active_events[label] = true
        sp1:addBehaviors({
            ['walkTo'] = sp1:walkToBehaviorGeneric(
                scene,
                tile_x,
                tile_y,
                label,
                first
            )
        })
        sp1:changeBehavior('walkTo')
    end
end

function teleport(p1, tile_x, tile_y)
    return function(scene)
        local sp1 = scene.participants[p1]
        local x, y = scene.chapter:getMap():tileToPixels(tile_x, tile_y)
        sp1:resetPosition(x, y)
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

scripts = {

    ['medallion_use'] = {
        ['ids'] = {'medallion'},
        ['events'] = {
            say(1, 1, false,
                "The silver medallion turns lazily as you hold it by its rope. \z
                 You pull it over your head. The fraying rope itches the back \z
                 of your neck, and the metal lump is inordinatelty heavy. \z
                 Who would wear this? You put it away."
            )
        },
        ['result'] = {}
    },

    ['kath_interact_base'] = {
        ['ids'] = {'abelon', 'kath'},
        ['events'] = {
            face(1, 2),
            focus(2, 100),
            say(2, 1, true,
                "Ho, Abelon! By Ignus, it's good to be alive! I must say, that \z
                 was one of our closer brushes with death. But we made it, as we \z
                 always do."
            ),
            choice({
                {
                    ['response'] = "Thanks to me",
                    ['events'] = {
                        say(2, 1, true,
                            "Yes, that magic was... something, wasn't it. Where \z
                             on Eruta did you discover such spells?"
                        )
                    },
                    ['result'] = {}
                },
                {
                    ['response'] = "Thanks to you",
                    ['events'] = {
                        say(2, 1, true,
                            "Come Abelon, we've known each other too long for \z
                             flattery. That strange magic of yours carried the \z
                             day. Where on Eruta did you discover such spells?"
                        )
                    },
                    ['result'] = {
                        ['awareness'] = {0, 1},
                        ['impressions'] = {-1, 1}
                    }
                },
                {
                    ['response'] = "We were lucky",
                    ['events'] = {
                        say(2, 1, true,
                            "Lucky's one word for it. I would sooner credit those \z
                             unholy spells you started slinging. Where on Eruta \z
                             did you discover such magic?"
                        )
                    },
                    ['result'] = {}
                }
            }),
            focus(2, 50),
            choice({
                {
                    ['response'] = "The Archives",
                    ['events'] = {
                        say(2, 1, false,
                            "You jest! No one makes it through the Ash without a \z
                             battalion and supplies, not to mention it's a week's \z
                             journey. I would have caught wind of this \z
                             expedition, surely!"
                        )
                    },
                    ['result'] = {
                        ['impressions'] = {0, 1},
                        ['callback'] = {
                            face(1, 2),
                            say(2, 1, false,
                                "I'll have to hear more about this trip of yours \z
                                 to the Ash, but perhaps it's best left for \z
                                 another time."
                            )
                        }
                    }
                },
                {
                    ['response'] = "My secret",
                    ['events'] = {
                        say(2, 2, false,
                            "Abelon, that's... quite a thing to keep secret. Ah \z
                             well. I know how you are when you've made up your \z
                             mind."
                        )
                    },
                    ['result'] = {
                        ['impressions'] = {0, -1},
                        ['callback'] = {
                            face(1, 2),
                            say(2, 3, false,
                                "You will tell me eventually, won't you? Or at \z
                                 least His Majesty? If we equipped our mages with \z
                                 those spells of yours, why,"
                            ),
                            say(2, 3, false,
                                "this city might survive the winter after all..."
                            )
                        }
                    }
                }
            }),
            br(function(i) return i > 50 end, {{2, 'i'}}, {
                say(2, 1, false,
                    "I trust you, Abelon."
                ),
                say(2, 3, false,
                    "Let me tell you a little bit about the history of the Kingdom."
                ),
                walk(2, 50, 63, 'walk1', RIGHT),
                wait(1.7),
                walk(1, 48, 63, 'walk2', RIGHT),
                say(2, 3, true,
                    "Do you know why the One Kingdom of Ebonach and Mistram is \z
                     called Lefally?"
                ),
                choice({
                    {
                        ['response'] = "Yes",
                        ['events'] = {
                            say(2, 3, false,
                                "Of course. Everyone does. Lefally, named after \z
                                 the proud first city of Lefellen, standing \z
                                 taller than the northern forest trees..."
                            ),
                            waitForEvent('walk1'),
                            waitForEvent('walk2'),
                            say(2, 2, false,
                                "...In the place we now know as The Ash."
                            ),
                            lookAt(2, 1),
                            say(2, 2, false,
                                "But Abelon, you probably don't know this one. \z
                                 The truth is, I was born in Lefellen, just \z
                                 before the dragon attack. Before this whole \z
                                 nightmare began..."
                            )
                        },
                        ['result'] = {}
                    },
                    {
                        ['response'] = "No",
                        ['events'] = {
                            say(2, 3, false,
                                "Ebonach wasn't always the capital. Indeed, at \z
                                 the beginning, it didn't exist. Lefally, named \z
                                 after the proud city of Lefellen, standing \z
                                 taller than the northern trees..."
                            ),
                            waitForEvent('walk1'),
                            waitForEvent('walk2'),
                            waitForEvent('camera'),
                            pan(0, -600, 200),
                            say(2, 2, false,
                                "...In the place we now know as The Ash."
                            ),
                            say(2, 2, false,
                                "That cold, desolate wasteland, where the once \z
                                 proud trees are now flattened, the city reduced \z
                                 to rubble..."
                            ),
                            waitForEvent('camera'),
                            wait(1),
                            focus(2, 200),
                            lookAt(2, 1),
                            waitForEvent('camera'),
                            say(2, 2, false,
                                "I've kept this from you for a long time, but \z
                                 the truth is, I was born in Lefellen, just \z
                                 before the dragon attack. Before this whole \z
                                 nightmare began..."
                            )
                        },
                        ['result'] = {}
                    }
                }),
                wait(0.2),
                lookDir(2, RIGHT),
                wait(0.5),
                lookDir(2, LEFT),
                wait(1),
                say(2, 1, false,
                    "...Well, that was a nice stroll. I've said all I need to, \z
                     for now."
                ),
            },
            {
                say(2, 3, false,
                    "I don't trust you, Abelon."
                )
            }),
            focus(1, 100),
            waitForEvent('camera')
        },
        ['result'] = {
            ['state'] = 'kath_interact_base'
        }
    },

    ['book_interact_base'] = {
        ['ids'] = {'abelon', 'book'},
        ['events'] = {
            lookAt(1, 2),
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
            ['callback'] = {
                lookAt(1, 2),
                say(2, 0, false,
                    "On a second glance, it looks like there's another small book \z
                     beneath the first."
                )
            }
        }
    },

    ['medallion_interact_base'] = {
        ['ids'] = {'abelon', 'medallion'},
        ['events'] = {
            lookAt(1, 2),
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
            ['callback'] = {
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
            }
        }
    },

    ['medallion_present_kath'] = {
        ['ids'] = {'abelon', 'kath'},
        ['events'] = {
            face(1, 2),
            walkTo(1, 2, 'walk'),
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
                        ['callback'] = {
                            face(1, 2),
                            say(2, 1, false,
                                "You're quite enchanted by that thing, aren't you?"
                            )
                        }
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
                        ['callback'] = {
                            face(1, 2),
                            say(2, 1, false,
                                "You're quite enchanted by that thing, aren't you?"
                            )
                        }
                    }
                }
            })
        },
        ['result'] = {}
    },

    ['meet_kath'] = {
        ['ids'] = {'abelon', 'kath', 'wolf1', 'wolf2'},
        ['events'] = {
            lookAt(2, 1),
            focus(2, 200),
            pan(-200, 0, 100),
            waitForEvent('camera'),
            say(2, 3, false,
                "Abelon! At last!"
            ),
            lookAt(1, 2),
            walk(2, 29, 73, 'walk'),
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
            walkTo(2, 1, 'walk'),
            waitForEvent('walk'),
            lookAt(2, 1),
            wait(1),
            walk(2, 28, 73, 'walk'),
            waitForEvent('walk'),
            lookAt(2, 1),
            teleport(3, 41, 69),
            teleport(4, 42, 73),
            lookAt(3, 1),
            lookAt(4, 1),
            say(2, 3, true,
                "I'll have none of your usual protests about bandages and such, \z
                 that sword arm of yours is well worth my ignea. Did one of the \z
                 wolves follow you here? Did you kill it?"
            ),
            choice({
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
                                    ['state'] = "mentioned_blood_rite"
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
                },
                {
                    ['response'] = "Who are you?",
                    ['events'] = {
                        say(2, 2, false,
                            "...What? Please tell me this is a jest, Abelon..."
                        ),
                        wait(1.5),
                        say(2, 3, false,
                            "Whatever's happened to you here, it's of less \z
                             importance than the battle at the gate. Come, we \z
                             must reinforce our soldiers immediately!"
                        )
                    },
                    ['result'] = {
                        ['awareness'] = {0, 2}
                    }
                }
            }),
            walk(2, 33, 73, 'walk'),
            waitForEvent('walk'),
            wait(0.5),
            say(2, 2, true,
                "Ah. They must have followed me here. I'm sorry, Abelon."
            ),
            waitForText(),
            wait(0.5),
            focus(2, 100),
            pan(150, -50, 100),
            wait(1),
            walk(1, 32, 72, 'walk'),
            waitForEvent('camera'),
            waitForEvent('walk'),
            choice({
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
                },
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
                }
            })
        },
        ['result'] = {
            ['do'] = function(c)
                local kath = c.current_map:getSprite('kath')
                c.player:joinParty(kath)
                c:launchBattle('1-1')
            end
        }
    }
}
