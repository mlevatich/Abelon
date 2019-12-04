require 'Util'

-- Apparent game resolution
VIRTUAL_WIDTH = 864
VIRTUAL_HEIGHT = 486

Dialogue = Class{}

-- Text variables
FONT_SIZE = 20
PORTRAIT_SIZE = 120
local LINES_PER_PAGE = 4
local TEXT_INTERVAL = 0.03
local BOX_MARGIN = 20
local TEXT_MARGIN_X = -5
local TEXT_MARGIN_Y = 10
local BOX_WIDTH = VIRTUAL_WIDTH - BOX_MARGIN*2
local CHARS_PER_LINE = math.floor((BOX_WIDTH - BOX_MARGIN*2 - PORTRAIT_SIZE)/(TEXT_MARGIN_X + FONT_SIZE))
local BOX_HEIGHT = TEXT_MARGIN_Y*(LINES_PER_PAGE+2) + FONT_SIZE*LINES_PER_PAGE + BOX_MARGIN

-- Initialize a new set of frames
function Dialogue:init(scriptfile, char1, char2, starting_track)

    -- Read script file into script data structure
    self.script = {}
    local pages = 1
    local speaker = nil
    local track = nil
    local lines = {}
    local portrait_id = nil
    for line in io.lines(scriptfile) do
        lines[#lines+1] = line
    end

    local i = 1
    while i <= #lines do
        if lines[i]:sub(5,5) == '~' then
            speaker = lines[i]:sub(6, #lines[i] - 2)
            portrait_id = tonumber(lines[i]:sub(#lines[i], #lines[i]))
            track = lines[i]:sub(1,2)
            if speaker == 'CHOICE' then
                self.script[pages] = {
                    ['speaker'] = speaker,
                    ['choices'] = {}
                }
                while true do
                    i = i + 1
                    if lines[i]:sub(5,5) == '~' then
                        i = i - 1
                        break
                    elseif lines[i] ~= '' then
                        cs = self.script[pages]['choices']
                        cs[#cs+1] = {
                            ['text'] = lines[i]:sub(5, #lines[i]),
                            ['track'] = lines[i]:sub(1,2)
                        }
                    end
                end
                pages = pages + 1
            end
        elseif lines[i] ~= '' then
            self.script[pages] = {
                ['speaker'] = speaker,
                ['portrait'] = portrait_id,
                ['text'] = splitByCharLimit(lines[i]),
                ['length'] = #lines[i],
                ['track'] = track
            }
            pages = pages + 1
        end
        i = i + 1
    end

    -- Participants
    self.char1 = char1
    self.char2 = char2

    -- Recording current position in the dialogue
    self.page_num = 1
    self.character_num = 0
    self.waiting = false

    -- Dialogue renders on a timer, one character at a time
    self.timer = 0
    self.interval = TEXT_INTERVAL

    -- Handling choices and branching
    self.responding = false
    self.selection = 0
    self.starting_track = starting_track
    self.track = starting_track

    -- Gobble pages until starting track is found
    while self.script[self.page_num]['track'] ~= self.track do
        self.page_num = self.page_num + 1
    end
end

-- Get other participant in the dialogue (the one not passed as an argument)
function Dialogue:getOther(char)
    if char.name == self.char1.name then
        return self.char2
    else
        return self.char1
    end
end

-- Called when player hits space while talking, returns true if dialogue over
function Dialogue:continue()

    if self.waiting then
        self.waiting = false
        if self.responding then
            self.responding = false
            self.track = self.script[self.page_num + 1]['choices'][self.selection]['track']
            self.page_num = self.page_num + 1
        end
        local has_next = false
        for x=self.page_num+1, #self.script do
            if self.script[x]['speaker'] ~= 'CHOICE' and self.script[x]['track'] == self.track then
                has_next = true
                self.page_num = x
                break
            end
        end
        self.character_num = 0
        if not has_next then
            return self.track
        end
    else
        self.character_num = self.script[self.page_num]['length']
        self.waiting = true
        if self.page_num ~= #self.script and self.script[self.page_num + 1]['speaker'] == 'CHOICE' then
            self.responding = true
            self.selection = 1
        end
    end
    return nil
end

-- Called when player presses up or down while talking to hover a selection
function Dialogue:hover(up)
    if self.responding then
        if up and self.selection ~= 1 then
            self.selection = self.selection - 1
        elseif not up and self.selection ~= #self.script[self.page_num+1]['choices'] then
            self.selection = self.selection + 1
        end
    end
end

-- Increment time and move to the next character
function Dialogue:update(dt)

    -- Update time passed
    self.timer = self.timer + dt

    -- Iteratively subtract interval from timer
    while self.timer > self.interval do
        self.timer = self.timer - self.interval

        -- If not waiting, go to next character
        if not self.waiting then
            self.character_num = self.character_num + 1

            -- If reached the end, wait for a continue input
            if self.character_num == self.script[self.page_num]['length'] then
                self.waiting = true
                if self.page_num ~= #self.script and self.script[self.page_num + 1]['speaker'] == 'CHOICE' then
                    self.responding = true
                    self.selection = 1
                end
            end
        end
    end
end

-- Render dialogue to screen at current position
function Dialogue:render(baseX, baseY)

    -- Render below the player if at the top of a map
    local bottom = false
    if baseY == 0 then
        baseY = VIRTUAL_HEIGHT - (BOX_HEIGHT + BOX_MARGIN*2)
        bottom = true
    end

    -- Current page
    local page = self.script[self.page_num]

    -- Speaker's character object
    local char = self.char1
    if self.char2.name == page['speaker'] then
        char = self.char2
    end

    -- Render black text box
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle('fill', baseX + BOX_MARGIN, baseY + BOX_MARGIN, BOX_WIDTH, BOX_HEIGHT)

    -- Render name of current speaker
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(page['speaker'], baseX + BOX_MARGIN*2, baseY + BOX_MARGIN + TEXT_MARGIN_Y)

    -- Render portrait of current speaker
    love.graphics.draw(char.ptexture, char.portraits[page['portrait']], baseX + BOX_MARGIN, baseY + BOX_MARGIN*3, 0, 1, 1, 0, 0)

    -- Render text up to current character position
    local x_beginning = baseX + BOX_MARGIN*2 + PORTRAIT_SIZE
    local y_beginning = baseY + BOX_MARGIN + TEXT_MARGIN_Y + 20
    local line_num = 1
    local j = 1
    for i = 1, self.character_num do

        local x = x_beginning + (TEXT_MARGIN_X + FONT_SIZE) * (j - 1)
        local y = y_beginning + (TEXT_MARGIN_Y + FONT_SIZE) * (line_num-1)
        love.graphics.print(page['text'][line_num]:sub(j, j), x, y)
        j = j + 1
        if j > #page['text'][line_num] then
            line_num = line_num + 1
            j = 1
        end
    end

    -- Render dialogue box with choices, and arrow hovering over selection
    if self.responding then
        local choices = self.script[self.page_num+1]['choices']

        local longest = 0
        for i=1, #choices do
            if #choices[i]['text'] > longest then
                longest = #choices[i]['text']
            end
        end
        local w = BOX_MARGIN*2 + (TEXT_MARGIN_X + FONT_SIZE) * (longest) + 10
        local h = TEXT_MARGIN_Y + (TEXT_MARGIN_Y + FONT_SIZE) * (#choices)

        -- Draw choice box
        local rect_x = baseX + BOX_MARGIN + BOX_WIDTH - w
        local rect_y = baseY + BOX_MARGIN*2 + BOX_HEIGHT
        if bottom then
            rect_y = baseY - TEXT_MARGIN_Y - (TEXT_MARGIN_Y + FONT_SIZE) * (#choices)
        end
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle('fill', rect_x, rect_y, w, h)

        -- Put choices in choice box
        love.graphics.setColor(1, 1, 1, 1)
        for i=1, #choices do
            for j=1, #choices[i]['text'] do
                local c = choices[i]['text']:sub(j,j)
                local x = rect_x + BOX_MARGIN + (FONT_SIZE + TEXT_MARGIN_X) * (j + longest - #choices[i]['text'])
                local y = rect_y + TEXT_MARGIN_Y + (FONT_SIZE + TEXT_MARGIN_Y) * (i-1)
                love.graphics.print(c, x, y)
            end
        end
        local arrow_y = rect_y + TEXT_MARGIN_Y + (FONT_SIZE + TEXT_MARGIN_Y) * (self.selection - 1)
        love.graphics.print(">", rect_x + 15, arrow_y)
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
