require 'Util'
require 'Map'
require 'Character'

Game = Class{}

-- Initialize game context
function Game:init()

    -- All characters in the game
    self.cast = {
        ['Abelon'] = Character('Abelon', true),
        ['Kath'] = Character('Kath', false),
    }
    self.player = self.cast['Abelon']

    -- All maps in the game
    self.maps = {
        ['Dungeon'] = Map('Dungeon')
    }

    -- Camera
    self.cameraX = 0
    self.cameraY = 0

    -- Current map and scene
    self.current_map = nil
    self.current_scene = 0

    -- Initial game state
    self:setScenario('Dungeon', 1)
    self:addToMap('Abelon', 224, 376)
    self:addToMap('Kath', 200, 200)
end

-- Clear all characters from the current map and change the current map
function Game:setScenario(name, scene_id)

    -- Remove all characters active in the current map
    if self.current_map then
        for name, _ in pairs(self.current_map:getCharacters()) do
            self:removeFromMap(name)
        end
        self.current_map:stopMusic()
    end

    -- Switch current map and music
    self.current_map = self.maps[name]
    self.current_scene = scene_id
    self.current_map:startMusic()
end

-- Add a character to the map at the specified position, with the specified scene
function Game:addToMap(name, x, y)

    -- Get character
    char = self.cast[name]

    -- Set fields of character
    char:setMap(self.current_map)
    char:setScene(self.current_scene)
    char:resetPosition(x, y)

    -- Add character to map
    self.current_map:addCharacter(char)
end

-- Remove a character from the map
function Game:removeFromMap(name)

    -- Get character
    char = self.cast[name]

    -- Clear fields of character
    char:setMap(nil)
    char:setScene(0)
    char:resetPosition(0, 0)

    -- Delete character from map
    self.current_map:removeCharacter(name)
end

-- Update game state
function Game:update(dt)

    -- Update map state and all characters on it
    self.current_map:update(dt)

    -- Update the x position of the camera to center on the player character
    camMaxX = math.min(self.current_map.mapWidthPixels - VIRTUAL_WIDTH, self.player.x + self.player.width/2)
    camPlayerX = self.player.x + self.player.width/2 - VIRTUAL_WIDTH/2
    self.cameraX = math.max(0, math.min(camPlayerX, camMaxX))

    -- Update the y position of the camera to center on the player character
    camMaxY = math.min(self.current_map.mapHeightPixels - VIRTUAL_HEIGHT, self.player.y + self.player.height/2)
    camPlayerY = self.player.y + self.player.height/2 - VIRTUAL_HEIGHT/2
    self.cameraY = math.max(0, math.min(camPlayerY, camMaxY))
end

-- Render map, set pieces, characters, text, menus, spells, etc
function Game:render()

    -- Move to the camera position
    love.graphics.translate(-self.cameraX, -self.cameraY)

    -- Render map and characters around camera position
    self.current_map:render()

    -- Render current dialogue if the player is talking to someone
    if self.player.currentDialogue then
        self.player.currentDialogue:render(self.cameraX, self.cameraY)
    end
end
