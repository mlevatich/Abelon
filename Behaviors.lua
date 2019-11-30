require 'Util'

local WALKING_SPEED = 140

-- Player controlled idle behavior
function playerIdle(dt, char)

    -- Read keypresses
    local l = love.keyboard.isDown('left')
    local r = love.keyboard.isDown('right')
    local u = love.keyboard.isDown('up')
    local d = love.keyboard.isDown('down')
    local space = love.keyboard.wasPressed('space')

    -- If any direction is tapped, start walking, otherwise set velocity to zero
    if not (l == r) or not (u == d) then
        char:changeBehavior('walking')
    else
        char.dx = 0
        char.dy = 0
    end

    -- If space is pressed, character tries to interact with a nearby object
    if space then
        char:interact()
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
    collided_with = char:checkCollisions()

    -- If space is pressed, character tries to interact with a nearby object
    if space then
        char:interact(collided_with)
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
        local done = char.currentDialogue:continue()
        if done then
            char.currentDialogue = nil
            char:changeBehavior('idle')
        end
    else
        char.currentDialogue:update(dt)
    end

    if u ~= d then
        char.currentDialogue:hover(u)
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

    -- Handle any collisions
    char:checkCollisions()
end

-- NPC talking behavior
function defaultTalking(dt, char)

    -- Character is still while talking
    char.dx = 0
    char.dy = 0

    -- Player is responsible for finishing the conversation
    if char.currentDialogue:getOther(char).currentDialogue == nil then
        char.currentDialogue = nil
        char:changeBehavior('idle')
    end
end
