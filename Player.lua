require 'Util'
require 'Constants'

require 'Animation'
require 'Scene'
require 'Sprite'
require 'Menu'

require 'Sounds'

Player = class('Player')

-- Movement constants
WALK_SPEED = 100
DIAG_SPEED = 80

-- Initialize the player character, Abelon
function Player:initialize(sp)

    -- Player is a superclass of Sprite
    self.sp = sp

    self:addBehaviors({ ['free'] = function(sp, dt) sp:updatePosition(dt) end })

    -- Abelon has different modes to account for the player's keyboard input
    self.modes = {
        ['frozen'] = function(p) p:stillMode()  end,
        ['free']   = function(p) p:freeMode()   end,
        ['scene']  = function(p) p:sceneMode()  end,
        ['browse'] = function(p) p:browseMode() end,
        ['battle'] = function(p) p:battleMode() end
    }
    self.mode = 'free'

    -- Abelon's inventory
    self.inventory = {}

    -- Abelon's party
    self.party = { self.sp }

    -- Abelon can open menus, like shops and the inventory
    self.open_menu = nil
end

function Player:openMenu(m)

    -- Change control mode to menu-browsing
    self:changeMode('browse')

    -- Create and open menu
    sfx['open']:play()
    self.open_menu = Menu:new(nil, m, BOX_MARGIN, BOX_MARGIN, false)
end

-- When player presses i to open the inventory, the inventory menu appears
function Player:openInventory()

    -- Player character is idle while navigating the inventory
    self:changeBehavior('idle')

    -- Make menu
    local inv_ch = mapf(function(sp) return sp:toItem() end, self.inventory)
    local party_ch = mapf(function(sp) return sp:toPartyMember() end, self.party)

    local inv_m = MenuItem:new('Items', inv_ch, 'View possessions')
    local party_m = MenuItem:new('Party', party_ch, 'View traveling companions')

    -- Open inventory menu
    self:openMenu({ inv_m, party_m, self:mkSettingsMenu(), self:mkQuitMenu() })
end

function Player:mkQuitMenu()
    local die = function(c) love.event.quit(0) end
    return MenuItem:new('Quit', {
        MenuItem:new('Save and quit', {}, nil, nil, die,
            "Save current progress and close the game?"
        ),
        MenuItem:new('Restart chapter', {}, nil, nil, pass,
            "Are you SURE you want to restart the chapter? You will lose ALL \z
             progress made during the chapter."
        )
    }, 'Save and quit, or restart the chapter')
end

function Player:mkDifficultyMenu()
    local setD = function(d)
        if self:getChapter().difficulty > d then
            return function(c, m)
                c:setDifficulty(d)

                -- Stupid hack to get difficulty menu option to update
                local nm = c.player:mkDifficultyMenu()
                local location = m.parent.hovering + m.parent.base - 1
                local hovering = m.hovering
                local base = m.base
                m.parent.menu_items[location] = nm
                initSubmenu(nm, m.parent)
                m:back()
                m.parent:forward()
                m.parent.selected.hovering = hovering
                m.parent.selected.base = base
            end
        else
            return nil
        end
    end
    local isD = function(d)
        return function(c)
            if c.difficulty == d then
                love.graphics.setColor(unpack(HIGHLIGHT))
            else
                love.graphics.setColor(unpack(WHITE))
            end
        end
    end
    return MenuItem:new('Difficulty', {
        MenuItem:new('Normal', {}, "Switch to this difficulty", nil,
            setD(NORMAL),
            "Lower the difficulty to Normal? Difficulty can \z
             be lowered but not raised.",
            isD(NORMAL)
        ),
        MenuItem:new('Adept', {}, "Switch to this difficulty", nil,
            setD(ADEPT),
            "Lower the difficulty to Adept? Difficulty can \z
             be lowered but not raised.",
            isD(ADEPT)
        ),
        MenuItem:new('Master', {}, "Switch to this difficulty", nil,
            setD(MASTER),
            "Lower the difficulty to Master? Difficulty can \z
             be lowered but not raised.",
            isD(MASTER)
        ),
    }, 'View and lower difficulty level')
end

function Player:mkSettingsMenu()
    local sv = function(k, v)
        return function(c)
            if     k == 'm' then c:setMusicVolume(v)
            elseif k == 's' then c:setSfxVolume(v)
            elseif k == 't' then c:setTextVolume(v)
            end
        end
    end
    local iv = function(k, v)
        return function(c)
            if (k == 'm' and c.music_volume == v) or
               (k == 's' and c.sfx_volume == v) or
               (k == 't' and c.text_volume == v) then
                love.graphics.setColor(unpack(HIGHLIGHT))
            else
                love.graphics.setColor(unpack(WHITE))
            end
        end
    end
    return MenuItem:new('Settings', {
        MenuItem:new('Video', {
            MenuItem:new('Coming soon!', {})
        }, 'Change video settings'),
        MenuItem:new('Volume', {
            MenuItem:new('Music', {
                MenuItem:new('Off',  {}, nil, nil, sv('m', OFF),  nil, iv('m', OFF)),
                MenuItem:new('Low',  {}, nil, nil, sv('m', LOW),  nil, iv('m', LOW)),
                MenuItem:new('Med',  {}, nil, nil, sv('m', MED),  nil, iv('m', MED)),
                MenuItem:new('High', {}, nil, nil, sv('m', HIGH), nil, iv('m', HIGH))
            }, 'Set music volume'),
            MenuItem:new('Sound effects', {
                MenuItem:new('Off',  {}, nil, nil, sv('s', OFF),  nil, iv('s', OFF)),
                MenuItem:new('Low',  {}, nil, nil, sv('s', LOW),  nil, iv('s', LOW)),
                MenuItem:new('Med',  {}, nil, nil, sv('s', MED),  nil, iv('s', MED)),
                MenuItem:new('High', {}, nil, nil, sv('s', HIGH), nil, iv('s', HIGH))
            }, 'Set sound effects volume'),
            MenuItem:new('Text effects', {
                MenuItem:new('Off',  {}, nil, nil, sv('t', OFF),  nil, iv('t', OFF)),
                MenuItem:new('Low',  {}, nil, nil, sv('t', LOW),  nil, iv('t', LOW)),
                MenuItem:new('Med',  {}, nil, nil, sv('t', MED),  nil, iv('t', MED)),
                MenuItem:new('High', {}, nil, nil, sv('t', HIGH), nil, iv('t', HIGH))
            }, 'Set text volume')
        }, 'Change audio settings'),
        self:mkDifficultyMenu()
    }, 'View settings and information')
