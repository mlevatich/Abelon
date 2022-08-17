require 'Util'
require 'Constants'

require 'Sprite'

Map = class('Map')

-- constructor for our map object
function Map:initialize(name, tileset)

    -- Map texture
    self.name = name
    self.tileset = tileset

    -- Sprites on the map
    self.sprites = {}

    -- Map files
    local prefix = 'Abelon/data/maps/' .. name .. '/'
    local meta_file = prefix .. 'meta.txt'
    local map_file = prefix .. 'map.txt'
    
    -- Set map and tile parameters
    local lines = readLines(meta_file)

    local wh = split(lines[2])
    self.width = tonumber(wh[1])
    self.height = tonumber(wh[2])

    -- Read collideable tile ids
    self.collide_tiles = {}
    local collideable = mapf(tonumber, split(lines[5]))
    for i = 1, #collideable do
        self.collide_tiles[collideable[i]] = true
    end

    -- Transition tiles gives the tiles on this map that move to a new map
    -- Transitions gives the map to move to
    -- and the location on that map to start at
    self.transition_tiles = {}
    self.transitions = {}
    local idx = 8
    while lines[idx] ~= '' do

        -- Transition tiles
        local data = split(lines[idx])
        table.insert(self.transition_tiles, {
            ['x'] = tonumber(data[1]),
            ['y'] = tonumber(data[2])
        })

        -- Transition
        local pixel_x = (tonumber(data[4]) - 1) * TILE_WIDTH
        local pixel_y = (tonumber(data[5]) - 1) * TILE_HEIGHT
        table.insert(self.transitions, {
            ['name'] = data[3],
            ['x'] = pixel_x,
            ['y'] = pixel_y
        })
        idx = idx + 1
    end

    -- Lighting data
    self.lit = tonumber(lines[idx+2])
    self.ambient = mapf(tonumber, split(lines[idx+3]))
    self.lights = {}
    idx = idx + 4
    while idx <= #lines do

        -- Each line is a single light source
        local data = mapf(tonumber, split(lines[idx]))
        local xc, yc = self:tileCenter(data[1], data[2])
        table.insert(self.lights, {
            ['x'] = xc,
            ['y'] = yc,
            ['r'] = data[3]/255,
            ['g'] = data[4]/255,
            ['b'] = data[5]/255,
            ['intensity'] = data[6]
        })
        idx = idx + 1
    end

    -- Read tiles from file
    lines = readLines(map_file)
    self.tiles = {}
    for y = 1, self.height do
        local l = lines[y]
        self.tiles[y] = {}
        for x = 1, self.width do
            local tile_id = tonumber(l:sub(x, x), 30)
            self.tiles[y][x] = tile_id
        end
    end
end

-- Retrieve sprites tied to this map
function Map:getSprites()
    return self.sprites
end

-- Get a sprite by its id
function Map:getSprite(id)
    for i = 1, #self.sprites do
        if self.sprites[i]:getId() == id then
            return self.sprites[i]
        end
    end
    return nil
end

