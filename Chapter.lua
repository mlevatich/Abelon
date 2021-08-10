require 'Util'
require 'Constants'

require 'Player'
require 'Sprite'
require 'Map'
require 'Scene'
require 'Music'

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

    -- Map info
    self.maps = {}
    self.current_map = nil

    -- Dict from map names to audio sources
    self.map_to_music = {}
    self.current_music = nil

    -- Rendering information
    self.alpha = 1
    self.fade_to = nil

    -- Sprites in this chapter
    self.sprites = {}
    self.player = nil

    -- State of a chapter is a capital letter, determines scene triggers
    self.quest_state = 'A'

    -- Scene map is indexed by sprite name, giving a mapping from chapter state to starting scene track,
    -- and from ending scene track to new chapter state
    self.scene_inputs = {}
    self.scene_maps = {}
    self.previous_scene = {}

    -- Tracking the scene the player is currently in
    self.current_scene = nil

    -- Read into the above fields from chapter file
    self:load()
end

-- Read information about sprites and scenes for this chapter
function Chapter:load()

    -- Load chapter's spritesheet into memory
    self.sheet = love.graphics.newImage('graphics/spritesheets/ch' .. self.id .. '.png')

    -- Read lines into list
    local lines = readLines('Abelon/data/chapters/' .. self.id .. '/chapterfile.txt')

    -- Iterate over lines of chapter file
    local audio_sources = {}
    local current_map_name = nil
    local current_sp_id = nil
    for i=1, #lines do

        -- Lines starting with ~~ denote a new map
        if lines[i]:sub(1,2) == '~~' then

            -- Read data from line
            local fields = split(lines[i]:sub(3))
            local map_name, tileset, music_name = fields[1], fields[2], fields[3]
            current_map_name = map_name

            -- Initialize map and tie it to chapter
            self.maps[map_name] = Map(map_name, tileset, nil)

            -- Maps sharing a music track share a pointer to the audio
            if not audio_sources[music_name] then
                audio_sources[music_name] = Music(music_name)
            end
            self.map_to_music[map_name] = audio_sources[music_name]

        -- Lines starting with ~ denote a new sprite
        elseif lines[i]:sub(1,1) == '~' then

            -- Collect sprite info from file
            local fields = split(lines[i]:sub(2))
            current_sp_id = fields[1]
            local init_x = (tonumber(fields[2]) - 1) * TILE_WIDTH
            local init_y = (tonumber(fields[3]) - 1) * TILE_HEIGHT
            local is_player = fields[4]

            -- Register this sprite's ID with the chapter's scene data structures
            self.previous_scene[current_sp_id] = {}
            self.scene_maps[current_sp_id] = {}

            -- Initialize sprite object and set its starting position
            local new_sp = Sprite(current_sp_id, self.sheet, self)
            self.sprites[current_sp_id] = new_sp
            new_sp:resetPosition(init_x, init_y)

            -- Add sprite this sprite to the map on which it appears
            self.maps[current_map_name]:addSprite(new_sp)

            -- If the sprite is the player character, we make the current map
            -- into the chapter's starting map, and initialize a player object
            if is_player then
                self.current_map = self.maps[current_map_name]
                self.player = Player(new_sp)
            end

        -- Other lines are state change mappings
        elseif lines[i] ~= '' and lines[i]:sub(1,2) ~= '//' then

            -- Read a scene mapping for the current sprite
            local map = self.scene_maps[current_sp_id]
            if lines[i]:sub(2,2) == ' ' then
                map[lines[i]:sub(1,1)] = lines[i]:sub(3,4)
            else
                map[lines[i]:sub(1,2)] = lines[i]:sub(4,4)
            end
        end
    end

    -- Start music
    self:startMapMusic()
end

-- End the current chapter and save what happened in it
function Chapter:endChapter()

    -- Stop music
    self:stopMapMusic()

    -- retire all sprites and write them to save file
    -- save relevant quest state info as well
    -- save Abelon's inventory
