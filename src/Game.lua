require 'src.Util'
require 'src.Constants'

require 'src.Chapter'

Game = class('Game')

-- Initialize game context
function Game:initialize(chapter)
    self.chapter = chapter
end

function Game:loadSave(path, quick, fresh)

    -- Load file
    local res, _ = binser.readFile('abelon/' .. SAVE_DIRECTORY .. path)
    local c = res[1]
    c:setSfxVolume(self.chapter.sfx_volume)
    -- c:setTextVolume(self.chapter.text_volume)
    c.scene_inputs = {}
    c.battle_inputs = {}
    if quick then
        os.remove('abelon/' .. SAVE_DIRECTORY .. path)
    else
        c:autosave(true)
        if c.battle then
            c.battle:openBattleStartMenu()
        end
    end

    -- When hot-reloading an earlier save, preserve some settings
    if not fresh then
        c.turn_autoend = self.chapter.turn_autoend
        c.music_volume = self.chapter.music_volume
        c.sfx_volume   = self.chapter.sfx_volume
        c.text_volume  = self.chapter.text_volume
        c:setSfxVolume(self.chapter.sfx_volume)
        -- c:setTextVolume(self.chapter.text_volume)
    end

    self.chapter = c
end
