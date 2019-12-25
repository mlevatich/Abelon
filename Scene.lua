require 'Util'
require 'Character'
require 'Map'
require 'Dialogue'

Scene = Class{}

-- Constructor for our scenario object
function Scene:init(id)

    -- Store id
    self.id = id

    -- Read lines of scene file
    local lines = {}
    for line in io.lines('Abelon/scenes/' .. self.id .. '/scenefile.txt') do
        lines[#lines+1] = line
    end

    -- Map info
    self.map_name = lines[1]
    self.map = nil
    self.lighting = nil

    -- Music track associated with this scene
    self.music = love.audio.newSource('music/' .. lines[2] .. '.wav', 'static')

    -- Sprite info
    self.player = nil
    self.characters = {}
    self.objects = nil

    -- State of a scene is a capital letter, determines dialogue and cinematic triggers
    self.state = 'A'

    -- Dialogue map is indexed by character name, giving a mapping from scene state to starting dialogue track,
    -- and from ending dialogue track to new scene state
    self.character_data = {}
    self.dialogue_maps = {}
    self.previousDialogue = {}

    -- Read into the above three fields from scene file
    self:readCharacterData(lines)

     -- Table of state and position triggers, and associated cinematic object (created via cinematic file)
    self.cinematic_maps = nil

    -- Array with indices corresponding to the indices of the map exits. Value is the
    -- scenario to swtich to upon changing the map, and the map entrance index for the new map
    self.map_transitions = nil

    -- Camera that follows coordinates of player character around the scene
    self.cameraX = 0
    self.cameraY = 0
end

-- Read information about characters and dialogues into scene
function Scene:readCharacterData(lines)

    -- Iterate over lines of scene file
    local name = ''
    for i=4, #lines do

        -- Lines starting with ~ denote a new character
        if lines[i]:sub(1,1) == '~' then

            -- Initialize data for new character
            local fields = split(lines[i]:sub(2))
            name = fields[1]
            local nchar = #self.character_data + 1
            self.character_data[nchar] = { ['name'] = name, ['x'] = fields[2], ['y'] = fields[3] }
            self.previousDialogue[name] = {}
            self.dialogue_maps[name] = {}

        elseif lines[i] ~= '' then

            -- Read a dialogue mapping for the current character
            local map = self.dialogue_maps[name]
            if lines[i]:sub(2,2) == ' ' then
                map[lines[i]:sub(1,1)] = lines[i]:sub(3,4)
            else
                map[lines[i]:sub(1,2)] = lines[i]:sub(4,4)
            end
        end
    end
end

-- Set characters based on names from scene file
function Scene:setCharacters(all_characters, player)

    -- Denote player character
    self.player = player

    -- For each character name, find corresponding character object among all characters
    for i=1, #self.character_data do
        local name = self.character_data[i]['name']
        self.characters[name] = all_characters[name]
    end
end

-- Set map based on name from scene file
function Scene:setMap(all_maps)
    self.map = all_maps[self.map_name]
end

-- Return all character objects belonging to this scene
function Scene:getCharacters()
    return self.characters
end

-- Return the map belonging to this scene
function Scene:getMap()
    return self.map
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
    local previous = self.previousDialogue[partner.name][starting_track]
    if previous then
        starting_track = previous:sub(1,1) .. '2'
    end

    -- Return dialogue object with starting track
    return Dialogue(dialogue_file, self.player, partner, self.characters, starting_track)
end

-- Resume a scene with all characters in their starting positions
function Scene:start()

    -- Start music
    -- self.music:setLooping(true)
    -- self.music:start()

    -- Set starting positions and scene of each character
    for _, data in pairs(self.character_data) do
        local char = self.characters[data['name']]
        char:setScene(self)
        char:resetPosition(tonumber(data['x']), tonumber(data['y']))
    end
end

-- End the current scene, but retain its state
function Scene:stop()

    -- Stop music
    -- self.music:stop()

    -- Wipe scene from each character object
    for _, char in pairs(self.characters) do
        char:setScene(nil)
        char:resetPosition(0, 0)
    end
end

-- Update the camera to center on the player but not cross the map edges
function Scene:updateCamera()

    -- Update the x position of the camera to center on the player character
    local camMaxX = math.min(self.map.mapWidthPixels - VIRTUAL_WIDTH, self.player.x + self.player.width/2)
    local camPlayerX = self.player.x + self.player.width/2 - VIRTUAL_WIDTH/2
    self.cameraX = math.max(0, math.min(camPlayerX, camMaxX))

    -- Update the y position of the camera to center on the player character
    local camMaxY = math.min(self.map.mapHeightPixels - VIRTUAL_HEIGHT, self.player.y + self.player.height/2)
    local camPlayerY = self.player.y + self.player.height/2 - VIRTUAL_HEIGHT/2
    self.cameraY = math.max(0, math.min(camPlayerY, camMaxY))
end

-- Update all of the characters and objects in a scene
function Scene:update(dt)

    -- Update the scene's map
    self.map:update()

    -- Update each character in the scene
    for _, char in pairs(self.characters) do
        char:update(dt)
    end

    -- Collect dialogue result for the player if there is one
    local end_track, start_track, talking_to = self.player:getDialogueResults()
    if end_track then

        -- Store that this conversation has already happened once
        self.previousDialogue[talking_to.name][start_track] = end_track

        -- Execute state change if there is one
        local mapping = self.dialogue_maps[talking_to.name]
        if mapping[end_track] then
            self.state = mapping[end_track]
        end
    end

    -- Update camera position
    self:updateCamera()
end

-- Render the map and characters of the scene at the current position, along with active dialogue
function Scene:render()

    -- Move to the camera position
    love.graphics.translate(-self.cameraX, -self.cameraY)

    -- Render the map
    self.map:render()

    -- Render all of the characters on the map
    for _, char in pairs(self.characters) do
        char:render()
    end

    -- Render current dialogue if the player is talking to someone
    if self.player.currentDialogue then
        self.player.currentDialogue:render(self.cameraX, self.cameraY)
    end
end
