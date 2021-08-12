require 'Util'
require 'Constants'

require 'Animation'
require 'Scene'
require 'Sprite'
require 'Menu'

Player = Class{}

-- Movement constants
local WALK_SPEED = 100
local DIAG_SPEED = 80

-- Initialize the player character, Abelon
function Player:init(sp)

    -- Player is a superclass of Sprite
    self.sp = sp

    self:addBehaviors({['free'] = function() pass() end})

    -- Abelon has different modes to account for the player's keyboard input
    self.modes = {
        ['frozen'] = function() self:stillMode() end,
        ['free'] = function() self:freeMode() end,
        ['scene'] = function() self:sceneMode() end,
        ['browse'] = function() self:browseMode() end
    }
    self.mode = 'free'

    -- Abelon's starting inventory
    local base_inventory = {
        {
            ['name'] = 'Items',
            ['children'] = {
                { ['name'] = "Abelon's Axe", ['action'] = pass },
                { ['name'] = "Abelon's Cloak", ['action'] = pass }
            }
        },
        {
            ['name'] = 'Party',
            ['children'] = {
                { ['name'] = "Abelon", ['action'] = pass },
                { ['name'] = "Kath", ['action'] = pass }
            }
        },
        {
            ['name'] = 'Settings',
            ['children'] = {
                { ['name'] = "Difficulty", ['action'] = pass },
                { ['name'] = "Video", ['action'] = pass },
                { ['name'] = "Audio", ['action'] = pass },
                { ['name'] = "Controls", ['action'] = pass }
            }
        },
        {
            ['name'] = 'Quicksave',
            ['action'] = function() love.event.quit(0) end
        }
    }
    self.inventory = Menu(nil, base_inventory, BOX_MARGIN, BOX_MARGIN)

    -- Abelon can open menus, like shops and the inventory
    self.open_menu = nil

    -- Abelon has a 'party' of other characters
    self.party_members = nil
end

-- When player presses i to open the inventory, the inventory menu appears
function Player:openInventory()

    -- Change player behavior to menu-browsing
    self:changeMode('browse')
    self:changeBehavior('idle')

    -- Set the inventory to be open
    self.open_menu = self.inventory
end

-- When player presses space to interact, a dialogue is started
function Player:interact()

    -- Look through active sprites
    local chapter = self:getChapter()
    local target = nil
    for _, sp in ipairs(chapter:getActiveSprites()) do

        -- If sprite is close, interactive, and not the player, it's valid
        if sp:isInteractive() and
           sp:getID() ~= self:getID() and
           self:AABB(sp, 10) then
            target = sp
            break
        end
    end

    -- Start this chapter's interaction with the found sprite
    if target then
        self:changeMode('scene')
        self:changeBehavior('idle')
        chapter:interactWith(target)
    end
end

function Player:changeMode(new_mode)
    self.mode = new_mode
end

-- Cannot accept keypresses in frozen mode
function Player:frozenMode(dt)
    pass()
end

