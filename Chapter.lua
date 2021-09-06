require 'Util'
require 'Constants'

require 'Player'
require 'Sprite'
require 'Map'
require 'Scene'
require 'Music'
require 'Triggers'
require 'Scripts'
require 'Battle'

Chapter = Class{}

-- Constructor for our scenario object
function Chapter:init(id, spriteesheet)

    -- Store id and spritesheet
    self.id = id

    -- This chapter's spritesheet
    self.sheet = nil

    -- Camera that follows coordinates of player sprite around the chapter
    self.camera_x = 0
    self.camera_y = 0
    self.camera_speed = 300

    -- Map info
    self.maps = {}
    self.current_map = nil

    -- Dict from map names to audio sources
    self.map_to_music = {}
    self.current_music = nil

    -- Volume levels
    self.music_volume = HIGH
    self.sfx_volume   = HIGH
    self.text_volume  = HIGH

    -- Rendering information
    self.alpha = 1
    self.fade_to = nil

    -- Sprites in this chapter
    self.sprites = {}
    self.player = nil

    local icon_indices = {
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18
    }
    self.itex = love.graphics.newImage('graphics/icons.png')
    self.icons = getSpriteQuads(icon_indices, self.itex, 22, 22, 0)

    -- Difficulty level
    self.difficulty = MASTER

    -- State of a chapter a dictionary of strings that correspond to different
    -- chapter events and determine quest progress, cinematic triggers, and
    -- sprite locations
    self.state = {}

    -- Tracking the scene the player is currently in
    self.current_scene = nil
    self.scene_inputs = {}

    -- If the player is in a battle, it goes here
    self.battle = nil
    self.battle_inputs = {}

    -- Read into the above fields from chapter file
    self:load()
end

-- Read information about sprites and scenes for this chapter
function Chapter:load()

    -- Load chapter's spritesheet into memory
    local sheet_file = 'graphics/spritesheets/ch' .. self.id .. '.png'
    self.sheet = love.graphics.newImage(sheet_file)

    -- Read lines into list
    local chap_file = 'Abelon/data/chapters/' .. self.id .. '/chapterfile.txt'
    local lines = readLines(chap_file)

    -- Iterate over lines of chapter file
    local audio_sources = {}
    local current_map_name = nil
    local current_sp_id = nil
    for i=1, #lines do

        -- Lines starting with ~~ denote a new map
        if lines[i]:sub(1,2) == '~~' then

            -- Read data from line
            local fields = split(lines[i]:sub(3))
            local map_name, tileset, song = fields[1], fields[2], fields[3]
            current_map_name = map_name

            -- Initialize map and tie it to chapter
            self.maps[map_name] = Map(map_name, tileset, nil)

            -- Maps sharing a music track share a pointer to the audio
            if not audio_sources[song] then
                audio_sources[song] = Music(song, self.music_volume)
            end
            self.map_to_music[map_name] = audio_sources[song]

        -- Lines starting with ~ denote a new sprite
        elseif lines[i]:sub(1,1) == '~' then

            -- Collect sprite info from file
            local fields = split(lines[i]:sub(2))
            current_sp_id = fields[1]
            local init_x = (tonumber(fields[2]) - 1) * TILE_WIDTH
            local init_y = (tonumber(fields[3]) - 1) * TILE_HEIGHT
            local first_interaction = fields[4]

            -- Initialize sprite object and set its starting position
            local new_sp = Sprite(current_sp_id, self.sheet, self)
            self.sprites[current_sp_id] = new_sp
            new_sp:resetPosition(init_x, init_y)

            -- Add sprite this sprite to the map on which it appears
            self.maps[current_map_name]:addSprite(new_sp)

            -- If the sprite is the player character, we make the current map
            -- into the chapter's starting map, and initialize a player object
            if first_interaction then
                if first_interaction == 'P' then
                    self.current_map = self.maps[current_map_name]
                    self.player = Player(new_sp)
                    self:updateCamera(100)
                else
                    scripts[current_sp_id] = scripts[first_interaction]
                end
            end
        end
    end

    -- Start music
    self:startMapMusic()
end

-- End the current chapter and save what happened in it
function Chapter:endChapter()

    -- Stop music
    self:stopMusic()

    -- retire all sprites and write them to save file
    -- save relevant quest state info as well
    -- save Abelon's inventory
end

-- Return all sprite objects belonging to the chapter's active map
function Chapter:getActiveSprites()
    return self.current_map:getSprites()
end

function Chapter:getSprite(sp_id)
    return self.sprites[sp_id]
end

-- Return the active map belonging to this chapter
function Chapter:getMap()
    return self.current_map
end

function Chapter:playerNearSprite(sp_id)
    local x, y = self.player.sp:getPosition()
    local sp = self.current_map:getSprite(sp_id)
    if sp then
        local kx, ky = sp:getPosition()
        return abs(x - kx) <= PRESENT_DISTANCE * TILE_WIDTH
           and abs(y - ky) <= PRESENT_DISTANCE * TILE_HEIGHT
    end
    return false
end

function Chapter:setDifficulty(d)
    local old = self.difficulty
    self.difficulty = d
    if self.battle then self.battle:adjustStatsForDifficulty(old) end