end

-- Return all sprite objects belonging to the chapter's active map
function Chapter:getActiveSprites()
    return self.current_map:getSprites()
end

-- Return the active map belonging to this chapter
function Chapter:getMap()
    return self.current_map
end

function Chapter:startMapMusic()
    self.current_music = self.map_to_music[self.current_map:getName()]
end

function Chapter:stopMapMusic()
    if self.current_music then
        self.current_music:stop()
    end
    self.current_music = nil
end

-- Begin an interaction with the target sprite, which depends on the chapter,
-- map, and quest state
function Chapter:interactWith(target)
    local scene_id = target:getID() .. '_interact_' .. self.id
    self.current_scene = Scene(scene_id, self.current_map, self.player)
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

    -- Move text forward
    self.current_scene:update(dt)

    -- Advance scene according to player input
    local done = false
    if self.scene_inputs['advance'] then
        done = self.current_scene:advance()
    end
    self.current_scene:hover(self.scene_inputs['hover'])

    -- Scene inputs are gobbled each frame
    self.scene_inputs = {}

    -- If scene has ended, shut it down and handle results
    if done then

        -- End scene
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
    self.maps[old_map]:dropSprite(self.player)
    self.maps[new_map]:addSprite(self.player)

    -- If music is different for new map, stop old music and start new music
    local old_music = self.map_to_music[old_map]
    local new_music = self.map_to_music[new_map]
    local track_change = old_music ~= new_music

    -- Switch current map to new map
    if track_change then self:stopMapMusic() end
    self.current_map = self.maps[new_map]
    if track_change then self:startMapMusic() end
    self.in_transition = nil
end

-- Initiate, update, and perform map transitions and the associated fade-out and in
function Chapter:updateTransition(transition)

    -- Start new transition if an argument was provided
    if transition then
        self.player:changeBehavior('idle')
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
            self.player:changeBehavior('wander')
        end
    end
end

-- Update the camera to center on the player but not cross the map edges
function Chapter:updateCamera()

    -- Get fields from map and player
    local pixel_width, pixel_height = self.current_map:getPixelDimensions()
    local x, y = self.player:getPosition()
    local w, h = self.player:getDimensions()

    -- Update the x position of the camera to center on the player character
    local cam_max_x = math.min(pixel_width - VIRTUAL_WIDTH, x + w/2)
    local cam_player_x = x + w/2 - VIRTUAL_WIDTH/2
    self.camera_x = math.max(0, math.min(cam_player_x, cam_max_x))

    -- Update the y position of the camera to center on the player character
    local cam_max_y = math.min(pixel_height - VIRTUAL_HEIGHT, y + w/2)
    local cam_player_y = y + h/2 - VIRTUAL_HEIGHT/2
    self.camera_y = math.max(0, math.min(cam_player_y, cam_max_y))
end

-- Update all of the sprites and objects in a chapter
function Chapter:update(dt)

    -- Update the chapter's active map and sprites
    local new_transition = self.current_map:update(dt, self.player)

    -- Update the currently active scene
    if self.current_scene then
        self:updateScene(dt)
    end

    -- Update music
    if self.current_music then
        self.current_music:update(dt)
    end

    -- Update current transition or initiate new one
    self:updateTransition(new_transition)

    -- Update camera position
    self:updateCamera()

    -- No chapter change
    return nil
end

-- Render the map and sprites of the chapter at the current position, along with active scene
function Chapter:render()

    -- Move to the camera position
    love.graphics.translate(-self.camera_x, -self.camera_y)

    -- Render the map
    love.graphics.setColor(1, 1, 1, self.alpha)
    self.current_map:render(self.camera_x, self.camera_y)

    -- Render player inventory
    self.player:render(self.camera_x, self.camera_y)

    -- Render effects and text from current scene if there is one
    if self.current_scene then
        self.current_scene:render(self.camera_x, self.camera_y)
    end
end
