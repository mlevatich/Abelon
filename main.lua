class = require 'lib.middleclass'
push = require 'lib.push'
binser = require 'lib.binser'

-- Seed RNG
math.randomseed(os.time())

-- Make upscaling look pixelated instead of blurry
love.graphics.setDefaultFilter('nearest', 'nearest')

require 'src.Util'
require 'src.Constants'

require 'src.Title'
require 'src.Game'
require 'src.Skill'
require 'src.Menu'
require 'src.Sprite'
require 'src.Player'
require 'src.Map'
require 'src.Battle'
require 'src.Chapter'

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
binser.register(Chapter)

local game = nil
local title = nil
local t = 0.0
local transition_t = 0.0

-- Initialize window and launch game
function love.load()

    -- Set up a screen with the virtual width and height
    local WINDOW_WIDTH, WINDOW_HEIGHT = love.window.getDesktopDimensions()
    push:setupScreen(
        VIRTUAL_WIDTH / ZOOM,
        VIRTUAL_HEIGHT / ZOOM,
        1280,
        720,
        { fullscreen = false, resizable = true }
    )
    love.window.setTitle('Abelon')

    -- Font used by LOVE's text engine
    local font_file = 'graphics/fonts/' .. FONT .. '.ttf'
    love.graphics.setFont(love.graphics.newFont(font_file, FONT_SIZE))

    -- Storing keypresses
    love.keyboard.keysPressed = {}
    love.keyboard.keysReleased = {}

    -- Go!
    title = Title:new(font_file)
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

    t = t + dt
    if t >= FRAME_DUR then

        -- Update game or title screen if game hasn't started
        if game and title then
            transition_t = transition_t + dt
            if transition_t >= 3.5 then
                title = nil
            end
        elseif game then
            game:update(FRAME_DUR)
        else
            game = title:update(FRAME_DUR)
            if game then game:update(FRAME_DUR) end
        end
        t = t - FRAME_DUR

        -- reset all keys pressed and released this frame
        love.keyboard.keysPressed = {}
        love.keyboard.keysReleased = {}
    end
end

-- Render game or title to screen each frame using virtual resolution from push
function love.draw()
    push:apply('start')
    if game and title then
        local bb_alpha = 1
        if transition_t < 2 then
            bb_alpha = 1 - (2 - transition_t) / 2
            title:render()
        elseif transition_t > 3 and transition_t < 3.5 then
            bb_alpha = 1 - (transition_t - 3) / 0.5
            game:render()
        end
        love.graphics.push('all')
        love.graphics.setColor(0, 0, 0, bb_alpha)
        love.graphics.rectangle('fill', 0, 0, VIRTUAL_WIDTH / ZOOM, VIRTUAL_HEIGHT / ZOOM)
        love.graphics.pop()
    elseif game then
        game:render()
    else
        title:render()
    end
    push:apply('end')
end