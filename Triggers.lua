require 'Util'
require 'Constants'

require 'Scripts'

function mkAreaTrigger(xTrigger, yTrigger, scene_id)
    return function(c)
        local x, y = c.player:getPosition()
        local tile = c.current_map:tileAt(x, y)
        if xTrigger(tile['x']) and yTrigger(tile['y']) then
            return scene_id
        end
        return nil
    end
end

function mkSimpleTrigger(check, action)
    return function(c)
        if check(c) then
            action(c)
            return DELETE
        else
            return nil
        end
    end
end

kathMedallionResponse = mkSimpleTrigger(
    function(c)
        return c.state['kath_interact_base'] and
               c.player:has('medallion')
    end,
    function(c)
        switchScriptFor('kath', 'kath_medallion_response')
    end
)

meetKath = mkAreaTrigger(
    function(x) return x > 25 end,
    function(y) return true end,
    'meet_kath'
)

triggers = {
    kathMedallionResponse,
    meetKath
}
