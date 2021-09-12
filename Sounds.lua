require 'Util'
require 'Constants'

local Sound = class('Sound')

function Sound:initialize(id)
    self.id = id
    local audio_file = 'audio/sounds/' .. self.id .. '.wav'
    self.src = love.audio.newSource(audio_file, 'static')
    self.src:setLooping(false)
end

function Sound:play()
    self.src:seek(0.0)
    self.src:play()
end

function Sound:setVolume(vol)
    self.src:setVolume(vol)
end

sfx = {}
local sfx_ids = { 'select', 'cancel', 'hover', 'close', 'open', 'victory' }
for i = 1, #sfx_ids do sfx[sfx_ids[i]] = Sound:new(sfx_ids[i]) end
