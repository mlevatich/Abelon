require 'src.Util'
require 'src.Constants'

local Music = class('Music')

-- Constructor for an audio source
function Music:initialize(name)

    -- Identity
    self.name = name

    -- Parse data file
    local data_file = 'Abelon/data/music/' .. self.name .. '.txt'
    local data = readLines(data_file)
    self.end_intro = readField(data[3], tonumber)
    self.begin_fade = readField(data[4], tonumber)
    self.fade_duration = readField(data[5], tonumber)

    -- Load audio source
    local audio_file = 'audio/music/' .. self.name .. '.wav'
    self.src = love.audio.newSource(audio_file, 'stream')
    self.src:setVolume(1)
    self.src:setLooping(false)

    -- We maintain a duplicate in a buffer to fade in as the src fades out,
    -- to accomplish smooth looping
    self.buf = love.audio.newSource(audio_file, 'stream')
    self.buf:setVolume(1)
    self.buf:setLooping(false)
end

-- Update/start the music
function Music:update(dt, volume)

    -- Start music track if it hasn't started already
    if not self.src:isPlaying() then
        self.src:seek(0.0)
        self.src:play()
    end

    -- Looping is controlled by fading out the source track
    -- as the buffer track fades in
    local factor = (self.src:tell() - self.begin_fade) / self.fade_duration
    if factor >= 0 and factor < 1 then

        -- Make sure buf is playing, starting from where the song's intro ends
        if not self.buf:isPlaying() then
            self.buf:seek(self.end_intro)
            self.buf:play()
        end

        -- Set volume of src and buf according to fade_factor
        self.src:setVolume((1 - factor * factor)             * volume)
        self.buf:setVolume((1 - (factor - 1) * (factor - 1)) * volume)

    elseif factor >= 1 then

        -- Buf is the only thing playing now, at full volume
        self.buf:setVolume(volume)
        self.src:setVolume(0)
        self.src:stop()

        -- Switch refs
        local tmp = self.src
        self.src = self.buf
        self.buf = tmp
    else

        -- Normally, src volume is full, buf volume is 0
        self.src:setVolume(volume)
        self.buf:setVolume(0)
    end
end

-- Stop the music
function Music:stop()

    -- Stop music
    self.src:stop()
    self.buf:stop()
    self.src:seek(0.0)
    self.buf:seek(0.0)
end

-- INITIALIZE AUDIO DATA
music_tracks = {}
local track_ids = { 'Dying-Forest', 'A-Single-Shard-Of-Ignea', 'The-Lonely-Knight' }
for i = 1, #track_ids do
    music_tracks[track_ids[i]] = Music:new(track_ids[i])
end
