require 'Util'
require 'Constants'

require 'Chapter'

Game = class('Game')

-- Initialize game context
function Game:initialize()

    -- Track current chapter
    self.chapter_id = 0
    self.chapter = nil

    -- TODO title screen stuff

    -- Start first chapter
    self:nextChapter()

    -- TODO: on reload
    -- set sfx volume
    -- set text volume

    -- TODO: upvalue suspects:
    -- MenuItem.action
    -- Sprite.behaviors
end

-- Clear all sprites from the current map and change the current map
function Game:nextChapter()

    -- Stop existing chapter if there is one
    if self.chapter then
        self.chapter:endChapter()
    end

    -- TODO if last chapter, roll credits!

    -- Start new chapter
    self.chapter_id = self.chapter_id + 1
    self.chapter = Chapter:new(self.chapter_id)
end

-- Update game state
function Game:update(dt)

    -- Update chapter state, map, and all sprites in chapter
    local chapter_end = self.chapter:update(dt)

    -- Detect and handle chapter change
    if chapter_end then
        self:nextChapter()
    end
end

-- Render everything!
function Game:render()
    self.chapter:render()
end
