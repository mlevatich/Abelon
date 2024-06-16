require 'src.Util'
require 'src.Constants'

-- INITIALIZE GRAPHICAL DATA
icon_texture = love.graphics.newImage('graphics/icons.png')
icons = getSpriteQuads(
    { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
    , 12, 13, 14, 15, 16, 17, 18, 19, 20, 21 },
    icon_texture, 22, 22, 0
)
status_icons = getSpriteQuads({0, 1, 2, 3, 4}, icon_texture, 8, 8, 23)
spritesheet = love.graphics.newImage('graphics/spritesheet.png')

require 'src.Player'
require 'src.Sprite'
require 'src.Map'
require 'src.Scene'
require 'src.Music'
require 'src.Menu'
require 'src.Sounds'
require 'src.Triggers'
require 'src.Script'
require 'src.Battle'

Game = class('Game')

-- Constructor for our scenario object
function Game:initialize(id, difficulty)

    -- Store id
    self.chapter_id = id
    self.chapter_transition_flag = false -- Has the chapter id changed?

    -- Camera that follows coordinates of player sprite around
    self.camera_x = 0
    self.camera_y = 0
    self.camera_speed = 300

    -- Map info
    self.maps = {}
    self.current_map = nil

    -- Dict from map names to audio sources
    self.map_to_music = {}
    self.current_music = nil

    -- Settings
    self.turn_autoend  = true
    self.music_volume  = ite(debug, OFF, HIGH)
    self.sfx_volume    = ite(debug, OFF, HIGH)
    self.text_volume   = ite(debug, OFF, MED)
    self:setSfxVolume(self.sfx_volume)
    self:setTextVolume(self.text_volume)

    -- Music control
    self.music_vol_mod        = 1
    self.music_vol_mod_target = 1
    self.music_vol_mod_rate   = 0

    -- Rendering information
    self.alpha = 1
    self.fade_rate = 0
    self.in_transition = nil
    self.autosave_flash = 0

    -- Additional rendering vars for flashing messages
    self.flash_alpha = 0
    self.flash_rate = 0
    self.flash_msg = nil

    -- Sprites
    self.sprites = {}
    self.player = nil

    -- Difficulty level
    self.difficulty = difficulty

    -- Dictionary of strings that correspond to different state flags, signifying
    -- that some particular event or dialogue response happened
    self.state = {}

    -- Tracking the scene the player is currently in
    self.current_scene = nil
    self.scene_inputs = {}
    self.callbacks = {}
    self.seen = {}
    self.global_timer = 0

    -- If a tutorial is in progress, store the name
    self.current_tutorial = nil

    -- If the player is in a battle, it goes here
    self.battle = nil
    self.battle_inputs = {}

    -- Stall particular key inputs
    self.input_stall = 0
    self.input_stall_keys = nil

    -- Read into the above fields from world file
    self.signal = nil
    self:loadFresh()
end

function Game:autosave()
    binser.writeFile('abelon/' .. SAVE_DIRECTORY .. AUTO_SAVE, self)
end

function Game:quicksave()
    binser.writeFile('abelon/' .. SAVE_DIRECTORY .. QUICK_SAVE, self)
    love.event.quit(0)
end

function Game:saveBattle()
    binser.writeFile('abelon/' .. SAVE_DIRECTORY .. BATTLE_SAVE, self)
    self:autosave()
end

function Game:saveChapter()
    binser.writeFile('abelon/' .. SAVE_DIRECTORY .. CHAPTER_SAVE, self)
    self:autosave()
end

function Game:saveAndQuit()
    self:autosave()
    love.event.quit(0)
end

function Game:reloadBattle()
    self.signal = RELOAD_BATTLE
    self:stopMusic()
end

function Game:reloadChapter()
    self.signal = RELOAD_CHAPTER
    self:stopMusic()
end

