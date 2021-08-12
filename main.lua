Class = require 'class'
push = require 'push'

require 'Util'
require 'Constants'

require 'Game'

-- Seed RNG
math.randomseed(os.time())

-- Make upscaling look pixelated instead of blurry
love.graphics.setDefaultFilter('nearest', 'nearest')

-- Initialize window and launch game
function love.load()

    -- Set up a screen with the virtual width and height
    push:setupScreen(
        VIRTUAL_WIDTH,
        VIRTUAL_HEIGHT,
        WINDOW_WIDTH,
        WINDOW_HEIGHT,
        { fullscreen = false, resizable = true }
    )
    love.window.setTitle('Abelon')

    -- Font used by LOVE's text engine
    local font_file = 'graphics/fonts/font.ttf'
    love.graphics.setFont(love.graphics.newFont(font_file, FONT_SIZE))

    -- Storing keypresses
    love.keyboard.keysPressed = {}
    love.keyboard.keysReleased = {}

    -- Go!
    game = Game()
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

    -- Update everything in the game
    game:update(dt)

    -- reset all keys pressed and released this frame
    love.keyboard.keysPressed = {}
    love.keyboard.keysReleased = {}
end

-- Render game to screen each frame using virtual resolution from push
function love.draw()
    push:apply('start')
    game:render()
    push:apply('end')
end
