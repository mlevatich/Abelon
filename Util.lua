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

-- Absolute value function
function abs(val)
    if val < 0 then
        return -val
    else
        return val
    end
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
