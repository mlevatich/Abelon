-- Seed RNG
math.randomseed(os.time())

-- Make upscaling look pixelated instead of blurry
love.graphics.setDefaultFilter('nearest', 'nearest')

-- Libs
class  = require 'lib.middleclass'
push   = require 'lib.push'
binser = require 'lib.binser'
require 'src.Util'
require 'src.Constants'
require 'src.Music'
require 'src.Sounds'
require 'src.Game'
require 'src.Skill'
require 'src.Menu'
require 'src.Sprite'
require 'src.Player'
require 'src.Map'
require 'src.Battle'

-- Register classes so they're serializable
-- Don't serialize Music, preloaded
-- Don't serialize Sound, preloaded
-- Don't serialize Animation, only referenced by graphics preload
-- Don't serialize Scene, can only save when current_scene is nil
binser.register(Scaling)
binser.register(Buff)
binser.register(Effect)
binser.register(Skill)
binser.register(MenuItem)
binser.register(Menu)
binser.register(Sprite)
binser.register(Player)
binser.register(Map)
binser.register(GridSpace)
binser.register(Battle)
binser.register(Game)

-- Game object, Title Screen object
local game = nil
local title = nil

-- total time, time of last frame
local t = 0
local lastframe = 0

-- Initialize window and start game
function love.load(args)

    -- Set up a window with the virtual width and height
    local WW, WH = love.window.getDesktopDimensions()
    push:setupScreen(ZOOM_WIDTH, ZOOM_HEIGHT, 1280, 720, {fullscreen=false, resizable=true})
    love.window.setTitle('Abelon')

    -- Set font
    love.graphics.setFont(love.graphics.newFont(FONT_FILE, FONT_SIZE))

    -- Storing keypresses
    love.keyboard.keysPressed = {}

    -- Time of last frame
    lastframe = love.timer.getTime()

    -- Debug mode
    debug = (args[1] == '-debug')

    -- In debug mode, delete existing saves
    if debug then
        os.remove('abelon/' .. SAVE_DIRECTORY .. 'save.dat')
        os.remove('abelon/' .. SAVE_DIRECTORY .. 'battle_save.dat')
        os.remove('abelon/' .. SAVE_DIRECTORY .. 'chapter_save.dat')
        os.remove('abelon/' .. SAVE_DIRECTORY .. 'quicksave.dat')
    end

    -- Start from title screen (or load from a chapter file in debug mode)
    if debug and args[2] then
        game = Game:new(args[2], NORMAL)
        game:saveChapter()
    else
        title = Title:new()
    end
end

-- Resize game window
function love.resize(w, h)
    push:resize(w, h)
end

-- Collect a keypress on this frame
function love.keyboard.wasPressed(key)
    return love.keyboard.keysPressed[key]
end

-- Record a keypress on this frame
function love.keypressed(key)
    love.keyboard.keysPressed[key] = true
end

-- Update each frame, dt is seconds since last frame
function love.update(dt)

    -- Cap framerate
    local slack = FRAME_DUR - (love.timer.getTime() - lastframe)
    if slack > 0 then love.timer.sleep(slack) end
	lastframe = love.timer.getTime()
    t = t + dt

    -- If in transition, check when we're finished with title
    if game and title then
        if t - title.t_launch >= 3.5 then
            title = nil
        end

    -- Update game and hot-reload a save if requested
    elseif game then
        local timestep = FRAME_DUR
        if debug then -- Fast forward and slow down allowed in debug mode
            if love.keyboard.isDown(',') then
                timestep = FRAME_DUR / 5
            elseif love.keyboard.isDown('.') then
                timestep = FRAME_DUR * 3
            end
        end
        local signal = game:update(timestep)
        if signal == RELOAD_BATTLE then
            game = game:loadSave(BATTLE_SAVE)
        elseif signal == RELOAD_CHAPTER then
            game = game:loadSave(CHAPTER_SAVE)
        end

    -- Update title screen, possibly launching game
    else
        title:update()
    end

    -- Reset all keys pressed this frame
    love.keyboard.keysPressed = {}
end

