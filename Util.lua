require 'Constants'

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
            quads[sheetCounter] = love.graphics.newQuad(
                x*tilewidth,
                y*tileheight,
                tilewidth,
                tileheight,
                dim,
                atlas
            )
            sheetCounter = sheetCounter + 1
        end
    end
    return quads
end

-- Get the quads listed in indices from the sprite's texture
function getSpriteQuads(indices, tex, width, height, sheet_position)
    frames = {}
    for x = 1, #indices do
        idx = indices[x]
        frames[x] = love.graphics.newQuad(
            (width + 1) * idx,
            sheet_position,
            width,
            height,
            tex:getDimensions()
        )
    end
    return frames
end

-- Split a string into several lines of text based on a maximum
-- number of characters per line, without breaking up words
function splitByCharLimit(text, char_limit)
    local lines = {}
    local i = 1
    local line_num = 1
    local holdover_word = ''
    while i <= #text do
        lines[line_num] = ''
        local word = holdover_word
        for x = 1, char_limit - #holdover_word do
            if i == #text then
                lines[line_num] = lines[line_num] .. word .. text:sub(i,i)
                i = i + 1
                break
            else
                local c = text:sub(i,i)
                if c == ' ' then
                    lines[line_num] = lines[line_num] .. word .. ' '
                    word = ''
                else
                    word = word .. c
                end
                i = i + 1
            end
        end
        holdover_word = word
        line_num = line_num + 1
    end
    local new_len = #text
    for i=1, #lines do
        if lines[i]:sub(-1) == ' ' then
            lines[i] = lines[i]:sub(0, -2)
            new_len = new_len - 1
        end
    end
    return lines, new_len
end

-- ite
function ite(i, t, e)
    if i then
        return t
    else
        return e
    end
end

-- Map a function over a table's values
function mapf(func, tbl)
    local new_tbl = {}
    for k,v in pairs(tbl) do
        new_tbl[k] = func(v)
    end
    return new_tbl
end

function concat(t1, t2)
    local t3 = {}
    for _,v in pairs(t1) do
        table.insert(t3, v)
    end
    for _,v in pairs(t2) do
        table.insert(t3, v)
    end
    return t3
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

-- Check if the given table find the given value
function find(t, val)
    for k, v in pairs(t) do
        if v == val then
            return k
        end
    end
    return nil
end

function avg(t)
    sum = 0
    for k, v in pairs(t) do
        sum = sum + v
    end
    return sum / #t
end

-- Split a spring by whitespace
function split(str)
    local list = {}
    for elem in string.gmatch(str, "%S+") do
        list[#list+1] = elem
    end
    return list
end

-- Split a spring by the given seperator
function splitSep(str, sep)
    local array = {}
    local reg = string.format("([^%s]+)",sep)
    for mem in string.gmatch(str,reg) do
        table.insert(array, mem)
    end
    return array
end

-- Read the second value in a string split by whitespace
function readField(str)
    return split(str)[2]
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
        for k,v in pairs(var) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. '[' .. k .. '] = ' .. toString(v) .. ','
        end
        return s .. '} '
    else
        return tostring(var)
    end
end

-- Deepcopy a table
function deepcopy(obj, seen)
    if type(obj) ~= 'table' then return obj end
    if seen and seen[obj] then return seen[obj] end
    local s = seen or {}
    local res = setmetatable({}, getmetatable(obj))
    s[obj] = res
    for k, v in pairs(obj) do res[deepcopy(k, s)] = deepcopy(v, s) end
    return res
end

-- Print the contents of any variable
function dump(var)
    print(toString(var))
end

function pass() end
