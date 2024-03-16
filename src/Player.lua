require 'src.Util'
require 'src.Constants'

require 'src.Animation'
require 'src.Scene'
require 'src.Sprite'
require 'src.Menu'

require 'src.Sounds'

Player = class('Player')

-- Movement constants
WALK_SPEED = 80
DIAG_SPEED = 64

-- Initialize the player character, Abelon
function Player:initialize(sp)

    -- Player is a superclass of Sprite
    self.sp = sp

    self:addBehaviors({ ['free'] = function(sp, dt) sp:updatePosition(dt) end })

    -- Abelon has different modes to account for the player's keyboard input
    self.modes = {
        ['frozen'] = function(p) p:frozenMode()  end,
        ['free']   = function(p) p:freeMode()   end,
        ['scene']  = function(p) p:sceneMode()  end,
        ['browse'] = function(p) p:browseMode() end,
        ['battle'] = function(p) p:battleMode() end
    }
    self.mode = 'free'

    -- Abelon's inventory
    self.inventory = {}

    -- Abelon's party and the names he knows
    self.party = { self.sp }
    self.introduced = {}
    self.old_tutorials = {}

    -- Abelon can open menus
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
    local inv_m = MenuItem:new('Items', inv_ch, 'View possessions')

    -- Open inventory menu
    self:openMenu(
        { inv_m, self:mkPartyMenu(), self:mkSettingsMenu(), self:mkQuitMenu() }
    )
end

function Player:mkPartyMenu()
    local party = mapf(function(sp) return sp:toPartyMember() end, self.party)
    return MenuItem:new('Party', party, 'View traveling companions')
end

function Player:mkQuitMenu()
    local save = function(c)
        self:changeMode('free')
        c:saveAndQuit()
    end
    local restart = function(c) c:reloadChapter() end
    return MenuItem:new('Quit', {
        MenuItem:new('Save and quit', {}, nil, nil, save,
            "Save current progress and close the game?"
        ),
        MenuItem:new('Restart chapter', {}, nil, nil, restart,
            "Are you SURE you want to restart the chapter? You will lose ALL \z
             progress made during the chapter."
        )
    }, 'Save and quit, or restart the chapter')
end

function Player:mkDifficultyMenu()
    local setD = function(d)
        if self:getGame().difficulty > d then
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
        return function(g)
            return ite(g.difficulty == d, HIGHLIGHT, WHITE)
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

function Player:mkTutorialBox(n, w, chars)
    local eles = {}
    local row = 0
    for j = 1, #TUTORIALS[n] do
        local s = TUTORIALS[n][j]
        if n == 'Battle: Ignea' and j == 2 then
            local sd, sp = "Master", "no Ignea"
            if self.sp.game.difficulty == ADEPT then
                sd = "Adept"
                sp = "25% of each ally's maximum Ignea"
            elseif self.sp.game.difficulty == NORMAL then
                sd = "Normal"
                sp = "50% of each ally's maximum Ignea"
            end
            s = string.format(s, sd, sp)
        end
        local lines, _ = splitByCharLimit(s, chars)
        eles[#eles + 1] = mkEle('text', lines, HALF_MARGIN, 
            HALF_MARGIN + row * LINE_HEIGHT, { 0.8, 0.8, 0.8, 1 }, true)
        row = row + #lines + 1
    end
    return { ['w'] = w, ['elements'] = eles, ['light'] = true }
end

function Player:mkTutorialsMenu()
    local items = {}
    for i = 1, #self.old_tutorials do
        local n = self.old_tutorials[i]
        local hbox = self:mkTutorialBox(n, HBOX_WIDTH, 58)
        items[#items + 1] = MenuItem:new(n, {}, "", hbox)
    end
    return MenuItem:new('Tutorials', items, 'View old tutorials')
end

function Player:mkSettingsMenu()
    local sv = function(k, v)
        return function(g)
            if     k == 'm' then g:setMusicVolume(v)
            elseif k == 's' then g:setSfxVolume(v)
            elseif k == 't' then g:setTextVolume(v)
            end
        end
    end
    local iv = function(k, v)
        return function(g)
            if (k == 'm' and g.music_volume == v) or
               (k == 's' and g.sfx_volume == v) or
               (k == 't' and g.text_volume == v) then
                return HIGHLIGHT
            else
                return WHITE
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
        MenuItem:new('Turn end', {
            MenuItem:new('Auto', {},
                "Turn automatically ends after all allies have acted",
                nil, function(g) g.turn_autoend = true end, nil,
                function(g)
                    return ite(g.turn_autoend, HIGHLIGHT, WHITE)
                end
            ),
            MenuItem:new('Manual', {},
                "'End turn' must be selected from the options menu",
                nil, function(g) g.turn_autoend = false end, nil,
                function(g)
                    return ite(g.turn_autoend, WHITE, HIGHLIGHT)
                end
            )
        }, 'Change turn ending behavior in battle'),
        self:mkTutorialsMenu(),
        self:mkDifficultyMenu()
    }, 'View settings and tutorials')
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

