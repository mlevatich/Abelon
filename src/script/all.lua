require 'src.script.Util'

sall = {}

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