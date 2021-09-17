require 'Util'
require 'Constants'

require 'Chapter'

Game = class('Game')

-- Initialize game context
function Game:initialize()

    -- Track current chapter
    self.chapter = nil

    -- TODO: title screen stuff

    if love.filesystem.getInfo(SAVE_DIRECTORY .. AUTO_SAVE) then

        -- Read the chapter from save file
        local res, _ = binser.readFile('abelon/' .. SAVE_DIRECTORY .. AUTO_SAVE)
        self.chapter = res[1]

        self:cleanChapter()

        -- If in a battle, reopen the closed menu
        if self.chapter.battle and self.chapter.battle.start_save then
            self.chapter.battle:openBattleStartMenu()
        end
    else
        self:nextChapter()
    end

    G = self
end

function Game:cleanChapter()

    -- Reset volume levels and clear any lingering inputs
    self.chapter:setSfxVolume(self.chapter.sfx_volume)
    -- self.chapter:setTextVolume(self.chapter.text_volume)
    self.chapter.scene_inputs = {}
    self.chapter.battle_inputs = {}
end

-- Clear all sprites from the current map and change the current map
function Game:nextChapter()

    -- Stop existing chapter if there is one
    if self.chapter then
        self.chapter:endChapter()

        -- TODO if last chapter, roll credits!

        -- Start new chapter
        self.chapter = Chapter:new(self.chapter.id + 1)
    else
        -- Start first chapter!
        self.chapter = Chapter:new(1)
    end
end

function Game:loadSave(path)
    local res, _ = binser.readFile('abelon/' .. SAVE_DIRECTORY .. path)
    self.chapter = res[1]
    self:cleanChapter()
    self.chapter:autosave(true)
end

-- Update game state
function Game:update(dt)

    -- Update chapter state, map, and all sprites in chapter
    local signal = self.chapter:update(dt)

    -- Detect and handle chapter change or reload
    if signal then

        local set_ta = self.chapter.turn_autoend
        local set_mv = self.chapter.music_volume
        local set_sv = self.chapter.sfx_volume
        local set_tv = self.chapter.text_volume
        if signal == RELOAD_BATTLE then
            self:loadSave(BATTLE_SAVE)
            self.chapter.battle:openBattleStartMenu()
        elseif signal == RELOAD_CHAPTER then
            self:loadSave(CHAPTER_SAVE)
        elseif signal == END_CHAPTER then
            self:nextChapter()
        end
        self.chapter.turn_autoend = set_ta
        self.chapter.music_volume = set_mv
        self.chapter.sfx_volume   = set_sv
        self.chapter.text_volume  = set_tv
        self.chapter:setSfxVolume(set_sv)
        -- self.chapter:setTextVolume(set_tv)
    end
end

-- Render everything!
function Game:render()
    self.chapter:render()
end