-- Populate the map with a sprite object
function Map:addSprite(sp)

    -- Insert sprite in order of depth
    for i = 1, #self.sprites do
        if self.sprites[i]:getDepth() <= sp:getDepth() then
            table.insert(self.sprites, i, sp)
            return
        end
    end

    -- If no sprite had lower depth, insert at end
    self.sprites[#self.sprites+1] = sp
end

-- Remove a sprite from this map
function Map:dropSprite(sp_id)

    -- Find and remove sprite
    for i = 1, #self.sprites do
        local sp = self.sprites[i]
        if sp.id == sp_id then
            table.remove(self.sprites, i)
            return sp
        end
    end
end

-- Return name of map
function Map:getName()
    return self.name
end

-- Get pixel dimensions of this maps
function Map:getPixelDimensions()
    return self.width * TILE_WIDTH, self.height * TILE_HEIGHT
end

-- Return whether a given tile is collidable (wall, obstacle)
function Map:collides(tile)
    return self.collide_tiles[tile['id']]
end

-- Return whether a pixel coordinate is on the given tile coordinates
function Map:pixelOnTile(pixel_x, pixel_y, tile_x, tile_y)

    -- Get tile and check if it's a match
    local tile = self:tileAt(pixel_x, pixel_y)
    if (tile['x'] == tile_x and tile['y'] == tile_y) then
        local origin_x = (tile_x - 1) * TILE_WIDTH
        local origin_y = (tile_y - 1) * TILE_HEIGHT
        return true, pixel_x - origin_x, pixel_y - origin_y
    end

    -- if no match, return nil
    return false
end

function Map:tileCenter(x, y)
    local x_center = (x - 1) * TILE_WIDTH + TILE_WIDTH/2
    local y_center = (y - 1) * TILE_HEIGHT + TILE_HEIGHT/2
    return x_center, y_center
end

function Map:tileToPixels(x, y)
    return (x - 1) * TILE_WIDTH, (y - 1) * TILE_HEIGHT
end

-- Get the tile type at a given pixel coordinate
function Map:tileAt(x, y)

    -- Get tile coordinates from pixel coordinates
    local tile_x = math.floor(x / TILE_WIDTH) + 1
    local tile_y = math.floor(y / TILE_HEIGHT) + 1

    -- return tile object
    return {
        ['x'] = tile_x,
        ['y'] = tile_y,
        ['id'] = self.tiles[tile_y][tile_x]
    }
end

function Map:tileAtExact(x, y)

    -- Get tile coordinates from pixel coordinates
    local tile_x = (x / TILE_WIDTH) + 1
    local tile_y = (y / TILE_HEIGHT) + 1

    return {
        ['x'] = tile_x,
        ['y'] = tile_y
    }
end

-- Figure out whether a map needs to be switched to, and what map
function Map:checkTransitionTiles(player)

    -- Iterate over all transition tiles
    for i=1, #self.transition_tiles do

        -- If player is on a transition tile, need to transition to the new map
        local tt = self.transition_tiles[i]
        local t = self.transitions[i]
        local on, xd, yd = player:onTile(tt['x'], tt['y'])
        if on then
            return {
                ['name'] = t['name'],
                ['x'] = t['x'] + xd,
                ['y'] = t['y'] + yd
            }
        end
    end

    -- If no transition, return nil
    return nil
end

-- Update the map
function Map:update(dt, player)

    -- Update each sprite on the map
    for _, sp in pairs(self.sprites) do
        sp:update(dt)
    end

    -- Check if the map needs to be switched
    return self:checkTransitionTiles(player)
end

-- Light each tile based on their proximity to the map's light sources
function Map:applyLightSources()

    -- Iterate over all tiles
    for x=1, self.width do
        for y=1, self.height do

            -- For each tile, add the light coming from every source on the map
            local alpha = self.lit
            local total = {
                ['r'] = self.ambient[1] / 255,
                ['g'] = self.ambient[2] / 255,
                ['b'] = self.ambient[3] / 255
            }
            for i=1, #self.lights do

                -- Calculate distance between light and tile
                local l = self.lights[i]
                local xc, yc = self:tileCenter(x, y)
                local x_dist, y_dist = l['x'] - xc, l['y'] - yc
                local dist = math.sqrt(x_dist * x_dist + y_dist * y_dist)

                -- Calculate whether light reaches tile using bresenhem
                -- (short circuit if initial dist is too big)

                -- Add this light's intensity to total based on distance
                local contribution = math.max(0,
                    (l['intensity'] - dist) / l['intensity'])
                for _, c in pairs({'r', 'g', 'b'}) do
                    total[c] = math.min(1, total[c] + contribution * l[c])
                end
                alpha = alpha * (1 - contribution)
            end

            -- Draw rectangle of light at the total intensity over tile
            love.graphics.setColor(total['r'], total['g'], total['b'], alpha)
            love.graphics.rectangle(
                "fill",
                (x - 1) * TILE_WIDTH,
                (y - 1) * TILE_HEIGHT,
                TILE_WIDTH,
                TILE_HEIGHT
            )
        end
    end
end

-- Apply all lighting effects
function Map:applyLighting()

    -- Individual light sources if the map is currently lit
    if self.lit then
        self:applyLightSources()
    end
end

-- Renders the map to the screen
function Map:renderTiles()

    -- Render all non-empty tiles
    love.graphics.setColor(1, 1, 1, 1)
    local tilesheet = map_graphics[self.name][self.tileset]['tilesheet']
    local quads = map_graphics[self.name][self.tileset]['quads']
    for y=1, self.height do
        for x=1, self.width do
            local tile = self.tiles[y][x]
            if tile then
                love.graphics.draw(
                    tilesheet,
                    quads[tile],
                    (x-1) * TILE_WIDTH,
                    (y-1) * TILE_HEIGHT
                )
            end
        end
    end
end

function Map:renderGroundSprites(cam_x, cam_y)

    -- Render all sprites at or below ground depth
    for _, sp in pairs(self.sprites) do
        if sp:getDepth() >= GROUND_DEPTH then
            sp:render(cam_x, cam_y)
        end
    end
end

function Map:renderStandingSprites(cam_x, cam_y)

    -- Render all sprites above ground depth
    for _, sp in pairs(self.sprites) do
        if sp:getDepth() < GROUND_DEPTH then
            sp:render(cam_x, cam_y)
        end
    end
end

-- Apply lighting effects to map
function Map:renderLighting()
    self:applyLighting()
end

-- INITIALIZE GRAPHICAL DATA
map_graphics = {}
local map_ids = {
    { 'west-forest',  'standard' },
    { 'north-forest', 'standard' },
    { 'south-forest', 'standard' },
    { 'east-forest',  'standard' }
}
for i = 1, #map_ids do
    local n = map_ids[i][1]
    local tileset = map_ids[i][2]

    if not map_graphics[n] then map_graphics[n] = {} end
    map_graphics[n][tileset] = {}

    local map = map_graphics[n][tileset]
    local img_file = 'graphics/tilesets/' .. n .. '/' .. tileset .. '.png'
    map['tilesheet'] = love.graphics.newImage(img_file)
    map['quads'] = generateQuads(map['tilesheet'], TILE_WIDTH+1, TILE_HEIGHT+1)
end