function Game:loadSave(path, quick, fresh)

    -- Load file
    local res, _ = binser.readFile('abelon/' .. SAVE_DIRECTORY .. path)
    local c = res[1]
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
        c.turn_autoend = self.turn_autoend
        c.music_volume = self.music_volume
        c.sfx_volume   = self.sfx_volume
        c.text_volume  = self.text_volume
        c:setSfxVolume(self.sfx_volume)
        c:setTextVolume(self.text_volume)
    end

    return c
end

-- Read a fresh game state from the world file
function Game:loadFresh()

    -- Read lines into list
    local chap_file = 'Abelon/data/' .. self.chapter_id .. '-init.txt'
    local lines = readLines(chap_file)

    -- Iterate over lines of file
    local audio_sources = {}
    local current_map_name = nil
    local sprite_ff = nil
    for i=1, #lines do

        -- Lines starting with -> denote a state fast-forward
        if lines[i]:sub(1,2) == '->' then
            local fname, vals = readNamed(lines[i]:sub(3), readArray)
            if fname == 'State' then
                for i=1, #vals do
                    self.state[vals[i]] = true
                end
            elseif fname == 'Seen' then
                for i=1, #vals do
                    self.seen[vals[i]] = true
                end
            elseif fname == 'Inventory' then
                for i=1, #vals do
                    local sp = self.sprites[vals[i]]
                    if not sp then
                        sp = Sprite:new(vals[i], self)
                        self.sprites[vals[i]] = sp
                    end
                    self.player:introduce(sp:getId())
                    self.player:acquire(sp)
                end
            elseif fname == 'Party' then
                for i=1, #vals do
                    local sp = self.sprites[vals[i]]
                    if not sp then
                        sp = Sprite:new(vals[i], self)
                        self.sprites[vals[i]] = sp
                    end
                    self.player:introduce(sp:getId())
                    self.player:joinParty(sp)
                end
            elseif fname == 'Day' then
                for k,v in pairs(self.maps) do
                    if k == 'east-forest' or k == 'west-forest' 
                    or k == 'south-forest' or k == 'monastery-approach' or k == 'monastery-entrance' then
                        v.lit = 0.0
                    end
                end
            elseif fname == 'Block' then
                for i=1, #vals do
                    self.current_map:blockExit(vals[i])
                end
            else
                sprite_ff = self.sprites[fname]
            end

        -- Lines starting with + denote a sprite fast-forward
        elseif lines[i]:sub(1,1) == '+' then

            local sp = sprite_ff
            local fname, vals = readNamed(lines[i]:sub(2), readArray)
            if fname == 'Impression' then
                sp:changeImpression(tonumber(vals[1]))
            elseif fname == 'Awareness' then
                sp:changeAwareness(tonumber(vals[1]))
            elseif fname == 'Level' then
                local lvls = tonumber(vals[1])
                sp.level = sp.level + lvls
                sp.skill_points = sp.skill_points + lvls
                for k, v in pairs(sp.attributes) do
                    sp.attributes[k] = sp.attributes[k] + lvls
                end
                sp.health = sp.health + (lvls * 2)
                sp.ignea = sp.ignea + lvls
            elseif fname == 'Exp' then
                sp.exp = tonumber(vals[1])
            elseif fname == 'Skills' then
                for i=1, #vals do
                    local known = false
                    for j=1, #sp.skills do
                        if sp.skills[j].id == vals[i] then known = true end
                    end
                    if not known then
                        sp:learn(vals[i])
                    end
                end
            elseif fname == 'BonusAttrs' then
                local attrs = readDict(lines[i]:sub(2), VAL, nil, tonumber)
                for k,_ in pairs(sp.attributes) do
                    if attrs[k] then
                        sp.attributes[k] = sp.attributes[k] + attrs[k]
                    end
                end
                if attrs['endurance'] then
                    sp.health = sp.health + attrs['endurance'] * 2
                end
                if attrs['focus'] then
                    sp.ignea = sp.ignea + attrs['focus']
                end
            end

        -- Lines starting with ~~ denote a new map
        elseif lines[i]:sub(1,2) == '~~' then

            -- Read data from line
            local fields = split(lines[i]:sub(3))
            local map_name, song_name = fields[1], fields[2]
            current_map_name = map_name

            -- Initialize map and tie it to game context
            self.maps[map_name] = Map:new(map_name, self)

            -- Maps sharing a music track share a pointer to the audio
            self.map_to_music[map_name] = song_name

        -- Lines starting with ~ denote a new sprite
        elseif lines[i]:sub(1,1) == '~' then

            -- Collect sprite info from file.
            -- Spawn sprite in map and add it to sprites
            local fields = split(lines[i]:sub(2))
            local sp = self.maps[current_map_name]:spawnSprite(fields, self)
            self.sprites[sp:getId()] = sp

            -- If the sprite is the player character, we make the current map
            -- into the starting map, and initialize a player object
            if fields[5] then
                if fields[5] == 'P' then
                    self.current_map = self.maps[current_map_name]
                    self.player = Player:new(sp)
                    self:updateCamera(100)
                else
                    sp:changeBehavior(fields[5])
                end
            end
        end
    end

    -- Start music
    self:startMapMusic()
