require 'Util'
require 'Animation'
require 'Behaviors'
require 'Dialogue'

Character = Class{}

-- Class constants
local ANIMATION_SPEED = 6.5
local WIDTH = 32
local HEIGHT = 40

-- Initialize a new character
function Character:init(name, is_player)

    -- Position
    self.x = 0
    self.y = 0
    self.leash_x = 0
    self.leash_y = 0

    -- Velocity
    self.dx = 0
    self.dy = 0

    -- Size
    self.width = WIDTH
    self.height = HEIGHT
    self.xoff = WIDTH / 2
    self.yoff = HEIGHT / 2

    -- Sprite textures
    self.name = name
    self.texture = love.graphics.newImage('graphics/sprites/' .. self.name .. '.png')
    self.ptexture = love.graphics.newImage('graphics/portraits/' .. self.name .. '.png')
    self.portraits = getSpriteQuads({0, 1, 2}, self.ptexture, PORTRAIT_SIZE, PORTRAIT_SIZE)

    -- Sprite animations
    self.animations = {
        ['idle'] = Animation({
            texture = self.texture,
            frames = getSpriteQuads({0}, self.texture, self.width, self.height),
            interval = 1 / ANIMATION_SPEED
        }),
        ['walking'] = Animation({
            texture = self.textures,
            frames = getSpriteQuads({1, 2, 3, 2}, self.texture, self.width, self.height),
            interval = 1 / ANIMATION_SPEED
        }),
        ['talking'] = Animation({
            texture = self.texture,
            frames = getSpriteQuads({0}, self.texture, self.width, self.height),
            interval = 1 / ANIMATION_SPEED
        })
    }
    self.direction = 'left'
    self.state = 'idle'
    self.animation = self.animations[self.state]
    self.currentFrame = self.animation:getCurrentFrame()

    -- Sprite behaviors
    self.behaviors = nil
    if is_player then
        self.behaviors = {
            ['idle'] = function(dt)
                playerIdle(dt, self)
            end,
            ['walking'] = function(dt)
                playerWalking(dt, self)
            end,
            ['talking'] = function(dt)
                playerTalking(dt, self)
            end
        }
    else
        self.behaviors = {
            ['idle'] = function(dt)
                defaultIdle(dt, self)
            end,
            ['walking'] = function(dt)
                defaultWalking(dt, self)
            end,
            ['talking'] = function(dt)
                defaultTalking(dt, self)
            end
        }
    end

    -- Sprite's opinion of the player
    self.impression = 20

    -- Sprite sound effects
    self.sounds = nil

    -- Current game context for this sprite
    self.scene = nil
    self.currentDialogue = nil
    self.dialogueResult = nil
end

-- Modify a character's position
function Character:resetPosition(new_x, new_y)

    -- Move character to position
    self.x = new_x
    self.y = new_y

    -- Chain character to position so they can't wander too far
    self.leash_x = new_x
    self.leash_y = new_y

    -- Stop character
    self.dx = 0
    self.dy = 0
end

-- Select a character's dialogue and interactions
function Character:setScene(scene_obj)
    self.scene = scene_obj
end

-- Change a character's behavior, and reset their corresponding animation
function Character:changeBehavior(behavior)
    self.state = behavior
    self.animations[behavior]:restart()
    self.animation = self.animations[behavior]
end

-- Change a character's impression of the player (cannot drop below zero)
function Character:changeImpression(value)
    self.impression = math.max(self.impression + value, 0)
end

-- Handler for when player presses space to interact with an object
function Character:interact(other)

    -- If a character was collided with and space was pressed
    if other then

        -- Make character face player
        if other.x <= self.x then
            other.direction = 'right'
        else
            other.direction = 'left'
        end

        -- Start dialogue with character based on current scene
        self.currentDialogue = self.scene:getDialogueWith(other)
        other.currentDialogue = self.currentDialogue
        self:changeBehavior('talking')
        other:changeBehavior('talking')
    end
end

-- Get the coordinates of the closest tile to the character
function Character:tileOn()
    return self.scene:getMap():tileAt(self.x + self.width / 2, self.y + self.height / 2)
end

