require 'Util'
require 'Character'

Map = Class{}

-- constructor for our map object
function Map:init(name, tileset, lighting)

    -- Read lines of map file
    local lines = readLines('Abelon/maps/' .. name .. '.txt')

    -- Set map and tile parameters
    local meta = split(lines[1])
    self.width = tonumber(meta[1])
    self.height = tonumber(meta[2])

    -- Read collideable tile ids
    self.collide_tiles = mapf(tonumber, split(lines[2]))

    -- Map texture and tile array
    self.name = name
    self.tilesheet = love.graphics.newImage('graphics/tilesets/' .. name .. '/' .. tileset .. '.png')
    self.quads = generateQuads(self.tilesheet, TILE_WIDTH, TILE_HEIGHT)

    -- Lighting
    self.lit = 0.5
    self.ambient = { ['r'] = 20/255, ['g'] = 20/255, ['b'] = 40/255 }
    self.lights = { { ['x'] = 800, ['y'] = 200, ['r'] = 248/255, ['g'] = 195/255, ['b'] = 119/255, ['intensity'] = 300 } }

    -- Read tiles from file
    self.tiles = {}
    for y = 3, self.height + 2 do
        local l = lines[y]
        for x = 1, self.width do
            local tile_id = tonumber(l:sub(x, x))
            self:setTile(x, y - 2, tile_id)
        end
    end

    -- Transition tiles gives the tiles on this map that move to a new map
    -- Transitions gives the map to move to and the location on that map to start at
    self.transition_tiles = {}
    self.transitions = {}
    for i = self.height + 3, #lines do

        -- Transition tiles
        local data = split(lines[i])
        table.insert(self.transition_tiles, { ['x'] = tonumber(data[1]), ['y'] = tonumber(data[2]) })

        -- Transition
        local pixel_x = (tonumber(data[4]) - 1) * TILE_WIDTH
        local pixel_y = (tonumber(data[5]) - 1) * TILE_HEIGHT
        table.insert(self.transitions, { ['name'] = data[3], ['x'] = pixel_x, ['y'] = pixel_y })
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
    return self.width * TILE_WIDTH, self.height * TILE_HEIGHT
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
    return { ['x'] = tile_x, ['y'] = tile_y, ['id'] = self:getTile(tile_x, tile_y) }
end

-- Return the id of the tile at the given coordinate
function Map:getTile(x, y)
    return self.tiles[(y - 1) * self.width + x]
end

-- Set the tile id at the given tile coordinate
function Map:setTile(x, y, id)
    self.tiles[(y - 1) * self.width + x] = id
end

-- Figure out whether a map needs to be switched to, and what map
function Map:checkTransitionTiles()

    -- Iterate over all transition tiles
    for i=1, #self.transition_tiles do

        -- If player is on a transition tile, we need to transition to the new map
        local tt = self.transition_tiles[i]
        local t = self.transitions[i]
        local on, xd, yd = self.player:onTile(tt['x'], tt['y'])
        if on then
            return { ['name'] = t['name'], ['x'] = t['x'] + xd, ['y'] = t['y'] + yd }
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

-- Light the whole map with the ambient light level
function Map:applyAmbientLight(cam_x, cam_y)
    love.graphics.setColor(self.ambient[1]/255, self.ambient[2]/255, self.ambient[3]/255, self.ambient[4])
    love.graphics.rectangle("fill", cam_x, cam_y, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)
end

-- Light each tile based on their proximity to the map's light sources
function Map:applyLightSources()

    -- Iterate over all tiles
    for x=1, self.width do
        for y=1, self.height do

            -- For each tile, add the light coming in from every source on the map
            local alpha = self.lit
            local total = { ['r'] = self.ambient['r'], ['g'] = self.ambient['g'], ['b'] = self.ambient['b'] }
            for i=1, #self.lights do

                -- Calculate distance between light and tile
                local l = self.lights[i]
                local xc, yc = self:tileCenter(x, y)
                local dist = math.sqrt((l['x'] - xc) * (l['x'] - xc) + (l['y'] - yc) * (l['y'] - yc))

                -- Calculate whether light reaches tile using bresenhem (short circuit if initial dist is too big)

                -- Add this light's intensity to total based on distance
                local contribution = math.max(0, (l['intensity'] - dist) / l['intensity'])
                for _, c in pairs({'r', 'g', 'b'}) do
                    total[c] = math.min(1, total[c] + contribution * l[c])
                end
                alpha = alpha * (1 - contribution)
            end

            -- Draw rectangle of light at the calculated total intensity over tile
            love.graphics.setColor(total['r'], total['g'], total['b'], alpha)
            love.graphics.rectangle("fill", (x - 1) * TILE_WIDTH, (y - 1) * TILE_HEIGHT, TILE_WIDTH, TILE_HEIGHT)
        end
    end
end

-- Apply all lighting effects
function Map:applyLighting()

    -- Ambient light over whole map
    --self:applyAmbientLight()

    -- Individual light sources if the map is currently lit
    if self.lit then
        self:applyLightSources()
    end
end

-- Renders the map to the screen
function Map:render(cam_x, cam_y)

    -- Render all non-empty tiles
    for y=1, self.height do
        for x=1, self.width do
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

    -- Apply lighting effects to map
    self:applyLighting()
end
