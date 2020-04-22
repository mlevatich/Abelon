require 'Util'
require 'Character'
require 'Map'
require 'Dialogue'

Scene = Class{}

-- Constructor for our scenario object
function Scene:init(id)

    -- Store id
    self.id = id

    -- Map info
    self.maps = {}
    self.current_map = nil

    -- Dict from map names to audio sources
    self.map_to_music = {}

    -- Sprite info
    self.characters = {}
    self.player = nil

    -- State of a scene is a capital letter, determines dialogue and cinematic triggers
    self.state = 'A'

    -- Dialogue map is indexed by character name, giving a mapping from scene state to starting dialogue track,
    -- and from ending dialogue track to new scene state
    self.character_data = {}
    self.dialogue_maps = {}
    self.previous_dialogue = {}

     -- Table of state and position triggers, and associated cinematic object (created via cinematic file)
    self.cinematic_maps = {}

    -- Camera that follows coordinates of player character around the scene
    self.camera_x = 0
    self.camera_y = 0

    -- Rendering information
    self.alpha = 1
    self.fade_to = nil

    -- Read into the above fields from scene file
    self:parseSceneFile()
end

-- Read information about characters and dialogues into scene
function Scene:parseSceneFile()

    -- Read lines into list
    local lines = readLines('Abelon/scenes/' .. self.id .. '/scenefile.txt')

    -- Iterate over lines of scene file
    local audio_sources = {}
    local current_map_name = nil
    local current_char_name = nil
    for i=1, #lines do

        -- Lines starting with ~~ denote a new map
        if lines[i]:sub(1,2) == '~~' then

            -- Read data from line
            local fields = split(lines[i]:sub(3))
            local map_name, tileset, music_name = fields[1], fields[2], fields[3]
            current_map_name = map_name

            -- Initialize map and tie it to scene
            self.maps[map_name] = Map(map_name, tileset, nil)

            -- Maps sharing a music track share a pointer to the audio
            if not audio_sources[music_name] then
                audio_sources[music_name] = love.audio.newSource('audio/music/' .. music_name .. '.wav', 'static')
            end
            self.map_to_music[map_name] = audio_sources[music_name]

        -- Lines starting with ~ denote a new character
        elseif lines[i]:sub(1,1) == '~' then

            -- Initialize data for new character
            local fields = split(lines[i]:sub(2))
            current_char_name = fields[1]

            -- Initialize character data
            table.insert(self.character_data, {
                ['char_name'] = current_char_name,
                ['map_name'] = current_map_name,
                ['x'] = (fields[2] - 1) * TILE_WIDTH,
                ['y'] = (fields[3] - 1) * TILE_HEIGHT
            })
            self.previous_dialogue[current_char_name] = {}
            self.dialogue_maps[current_char_name] = {}

        -- Other lines are state change mappings
        elseif lines[i] ~= '' and lines[i]:sub(1,2) ~= '//' then

            -- Read a dialogue mapping for the current character
            local map = self.dialogue_maps[current_char_name]
            if lines[i]:sub(2,2) == ' ' then
                map[lines[i]:sub(1,1)] = lines[i]:sub(3,4)
            else
                map[lines[i]:sub(1,2)] = lines[i]:sub(4,4)
            end
        end
    end
end

-- Set characters based on names from scene file
function Scene:loadCharacters(all_characters, player)

    -- Denote player character
    self.player = player

    -- For each character name, find corresponding character object among all characters
    for i=1, #self.character_data do
        local name = self.character_data[i]['char_name']
        self.characters[name] = all_characters[name]
    end
end

-- Return all character objects belonging to this scene
function Scene:getActiveCharacters()
    return self.current_map:getCharacters()
end

-- Return the map belonging to this scene
function Scene:getMap()
    return self.current_map
end