end

-- Return all sprite objects belonging to the active map
function Game:getActiveSprites()
    return self.current_map:getSprites()
end

function Game:getSprite(sp_id)
    return self.sprites[sp_id]
end

-- Return the active map
function Game:getMap()
    return self.current_map
end

function Game:playerNearSprite(sp_id, buf, down_ok)
    local x, y = self.player.sp:getPosition()
    local sp = self.current_map:getSprite(sp_id)
    if sp and (sp.current_behavior == 'idle' or sp.current_behavior == 'wander' or (down_ok and sp.current_behavior == 'down')) then
        local kx, ky = sp:getPosition()
        local d = (x - kx) * (x - kx) + (y - ky) * (y - ky)
        local pd = buf * buf
        return d <= pd, d
    end
    return false
end

function Game:nextChapter()
    local ch = tonumber(self.chapter_id:sub(3,3))
    if ch == 7 then
        self.chapter_id = ite(self.chapter_id:sub(1,1) == '1', '2-1', 'epilogue')
    else
        self.chapter_id = self.chapter_id:sub(1,2) .. tostring(ch + 1)
    end
    self.chapter_transition_flag = true
end

function Game:spawnSprite(sp_id, x, y, dir)
    local fields = { sp_id, tostring(x), tostring(y), ite(dir == RIGHT, 'R', 'L') }
    local sp = self.current_map:spawnSprite(fields, self)
    self.sprites[sp:getId()] = sp
    return sp
end

function Game:deleteSprite(sp_id)
    self.current_map:dropSprite(sp_id)
    self.sprites[sp_id] = nil
end

function Game:setDifficulty(d)
    local old = self.difficulty
    self.difficulty = d
    if self.battle then self.battle:adjustDifficulty() end
end

function Game:startTutorial(n)
    self.current_tutorial = n
end

