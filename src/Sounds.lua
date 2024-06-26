require 'src.Util'
require 'src.Constants'

Sound = class('Sound')

function Sound:initialize(id, base_vol)
    self.id = id
    self.base_vol = base_vol
    self.set_vol = 1
    local audio_file = 'audio/sounds/' .. self.id .. '.wav'
    self.src = love.audio.newSource(audio_file, 'static')
    self.src:setLooping(false)
end

function Sound:play(mod)
    if not mod then mod = 1 end
    self.src:setVolume(mod * self.base_vol * self.set_vol)
    self.src:seek(0.0)
    self.src:play()
end

function Sound:setVolume(vol)
    self.set_vol = vol
end

-- INITIALIZE AUDIO DATA
sfx = {}
local sfx_data = {
    {
        ['id'] = 'select'
    },
    {
        ['id'] = 'cancel'
    },
    {
        ['id'] = 'hover'
    },
    {
        ['id'] = 'close'
    },
    {
        ['id'] = 'open'
    },
    {
        ['id'] = 'victory'
    },
    {
        ['id'] = 'walk',
        ['users'] = {{'abelon'}, {'kath'}, {'elaine'}, {'wolf', 4}, {'alphawolf', 2}}
    },
    {
        ['id'] = 'crackle',
        ['users'] = {{'torch', 4}},
        ['base'] = 0.5
    },
    {
        ['id'] = 'loud-crackle',
        ['users'] = {{'campfire'}}
    },
    {
        ['id'] = 'levelup'
    },
    {
        ['id'] = 'ally-phase'
    },
    {
        ['id'] = 'enemy-phase'
    },
    {
        ['id'] = 'new-game'
    },
    {
        ['id'] = 'conflagration'
    },
    {
        ['id'] = 'sever'
    },
    {
        ['id'] = 'text-kath-1'
    },
    {
        ['id'] = 'text-kath-2'
    },
    {
        ['id'] = 'text-elaine-1'
    },
    {
        ['id'] = 'text-elaine-2'
    },
    {
        ['id'] = 'text-default'
    }
}
for i = 1, #sfx_data do
    local d = sfx_data[i]
    local base_vol = 1
    if d['base'] then base_vol = d['base'] end
    if d['users'] then
        for j = 1, #d['users'] do
            local user = d['users'][j]
            if user[2] then
                for k = 1, user[2] do
                    sfx[user[1] .. tostring(k) .. '-' .. d['id']] = Sound:new(d['id'], base_vol)
                end
            else
                sfx[user[1] .. '-' .. d['id']] = Sound:new(d['id'], base_vol)
            end
        end
    else
        sfx[d['id']] = Sound:new(d['id'], base_vol)
    end
end
