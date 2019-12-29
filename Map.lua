require 'Util'
require 'Character'

Map = Class{}

-- constructor for our map object
function Map:init(name, tileset, lighting)

    -- Read lines of map file
    local lines = readLines('Abelon/maps/' .. name .. '.txt')

    -- Set map and tile parameters
    local meta = split(lines[1])
    self.map_width = tonumber(meta[1])
    self.map_height = tonumber(meta[2])

    -- Read collideable tile ids
    self.collide_tiles = mapf(tonumber, split(lines[2]))

    -- Map texture and tile array
    self.name = name
    self.tilesheet = love.graphics.newImage('graphics/tilesets/' .. name .. '/' .. tileset .. '.png')
    self.quads = generateQuads(self.tilesheet, TILE_WIDTH, TILE_HEIGHT)
    self.lighting = lighting

    -- Read tiles from file
    self.tiles = {}
    for y = 3, self.map_height + 2 do
        local l = lines[y]
        for x = 1, self.map_width do
            local tile_id = tonumber(l:sub(x, x))
            self:setTile(x, y - 2, tile_id)
        end
    end

    -- Transition tiles gives the tiles on this map that move to a new map
    -- Transitions gives the map to move to and the location on that map to start at
    self.transition_tiles = {}
    self.transitions = {}
    for i = self.map_height + 3, #lines do
        local data = split(lines[i])
        table.insert(self.transition_tiles, { ['x'] = tonumber(data[1]), ['y'] = tonumber(data[2]) })
        table.insert(self.transitions, { ['name'] = data[3], ['x'] = tonumber(data[4]), ['y'] = tonumber(data[5]) })
    end

    -- Characters on the map
    self.characters = {}
    self.player = nil
end

-- Retrieve characters tied to this map
function Map:getCharacters()
    return self.characters
end

-- Populate the map with a character object
function Map:addCharacter(char, is_player)

    -- Set player object
    if is_player then
        self.player = char
    end

    -- Add to character list
    self.characters[char:getName()] = char
end

-- Remove a character object from this map
function Map:dropCharacter(char)
    self.characters[char:getName()] = nil
end

-- Return name of map
function Map:getName()
    return self.name
end

-- Get pixel dimensions of this maps
function Map:getPixelDimensions()
    return self.map_width * TILE_WIDTH, self.map_height * TILE_HEIGHT
end

-- Return whether a given tile is collidable (wall, obstacle)
function Map:collides(tile)

    -- Return true if tile type matches
    for _, id in pairs(self.collide_tiles) do
        if tile.id == id then
            return true
        end
    end

    -- If tile not in collide_tiles, it's walkable
    return false
end

-- Return whether a pixel coordinate is on the given tile coordinates
function Map:pixelOnTile(pixel_x, pixel_y, tile_x, tile_y)
    local tile = self:tileAt(pixel_x, pixel_y)
    return (tile['x'] == tile_x and tile['y'] == tile_y)
end

-- Get the tile type at a given pixel coordinate
function Map:tileAt(x, y)

    -- Get tile coordinates from pixel coordinates
    local tile_x = math.floor(x / TILE_WIDTH) + 1
    local tile_y = math.floor(y / TILE_HEIGHT) + 1

    -- return tile object
    return { ['x'] = tile_x, ['y'] = tile_y, ['id'] = self:getTile(tile_x, tile_y) }
end

-- Return the id of the tile at the given coordinate
function Map:getTile(x, y)
    return self.tiles[(y - 1) * self.map_width + x]
end

-- Set the tile id at the given tile coordinate
function Map:setTile(x, y, id)
    self.tiles[(y - 1) * self.map_width + x] = id
end

-- Figure out whether a map needs to be switched to, and what map
function Map:checkTransitionTiles()

    -- Iterate over all transition tiles
    for i=1, #self.transition_tiles do

        -- If player is on a transition tile, we need to transition to the new map
        local t = self.transition_tiles[i]
        if self.player:onTile(t['x'], t['y']) then
            return self.transitions[i]
        end
    end

    -- If no transition, return nil
    return nil
end

-- Update the map
function Map:update(dt)

    -- Update each character on the map
    for _, char in pairs(self.characters) do
        char:update(dt)
    end

    -- Check if the map needs to be switched
    return self:checkTransitionTiles()
end

-- Renders the map to the screen
function Map:render()

    -- Render all non-empty tiles
    for y=1, self.map_height do
        for x=1, self.map_width do
            local tile = self:getTile(x, y)
            if tile then
                love.graphics.draw(self.tilesheet, self.quads[tile], (x-1) * TILE_WIDTH, (y-1) * TILE_HEIGHT)
            end
        end
    end

    -- Render all of the characters on the map
    for _, char in pairs(self.characters) do
        char:render()
    end
end
