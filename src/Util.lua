require 'src.Constants'

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

function tileToPixels(x, y)
    return (x - 1) * TILE_WIDTH, (y - 1) * TILE_HEIGHT
end

function drawFade(alpha)
    love.graphics.push('all')
    love.graphics.setColor(0, 0, 0, alpha)
    love.graphics.rectangle('fill', 0, 0, VIRTUAL_WIDTH / ZOOM, VIRTUAL_HEIGHT / ZOOM)
    love.graphics.pop()
end

function printChar(s, x, y, rot)
    love.graphics.print(s, x, y, rot)
end

function renderString(s, x, y, pen, auto_color, inherit_clr)
    if not pen then pen = WHITE end
    if not inherit_clr then
        love.graphics.setColor(unpack(pen))
    end
    local char_color = {}
    if auto_color then
        for i = 1, #s do char_color[i] = pen end
        for k, clr in pairs(AUTO_COLOR) do
            local st, ed = s:find(k)
            while st and ed do
                for i = st, ed do char_color[i] = clr end
                st, ed = s:find(k, ed)
            end
        end
    end
    for i = 1, #s do
        local c = s:sub(i, i)
        if auto_color and c ~= ' ' and c ~= '*' and
        not (tonumber(c) or tonumber(s:sub(i,i+1) or tonumber(s:sub(i,i+2))))
        then
            love.graphics.setColor(unpack(char_color[i]))
            printChar(c, x + CHAR_WIDTH * (i - 1), y)
        elseif auto_color and tonumber(c) then
            r, g, b, a = love.graphics.getColor()
            if r == g and g == b then
                love.graphics.push('all')
                love.graphics.setColor(unpack(HIGHLIGHT))
                printChar(c, x + CHAR_WIDTH * (i - 1), y)
                love.graphics.pop()
            else
                printChar(c, x + CHAR_WIDTH * (i - 1), y)
            end
        else
            printChar(c, x + CHAR_WIDTH * (i - 1), y)
        end
    end
end

function mkEle(t, data, x, y, extra, auto_color)
    local ele = {
        ['type'] = t,
        ['data'] = data,
        ['x'] = x,
        ['y'] = y,
        ['auto_color'] = auto_color
    }
    ele[ite(t == 'image', 'texture', 'color')] = extra
    return ele
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

function filter(func, tbl)
    local new_tbl = {}
    for k,v in pairs(tbl) do
        if func(v) then
            if type(k) == "number" and math.floor(k) == k then
                table.insert(new_tbl, v)
            else
                new_tbl[k] = v
            end
        end
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

-- Find the given value in the table, return key, or nil if missing
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

-- Read a field and save its name
function readNamed(str, f)
    local n = split(str)[1]
    return n, f(str)
end

-- Read a field as a single string
function readField(str, apply)
    local val = split(str)[2]
    if apply and val then
        return apply(val)
    else
        return val
    end
end

-- Read a field as an array
function readArray(str, apply)
    local arr_str = readField(str)
    local arr = {}
    if arr_str then
        arr = splitSep(arr_str, ',')
        if apply then
            arr = mapf(apply, arr)
        end
    end
    return arr
end

-- Read a field as a dictionary
function readDict(str, kind, order, apply)
    local pairs = split(str)
    local dict = {}
    for i = 2, #pairs do

        -- Get key and value
        local pair = splitSep(pairs[i],':')
        local arr = splitSep(pair[2], ',')
        if apply then
            arr = mapf(apply, arr)
        end

        -- Parse value to array or val
        local insert = arr
        if kind == VAL then
            insert = arr[1]
        end

        -- Ordered dict goes into table as pairs
        if order then
            table.insert(dict, { [order[1]] = pair[1], [order[2]] = insert })
        else
            dict[pair[1]] = insert
        end
    end
    return dict
end

function readMultiline(data, line_id)

    -- Break into individual words across multiple lines, end at EOS
    local str = ''
    for i = line_id, #data do
        local word_id = ite(i == line_id, 2, 1)
        local line = split(data[i])
        for j = word_id, #line do
            if line[j] == 'EOS' then break end
            str = str .. line[j] .. ' '
        end
    end

    -- Cut off trailing space character
    if #str > 0 then
        return str:sub(1, -1)
    else
        return ''
    end
end

-- Read a file into a table of lines
function readLines(filename)
    local lines = {}
    for l in io.lines(filename) do
        table.insert(lines, l)
    end
    return lines
end

-- Does a file exist?
function fileExists(filename)
    local f = io.open(filename, "r")
    if f ~= nil then
        io.close(f)
        return true
    else 
        return false
    end
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

-- Shallow copy
function copy(tbl)
    tbl2 = {}
    for k,v in pairs(tbl) do
        tbl2[k] = v
    end
    return tbl2
end

-- Print the contents of any variable
function dump(var)
    log(toString(var))
end

function log(s)
    if debug then print(s) end
end

function pass() end
