Class = require 'class'
push = require 'push'
require 'Game'

-- Apparent game resolution
VIRTUAL_WIDTH = 864
VIRTUAL_HEIGHT = 486

-- Actual window resolution
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

-- Seed RNG
math.randomseed(os.time())

-- Make upscaling look pixelated instead of blurry
love.graphics.setDefaultFilter('nearest', 'nearest')

-- Initialize window and launch game
function love.load()

    -- Set up a screen with the virtual width and height
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true
    })
    love.window.setTitle('Abelon')

    -- Font used by LOVE's text engine
    love.graphics.setFont(love.graphics.newFont('fonts/font.ttf', 8))

    -- Storing
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

-- Collect a key release on this frame
function love.keyboard.wasReleased(key)
    return love.keyboard.keysReleased[key]
end

-- Record a keypress on this frame
function love.keypressed(key)
    love.keyboard.keysPressed[key] = true
end

-- Record a keyrelease on this frame
function love.keyreleased(key)
    love.keyboard.keysReleased[key] = true
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