function Player:introduce(name)
    self.introduced[name] = true
end

function Player:knows(name)
    return self.introduced[name]
end

-- When player presses space to interact, a dialogue is started
function Player:interact()

    -- Look through active sprites
    local game = self:getGame()
    local target = nil
    for _, sp in ipairs(game:getActiveSprites()) do

        -- If sprite is close, interactive, and not the player, it's valid
        if sp:isInteractive() and
           sp:getId() ~= self:getId() and
           self:AABB(sp, 20) then
            target = sp
            break
        end
    end

    -- Start interaction with the found sprite
    if target then
        game:interactWith(target)
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
    local l = love.keyboard.isDown('left') or love.keyboard.isDown('l')
    local r = love.keyboard.isDown('right') or love.keyboard.isDown("'")
    local u = love.keyboard.isDown('up') or love.keyboard.isDown('p')
    local d = love.keyboard.isDown('down') or love.keyboard.isDown(';')
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
    local u = love.keyboard.wasPressed('up') or love.keyboard.wasPressed('p')
    local d = love.keyboard.wasPressed('down') or love.keyboard.wasPressed(';')
    local f = love.keyboard.wasPressed('f')

    -- Advance scene based on keypresses
    self:getGame():sceneInput(f, u, d)
end

function Player:battleMode()

    -- Read keypresses
    local up = love.keyboard.wasPressed('up') or love.keyboard.wasPressed('p')
    local down = love.keyboard.wasPressed('down') or love.keyboard.wasPressed(';')
    local left = love.keyboard.wasPressed('left') or love.keyboard.wasPressed('l')
    local right = love.keyboard.wasPressed('right') or love.keyboard.wasPressed("'")
    local f = love.keyboard.wasPressed('f')
    local d = love.keyboard.wasPressed('d')

    -- Interface with battle based on keypresses
    self:getGame():battleInput(up, down, left, right, f, d)
end

function Player:browseMode()

    -- Read keypresses
    local up = love.keyboard.wasPressed('up') or love.keyboard.wasPressed('p')
    local down = love.keyboard.wasPressed('down') or love.keyboard.wasPressed(';')
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
        self.open_menu:forward(self:getGame())
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
function Player:render(g)

    -- Render menu if it exists
    if self.open_menu then
        self.open_menu:render(g)
    end
end

-- MOCK SUPERCLASS
function Player:getId() return self.sp:getId() end
function Player:getName() return self.sp:getName() end
function Player:getPosition() return self.sp:getPosition() end
function Player:getPositionOnScreen() return self.sp:getPositionOnScreen() end
function Player:isGround() return self.sp:isGround() end
function Player:getDimensions() return self.sp:getDimensions() end
function Player:getImpression() return self.sp:getImpression() end
function Player:getAwareness() return self.sp:getAwareness() end
function Player:getGame() return self.sp:getGame() end
function Player:isInteractive() return self.sp:isInteractive() end
function Player:isBlocking() return self.sp:isBlocking() end
function Player:getHitboxRect() return self.sp:getHitboxRect() end
function Player:toMenuItem() return self.sp:toMenuItem() end
function Player:resetPosition(a, b) return self.sp:resetPosition(a, b) end
function Player:move(a, b) return self.sp:move(a, b) end
function Player:stop() return self.sp:stop() end
function Player:updatePosition(a, b, c) return self.sp:updatePosition(a, b, c) end
function Player:changeImpression(a) return self.sp:changeImpression(a) end
function Player:changeAwareness(a) return self.sp:changeAwareness(a) end
function Player:changeAnimation(a) return self.sp:changeAnimation(a) end
function Player:changeBehavior(a) return self.sp:changeBehavior(a) end
function Player:addBehaviors(a) return self.sp:addBehaviors(a) end
function Player:AABB(a, b) return self.sp:AABB(a, b) end
function Player:onTile(a, b) return self.sp:onTile(a, b) end
function Player:checkCollisions() return self.sp:checkCollisions() end
