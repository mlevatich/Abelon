require 'Util'
require 'Constants'

require 'Chapter'

Game = class('Game')

-- Initialize game context
function Game:initialize()

    -- Track current chapter
    self.chapter = nil

    -- Time passed since last game update
    self.t = 0

    -- Detect quicksave or autosave
    if love.filesystem.getInfo(SAVE_DIRECTORY .. QUICK_SAVE) then
        self:loadSave(QUICK_SAVE, true)
    elseif love.filesystem.getInfo(SAVE_DIRECTORY .. AUTO_SAVE) then
        self:loadSave(AUTO_SAVE)
    else
        self:nextChapter()
    end
end

function Game:cleanChapter()
    self.chapter:setSfxVolume(self.chapter.sfx_volume)
    -- self.chapter:setTextVolume(self.chapter.text_volume)
    self.chapter.scene_inputs = {}
    self.chapter.battle_inputs = {}
end

-- Clear all sprites from the current map and change the current map
function Game:nextChapter()
    if self.chapter then
        self.chapter:endChapter()
        self.chapter = Chapter:new(self.chapter.id + 1)
    else
        self.chapter = Chapter:new(1)
    end
end

function Game:loadSave(path, quick)

    -- Store settings
    local c = self.chapter
    if c then
        set_ta = c.turn_autoend
        set_mv = c.music_volume
        set_sv = c.sfx_volume
        set_tv = c.text_volume
    end

    -- Load file
    local res, _ = binser.readFile('abelon/' .. SAVE_DIRECTORY .. path)
    self.chapter = res[1]
    self:cleanChapter()
    if quick then
        os.remove('abelon/' .. SAVE_DIRECTORY .. path)
    else
        self.chapter:autosave(true)
        if self.chapter.battle then
            self.chapter.battle:openBattleStartMenu()
        end
    end

    -- Restore settings
    if c then
        self.chapter.turn_autoend = set_ta
        self.chapter.music_volume = set_mv
        self.chapter.sfx_volume   = set_sv
        self.chapter.text_volume  = set_tv
        self.chapter:setSfxVolume(set_sv)
        -- self.chapter:setTextVolume(set_tv)
    end
end

-- Update game state
function Game:update(dt)

    -- Update chapter state, map, and all sprites in chapter
    local signal = self.chapter:update(dt)

    -- Detect and handle chapter change or reload
    if signal == RELOAD_BATTLE then
        self:loadSave(BATTLE_SAVE)
    elseif signal == RELOAD_CHAPTER then
        self:loadSave(CHAPTER_SAVE)
    elseif signal == END_CHAPTER then
        self:nextChapter()
    end
end

-- Render everything!
function Game:render()
    self.chapter:render()
end
