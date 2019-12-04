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
    self.spritesheet = love.graphics.newImage('graphics/maps/' .. name .. '.png')
    self.sprites = generateQuads(self.spritesheet, self.tileWidth, self.tileHeight)
    self.tiles = {}

    -- Transition tiles, with map to transition to and entrance index in new map
    self.transitions = nil

    -- Generate terrain
    for y = 1, self.mapHeight do
        local line = io.read()
        for x = 1, self.mapWidth do
            tile_id = tonumber(line:sub(x, x))
            self:setTile(x, y, tile_id)
        end
    end
    io.close(mapfile)
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

-- Update the map
function Map:update()
    -- No-op
end

-- Renders the map to the screen
function Map:render()

    -- Render all non-empty tiles
    for y=1, self.mapHeight do
        for x=1, self.mapWidth do
            local tile = self:getTile(x, y)
            if tile ~= TILE_EMPTY then
                love.graphics.draw(self.spritesheet, self.sprites[tile], (x-1) * self.tileWidth, (y-1) * self.tileHeight)
            end
        end
    end
end