-- Render game or title to screen each frame using virtual resolution from push
function love.draw()
    
    -- If in transition, fade from title render into game render
    push:apply('start')
    if game and title then
        local alpha = 1
        local dt = t - title.t_launch
        if dt < 2 then
            alpha = 1 - (2 - dt) / 2
            title:render()
        elseif dt > 3 then
            alpha = math.max(0, 1 - (dt - 3) / 0.5)
            game:render()
        end
        drawFade(alpha)

    -- Otherwise render whichever of title or game is active
    elseif game then
        game:render()
    else
        title:render()
    end
    push:apply('end')
end



-- TITLE SCREEN CLASS
Title = class('Title')

-- Initialize title sequence
function Title:initialize()

    -- Fonts
    self.titlefont = love.graphics.newFont(FONT_FILE, TITLE_FONT_SIZE)
    self.subfont = love.graphics.newFont(FONT_FILE, SUBFONT_SIZE)

    -- Menu state
    self.state = M_GAME
    self.cursor = 0
    self.difficulty = MASTER
    self.t_launch = 0

    -- Detect existing saved game
    self.save = nil
    if love.filesystem.getInfo(SAVE_DIRECTORY .. QUICK_SAVE) then
        self.save = self:freshGame('1-1')
        self.save = self.save:loadSave(QUICK_SAVE, true, true)
    elseif love.filesystem.getInfo(SAVE_DIRECTORY .. AUTO_SAVE) then
        self.save = self:freshGame('1-1')
        self.save = self.save:loadSave(AUTO_SAVE, false, true)
    end
end

-- Create a brand new game context
function Title:freshGame(id)
    return Game:new(id, self.difficulty)
end

-- Initialize the game variable, starting the
-- transition from title to game
function Title:launchGame(from_save)
    self.t_launch = t
    music_tracks['The-Lonely-Knight']:stop()
    sfx['new-game']:play()
    love.keyboard.keysPressed = {}
    if from_save then
        game = from_save
    else
        game = self:freshGame('1-1')
        game:saveChapter()
    end
    game:update(FRAME_DUR, true)
end

function Title:update()

    -- Ignore keyboard inputs until the byline is finished
    if t > T_BYLINE + 1 then

        -- How many cursor options?
        local n = ite(self.state == M_GAME and not self.save, 1, ite(self.state == M_DIFF, 3, 2))

        -- Get keyboard inputs
        local f    = love.keyboard.wasPressed('f')
        local d    = love.keyboard.wasPressed('d')
        local up   = love.keyboard.wasPressed('up')
        local down = love.keyboard.wasPressed('down')

        -- Process inputs
        -- 'select'
        if f then
            if self.state == M_GAME then
                if self.save and self.cursor == 0 then
                    return self:launchGame(self.save)
                else
                    self.state = M_DIFF
                    sfx['select']:play()
                end
            elseif self.state == M_DIFF then
                self.difficulty = self.cursor + 1
                if not self.save then
                    return self:launchGame()
                else
                    self.state = M_CONF
                    sfx['select']:play()
                end
            else
                if self.cursor == 0 then
                    self.state = M_DIFF
                    sfx['cancel']:play()
                else
                    return self:launchGame()
                end
            end
            self.cursor = 0

        -- 'go back'
        elseif d then
            self.cursor = 0
            local old = self.state
            self.state = ite(self.state == M_CONF, M_DIFF, M_GAME)
            if self.state ~= old then sfx['cancel']:play() end

        -- Cursor up
        elseif down and not up then
            self.cursor = (self.cursor + 1) % n
            sfx['hover']:play()

        -- Cursor down
        elseif up and not down then
            self.cursor = (self.cursor + n - 1) % n
            sfx['hover']:play()
        end
    end

    music_tracks['The-Lonely-Knight']:update(0, HIGH * math.min(1, 1 - ((2 - t) / 2)))
end