end

function Player:acquire(sp)
    table.insert(self.inventory, sp)
end

function Player:has(id)
    return find(id, mapf(function(s) return s.id end, self.inventory))
end

function Player:discard(id)
    for i = 1, #self.inventory do
        if self.inventory[i].id == id then
            table.remove(self.inventory, i)
            return
        end
    end
end

function Player:joinParty(sp)
    table.insert(self.party, sp)
end

-- When player presses space to interact, a dialogue is started
function Player:interact()

    -- Look through active sprites
    local chapter = self:getChapter()
    local target = nil
    for _, sp in ipairs(chapter:getActiveSprites()) do

        -- If sprite is close, interactive, and not the player, it's valid
        if sp:isInteractive() and
           sp:getId() ~= self:getId() and
           self:AABB(sp, 10) then
            target = sp
            break
        end
    end

    -- Start this chapter's interaction with the found sprite
    if target then
        chapter:interactWith(target)
    end
end

function Player:changeMode(new_mode)
    if new_mode ~= 'browse' then
        self.open_menu = nil
    end
    self.mode = new_mode
end

-- Cannot accept keypresses in frozen mode
function Player:frozenMode()
    pass()
end

function Player:freeMode()

    -- Get keypresses
    local l = love.keyboard.isDown('left')
    local r = love.keyboard.isDown('right')
    local u = love.keyboard.isDown('up')
    local d = love.keyboard.isDown('down')
    local f = love.keyboard.wasPressed('f')
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
    elseif f then
        self:interact()
    end
end

function Player:sceneMode()

    -- Get keypresses
    local u = love.keyboard.wasPressed('up')
    local d = love.keyboard.wasPressed('down')
    local f = love.keyboard.wasPressed('f')

    -- Advance scene based on keypresses
    self:getChapter():sceneInput(f, u, d)
end

function Player:battleMode()

    -- Read keypresses
    local up = love.keyboard.wasPressed('up')
    local down = love.keyboard.wasPressed('down')
    local left = love.keyboard.wasPressed('left')
    local right = love.keyboard.wasPressed('right')
    local f = love.keyboard.wasPressed('f')
    local d = love.keyboard.wasPressed('d')

    -- Interface with battle based on keypresses
    self:getChapter():battleInput(up, down, left, right, f, d)
end

function Player:browseMode()

    -- Read keypresses
    local up = love.keyboard.wasPressed('up')
    local down = love.keyboard.wasPressed('down')
    local f = love.keyboard.wasPressed('f')
    local d = love.keyboard.wasPressed('d')
    local e = love.keyboard.wasPressed('e')
    local esc = love.keyboard.wasPressed('escape')

    local done = false
    if esc or e then
        done = true
    elseif d then
        done = self.open_menu:back()
    elseif f then
        self.open_menu:forward(self:getChapter())
    elseif up ~= down then
        self.open_menu:hover(ite(up, UP, DOWN))
    end

    if done then
        sfx['close']:play()
        self.open_menu:reset()
        self.open_menu = nil
        self:changeMode('free')
    end
end

-- Update player character based on key presses
function Player:update()
    self.modes[self.mode](self)
end

-- Render the player character's interactions
function Player:render(cam_x, cam_y, c)

    -- Render menu if it exists
    if self.open_menu then
        self.open_menu:render(cam_x, cam_y, c)
    end
end

-- MOCK SUPERCLASS
function Player:getId() return self.sp:getId() end
function Player:getName() return self.sp:getName() end
function Player:getPosition() return self.sp:getPosition() end
function Player:getDepth() return self.sp:getDepth() end
function Player:getDimensions() return self.sp:getDimensions() end
function Player:getImpression() return self.sp:getImpression() end
function Player:getAwareness() return self.sp:getAwareness() end
function Player:getChapter() return self.sp:getChapter() end
function Player:isInteractive() return self.sp:isInteractive() end
function Player:isBlocking() return self.sp:isBlocking() end
function Player:toMenuItem() return self.sp:toMenuItem() end
function Player:resetPosition(a, b) return self.sp:resetPosition(a, b) end
function Player:move(a, b) return self.sp:stop(a, b) end
function Player:stop() return self.sp:stop() end
function Player:updatePosition(a, b, c) return self.sp:updatePosition(a, b, c) end
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
