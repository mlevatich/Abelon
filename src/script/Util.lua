require 'src.Util'
require 'src.Constants'
require 'src.Music'

function addEvents(scene, e, at)
    for i = 1, #e do
        table.insert(scene.script['events'], at, e[#e + 1 - i])
    end
end

function insertEvents(events)
    return function(scene)
        addEvents(scene, events, scene.event + 1)
    end
end

function changeMusic(track, offset)
    if not offset then offset = 0 end
    return function(scene)
        scene.game:stopMusic()
        scene.game.current_music = track
        scene.game:modMusicVolume(1, 10000)
        music_tracks[track]:jumpTo(offset)
    end
end

function fadeoutMusic()
    return function(scene)
        scene.game:modMusicVolume(0, 1)
    end
end

function mute()
    return function(scene)
        scene.game:stopMusic()
    end
end

function br(test, events)
    return function(scene)
        if test(scene.game) then
            addEvents(scene, events, scene.event + 1)
        end
    end
end

function brState(key, t_events, f_events)
    return function(scene)
        local events = ite(scene.game.state[key], t_events, f_events)
        addEvents(scene, events, scene.event + 1)
    end
end

function brPresent(p1, t_events, f_events)
    return function(scene)
        local stat = scene.game.battle.status
        local sp = scene.participants[p1]
        local events = ite(stat[sp:getId()]['inbattle'], t_events, f_events)
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

function unlockCamera()
    return function(scene)
        scene.cam_speed = 0
    end
end

function putOut(p1)
    return function(scene)
        local sp = scene.participants[p1]
        sp:changeBehavior('down')
    end
end

function light(p1)
    return function(scene)
        local sp = scene.participants[p1]
        sp:changeBehavior('idle')
    end
end

function getUp(p1)
    return function(scene)
        local sp = scene.participants[p1]
        sp:behaviorSequence({ function(d) return sp:animateBehaviorGeneric(d, 'getup') end }, function() sp:changeBehavior('idle') end)
    end
end

function combatReady(p1)
    return function(scene)
        local sp = scene.participants[p1]
        sp:behaviorSequence({ function(d) return sp:animateBehaviorGeneric(d, 'combat-entry') end }, function() sp:changeAnimation('combat') end)
    end
end

function combatExit(p1)
    return function(scene)
        local sp = scene.participants[p1]
        sp:behaviorSequence({ function(d) return sp:animateBehaviorGeneric(d, 'combat-exit') end }, function() sp:changeBehavior('idle') end)
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
        local map = scene.game:getMap()
        local x, y = sp2:getPosition()
        local w, h = sp2:getDimensions()
        local sp2_tile = ite(pathing,
            map:tileAt(x + w/2, y + h/2), map:tileAtExact(x, y)
        )
        if not side then side = ite(sp1.x < sp2.x, LEFT, RIGHT) end
        _walk(scene, pathing, sp1, sp2_tile['x'] + side, sp2_tile['y'], label)
    end
end

function teleport(p1, tile_x, tile_y, mapname)
    return function(scene)
        if mapname == nil then
            mapname = scene.game.current_map:getName()
        end
        local sp1 = scene.participants[p1]
        local x, y = tileToPixels(tile_x, tile_y)
        scene.game:warpSprite(sp1, x, y, mapname)
        if sp1 == scene.game.player.sp then
            scene.game:changeMapTo(mapname)
        end
    end
end

function choiceNoGuard(op)
    return function(scene)
        slect = function(s) return mapf(function(c) return c[s] end, op) end
        scene.text_state['choices'] = slect('response')
        scene.text_state['choice_result'] = slect('result')
        scene.text_state['choice_events'] = slect('events')
        scene.text_state['selection'] = 1
        scene.await_input = true
    end
end

function choice(ops)
    return function(scene)
        slect = function(ls, field) return mapf(function(c) return c[field] end, ls) end
        filtered_ops = {}
        for _, op in pairs(ops) do
            if op['guard'](scene.game) then
                table.insert(filtered_ops, op)
            end
        end
        scene.text_state['choices'] = slect(filtered_ops, 'response')
        scene.text_state['choice_result'] = slect(filtered_ops, 'result')
        scene.text_state['choice_events'] = slect(filtered_ops, 'events')
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
            ['muted'] = 0,
            ['voicing'] = 1,
            ['timer'] = 0
        }
        scene.await_input = not requires_response
    end
end

function _lookAt(sp1, sp2)
    sp1.dir = ite(sp1.x + sp1.w >= sp2.x + sp2.w, LEFT, RIGHT)
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

function daytime()
    return function(scene)
        for k,v in pairs(scene.game.maps) do
            if k == 'east-forest' or k == 'west-forest' 
            or k == 'south-forest' or k == 'monastery-approach' or k == 'monastery-entrance' then
                v.lit = 0.0
            end
        end
    end
end

function evening()
    return function(scene)
        for k,v in pairs(scene.game.maps) do
            if k == 'east-forest' or k == 'west-forest' 
            or k == 'south-forest' or k == 'monastery-approach' or k == 'monastery-entrance' then
                v.lit = 0.2
                v.ambient = { 62, 24, 20 }
            end
        end
    end
end

function nighttime()
    return function(scene)
        for k,v in pairs(scene.game.maps) do
            if k == 'east-forest' or k == 'west-forest' 
            or k == 'south-forest' or k == 'monastery-approach' or k == 'monastery-entrance' then
                v.lit = 0.7
                v.ambient = { 10, 10, 20 }
            end
        end
    end
end

function blackout()
    return function(scene)
        scene.game.alpha = 0
    end
end

function fade(rate)
    return function(scene)
        scene.game.fade_rate = rate
    end
end

function chaptercard()
    return function(scene)
        scene.game:flash(scene.game.chapter_id, 0.2)
    end
end

function introduce(name)
    return function(scene)
        scene.player:introduce(name)
    end
end

function addChoice(choices, c)
    new_choices = deepcopy(choices)
    new_choices[#new_choices + 1] = c
    return new_choices
end