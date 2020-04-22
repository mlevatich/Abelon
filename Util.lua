-- Takes a spritesheet texture and width and height of tiles,
-- and splits into quads that can be individually drawn
function generateQuads(atlas, tilewidth, tileheight)

    -- Spritesheet dimensions in number of tiles
    local sheetWidth = atlas:getWidth() / tilewidth
    local sheetHeight = atlas:getHeight() / tileheight
    local dim = atlas:getDimensions()

    -- Read quads from sheet
    local sheetCounter = 1
    local quads = {}
    for y = 0, sheetHeight - 1 do
        for x = 0, sheetWidth - 1 do
            quads[sheetCounter] = love.graphics.newQuad(x*tilewidth, y*tileheight, tilewidth, tileheight, dim, atlas)
            sheetCounter = sheetCounter + 1
        end
    end

    -- Return separate quads in list
    return quads
end

-- Get the quads listed in indices from the sprite's texture
function getSpriteQuads(indices, tex, width, height)
    frames = {}
    for x = 1, #indices do
        idx = indices[x]
        frames[x] = love.graphics.newQuad((width + 1) * idx, 0, width, height, tex:getDimensions())
    end
    return frames
end

-- Map a function over a table's values
function mapf(func, tbl)
    local new_tbl = {}
    for k,v in pairs(tbl) do
        new_tbl[k] = func(v)
    end
    return new_tbl
end

-- Get maximum number in a table
function max(tbl)
    local best = -100000
    for i=1, #tbl do
        if tbl[i] > best then
            best = tbl[i]
        end
    end
    return best
end

-- Absolute value function
function abs(val)
    if val < 0 then
        return -val
    else
        return val
    end
end

-- Check if the given table contains the given value
function contains(t, val)
    for _, v in pairs(t) do
        if v == val then
            return true
        end
    end
    return false
end

-- Split a spring by whitespace
function split(str)
    local list = {}
    for elem in string.gmatch(str, "%S+") do
        list[#list+1] = elem
    end
    return list
end

-- Read a file into a table of lines
function readLines(filename)
    local lines = {}
    for l in io.lines(filename) do
        table.insert(lines, l)
    end
    return lines
end

-- Converts a table or primitive into a readable string
function toString(var)
    if type(var) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(var)
    end
end

-- Print the contents of any variable
function dump(var)
    print(toString(var))
end

function pass() end
