require 'Util'

local WALKING_SPEED = 140

-- Player controlled idle behavior
function playerIdle(dt, char)

    -- Read keypresses
    local l = love.keyboard.isDown('left')
    local r = love.keyboard.isDown('right')
    local u = love.keyboard.isDown('up')
    local d = love.keyboard.isDown('down')

    -- If any direction is tapped, start walking, otherwise set velocity to zero
    if not (l == r) or not (u == d) then
        char:changeBehavior('walking')
    else
        char.dx = 0
        char.dy = 0
    end
end

-- Player controlled walking behavior
function playerWalking(dt, char)

    -- Read keypresses
    local l = love.keyboard.isDown('left')
    local r = love.keyboard.isDown('right')
    local u = love.keyboard.isDown('up')
    local d = love.keyboard.isDown('down')

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

    -- Handle any collisions
    char:checkCollisions()
end

-- Default idle behavior
function defaultIdle(dt, char)

    -- Set walking and walk velocity on very low chance, otherwise set still
    char.dx = 0
    char.dy = 0
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

-- Default walking behavior
function defaultWalking(dt, char)

    -- Chance to stop walking
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

    if math.random() <= 0.05 then
        char:changeBehavior('idle')
    end

    -- Handle any collisions
    char:checkCollisions()
end