function Player:freeMode(dt)

    -- Get keypresses
    local l = love.keyboard.isDown('left')
    local r = love.keyboard.isDown('right')
    local u = love.keyboard.isDown('up')
    local d = love.keyboard.isDown('down')
    local space = love.keyboard.wasPressed('space')
    local inv = love.keyboard.wasPressed('e')

    -- If any direction is tapped, start walking
    if not (l == r) or not (u == d) then

        -- Change animation to walking
        self:changeBehavior('free')
        self:changeAnimation('walking')

        -- If a left/right direction is held, set x velocity and direction
        if (l and not r) and (u and not d) then
            self.sp.dir = LEFT
            self.sp.dx = -DIAG_SPEED
            self.sp.dy = -DIAG_SPEED
        elseif (l and not r) and (d and not u) then
            self.sp.dir = LEFT
            self.sp.dx = -DIAG_SPEED
            self.sp.dy = DIAG_SPEED
        elseif (r and not l) and (u and not d) then
            self.sp.dir = RIGHT
            self.sp.dx = DIAG_SPEED
            self.sp.dy = -DIAG_SPEED
        elseif (r and not l) and (d and not u) then
            self.sp.dir = RIGHT
            self.sp.dx = DIAG_SPEED
            self.sp.dy = DIAG_SPEED
        elseif (l and not r) then
            self.sp.dir = LEFT
            self.sp.dx = -WALK_SPEED
            self.sp.dy = 0
        elseif (r and not l) then
            self.sp.dir = RIGHT
            self.sp.dx = WALK_SPEED
            self.sp.dy = 0
        elseif (u and not d) then
            self.sp.dy = -WALK_SPEED
            self.sp.dx = 0
        elseif (d and not u) then
            self.sp.dy = WALK_SPEED
            self.sp.dx = 0
        else
            self.sp.dx = 0
            self.sp.dy = 0
        end

    -- If no direction was tapped, stop walking
    else
        -- Idle behavior
        self:changeBehavior('idle')
    end

    -- If e is pressed, the inventory opens. Otherwise, if space is pressed,
    -- player tries to interact with a nearby object
    if inv then
        self:openInventory()
    elseif space then
        self:interact()
    end
end

function Player:sceneMode(dt)

    -- Get keypresses
    local u = love.keyboard.wasPressed('up')
    local d = love.keyboard.wasPressed('down')
    local space = love.keyboard.wasPressed('space')

    -- Advance scene based on keypresses
    self:getChapter():sceneInput(space, u, d)
end

function Player:browseMode(dt)

    -- Read keypresses
    local l = love.keyboard.wasPressed('left')
    local r = love.keyboard.wasPressed('right')
    local u = love.keyboard.wasPressed('up')
    local d = love.keyboard.wasPressed('down')
    local e = love.keyboard.wasPressed('e')
    local enter = love.keyboard.wasPressed('return')
    local esc = love.keyboard.wasPressed('escape')

    if esc or e then
        self.open_menu:reset()
        self.open_menu = nil
        self:changeMode('free')
    elseif l then
        self.open_menu:back()
    elseif r or enter then
        self.open_menu:forward()
    elseif u ~= d then
        self.open_menu:hover(ite(u, UP, DOWN))
    end
end

-- Update player character based on key presses
function Player:update(dt)
    self.modes[self.mode](dt)
end

-- Render the player character's interactions
function Player:render(cam_x, cam_y)

    -- Render menu if it exists
    if self.open_menu then
        self.open_menu:render(cam_x, cam_y)
    end
end

-- MOCK SUPERCLASS
function Player:getID() return self.sp:getID() end
function Player:getName() return self.sp:getName() end
function Player:getPosition() return self.sp:getPosition() end
function Player:getDepth() return self.sp:getDepth() end
function Player:getDimensions() return self.sp:getDimensions() end
function Player:getImpression() return self.sp:getImpression() end
function Player:getAwareness() return self.sp:getAwareness() end
function Player:getChapter() return self.sp:getChapter() end
function Player:isInteractive() return self.sp:isInteractive() end
function Player:isBlocking() return self.sp:isBlocking() end
function Player:resetPosition(a, b) return self.sp:resetPosition(a, b) end
function Player:move(a, b) return self.sp:stop(a, b) end
function Player:stop() return self.sp:stop() end
function Player:changeImpression(a) return self.sp:changeImpression(a) end
function Player:changeAwareness(a) return self.sp:changeAwareness(a) end
function Player:changeAnimation(a) return self.sp:changeAnimation(a) end
function Player:changeVersion(a) return self.sp:changeVersion(a) end
function Player:changeBehavior(a) return self.sp:changeBehavior(a) end
function Player:atEase() return self.sp:atEase() end
function Player:addBehaviors(a) return self.sp:addBehaviors(a) end
function Player:AABB(a, b) return self.sp:AABB(a, b) end
function Player:onTile(a, b) return self.sp:onTile(a, b) end
function Player:checkCollisions() return self.sp:checkCollisions() end
