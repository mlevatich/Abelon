require 'Util'
require 'Character'

Map = Class{}

-- Dimensions of a tile
local TILE_WIDTH = 32
local TILE_HEIGHT = 32

-- Tile ids
TILE_EMPTY = 0
TILE_BRICK = 1
TILE_COBBLE = 2

-- constructor for our map object
function Map:init(name)

    -- Get mapfile and grab first line
    local mapfile = io.open("Abelon/maps/" .. name .. ".txt", "r")
    io.input(mapfile)
    local tokens = {}
    for s in io.read():gmatch("[^ ]+") do
        table.insert(tokens, s)
    end

    -- Set map and tile parameters
    self.tileWidth = TILE_WIDTH
    self.tileHeight = TILE_HEIGHT
    self.mapWidth = tonumber(tokens[1])
    self.mapHeight = tonumber(tokens[2])
    self.mapWidthPixels = self.tileWidth * self.mapWidth
    self.mapHeightPixels = self.tileHeight * self.mapHeight

    -- Map texture and tile array
    self.name = name
    self.spritesheet = love.graphics.newImage('graphics/' .. name .. '.png')
    self.sprites = generateQuads(self.spritesheet, self.tileWidth, self.tileHeight)
    self.tiles = {}

    -- Generate terrain
    for y = 1, self.mapHeight do
        local line = io.read()
        for x = 1, self.mapWidth do
            tile_id = tonumber(line:sub(x, x))
            self:setTile(x, y, tile_id)
        end
    end
    io.close(mapfile)

    -- Music for this map
    self.music = love.audio.newSource('music/' .. name .. '.wav', 'static')

    -- List of characters on map
    self.active_characters = {}
end

-- Return whether a given tile is collidable
function Map:collides(tile)

    -- Define collidable tiles
    local collidables = { TILE_BRICK }

    -- Return true if tile type matches
    for _, id in pairs(collidables) do
        if tile.id == id then
            return true
        end
    end
    return false
end

-- Get the tile type at a given pixel coordinate
function Map:tileAt(x, y)
    return {
        x = math.floor(x / self.tileWidth) + 1,
        y = math.floor(y / self.tileHeight) + 1,
        id = self:getTile(math.floor(x / self.tileWidth) + 1, math.floor(y / self.tileHeight) + 1)
    }
end

-- Return the id of the tile at the given coordinate
function Map:getTile(x, y)
    return self.tiles[(y - 1) * self.mapWidth + x]
end

-- Set the tile id at the given coordinate
function Map:setTile(x, y, id)
    self.tiles[(y - 1) * self.mapWidth + x] = id
end

-- Start the map's music
function Map:startMusic()
    self.music:setLooping(true)
    self.music:play()
end

-- Stop the map's music
function Map:stopMusic()
    self.music:stop()
end

-- Set a new character to be active on this map
function Map:addCharacter(char)
    self.active_characters[char.name] = char
end

-- Remove a character from this map
function Map:removeCharacter(name)
    self.active_characters.remove(name)
end

-- Get all characters currently active on the map
function Map:getCharacters()
    return self.active_characters
end

-- Update all of the characters active in the current map
function Map:update(dt)
    for _, char in pairs(self.active_characters) do
        char:update(dt)
    end
end

-- Renders the map to the screen, and all of its active objects
function Map:render()

    -- Render tiles
    for y = 1, self.mapHeight do
        for x = 1, self.mapWidth do
            local tile = self:getTile(x, y)
            if tile ~= TILE_EMPTY then
                love.graphics.draw(self.spritesheet, self.sprites[tile], (x-1)*self.tileWidth, (y-1)*self.tileHeight)
            end
        end
    end

    -- Render active characters
    for _, char in pairs(self.active_characters) do
        char:render()
    end
end