function Title:render()

    -- Render either byline or title menu, depending on time passed
    if t < T_BYLINE then

        -- Render fade-in byline
        local s = "A game by Max Levatich"
        local x = ZOOM_WIDTH / 2 - (#s / 2 * CHAR_WIDTH)
        local y = ZOOM_HEIGHT / 2 - FONT_SIZE / 2
        local alpha = 0
        if t < T_BYLINE / 3 then
            alpha = (T_BYLINE / 3 - t) / (T_BYLINE / 3)
        elseif t > T_BYLINE * 2 / 3 then
            alpha = (t - T_BYLINE * 2 / 3) / (T_BYLINE / 3)
        end
        renderString(s, x, y)
        drawFade(alpha)
    else

        -- Render sprites
        local abelon_anim = sprite_graphics['abelon']['animations']['walking']
        local kath_anim = sprite_graphics['kath']['animations']['walking']
        love.graphics.draw(
            spritesheet,
            abelon_anim.frames[math.floor(t / (1/6.5)) % 4 + 1],
            ZOOM_WIDTH / 2 + 100, ZOOM_HEIGHT / 2 + 60,
            0, RIGHT, 1, 15.5, 15.5
        )
        love.graphics.draw(
            spritesheet,
            kath_anim.frames[(math.floor(t / (1/6.5)) + 2) % 4 + 1],
            ZOOM_WIDTH / 2 - 100, ZOOM_HEIGHT / 2 + 60,
            0, LEFT, 1, 15.5, 15.5
        )

        -- Render game title
        local s = "ABELON"
        local w = TITLE_FONT_SIZE + TEXT_MARGIN_X
        local x = ZOOM_WIDTH / 2 - (#s / 2 * w) + 9
        love.graphics.push('all')
        love.graphics.setColor(unpack(WHITE))
        love.graphics.setFont(self.titlefont)
        for i = 1, #s do
            printChar(s:sub(i, i), x + w * (i - 1), ZOOM_HEIGHT / 5)
        end
        love.graphics.pop()

        -- Render controls
        local s1 = "Use the arrow keys to navigate"
        local s2 = "Press F to confirm"
        local s3 = "Press D to go back"
        love.graphics.push('all')
        love.graphics.scale(1 / ZOOM)
        love.graphics.setFont(self.subfont)
        renderString(s1, HALF_MARGIN, HALF_MARGIN)
        renderString(s2, HALF_MARGIN, HALF_MARGIN + LINE_HEIGHT)
        renderString(s3, HALF_MARGIN, HALF_MARGIN + LINE_HEIGHT * 2)

        -- Render menu options
        local vh = VIRTUAL_HEIGHT / 2
        local vw = VIRTUAL_WIDTH / 2
        local xCenter = function(s)
            return vw - CHAR_WIDTH * #s / 2 + 3
        end
        if self.state == M_GAME then
            local s1, s2 = 'Continue', 'New game'
            if self.save then
                renderString(s1, xCenter(s1), vh + 50)
                renderString(s2, xCenter(s2), vh + 90)
            else
                renderString(s2, xCenter(s2), vh + 70)
            end
        elseif self.state == M_DIFF then
            local s1 = 'Select a difficulty level'
            local s2, s3, s4 = 'Normal', 'Adept ', 'Master'
            renderString(s1, xCenter(s1), vh - 30)
            renderString(s2, xCenter(s2), vh + 30)
            renderString(s3, xCenter(s3), vh + 70)
            renderString(s4, xCenter(s4), vh + 110)
        else
            local s1 = 'Are you sure? This will OVERWRITE your existing saved game!'
            local s2, s3 = 'No ', 'Yes'
            renderString(s1, xCenter(s1), vh - 30)
            renderString(s2, xCenter(s2), vh + 50)
            renderString(s3, xCenter(s3), vh + 90)
        end
        
        -- Render cursor
        if t > T_BYLINE + 1 then
            if self.state == M_GAME then
                if self.save then
                    renderString('>', xCenter('Continue') - 20 - (math.floor(t*2) % 2) * 2, vh + 50 + self.cursor * 40)
                else
                    renderString('>', xCenter('Continue') - 20 - (math.floor(t*2) % 2) * 2, vh + 70)
                end
            elseif self.state == M_DIFF then
                renderString('>', xCenter('Normal') - 20 - (math.floor(t*2) % 2) * 2, vh + 30 + self.cursor * 40)
            else
                renderString('>', xCenter('Yes') - 20 - (math.floor(t*2) % 2) * 2, vh + 50 + self.cursor * 40)
            end
        end
        love.graphics.pop()

        -- Render fade-in
        drawFade(math.max(0, 1 - (t - T_BYLINE)))
    end
end