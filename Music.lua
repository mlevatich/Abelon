require 'Util'
require 'Constants'

Music = Class{}

-- Constructor for an audio source
function Music:init(name)

    -- Identity
    self.name = name

    -- Parse data file
    local data_file = 'Abelon/data/music/' .. self.name .. '.txt'
    local data = readLines(data_file)
    self.end_intro = tonumber(readField(data[3]))
    self.begin_fade = tonumber(readField(data[4]))
    self.fade_duration = tonumber(readField(data[5]))

    -- Load audio source
    local audio_file = 'audio/music/' .. self.name .. '.wav'
    self.src = love.audio.newSource(audio_file, 'stream')
    self.src:setLooping(false)

    -- We maintain a duplicate in a buffer to fade in as the src fades out,
    -- to accomplish smooth looping
    self.buf = love.audio.newSource(audio_file, 'stream')
    self.buf:setLooping(false)
end

-- Update/start the music
function Music:update(dt)

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
        -- (volumes add up to full volume)
        self.src:setVolume(1 - factor)
        self.buf:setVolume(factor)

    elseif factor >= 1 then

        -- Buf is the only thing playing now, at full volume
        self.buf:setVolume(1)
        self.src:stop()

        -- Switch refs
        local tmp = self.src
        self.src = self.buf
        self.buf = tmp
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
