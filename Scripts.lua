require 'Util'
require 'Constants'

-- Split a string into several lines of text based on a maximum
-- number of characters per line, without breaking up words
function splitByCharLimit(text, char_limit)

    local lines = {}
    local i = 1
    local line_num = 1
    local holdover_word = ''
    while i <= #text do
        lines[line_num] = ''
        local word = holdover_word
        for x = 1, char_limit - #holdover_word do
            if i == #text then
                lines[line_num] = lines[line_num] .. word .. text:sub(i,i)
                i = i + 1
                break
            else
                local c = text:sub(i,i)
                if c == ' ' then
                    lines[line_num] = lines[line_num] .. word .. ' '
                    word = ''
                else
                    word = word .. c
                end
                i = i + 1
            end
        end
        holdover_word = word
        line_num = line_num + 1
    end
    return lines
end

function addEvents(scene, e, at)
    for i = 1, #e do
        table.insert(scene.script['events'], at, e[#e + 1 - i])
    end
end

function br(test, args, t_events, f_events)
    return function(scene)
        packed = {}
        getI = function(p) return scene.participants[p]:getImpression() end
        getA = function(p) return scene.participants[p]:getAwareness() end
        for i = 1, #args do
            packed[i] = ite(args[i][2] == 'i', getI(args[i][1]), getA(args[i][1]))
        end
        if test(unpack(packed)) then
            addEvents(scene, t_events, scene.event + 1)
        else
            addEvents(scene, f_events, scene.event + 1)
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
        sp = scene.participants[p1]
        scene.cam_lock = sp
        scene.cam_offset_x = 0
        scene.cam_offset_y = 0
        scene.cam_speed = speed
    end
end

function walk(p1, tile_x, tile_y, label)
    return function(scene)
        scene.active_events[label] = true
        sp = scene.participants[p1]
        sp:addBehaviors({
            ['walkTo'] = sp:walkToBehaviorGeneric(scene, tile_x, tile_y, label)
        })
        sp:changeBehavior('walkTo')
    end
end

function choice(op)
    return function (scene)
        scene.text_state['choices'] = mapf(function(c) return c['response'] end, op)
        scene.text_state['choice_result'] = mapf(function(c) return c['result'] end, op)
        scene.text_state['choice_events'] = mapf(function(c) return c['events'] end, op)
        scene.text_state['selection'] = 1
        scene.await_input = true
    end
end

function say(p1, portrait, requires_response, line)
    return function(scene)
        scene.text_state = {
            ['speaker'] = scene.participants[p1],
            ['portrait'] = portrait,
            ['text'] = splitByCharLimit(line, CHARS_PER_LINE),
            ['length'] = #line,
            ['cnum'] = 0,
            ['timer'] = 0
        }
        scene.await_input = not requires_response
    end
end

function _lookAt(sp1, sp2, player)

    -- sp1 stops what they're doing
    if sp1 == player.sp then
        player:stop()
        player:changeAnimation('idle')
    else
        sp1:changeBehavior('idle')
    end

    -- sp1 changes direction to face sp2
    sp1.dir = ite(sp1.x >= sp2.x, LEFT, RIGHT)
end

function face(p1, p2)
    return function(scene)
        _lookAt(scene.participants[p1], scene.participants[p2], scene.player)
        _lookAt(scene.participants[p2], scene.participants[p1], scene.player)
    end
end

function lookAt(p1, p2)
    return function(scene)
        _lookAt(scene.participants[p1], scene.participants[p2], scene.player)
    end
end

function lookDir(p1, dir)
    return function(scene)
        scene.participants[p1].dir = dir
    end
end

kath_interact_1 = {
    ['ids'] = {'abelon', 'kath'},
    ['trigger'] = nil,
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
            walk(2, 21, 73, 'ev-walk-1'),
            say(2, 3, true,
                "Do you know why the One Kingdom of Ebonach and Mistram is \z
                 called Lefally?"
            ),
            choice({
                {
                    ['response'] = "Yes",
                    ['events'] = {
                        say(2, 3, false,
                            "Of course. Everyone does. Lefally, named after the \z
                             proud first city of Lefellen, standing taller than \z
                             the northern forest trees..."
                        ),
                        waitForEvent('ev-walk-1'),
                        say(2, 2, false,
                            "...In the place we now know as The Ash."
                        ),
                        say(2, 2, false,
                            "But Abelon, you probably don't know this one. \z
                             The truth is, I was born in Lefellen, just before \z
                             the dragon attack. Before this whole nightmare \z
                             began..."
                        )
                    },
                    ['result'] = {}
                },
                {
                    ['response'] = "No",
                    ['events'] = {
                        say(2, 3, false,
                            "Ebonach wasn't always the capital. Indeed, at the \z
                             beginning, it didn't exist. Lefally, named after the \z
                             proud city of Lefellen, standing taller than \z
                             the northern trees..."
                        ),
                        waitForEvent('ev-walk-1'),
                        waitForEvent('camera'),
                        pan(0, -300, 80),
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
                        focus(2, 80),
                        waitForEvent('camera'),
                        say(2, 2, false,
                            "I've kept this from you for a long time, but \z
                             the truth is, I was born in Lefellen, just before \z
                             the dragon attack. Before this whole nightmare \z
                             began..."
                        )
                    },
                    ['result'] = {}
                }
            }),
            wait(0.5),
            lookDir(2, LEFT),
            wait(0.5),
            lookDir(2, RIGHT),
            wait(1),
            say(2, 1, false,
                "...Well, that was a nice stroll. I've said all I need to, \z
                 for now."
            ),
            walk(2, 19, 76, 'ev-walk-2')
        },
        {
            say(2, 3, false,
                "I don't trust you, Abelon."
            )
        }),
        focus(1, 100),
        waitForEvent('camera'),
        waitForEvent('ev-walk-2')
    },
    ['result'] = {}
}

book_interact_1 = {
    ['ids'] = {'abelon', 'book'},
    ['trigger'] = nil,
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
}

medallion_interact_1 = {
    ['ids'] = {'abelon', 'medallion'},
    ['trigger'] = nil,
    ['events'] = {
        lookAt(1, 2),
        say(2, 0, true,
            "A silver medallion on a string lies on the ground, smeared with \z
             dirt. The image of a round shield over a longsword is engraved \z
             in the metal."
        ),
        choice({
            {
                ['response'] = "Pick it up",
                ['events'] = {
                    say(2, 0, false,
                        "You brush the dirt off of the medallion and place it \z
                         in your pack."
                    )
                },
                ['result'] = {
                    ['state'] = 'have_medallion',
                    ['gain'] = 'medallion',
                    ['destroy'] = 'medallion'
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
            say(2, 0, true,
                "The medallion shines among the twigs and leaves of the \z
                 forest floor."
            ),
            choice({
                {
                    ['response'] = "Pick it up",
                    ['events'] = {
                        say(2, 0, false,
                            "You brush the dirt off of the medallion and \z
                             place it in your pack."
                        )
                    },
                    ['result'] = {
                        ['state'] = 'have_medallion',
                        ['gain'] = 'medallion',
                        ['destroy'] = 'medallion'
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
}

scripts = {
    ['kath_interact_1'] = kath_interact_1,
    ['book_interact_1'] = book_interact_1,
    ['medallion_interact_1'] = medallion_interact_1
}
