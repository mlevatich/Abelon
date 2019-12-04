require 'Util'
require 'Scene'
require 'Map'
require 'Character'

Game = Class{}

local NUM_SCENES = 1

-- Initialize game context
function Game:init()

    -- All characters in the game
    self.cast = {
        ['Abelon'] = Character('Abelon', true),
        ['Kath'] = Character('Kath', false),
        ['Uther'] = Character('Uther', false),
    }

    -- All maps in the game
    self.maps = {
        ['Dungeon'] = Map('Dungeon')
    }

    -- All scenes in the game
    self.scenes = {}
    for i=1, NUM_SCENES do
        self.scenes[i] = Scene(i)
        self.scenes[i]:setMap(self.maps)
        self.scenes[i]:setCharacters(self.cast, self.cast['Abelon'])
    end

    -- Current scene
    self.current_scene = nil

    -- Initial game state
    self:sceneChange(1)
end

-- Clear all characters from the current map and change the current map
function Game:sceneChange(scene_id)

    -- Stop existing scene and start new scene
    if self.current_scene then
        self.current_scene:stop()
    end
    self.current_scene = self.scenes[scene_id]
    self.current_scene:start()
end

-- Update game state
function Game:update(dt)

    -- Update scene state, map, and all characters in scene
    local new_scene_id = self.current_scene:update(dt)

    -- Detect and handle scene change
    if new_scene_id then
        self:sceneChange(new_scene_id)
    end
end

-- Render everything!
function Game:render()
    self.current_scene:render()
end