end

function Chapter:startMapMusic()
    self.current_music = self.map_to_music[self.current_map:getName()]
end

function Chapter:stopMusic()
    if self.current_music then
        self.current_music:stop()
    end
    self.current_music = nil
end

function Chapter:setMusicVolume(vol)
    self.music_volume = vol
end

function Chapter:setSfxVolume(vol)
    self.sfx_volume = vol
end

function Chapter:setTextVolume(vol)
    self.text_volume = vol
end

function Chapter:launchBattle(b_id)
    self.battle = Battle(b_id, self.player, self)
end

-- Store player inputs to a scene, to be processed on update
function Chapter:battleInput(up, down, left, right, f, d)
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
function Chapter:launchScene(s_id, returnToBattle)
    self.player:changeMode('scene')
    if not returnToBattle then
        self.player:changeBehavior('idle')
    end
    self.current_scene = Scene(s_id, self.player, self, returnToBattle)
end

-- Begin an interaction with the target sprite
function Chapter:interactWith(target)
    self:launchScene(target:getId())
end

-- Store player inputs to a scene, to be processed on update
function Chapter:sceneInput(space, u, d)

    -- Spacebar means advance dialogue
    if space then
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
function Chapter:updateScene(dt)

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
    end
end

-- Switch from one map to another when the player touches a transition tile
function Chapter:performTransition()

    -- New map
    local tr = self.in_transition
    local old_map = self.current_map:getName()
    local new_map = tr['name']

    -- Reset player's position
    self.player:resetPosition(tr['x'], tr['y'])

    -- Move player from old map to new map
    self.maps[old_map]:dropSprite(self.player:getId())
    self.maps[new_map]:addSprite(self.player)

    -- If music is different for new map, stop old music and start new music
    local old_music = self.map_to_music[old_map]
    local new_music = self.map_to_music[new_map]
    local track_change = old_music ~= new_music

    -- Switch current map to new map
    if track_change then self:stopMusic() end
    self.current_map = self.maps[new_map]
    if track_change then self:startMapMusic() end
    self.in_transition = nil
end

-- Initiate, update, and perform map transitions
-- and the associated fade-out and in
function Chapter:updateTransition(transition)

    -- Start new transition if an argument was provided
    if transition then
        self.player:changeBehavior('idle')
        self.player:changeMode('frozen')
        self.in_transition = transition
    end

    -- When fade out is complete, perform switch
    if self.alpha == 0 then
        self:performTransition()
    end

    -- If in a transition, fade out
    if self.in_transition then
        self.alpha = math.max(0, self.alpha - 0.05)
    end

    -- If map has switched, fade in until alpha is full
    if not self.in_transition and self.alpha < 1 then
        self.alpha = math.min(1, self.alpha + 0.05)

        -- End transition when alpha is full
        if self.alpha == 1 then
            self.player:changeMode('free')
        end
    end
end

-- Update the camera to center on the player but not cross the map edges
function Chapter:updateCamera(dt)

    -- Get camera bounds from map
    local pixel_width, pixel_height = self.current_map:getPixelDimensions()
    local cam_max_x = pixel_width - VIRTUAL_WIDTH
    local cam_max_y = pixel_height - VIRTUAL_HEIGHT

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
        x_target = x + w/2 + x_offset - VIRTUAL_WIDTH / 2
        y_target = y + h/2 + y_offset - VIRTUAL_HEIGHT / 2
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

function Chapter:checkSceneTriggers()
    local i = 1
    while i <= #scene_triggers do
        local check = scene_triggers[i](self)
        if check then
            table.remove(scene_triggers, i)
            if check ~= DELETE then
                self:launchScene(check)
            end
        else
            i = i + 1
        end
    end
end

-- Update all of the sprites and objects in a chapter
function Chapter:update(dt)

    -- Update the chapter's active map and sprites
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
    end

    self:checkSceneTriggers()

    -- Update music
    if self.current_music then
        self.current_music:update(dt, self.music_volume)
    end

    -- Update current transition or initiate new one
    self:updateTransition(new_transition)

    -- Update camera position
    self:updateCamera(dt)

    -- No chapter change
    return nil
end

-- Render the map and sprites of the chapter at the current position,
-- along with active scene
function Chapter:render()

    -- Move to the camera position
    love.graphics.translate(-self.camera_x, -self.camera_y)

    -- Render the map tiles
    love.graphics.setColor(1, 1, 1, self.alpha)
    self.current_map:renderTiles()

    -- Render battle grid
    if self.battle then
        self.battle:renderGrid()
    end

    -- Render sprites on map and lighting
    love.graphics.setColor(1, 1, 1, self.alpha)
    self.current_map:renderSprites(self.camera_x, self.camera_y)
    self.current_map:renderLighting()

    -- Render battle overlay
    if self.battle then
        self.battle:renderOverlay(self.camera_x, self.camera_y)
    end

    -- Render player inventory
    self.player:render(self.camera_x, self.camera_y, self)

    -- Render effects and text from current scene if there is one
    if self.current_scene then
        self.current_scene:render(self.camera_x, self.camera_y)
    end
end