-- Handle all collisions in current frame
function Character:checkCollisions()
    self:checkMapCollisions()
    return self:checkSpriteCollisions()
end

-- Handle collisions with other sprites for this character
function Character:checkSpriteCollisions()

    -- Iterate over all active characters
    local target = nil
    for name, char in pairs(self.scene:getCharacters()) do
        if char.name ~= self.name then

            -- Collision from right or left of target
            local y_inside = (self.y < char.y + char.height) and (self.y + self.height > char.y)
            local right_dist = self.x - (char.x + char.width)
            local left_dist = char.x - (self.x + self.width)
            if y_inside and right_dist <= 0 and right_dist > -char.width/2 and self.dx < 0 then
                self.dx = 0
                self.x = char.x + char.width
                target = char
            elseif y_inside and left_dist <= 0 and left_dist > -char.width/2 and self.dx > 0 then
                self.dx = 0
                self.x = char.x - self.width
                target = char
            end

            -- Collision from below target or above target
            local x_inside = (self.x < char.x + char.width) and (self.x + self.width > char.x)
            local down_dist = self.y - (char.y + char.height)
            local up_dist = char.y - (self.y + self.height)
            if x_inside and down_dist <= 0 and down_dist > -char.height/2 and self.dy < 0 then
                self.dy = 0
                self.y = char.y + char.height
                target = char
            elseif x_inside and up_dist <= 0 and up_dist > -char.height/2 and self.dy > 0 then
                self.dy = 0
                self.y = char.y - self.height
                target = char
            end
        end
    end
    return target
end

-- Handle map collisions for this character
function Character:checkMapCollisions()

    -- Final destination to move to
    local x_dest = self.x
    local y_dest = self.y
    local map = self.scene:getMap()
    local h = self.height
    local w = self.width

    -- Check for collision from left or right
    if self.dx < 0 then

        -- left
        if map:collides(map:tileAt(self.x - 1, self.y))
        or map:collides(map:tileAt(self.x - 1, self.y + h / 2))
        or map:collides(map:tileAt(self.x - 1, self.y + h - 1)) then
            self.dx = 0
            x_dest = map:tileAt(self.x - 1, self.y).x * map.tileWidth
        end

    elseif self.dx > 0 then

        -- right
        if map:collides(map:tileAt(self.x + w, self.y))
        or map:collides(map:tileAt(self.x + w, self.y + h / 2))
        or map:collides(map:tileAt(self.x + w, self.y + h - 1)) then
            self.dx = 0
            x_dest = (map:tileAt(self.x + w, self.y).x - 1) * map.tileWidth - w
        end
    end

    -- Check for collision from above or below
    if self.dy < 0 then

        -- above
        if map:collides(map:tileAt(self.x, self.y - 1))
        or map:collides(map:tileAt(self.x + w - 1, self.y - 1)) then
            self.dy = 0
            y_dest = map:tileAt(self.x, self.y - 1).y * map.tileHeight
        end

    elseif self.dy > 0 then

        -- below
        if map:collides(map:tileAt(self.x, self.y + h))
        or map:collides(map:tileAt(self.x + w - 1, self.y + h)) then
            self.dy = 0
            y_dest = (map:tileAt(self.x, self.y + h).y - 1) * map.tileHeight - h
        end
    end

    -- Push sprite to destination of lowest distance
    if abs(x_dest - self.x) < abs(y_dest - self.y) then
        self.x = x_dest
    else
        self.y = y_dest
    end
end

-- Update this character's animation, position, and behavior
function Character:update(dt)

    -- Update velocity, direction, behavior based on current behavior
    self.behaviors[self.state](dt)

    -- Update frame of animation
    self.animation:update(dt)
    self.currentFrame = self.animation:getCurrentFrame()

    -- Update position based on velocity
    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt
end

-- Render a character to the screen
function Character:render()

    -- Set direction of sprite to draw
    local d = 1
    if self.direction == 'left' then
        d = -1
    end

    -- Draw sprite at position
    love.graphics.draw(self.texture, self.currentFrame, self.x+self.xoff, self.y+self.yoff, 0, d, 1, self.xoff, self.yoff)
end
