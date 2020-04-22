require 'Util'

local WALKING_SPEED = 140

-- Player halts
function playerStill(dt, char)
    char.dx = 0
    char.dy = 0
end

-- Player controlled idle behavior
function playerIdle(dt, char)

    -- Read keypresses
    local l = love.keyboard.isDown('left')
    local r = love.keyboard.isDown('right')
    local u = love.keyboard.isDown('up')
    local d = love.keyboard.isDown('down')
    local space = love.keyboard.wasPressed('space')
    local inv = love.keyboard.wasPressed('e')

    -- If any direction is tapped, start walking, otherwise set velocity to zero
    if not (l == r) or not (u == d) then
        char:changeBehavior('walking')
    else
        char.dx = 0
        char.dy = 0
    end

    -- If e is pressed, the inventory opens. Otherwise, if space is pressed,
    -- character tries to interact with a nearby object
    if inv then
        char:openInventory()
    elseif space then
        char:startDialogue()
    end
end

-- Player controlled walking behavior
function playerWalking(dt, char)

    -- Read keypresses
    local l = love.keyboard.isDown('left')
    local r = love.keyboard.isDown('right')
    local u = love.keyboard.isDown('up')
    local d = love.keyboard.isDown('down')
    local space = love.keyboard.wasPressed('space')
    local inv = love.keyboard.wasPressed('e')

    -- If a left/right direction is held, set x velocity and direction
    local continue = false
    if l and not r then
        char.direction = 'left'
        char.dx = -WALKING_SPEED
        continue = true
    elseif r and not l then
        char.direction = 'right'
        char.dx = WALKING_SPEED
        continue = true
    else
        char.dx = 0
    end

    -- If an up/down direction is held, set y velocity in that direction
    if d and not u then
        char.dy = WALKING_SPEED
        continue = true
    elseif u and not d then
        char.dy = -WALKING_SPEED
        continue = true
    else
        char.dy = 0
    end

    -- If no direction is held, set idle behavior
    if not continue then
        char:changeBehavior('idle')
    end

    -- If e is pressed, the inventory opens. Otherwise, if space is pressed,
    -- character tries to interact with a nearby object
    if inv then
        char:openInventory()
    elseif space then
        char:startDialogue()
    end
end

-- Player in-dialogue behavior
function playerTalking(dt, char)

    -- Character is still while talking
    char.dx = 0
    char.dy = 0

    -- Get keypresses
    local u = love.keyboard.wasPressed('up')
    local d = love.keyboard.wasPressed('down')
    local space = love.keyboard.wasPressed('space')

    if space then
        local result = char.current_dialogue:advance()
        if result then
            char.dialogue_end_track = result
            char:changeBehavior('idle')
        end
    else
        char.current_dialogue:update(dt)
    end

    if u ~= d then
        char.current_dialogue:hover(u)
    end
end

-- Player in-menu behavior
function playerBrowsing(dt, char)

    -- Character is still while a menu is open
    char.dx = 0
    char.dy = 0

    -- Read keypresses
    local l = love.keyboard.wasPressed('left')
    local r = love.keyboard.wasPressed('right')
    local u = love.keyboard.wasPressed('up')
    local d = love.keyboard.wasPressed('down')
    local e = love.keyboard.wasPressed('e')
    local enter = love.keyboard.wasPressed('return')
    local esc = love.keyboard.wasPressed('escape')

    if esc or e then
        char.open_menu:reset()
        char.open_menu = nil
        char:changeBehavior('idle')
    elseif l then
        char.open_menu:back()
    elseif r or enter then
        char.open_menu:forward()
    elseif u ~= d then
        char.open_menu:hover(u)
    end
end

-- NPC idle behavior
function defaultIdle(dt, char)

    -- Character is still
    char.dx = 0
    char.dy = 0

    -- Low chance to start walking in random direction
    if math.random() <= 0.01 then
        dir = math.random()
        if dir >= 0.75 then
            char.dx = WALKING_SPEED/2
            char.direction = 'right'
        elseif dir < 0.75 and dir >= 0.5 then
            char.dx = -WALKING_SPEED/2
            char.direction = 'left'
        elseif dir < 0.50 and dir >= 0.25 then
            char.dy = WALKING_SPEED/2
        else
            char.dy = -WALKING_SPEED/2
        end
        char:changeBehavior('walking')
    end
end

-- NPC walking behavior
function defaultWalking(dt, char)

    -- Character can't walk too far from leash
    x_dist = char.x - char.leash_x
    y_dist = char.y - char.leash_y
    if x_dist > 100 then
        char.dx = -WALKING_SPEED/2
        char.direction = 'left'
        char.dy = 0
    elseif x_dist < -100 then
        char.dx = WALKING_SPEED/2
        char.direction = 'right'
        char.dy = 0
    elseif y_dist > 100 then
        char.dx = 0
        char.dy = -WALKING_SPEED/2
    elseif y_dist < -100 then
        char.dx = 0
        char.dy = WALKING_SPEED/2
    end

    -- Chance to stop walking
    if math.random() <= 0.05 then
        char:changeBehavior('idle')
    end
end

-- NPC talking behavior
function defaultTalking(dt, char)

    -- Character is still while talking
    char.dx = 0
    char.dy = 0
end
