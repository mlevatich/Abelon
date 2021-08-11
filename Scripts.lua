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

function _choice(scene, op)
    scene.text_state['choices'] = mapf(function(c) return c['response'] end, op)
    scene.text_state['choice_result'] = mapf(function(c) return c['result'] end, op)
    scene.text_state['choice_events'] = mapf(function(c) return c['events'] end, op)
    scene.text_state['selection'] = 1
    scene.wait = true
end

function _say(scene, sp, portrait, requires_response, line)
    scene.text_state = {
        ['speaker'] = sp,
        ['portrait'] = portrait,
        ['text'] = splitByCharLimit(line, CHARS_PER_LINE),
        ['length'] = #line,
        ['cnum'] = 0,
        ['timer'] = 0
    }
    scene.wait = not requires_response
end

function _look(sp1, sp2, player)

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

function choice(options)
    return function (scene)
        _choice(scene, options)
    end
end

function say(p1, portrait, requires_response, line)
    return function(scene)
        _say(scene, scene.participants[p1], portrait, requires_response, line)
    end
end

function face(p1, p2)
    return function(scene)
        _look(scene.participants[p1], scene.participants[p2], scene.player)
        _look(scene.participants[p2], scene.participants[p1], scene.player)
    end
end

function look(p1, p2)
    return function(scene)
        _look(scene.participants[p1], scene.participants[p2], scene.player)
    end
end

kath_interact_1 = {
    ['ids'] = {'abelon', 'kath'},
    ['trigger'] = nil,
    ['events'] = {
        face(1, 2),
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
            )
        },
        {
            say(2, 3, false,
                "I don't trust you, Abelon."
            )
        })
    },
    ['result'] = {}
}

book_interact_1 = {
    ['ids'] = {'abelon', 'book'},
    ['trigger'] = nil,
    ['events'] = {
        look(1, 2),
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
            look(1, 2),
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
        look(1, 2),
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
            look(1, 2),
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
