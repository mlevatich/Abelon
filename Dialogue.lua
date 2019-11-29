require 'Util'

-- Apparent game resolution
VIRTUAL_WIDTH = 864
VIRTUAL_HEIGHT = 486

Dialogue = Class{}

-- Text variables
FONT_SIZE = 20
local LINES_PER_PAGE = 4
local TEXT_INTERVAL = 0.03
local BOX_MARGIN = 20
local BOX_WIDTH = VIRTUAL_WIDTH - BOX_MARGIN*2
local TEXT_MARGIN_X = -5
local TEXT_MARGIN_Y = 10
local CHARS_PER_LINE = math.floor((BOX_WIDTH - BOX_MARGIN*2)/(TEXT_MARGIN_X + FONT_SIZE))
local BOX_HEIGHT = TEXT_MARGIN_Y*(LINES_PER_PAGE+2) + FONT_SIZE*LINES_PER_PAGE

-- Initialize a new set of frames
function Dialogue:init(scriptfile)

    -- Read script file into script data structure
    self.script = {}
    pages = 1
    speaker = nil
    for line in io.lines(scriptfile) do
        if line:sub(1,1) == '~' then
            speaker = line:sub(2, #line)
        else
            self.script[pages] = {
                ['speaker'] = speaker,
                ['text'] = splitByCharLimit(line),
                ['length'] = #line
            }
            pages = pages + 1
        end
    end

    -- Keeping track of current position in the dialogue
    self.page_num = 1
    self.character_num = 0
    self.timer = 0
    self.waiting = false
end

-- Called when player hits space while talking, returns true if dialogue over
function Dialogue:continue()

    if self.waiting then
        -- TODO: Make hovered selection and proceed accordingly in script
        self.waiting = false
        if self.page_num ~= #self.script then
            self.page_num = self.page_num + 1
            self.character_num = 0
        else
            return true
        end
    else
        self.character_num = self.script[self.page_num]['length']
        self.waiting = true
    end
    return false
end

-- Called when player presses up or down while talking to hover a selection
function Dialogue:hover()
    -- TODO
end

-- Increment time and move to the next character
function Dialogue:update(dt)

    -- Update time passed
    self.timer = self.timer + dt

    -- Iteratively subtract interval from timer
    while self.timer > TEXT_INTERVAL do
        self.timer = self.timer - TEXT_INTERVAL

        -- If not waiting, go to next character
        if not self.waiting then
            self.character_num = self.character_num + 1

            -- If reached the end, wait for a continue input
            if self.character_num == self.script[self.page_num]['length'] then
                self.waiting = true
            end
        end
    end
end

-- Render dialogue to screen at current position
function Dialogue:render(baseX, baseY)

    -- Render below the player if at the top of a map
    if baseY == 0 then
        baseY = VIRTUAL_HEIGHT - (BOX_HEIGHT + BOX_MARGIN*2)
    end

    -- Current page
    local page = self.script[self.page_num]

    -- Render black text box
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle('fill', baseX + BOX_MARGIN, baseY + BOX_MARGIN, BOX_WIDTH, BOX_HEIGHT)

    -- Render name of current speaker
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(page['speaker'], baseX + BOX_MARGIN*2, baseY + BOX_MARGIN + TEXT_MARGIN_Y)

    -- TODO: render portrait of current speaker

    -- Render text up to current character position
    local x_beginning = baseX + BOX_MARGIN * 2
    local y_beginning = baseY + BOX_MARGIN + TEXT_MARGIN_Y
    local line_num = 1
    local j = 1
    for i = 1, self.character_num do

        local x = x_beginning + (TEXT_MARGIN_X + FONT_SIZE) * (j - 1)
        local y = y_beginning + (TEXT_MARGIN_Y + FONT_SIZE) * line_num
        love.graphics.print(page['text'][line_num]:sub(j, j), x, y)
        j = j + 1
        if j > #page['text'][line_num] then
            line_num = line_num + 1
            j = 1
        end
    end
end

function splitByCharLimit(text)
    local lines = {}
    local i = 1
    local line_num = 1
    local holdover_word = ''
    while i <= #text do
        lines[line_num] = ''
        local word = holdover_word
        for x = 1, CHARS_PER_LINE - #holdover_word do
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
    return lines
end
