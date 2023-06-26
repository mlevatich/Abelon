require 'src.Util'
require 'src.Constants'

require 'src.Chapter'

Game = class('Game')

-- Initialize game context
function Game:initialize(chapter)
    self.chapter = chapter
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
    self.chapter:setSfxVolume(self.chapter.sfx_volume)
    -- self.chapter:setTextVolume(self.chapter.text_volume)
    self.chapter.scene_inputs = {}
    self.chapter.battle_inputs = {}
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
