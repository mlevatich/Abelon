require 'src.script.Util'

sall = {}

subscene_take_scroll = {
    say(2, 1, false, 
        "You carefully roll up the scroll and place it in your pack."
    )
}

sall['scroll-callback'] = {
    ['ids'] = {'abelon', 'scroll'},
    ['events'] = {
        lookAt(1, 2),
        say(2, 1, true, 
            "The scroll rests unmoving on the ground."
        ),
        choice({
            {
                ["guard"] = function(g) return true end,
                ["response"] = "Pick it up",
                ['events'] = {
                    insertEvents(subscene_take_scroll)
                },
                ['result'] = {
                    ['do'] = function(g)
                        g.player:acquire(g:getMap():dropSprite('scroll'))
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

sall['scroll'] = {
    ['ids'] = {'abelon', 'scroll'},
    ['events'] = {
        lookAt(1, 2),
        introduce('scroll'),
        say(2, 1, false, 
            "An unfurled scroll lies among the twigs and leaves of the forest \z
             floor. It is full of strange drawings and scrawled paragraphs resembling \z
             instructions."
        ),
        say(2, 1, true, 
            "The writing is faded and barely legible, and the parchment feels as \z
             though it would crumble to dust at the slightest gust of wind."
        ),
        choice({
            {
                ["guard"] = function(g) return true end,
                ["response"] = "Pick it up",
                ['events'] = {
                    insertEvents(subscene_take_scroll)
                },
                ['result'] = {
                    ['do'] = function(g)
                        g.player:acquire(g:getMap():dropSprite('scroll'))
                    end
                }
            },
            {
                ["guard"] = function(g) return true end,
                ["response"] = "Leave it",
                ['events'] = {

                },
                ['result'] = {
                    ['callback'] = { 'scroll-callback', false }
                }
            }
        })
    },
    ['result'] = {

    }
}

subscene_take_medallion = {
    say(2, 1, false, 
        "You brush the dirt off of the medallion and place it in your pack."
    )
}

sall['medallion-callback'] = {
    ['ids'] = {'abelon', 'medallion'},
    ['events'] = {
        lookAt(1, 2),
        say(2, 1, true, 
            "The medallion glimmers on the forest floor, reflecting light."
        ),
        choice({
            {
                ["guard"] = function(g) return true end,
                ["response"] = "Pick it up",
                ['events'] = {
                    insertEvents(subscene_take_medallion)
                },
                ['result'] = {
                    ['do'] = function(g)
                        g.player:acquire(g:getMap():dropSprite('medallion'))
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

sall['medallion'] = {
    ['ids'] = {'abelon', 'medallion'},
    ['events'] = {
        lookAt(1, 2),
        introduce('medallion'),
        say(2, 1, true, 
            "On the ground is a silver medallion, strung with a thin rope and \z
             smeared with dirt. The image of a round shield over a longsword is engraved \z
             in the metal."
        ),
        choice({
            {
                ["guard"] = function(g) return true end,
                ["response"] = "Pick it up",
                ['events'] = {
                    insertEvents(subscene_take_medallion)
                },
                ['result'] = {
                    ['do'] = function(g)
                        g.player:acquire(g:getMap():dropSprite('medallion'))
                    end
                }
            },
            {
                ["guard"] = function(g) return true end,
                ["response"] = "Leave it",
                ['events'] = {

                },
                ['result'] = {
                    ['callback'] = { 'medallion-callback', false }
                }
            }
        })
    },
    ['result'] = {

    }
}

function mkIgneaShardDialogue(n)
    local s = 'igneashard' .. tostring(n)
    return {
        lookAt(1, 2),
        introduce(s),
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
                        g.player:acquire(g:getMap():dropSprite(s))
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
    }
end

sall['igneashard1'] = {
    ['ids'] = {'abelon', 'igneashard1'},
    ['events'] = mkIgneaShardDialogue(1),
    ['result'] = {}
}
sall['igneashard2'] = {
    ['ids'] = {'abelon', 'igneashard2'},
    ['events'] = mkIgneaShardDialogue(2),
    ['result'] = {}
}
sall['igneashard3'] = {
    ['ids'] = {'abelon', 'igneashard3'},
    ['events'] = mkIgneaShardDialogue(3),
    ['result'] = {}
}
sall['igneashard4'] = {
    ['ids'] = {'abelon', 'igneashard4'},
    ['events'] = mkIgneaShardDialogue(4),
    ['result'] = {}
}
sall['igneashard5'] = {
    ['ids'] = {'abelon', 'igneashard5'},
    ['events'] = mkIgneaShardDialogue(5),
    ['result'] = {}
}
sall['igneashard6'] = {
    ['ids'] = {'abelon', 'igneashard6'},
    ['events'] = mkIgneaShardDialogue(6),
    ['result'] = {}
}
sall['igneashard7'] = {
    ['ids'] = {'abelon', 'igneashard7'},
    ['events'] = mkIgneaShardDialogue(7),
    ['result'] = {}
}
sall['igneashard8'] = {
    ['ids'] = {'abelon', 'igneashard8'},
    ['events'] = mkIgneaShardDialogue(8),
    ['result'] = {}
}
sall['igneashard9'] = {
    ['ids'] = {'abelon', 'igneashard9'},
    ['events'] = mkIgneaShardDialogue(9),
    ['result'] = {}
}