-- Construct an instance of dialogue with the given character based on the current state
function Scene:getDialogueWith(partner)

    -- Construct filename
    local dialogue_file = 'Abelon/scenes/' .. self.id .. '/dialogue/' .. partner.name .. '.txt'

    -- Get starting track from the current state
    local mapping = self.dialogue_maps[partner.name][self.state]
    local starting_track = 'a1'
    if mapping then
        starting_track = mapping
    end

    -- Change to secondary track of the previous ending track,
    -- if already talked on this starting track
    local previous = self.previous_dialogue[partner.name][starting_track]
    if previous then
        starting_track = previous:sub(1,1) .. '2'
    end

    -- Return dialogue object with starting track
    return Dialogue(dialogue_file, self.player, partner, self.characters, starting_track)
end

-- Resume a scene with all characters in their starting positions
function Scene:start()

    -- Set starting positions and scene of each character, tie to map
    for _, data in pairs(self.character_data) do

        -- Set character fields
        local char = self.characters[data['char_name']]
        char:setScene(self)
        char:resetPosition(tonumber(data['x']), tonumber(data['y']))

        -- Add character info to relevant map
        local is_player = (char == self.player)
        self.maps[data['map_name']]:addCharacter(char, is_player)
        if is_player then
            self.current_map = self.maps[data['map_name']]
        end
    end

    -- Start music
    -- local music = self.map_to_music[self.current_map:getName()]
    -- music:setLooping(true)
    -- music:start()
end

-- End the current scene, but retain its state
function Scene:stop()

    -- Stop music
    -- local music = self.map_to_music[self.current_map:getName()]
    -- music:stop()

    -- Wipe scene from each character object
    for _, char in pairs(self.characters) do
        char:setScene(nil)
        char:resetPosition(0, 0)
    end
end

-- Switch from one map to another when the player touches a transition tile
-- and return the scene to change to if there is a scene change
function Scene:performTransition()

    -- New map
    local tr = self.in_transition
    local old_map = self.current_map:getName()
    local new_map = tr['name']

    -- Reset player's position
    self.player:resetPosition(tr['x'], tr['y'])

    -- Move player from old map to new map
    self.maps[old_map]:dropCharacter(self.player)
    self.maps[new_map]:addCharacter(self.player, true)

    -- If music is different for new map, stop old music and start new music
    local old_music = self.map_to_music[old_map]
    local new_music = self.map_to_music[new_map]
    if old_music ~= new_music then
        -- old_music:stop()
        -- new_music:setLooping(true)
        -- new_music:start()
    end

    -- Switch current map to new map
    self.current_map = self.maps[new_map]
    self.in_transition = nil
end

-- Initiate, update, and perform map transitions and the associated fade-out and in
function Scene:updateTransition(transition)

    -- Start new transition if an argument was provided
    if transition then
        self.player:changeBehavior('still')
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
            self.player:changeBehavior('idle')
        end
    end
end

-- Update the camera to center on the player but not cross the map edges
function Scene:updateCamera()

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

-- Update all of the characters and objects in a scene
function Scene:update(dt)

    -- Update the scene's map and characters
    local new_transition = self.current_map:update(dt)

    -- Collect dialogue result for the player if there is one
    local end_track, start_track, talking_to = self.player:dialogueResults()
    if end_track then

        -- Store that this conversation has already happened once
        self.previous_dialogue[talking_to.name][start_track] = end_track

        -- Execute state change if there is one
        local mapping = self.dialogue_maps[talking_to.name]
        if mapping[end_track] then
            self.state = mapping[end_track]
        end
    end

    -- Update current transition or initiate new one
    self:updateTransition(new_transition)

    -- Update camera position
    self:updateCamera()

    -- No scene change
    return nil
end

-- Render the map and characters of the scene at the current position, along with active dialogue
function Scene:render()

    -- Move to the camera position
    love.graphics.translate(-self.camera_x, -self.camera_y)

    -- Render the map
    love.graphics.setColor(1, 1, 1, self.alpha)
    self.current_map:render(self.camera_x, self.camera_y)

    -- Render current dialogue if the player is talking to someone
    self.player:renderDialogue(self.camera_x, self.camera_y)

    -- Render current menu layout if the player is in inventory/shop
    self.player:renderMenu(self.camera_x, self.camera_y)
end