function Game:endTutorial()
    self.player.old_tutorials[#self.player.old_tutorials+1] = self.current_tutorial
    self.current_tutorial = nil
end

function Game:startMapMusic()
    self.current_music = self.map_to_music[self.current_map:getName()]
end

function Game:stopMusic()
    if self.current_music then
        music_tracks[self.current_music]:stop()
    end
    self.current_music = nil
end

function Game:setMusicVolume(vol)
    self.music_volume = vol
end

function Game:modMusicVolume(target, rate)
    self.music_vol_mod_target = target
    self.music_vol_mod_rate = rate
end

function Game:setSfxVolume(vol)
    self.sfx_volume = vol
    for k, v in pairs(sfx) do if k:sub(1,4) ~= 'text' then v:setVolume(vol) end end
end

function Game:setTextVolume(vol)
    self.text_volume = vol
    for k, v in pairs(sfx) do if k:sub(1,4) == 'text' then v:setVolume(vol * 0.6) end end
end

function Game:flash(msg, rate)
    self.flash_alpha = 0.001
    self.flash_rate = rate
    self.flash_msg = msg
end

function Game:stallInputs(t, keys)
    self.input_stall = t
    self.input_stall_keys = keys
end

function Game:launchBattle(id)
    self.current_scene = nil
    self.battle = Battle:new(self.player, self, id)
    self:saveBattle()
    self.battle:openBattleStartMenu()
end

-- Store player inputs to a scene, to be processed on update
function Game:battleInput(up, down, left, right, f, d)
    self.battle_inputs = {
        ['up'] = up,
        ['down'] = down,
        ['left'] = left,
        ['right'] = right,
        ['f'] = f,
        ['d'] = d,
    }
end

-- Start scene with the given scene id
function Game:launchScene(s_id, returnToBattle)
    self.player:changeMode('scene')
    if not returnToBattle then
        self.player:changeBehavior('idle')
    end

    self:modMusicVolume(0.5, 2)
    while self.callbacks[s_id] do s_id = self.callbacks[s_id] end
    self.current_scene = Scene:new(s_id, self.player, self, returnToBattle)
end

-- Begin an interaction with the target sprite
function Game:interactWith(target)
    self:launchScene(self.chapter_id .. '-' .. target.id)
end

-- Store player inputs to a scene, to be processed on update
function Game:sceneInput(f, u, d)

    -- Spacebar means advance dialogue or make a choice
    if f then
        self.scene_inputs['advance'] = true
    end

    -- Up or down means hover a selection
    if u and not d then
        self.scene_inputs['hover'] = UP
    elseif d and not u then
        self.scene_inputs['hover'] = DOWN
    end
end

-- Advance current scene and collect results from a finished scene
function Game:updateScene(dt)

    -- Advance scene according to player input
    if self.scene_inputs['advance'] then
        self.current_scene:advance()
    end
    self.current_scene:hover(self.scene_inputs['hover'])
    self.scene_inputs = {}

    -- Advance events in scene and text
    self.current_scene:update(dt)

    -- If scene has ended, shut it down and handle results
    if self.current_scene:over() then
        self.current_scene:close()
        self.current_scene = nil
        if not self.battle then
            self:autosave()
        end
        if self.chapter_transition_flag then
            self.chapter_transition_flag = false
            self:saveChapter()
        end
        -- Guard to prevent the player from starting an interaction scene in between two triggers
        self:stallInputs(0.1)
    end
end

function Game:warpSprite(sp, x, y, new_map)
    local old_map = nil
    for k,m in pairs(self.maps) do
        if m:getSprite(sp:getId()) then
            old_map = k
            break
        end
    end
    sp:resetPosition(x, y)
    if old_map then
        self.maps[old_map]:dropSprite(sp:getId())
    end
    self.maps[new_map]:addSprite(sp)
end

function Game:changeMapTo(new_map)

    -- If music is different for new map, stop old music and start new music
    local old_map = self.current_map:getName()
    local old_music = self.map_to_music[old_map]
    local new_music = self.map_to_music[new_map]
    local track_change = old_music ~= new_music

    -- Switch current map to new map
    if track_change then self:stopMusic() end
    self.current_map = self.maps[new_map]
    if track_change then self:startMapMusic() end
end

-- Switch from one map to another when the player touches a transition tile
function Game:performTransition()
    local tr = self.in_transition
    local new_map = tr['name']
    self:warpSprite(self.player.sp, tr['x'], tr['y'], new_map)
    self:changeMapTo(new_map)
end

-- Fade in or out (depending on sign of fade rate)
function Game:updateFade(dt)
    self.alpha = math.max(0, math.min(1, self.alpha + self.fade_rate * dt))
    self.flash_alpha = math.max(0, math.min(1, self.flash_alpha + self.flash_rate * dt))
end

-- Initiate, update, and perform map transitions
function Game:updateTransition(transition)

    -- When fade in is complete, transition is over
    if self.in_transition and self.alpha == 1 then
        self.player:changeMode('free')
        self.in_transition = nil
        self.fade_rate = 0
    end

    -- Start new transition if an argument was provided
    if transition then
        self.player:changeBehavior('idle')
        self.player:changeMode('frozen')
        self.in_transition = transition
        self.fade_rate = -2
    end

    -- When fade out is complete, perform switch and start fade-in
    if self.in_transition and self.alpha == 0 then
        self:performTransition()
        self:updateCamera(100)
        self.fade_rate = 2
    end
end

function Game:updateFlash()

    if self.flash_msg and self.flash_alpha == 0 then
        self.flash_msg = nil
        self.flash_rate = 0
    end

    if self.flash_msg and self.flash_alpha == 1 then
        self.flash_rate = self.flash_rate * -0.8
    end
end

-- Update the camera to center on the player but not cross the map edges
function Game:updateCamera(dt)

    -- Get camera bounds from map
    local pixel_width, pixel_height = self.current_map:getPixelDimensions()
    local cam_max_x = pixel_width - VIRTUAL_WIDTH / ZOOM
    local cam_max_y = pixel_height - VIRTUAL_HEIGHT / ZOOM

    -- Default camera info
    local focus = self.player
    local x_offset = 0
    local y_offset = 0
    local speed = self.camera_speed

    -- Target: where is the camera headed?
    local x_target = 0
    local y_target = 0

    -- Overwrite camera info from scene if it exists, or battle if it
    -- exists and there's no scene
    if self.current_scene then
        focus = self.current_scene.cam_lock
        x_offset = self.current_scene.cam_offset_x
        y_offset = self.current_scene.cam_offset_y
        speed = self.current_scene.cam_speed
    elseif self.battle then
        x_target, y_target, speed = self.battle:getCamera()
    end
    if not self.battle or (self.current_scene and self.battle) then
        local x, y = focus:getPosition()
        local w, h = focus:getDimensions()
        x_target = x + math.ceil(w / 2) + x_offset - (VIRTUAL_WIDTH / ZOOM) / 2
        y_target = y + math.ceil(h / 2) + y_offset - (VIRTUAL_HEIGHT / ZOOM) / 2
        x_target = math.max(0, math.min(x_target, cam_max_x))
        y_target = math.max(0, math.min(y_target, cam_max_y))
    end

    -- Compute move in the direction of camera target based on dt
    local new_x = ite(self.camera_x < x_target,
        math.min(self.camera_x + speed * dt, x_target),
        math.max(self.camera_x - speed * dt, x_target)
    )
    local new_y = ite(self.camera_y < y_target,
        math.min(self.camera_y + speed * dt, y_target),
        math.max(self.camera_y - speed * dt, y_target)
    )

    -- Release the camera event from the scene if the camera is done moving
    if new_x == x_target and new_y == y_target and self.current_scene then
        self.current_scene:release('camera')
    end

    -- Update camera position
    self.camera_x = math.max(0, math.min(new_x, cam_max_x))
    self.camera_y = math.max(0, math.min(new_y, cam_max_y))
end

function Game:checkSceneTriggers()
    for k, v in pairs(scene_triggers[self.chapter_id]) do
        if not self.seen[k] then
            local check = v[1](self)
            if check then
                local persist = v[2]
                if not persist then
                    self.seen[k] = true
                end
                if check ~= DELETE then
                    self:launchScene(check)
                end
            end
        end
    end
end

-- Update everything in the game
function Game:update(dt, no_music)

    -- If input is stalled, munch keyboard inputs on this frame
    if self.input_stall > 0 then
        self.input_stall = math.max(0, self.input_stall - dt)
        if self.input_stall_keys then
            for _,key in pairs(self.input_stall_keys) do
                love.keyboard.keysPressed[key] = nil
            end
        else
            love.keyboard.keysPressed = {}
        end
        if self.input_stall == 0 then
            self.input_stall_keys = nil
        end
    end

    -- Update the active map and sprites on it
    local new_transition = self.current_map:update(dt, self.player)

    -- Update current battle
    if self.battle then
        self.battle:update(self.battle_inputs, dt)
        self.battle_inputs = {}
    end

    -- Update player character based on key-presses
    self.player:update()

    -- Update the currently active scene
    if self.current_scene then
        self:updateScene(dt)
    else
        self:checkSceneTriggers()
    end

    -- Update music
    if self.current_music and not no_music then
        music_tracks[self.current_music]:update(dt, self.music_volume * self.music_vol_mod)

        local tgt = self.music_vol_mod_target
        if self.music_vol_mod < tgt then
            self.music_vol_mod = math.min(tgt, self.music_vol_mod + dt * self.music_vol_mod_rate)
        elseif self.music_vol_mod > tgt then
            self.music_vol_mod = math.max(tgt, self.music_vol_mod - dt * self.music_vol_mod_rate)
        end
    end

    -- Update current transition or initiate new one
    self:updateTransition(new_transition)
    
    -- Update fades on screens/messages
    self:updateFlash()
    self:updateFade(dt)

    -- Update camera position
    self:updateCamera(dt)

    -- Return reload/end signal
    self.global_timer = self.global_timer + dt * 2
    return self.signal
end

function Game:renderTutorial()

    -- Determine if tutorial should be hidden
    local hide_tutorial = self.alpha ~= 1 or self.current_scene
    if self.battle then
        local st = self.battle:getStage()
        if st == STAGE_WATCH or st == STAGE_TARGET or st == STAGE_LEVELUP
        or #self.battle.levelup_queue ~= 0
        or (self.battle:getMenu() and self.battle:getMenu().confirm_msg) then
            hide_tutorial = true
        end
    end

    -- If there's an active tutorial, and we aren't hiding it, render!
    if self.current_tutorial and not hide_tutorial then
        local w = VIRTUAL_WIDTH / 3 - BOX_MARGIN
        local hbox = self.player:mkTutorialBox(self.current_tutorial, w, 28)
        renderHoverBox(hbox, VIRTUAL_WIDTH - w - BOX_MARGIN, 150, 270)
    end
end

-- Render the map and sprites at the current position,
-- along with active scene or battle, and camera effects
function Game:render()

    -- Move to the camera position
    love.graphics.translate(-self.camera_x, -self.camera_y)

    -- Render the map tiles
    self.current_map:renderTiles()

    -- Render battle grid
    if self.battle then
        self.battle:renderGrid()
    end

    -- Render ground sprites
    self.current_map:renderGroundSprites()

    -- Render battle underlay
    if self.battle then
        self.battle:renderUnderlay()
    end

    -- Render standing sprites
    self.current_map:renderStandingSprites()

    if self.battle then
        self.battle:renderActingSpriteImage()
    end

    -- Apply lighting
    self.current_map:renderLighting()

    -- Fade in/out
    love.graphics.origin()
    drawFade(1 - self.alpha)
    
    -- Render battle overlay
    love.graphics.scale(1 / ZOOM)
    if self.battle then
        self.battle:renderOverlay()
    end

    -- Render player inventory
    self.player:render(self)

    -- Render effects and text from current scene if there is one
    if self.current_scene then
        self.current_scene:render()
    end

    -- Render tutorial message, if one exists
    self:renderTutorial()

    -- Render flashed message
    if self.flash_msg then
        renderString(self.flash_msg,
            (VIRTUAL_WIDTH - #self.flash_msg * CHAR_WIDTH) / 2,
            VIRTUAL_HEIGHT - 50, { 1, 1, 1, self.flash_alpha }
        )
    end

    love.graphics.origin()
end
