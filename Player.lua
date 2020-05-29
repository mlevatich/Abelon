require 'Util'
require 'Constants'

require 'Animation'
require 'Scene'
require 'Sprite'
require 'Menu'

Player = Class{}

-- Movement constants
local WALK_SPEED = 140

-- Initialize the player character, Abelon
function Player:init(sp)

    -- Player is a superclass of Sprite
    self.sp = sp

    -- Abelon has different behaviors to account for the player's keyboard input
    -- which overwrite the standard sprite behaviors
    self:addBehaviors({
        ['wander'] = function() self:wanderBehavior() end,
        ['idle'] = function() self:idleBehavior() end,
        ['scene'] = function() self:sceneBehavior() end,
        ['browsing'] = function() self:browsingBehavior() end
    })

    -- Abelon's starting inventory
    local base_inventory = {
        {['name'] = 'Items', ['children'] = {
            {['name'] = "Abelon's Axe", ['action'] = pass},
            {['name'] = "Abelon's Cloak", ['action'] = pass}
        }},
        {['name'] = 'Party', ['children'] = {
            {['name'] = "Abelon", ['action'] = pass},
            {['name'] = "Kath", ['action'] = pass}
        }},
        {['name'] = 'Settings', ['children'] = {
            {['name'] = "Difficulty", ['action'] = pass},
            {['name'] = "Video", ['action'] = pass},
            {['name'] = "Audio", ['action'] = pass},
            {['name'] = "Controls", ['action'] = pass}
        }},
        { ['name'] = 'Quicksave', ['action'] = function() love.event.quit(0) end }
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
    self:changeBehavior('browsing')
    self:changeAnimation('idle')

    -- Set the inventory to be open
    self.open_menu = self.inventory
end

-- When player presses space to interact, a dialogue is started
function Player:interact()

    -- Look through active sprites
    local chapter = self:getChapter()
    local target = nil
    for _, sp in pairs(chapter:getActiveSprites()) do

        -- If sprite is close, interactive, and not the player, it's valid
        if sp:isInteractive() and sp:getID() ~= self:getID() and self:AABB(sp, 10) then
            target = sp
            break
        end
    end

    -- Start this chapter's interaction with the found sprite
    if target then
        self:changeBehavior('scene')
        chapter:interactWith(target)
    end
end

-- For stopping the player
function Player:idleBehavior(dt)
    self:stop()
end

-- Normal player movement behavior
function Player:wanderBehavior(dt)

    -- Read keypresses
    local l = love.keyboard.isDown('left')
    local r = love.keyboard.isDown('right')
    local u = love.keyboard.isDown('up')
    local d = love.keyboard.isDown('down')
    local space = love.keyboard.wasPressed('space')
    local inv = love.keyboard.wasPressed('e')

    -- If any direction is tapped, start walking
    if not (l == r) or not (u == d) then

        -- Change animation to walking
        self:changeAnimation('walking')

        -- If a left/right direction is held, set x velocity and direction
        if l and not r then
            self.sp.dir = LEFT
            self.sp.dx = -WALK_SPEED
        elseif r and not l then
            self.sp.dir = RIGHT
            self.sp.dx = WALK_SPEED
        else
            self.sp.dx = 0
        end

        -- If an up/down direction is held, set y velocity in that direction
        if d and not u then
            self.sp.dy = WALK_SPEED
        elseif u and not d then
            self.sp.dy = -WALK_SPEED
        else
            self.sp.dy = 0
        end

    -- If no direction was tapped, stop walking
    else
        -- Halt and change to idle animation
        self:stop()
        self:changeAnimation('idle')
    end

    -- If e is pressed, the inventory opens. Otherwise, if space is pressed,
    -- player tries to interact with a nearby object
    if inv then
        self:openInventory()
    elseif space then
        self:interact()
    end
end

-- Player in-scene behavior
function Player:sceneBehavior(dt)

    -- Get keypresses
    local u = love.keyboard.wasPressed('up')
    local d = love.keyboard.wasPressed('down')
    local space = love.keyboard.wasPressed('space')

    -- Advance scene based on keypresses
    self:getChapter():sceneInput(space, u, d)
end

-- Player in-menu behavior
function Player:browsingBehavior(dt)

    -- Player is still while a menu is open
    self:stop()

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
        self:changeBehavior('wander')
    elseif l then
        self.open_menu:back()
    elseif r or enter then
        self.open_menu:forward()
    elseif u ~= d then
        self.open_menu:hover(u)
    end
end

-- Render the player character
function Player:render(cam_x, cam_y)

    -- Render the player's sprite
    self.sp:render(cam_x, cam_y)

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
function Player:resetPosition(arg1, arg2) return self.sp:resetPosition(arg1, arg2) end
function Player:move(arg1, arg2) return self.sp:stop(arg1, arg2) end
function Player:stop() return self.sp:stop() end
function Player:changeImpression(arg1) return self.sp:changeImpression(arg1) end
function Player:changeAwareness(arg1) return self.sp:changeAwareness(arg1) end
function Player:changeAnimation(arg1) return self.sp:changeAnimation(arg1) end
function Player:changeVersion(arg1) return self.sp:changeVersion(arg1) end
function Player:changeBehavior(arg1) return self.sp:changeBehavior(arg1) end
function Player:atEase() return self.sp:atEase() end
function Player:addBehaviors(arg1) return self.sp:addBehaviors(arg1) end
function Player:AABB(arg1, arg2) return self.sp:AABB(arg1, arg2) end
function Player:onTile(arg1, arg2) return self.sp:onTile(arg1, arg2) end
function Player:checkCollisions() return self.sp:checkCollisions() end
function Player:update(dt) return self.sp:update(dt) end
