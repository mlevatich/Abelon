require 'src.Util'
require 'src.Constants'

require 'src.Sprite'

Map = class('Map')

-- constructor for our map object
function Map:initialize(name, c)

    -- Map texture
    self.name = name

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
    for i = 1, #lines[5] do
        local t = tonumber(lines[5]:sub(i, i), 30)
        self.collide_tiles[t] = true
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
    self.base_intensity = {}
    idx = idx + 4
    while lines[idx] ~= '' do

        -- Each line is a single light source
        local data = mapf(tonumber, split(lines[idx]))
        local xc, yc = self:tileCenter(data[1], data[2])
        table.insert(self.lights, {
            ['x'] = xc,
            ['y'] = yc,
            ['intensity'] = data[3]
        })
        table.insert(self.base_intensity, data[3])
        idx = idx + 1
    end

    -- Non-interactive sprites which are fixed to this map
    idx = idx + 2
    while idx <= #lines do
        if lines[idx]:sub(1,1) == '~' then
            local fields = split(lines[idx]:sub(2))
            self:spawnSprite(fields, c)
        end
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
    for i = 1, #self.sprites do
        if (sp.y + sp.h) <= (self.sprites[i].y + self.sprites[i].h) then
            table.insert(self.sprites, i, sp)
            return
        end
    end
    table.insert(self.sprites, sp)
end

-- Create a sprite from string fields and add it to the map
function Map:spawnSprite(fields, c)

    -- Create sprite from ID
    local sp = Sprite:new(fields[1], c)

    -- Set position
    local x = math.floor(0.5 + (tonumber(fields[2]) - 1) * TILE_WIDTH)
    local y = math.floor(0.5 + (tonumber(fields[3]) - 1) * TILE_HEIGHT)
    sp:resetPosition(x, y)

    -- Set direction
    local dir = fields[4]
    sp.dir = ite(dir == 'R', RIGHT, LEFT)

    -- Add to map
    self:addSprite(sp)
    return sp
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

-- Get pixel dimensions of this map
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

-- Maintain rendering order when sprites move
function Map:updateSpriteY(sp, dy)
    if dy ~= 0 then
        local i = find(self.sprites, sp)
        while true do
            local j = i + ite(dy > 0, 1, -1)
            while self.sprites[j] and self.sprites[j]:isGround() do
                j = j + ite(dy > 0, 1, -1)
            end
            local other = self.sprites[j]
            if other then
                local sp_g = sp.y + sp.h
                local o_g = other.y + other.h
                if (dy > 0 and o_g < sp_g) or (dy < 0 and o_g > sp_g) then
                    self.sprites[i] = other
                    self.sprites[j] = sp
                    i = j
                else
                    break
                end
            else
                break
            end
        end
    end
end

-- Update the map
function Map:update(dt, player)

    -- Update each sprite on the map
    for _, sp in pairs(self.sprites) do
        self:updateSpriteY(sp, sp:update(dt))
    end

    -- Check if the map needs to be switched
    return self:checkTransitionTiles(player)
end

-- Light each tile based on their proximity to the map's light sources
function Map:applyLightSources()

    -- Track a smooth but varying intensity for each light to allow them to flicker
    for i=1, #self.lights do
        local base = self.base_intensity[i]
        local l = self.lights[i]
        local hi = base * 1.15
        local lo = base * 0.85
        local variance = base / 30
        l['intensity'] = math.max(lo, math.min(hi, l['intensity'] + math.random() * variance - variance / 2))
    end

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

                -- Add this light's intensity to total based on distance
                local contribution = math.max(0,
                    (l['intensity'] - dist) / l['intensity'])
                alpha = alpha * (1 - contribution)
            end

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
    local tilesheet = map_graphics[self.name]['tilesheet']
    local quads = map_graphics[self.name]['quads']
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

function Map:renderGroundSprites()

    -- Render all sprites at or below ground depth
    for _, sp in pairs(self.sprites) do
        if sp:isGround() then sp:render() end
    end
end

function Map:renderStandingSprites()

    -- Render all sprites above ground depth
    for i=1, #self.sprites do
        if not self.sprites[i]:isGround() then
            self.sprites[i]:render()
        end
    end
end

-- Apply lighting effects to map
function Map:renderLighting()
    self:applyLighting()
end

-- INITIALIZE GRAPHICAL DATA
map_graphics = {}
local map_ids = { 'west-forest', 'south-forest', 'east-forest', 'monastery-approach', 'monastery-entrance', 'waiting-room' }
for i = 1, #map_ids do
    local n = map_ids[i]
    map_graphics[n] = {}
    local img_file = 'graphics/tilesets/' .. n .. '.png'
    map_graphics[n]['tilesheet'] = love.graphics.newImage(img_file)
    map_graphics[n]['quads'] = generateQuads(
        map_graphics[n]['tilesheet'], TILE_WIDTH + 1, TILE_HEIGHT + 1
    )
end
