require 'Util'
require 'Animation'
require 'Behaviors'
require 'Dialogue'

Character = Class{}

NUM_SCENES = 1

-- Class constants
local ANIMATION_SPEED = 6.5
local WIDTH = 32
local HEIGHT = 40

-- Initialize a new character
function Character:init(name, is_player)

    -- position
    self.x = 0
    self.y = 0
    self.leash_x = 0
    self.leash_y = 0

    -- velocity
    self.dx = 0
    self.dy = 0

    -- size
    self.width = WIDTH
    self.height = HEIGHT
    self.xoff = WIDTH / 2
    self.yoff = HEIGHT / 2

    -- current map
    self.map = nil

    -- sprite and animations
    self.name = name
    self.texture = love.graphics.newImage('graphics/' .. self.name .. '.png')
    self.animations = {
        ['idle'] = Animation({
            texture = self.texture,
            frames = getSpriteQuads({0}, self.texture, self.width, self.height),
            interval = 1 / ANIMATION_SPEED
        }),
        ['walking'] = Animation({
            texture = self.texture,
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

    -- behavior
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
            ['talking'] = function(dt) end
        }
    end

    -- sound effects
    self.sounds = nil -- love.audio.newSource('sounds/jump.wav', 'static')

    -- scene control
    self.scene = 0
    self.sceneFiles = {}
    for x = 1, NUM_SCENES do
        self.sceneFiles[x] = "Abelon/scenes/" .. x .. "/" .. self.name .. ".txt"
    end
    self.currentDialogue = nil
end

-- Modify a character's position
function Character:resetPosition(new_x, new_y)
    self.x = new_x
    self.y = new_y
    self.leash_x = new_x
    self.leash_y = new_y
end

-- Put a character on a certain map
function Character:setMap(new_map)
    self.map = new_map
end

-- Select a character's dialogue and interactions
function Character:setScene(scene_id)
    self.scene = scene_id
end

-- Change a character's behavior, and reset their corresponding animation
function Character:changeBehavior(behavior)
    self.state = behavior
    self.animations[behavior]:restart()
    self.animation = self.animations[behavior]
end

function Character:interact()

    -- TODO: don't hardcode!
    -- check for nearby characters. If nearby and facing,
        -- create dialogue object and set as self.current dialogue, based on character
        -- set behavior
        -- make the other dialogue partner face self
    -- else do nothing
    char = self.map.active_characters['Kath']

    -- Start dialogue with character based on current scene
    sceneFile = char.sceneFiles[self.scene]
    self.currentDialogue = Dialogue(sceneFile)
    self:changeBehavior('talking')
end

-- Get the coordinates of the closest tile to the character
function Character:tileOn()
    return self.map:tileAt(self.x + self.width / 2, self.y + self.height / 2)
end

-- Handle all collisions in current frame
function Character:checkCollisions()
    self:checkMapCollisions()
    self:checkSpriteCollisions()
end

-- Handle collisions with other sprites for this character
function Character:checkSpriteCollisions()

    -- Iterate over all active characters
    my_tile = self:tileOn()
    for name, char in pairs(self.map:getCharacters()) do
        tile = char:tileOn()
        if char.name ~= self.name then

            -- Collision from right or left of target
            y_inside = (self.y < char.y + char.height) and (self.y + self.height > char.y)
            right_dist = self.x - (char.x + char.width)
            left_dist = char.x - (self.x + self.width)
            if y_inside and right_dist <= 0 and right_dist > -char.width/2 and self.dx < 0 then
                self.dx = 0
                self.x = char.x + char.width
            elseif y_inside and left_dist <= 0 and left_dist > -char.width/2 and self.dx > 0 then
                self.dx = 0
                self.x = char.x - self.width
            end

            -- Collision from below target or above target
            x_inside = (self.x < char.x + char.width) and (self.x + self.width > char.x)
            down_dist = self.y - (char.y + char.height)
            up_dist = char.y - (self.y + self.height)
            if x_inside and down_dist <= 0 and down_dist > -char.height/2 and self.dy < 0 then
                self.dy = 0
                self.y = char.y + char.height
            elseif x_inside and up_dist <= 0 and up_dist > -char.height/2 and self.dy > 0 then
                self.dy = 0
                self.y = char.y - self.height
            end
        end
    end
end

-- Handle map collisions for this character
function Character:checkMapCollisions()

    -- Final destination to move to
    local x_dest = self.x
    local y_dest = self.y

    -- Check for collision from left or right
    if self.dx < 0 then

        -- left
        if self.map:collides(self.map:tileAt(self.x - 1, self.y))
        or self.map:collides(self.map:tileAt(self.x - 1, self.y + self.height / 2))
        or self.map:collides(self.map:tileAt(self.x - 1, self.y + self.height - 1)) then
            self.dx = 0
            x_dest = self.map:tileAt(self.x - 1, self.y).x * self.map.tileWidth
        end

    elseif self.dx > 0 then

        -- right
        if self.map:collides(self.map:tileAt(self.x + self.width, self.y))
        or self.map:collides(self.map:tileAt(self.x + self.width, self.y + self.height / 2))
        or self.map:collides(self.map:tileAt(self.x + self.width, self.y + self.height - 1)) then
            self.dx = 0
            x_dest = (self.map:tileAt(self.x + self.width, self.y).x - 1) * self.map.tileWidth - self.width
        end
    end

    -- Check for collision from above or below
    if self.dy < 0 then

        -- above
        if self.map:collides(self.map:tileAt(self.x, self.y - 1))
        or self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y - 1)) then
            self.dy = 0
            y_dest = self.map:tileAt(self.x, self.y - 1).y * self.map.tileHeight
        end

    elseif self.dy > 0 then

        -- below
        if self.map:collides(self.map:tileAt(self.x, self.y + self.height))
        or self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y + self.height)) then
            self.dy = 0
            y_dest = (self.map:tileAt(self.x, self.y + self.height).y - 1) * self.map.tileHeight - self.height
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
