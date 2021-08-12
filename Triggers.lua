require 'Util'
require 'Constants'
require 'Scripts'

function areaTrigger(xTrigger, yTrigger, scene_id)
    return function(c)
        local x, y = c.player:getPosition()
        local tile = c.current_map:tileAt(x, y)
        if xTrigger(tile['x']) and yTrigger(tile['y']) then
            return scene_id
        end
        return nil
    end
end

function simpleTrigger(check, action)
    return function(c)
        if check(c) then
            action(c)
            return DELETE
        else
            return nil
        end
    end
end

kathMedallionResponse = simpleTrigger(
    function(c)
        return c.state['kath_interact_base'] and
               c.player:has('Silver medallion')
    end,
    function(c)
        switchScriptFor('kath', 'kath_medallion_response')
    end
)

pickUpMedallion = simpleTrigger(
    function(c)
        return c.state['pick_up_medallion']
    end,
    function(c)
        c:dropSprite('medallion')
        c.player:acquire({ ['name'] = "Silver medallion", ['action'] = pass })
    end
)

meetKath = areaTrigger(
    function(x) return x > 25 end,
    function(y) return true end,
    'meet_kath'
)

triggers = {
    pickUpMedallion,
    kathMedallionResponse,
    meetKath
}
