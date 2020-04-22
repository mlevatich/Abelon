require 'Util'

-- Apparent game resolution
VIRTUAL_WIDTH = 864
VIRTUAL_HEIGHT = 486

Dialogue = Class{}

-- Text variables
FONT_SIZE = 20
PORTRAIT_SIZE = 120
BOX_MARGIN = 20
TEXT_MARGIN_X = -5
TEXT_MARGIN_Y = 10

local LINES_PER_PAGE = 4
local TEXT_INTERVAL = 0.03
local BOX_WIDTH = VIRTUAL_WIDTH - BOX_MARGIN*2
local CHARS_PER_LINE = math.floor((BOX_WIDTH - BOX_MARGIN*2 - PORTRAIT_SIZE)/(TEXT_MARGIN_X + FONT_SIZE))
local BOX_HEIGHT = TEXT_MARGIN_Y*(LINES_PER_PAGE+2) + FONT_SIZE*LINES_PER_PAGE + BOX_MARGIN

-- Initialize a new dialogue
function Dialogue:init(scriptfile, player, partner, characters, starting_track)

    -- Parse the given file into the script data structure
    self.script = {}
    self:parseScriptFile(scriptfile)

    -- Participants
    self.player = player
    self.partner = partner
    self.chars_in_scene = characters

    -- Record current position in the dialogue
    self.page_num = 0
    self.character_num = 0

    -- Maintain current track and starting track
    self.starting_track = starting_track
    self.track = starting_track

    -- Record which of two options is selected in a choice
    self.selection = 1

    -- Record how much time has passed since the last update
    self.timer = 0

    -- Start at the first line of the given starting track
    self:gotoNext()
end

-- Read the lines from the script file into the script data structure
function Dialogue:parseScriptFile(scriptfile)

    -- Read lines and store into script
    local page = 1
    local lines = readLines(scriptfile)
    for i=1, #lines do

        -- A starting colon signals a new choice or line of dialogue, other lines are ignored
        if lines[i]:sub(1,1) == ':' then

            -- Read parameters from this line
            local params = split(lines[i]:sub(3))

            -- Grab speaker and portrait id from end of params
            local speaker = params[#params-1]
            local portrait_id = tonumber(params[#params])

            -- Read valid tracks for this line
            local tracks = {}
            local j = 1
            while params[j] ~= ':' do
                tracks[j] = params[j]
                j = j + 1
            end

            -- Read all impression thresholds required for this line to appear
            local thresholds = {}
            while params[j+1] ~= ':' do
                thresholds[#thresholds+1] = parseThreshold(params[j+1])
                j = j + 1
            end

            -- A line in the script is either a choice or a line of dialogue
            if speaker == 'CHOICE' then

                -- A choice has a set of tracks and list of choices
                self.script[page] = {
                    ['thresholds'] = thresholds,
                    ['tracks'] = tracks,
                    ['choices'] = {}
                }

                -- Parse choices and their effects from the following two lines in the file
                for j=1, 2 do

                    -- Read the text and effects of a single option
                    local rest = lines[i+j]:sub(6)
                    local idx, _ = rest:find(':')
                    local impressions = {}
                    for imp in string.gmatch(rest:sub(1, idx-2), "%S+") do
                        impressions[imp:sub(5)] = tonumber(imp:sub(2,3))
                    end

                    -- Store in choices
                    self.script[page]['choices'][j] = {
                        ['text'] = rest:sub(idx+2),
                        ['to_track'] = lines[i+j]:sub(1,2),
                        ['impressions'] = impressions
                    }
                end

            else

                -- A dialogue line has a speaker, portrait, tracks, length, and the text itself
                self.script[page] = {
                    ['speaker'] = speaker,
                    ['portrait'] = portrait_id,
                    ['text'] = splitByCharLimit(lines[i+1], CHARS_PER_LINE),
                    ['length'] = #lines[i+1],
                    ['thresholds'] = thresholds,
                    ['tracks'] = tracks
                }
            end

            -- Page count is incremented whenever a new page is made
            page = page + 1
        end
    end
end

-- Read a string containing an impression threshold
function parseThreshold(str)

    -- A threshold is either > some number or < some number
    if str:find('>') then

        -- Format is 'name>val'
        local idx, _ = str:find('>')
        local name = str:sub(1, idx-1)
        local val = tonumber(str:sub(idx+1))

        -- Return the name of the character and the function to check their impression against
        return { ['name'] = name, ['test'] = function(n) return n > val end }
    else

        -- Format is 'name<val'
        local idx, _ = str:find('<')
        local name = str:sub(1, idx-1)
        local val = tonumber(str:sub(idx+1))

        -- Return the name of the character and the function to check their impression against
        return { ['name'] = name, ['test'] = function(n) return n < val end }
    end
end

-- Check if all required thresholds for the given page to be valid are met
function Dialogue:meetsThresholds(page)

    -- Check if any character's impression doesn't meet the threshold
    for i=1, #page['thresholds'] do

        -- Get character's impression to test
        local name = page['thresholds'][i]['name']
        local impr = self.chars_in_scene[name]:getImpression()

        -- Test impression
        local test = page['thresholds'][i]['test']
        if not test(impr) then
            return false
        end
    end

    -- If no threshold failed, they all passed and this page is valid
    return true
end

-- Retrieve the number of the next page for this track
function Dialogue:nextValidPage(skip_choices)

    -- Start at page immediately after current
    local page_id = self.page_num + 1

    -- Gobble pages until a valid page is found or the end of the script is reached
    while page_id <= #self.script do

        -- If the page is for the current track (and isn't a choice if we're skipping those), return it
        local p = self.script[page_id]
        if contains(p['tracks'], self.track) and self:meetsThresholds(p) and not (skip_choices and p['choices']) then
            return page_id
        end

        -- Otherwise keep going
        page_id = page_id + 1
    end

    -- If no matching page was found, we're at the end of the script
    return page_id
end

-- Find the next line or choice on this track
function Dialogue:getNext()

    -- return next page in script (will be nil if end of script was reached)
    return self.script[self:nextValidPage(false)]
end

-- Move on to the next page for this track, skipping choices
function Dialogue:gotoNext()

    -- Go to next page number and set character count to zero
    self.page_num = self:nextValidPage(true)
    self.character_num = 0
end

-- Determine if the current page has a choice after it
function Dialogue:atChoice()

    -- Get next page
    local next = self:getNext()

    -- Return true if next page exists and is a choice page
    return (next and next['choices'] ~= nil)
end

-- Take a choice based on selection and propogate its effects
function Dialogue:makeChoice()

    -- Assume the choice is on the following page
    local choice = self:getNext()['choices'][self.selection]

    -- Need to jump forward in the script to the choice before switching tracks, in case there are lines from
    -- the chosen track in between the current page and the choice page
    self.page_num = self:nextValidPage(false)

    -- Effects of choice is to change the dialogue track and change character impressions
    self.track = choice['to_track']
    for name, change in pairs(choice['impressions']) do
        self.chars_in_scene[name]:changeImpression(change)
    end
end

-- Called when the player hits space while talking, returns ending track if is dialogue over or nil otherwise
function Dialogue:advance()

    -- If we're at the end of a line, continue to next page
    local page = self.script[self.page_num]
    if page['length'] == self.character_num then

        -- If we're waiting at a choice, then make choice based on current selection
        if self:atChoice() then
            self:makeChoice()
        end

        -- Advance to the next page, end dialogue if no more pages
        self:gotoNext()
        if self.page_num > #self.script then
            return self.track
        end
    else

        -- If not already at the end, jump to the end of the line
        self.character_num = page['length']
    end

    -- Return nil if the dialogue didn't end
    return nil
end

-- Called when player presses up or down while talking to hover a selection
function Dialogue:hover(up)

    -- self.selection determines where the selection arrow is rendered
    if up then
        self.selection = math.max(1, self.selection - 1)
    else
        self.selection = math.min(2, self.selection + 1)
    end
end

-- Increment time and move to the next character
function Dialogue:update(dt)

    -- Update time passed
    self.timer = self.timer + dt

    -- Iteratively subtract interval from timer and increment character count
    while self.timer > TEXT_INTERVAL do
        self.timer = self.timer - TEXT_INTERVAL
        self.character_num = math.min(self.script[self.page_num]['length'], self.character_num + 1)
    end
end

-- Render a black text box at the given position
function Dialogue:renderTextBox(x, y)

    -- Render black text box
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle('fill', x + BOX_MARGIN, y + BOX_MARGIN, BOX_WIDTH, BOX_HEIGHT)
end

-- Render the speaker's name and portrait
function Dialogue:renderSpeaker(speaker, portrait, x, y)

    -- Render name of current speaker
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(speaker, x + BOX_MARGIN*2, y + BOX_MARGIN + TEXT_MARGIN_Y)

    -- Render portrait of current speaker
    local char = self.chars_in_scene[speaker]
    love.graphics.draw(char.ptexture, char.portraits[portrait], x + BOX_MARGIN, y + BOX_MARGIN*3, 0, 1, 1, 0, 0)
end

-- Render text in dialogue box up to current character position
function Dialogue:renderText(text, base_x, base_y)

    -- Determine starting location of text
    love.graphics.setColor(1, 1, 1, 1)
    local x_beginning = base_x + BOX_MARGIN*2 + PORTRAIT_SIZE
    local y_beginning = base_y + BOX_MARGIN + TEXT_MARGIN_Y + 20

    -- Iterate over lines and characters in the text, printing one-by-one
    local line_num = 1
    local char_num = 1
    for _=1, self.character_num do

        -- Position of current character
        local x = x_beginning + (TEXT_MARGIN_X + FONT_SIZE) * (char_num - 1)
        local y = y_beginning + (TEXT_MARGIN_Y + FONT_SIZE) * (line_num - 1)

        -- Print character
        love.graphics.print(text[line_num]:sub(char_num, char_num), x, y)

        -- Increment character count
        char_num = char_num + 1

        -- If character count overflows, go to next line
        if char_num > #text[line_num] then
            line_num = line_num + 1
            char_num = 1
        end
    end
end

-- Render choice box, options, and selection arrow
function Dialogue:renderChoice(choices, base_x, base_y, flip)

    -- Get the length of the longest option
    local longest = 0
    for i=1, #choices do
        if #choices[i]['text'] > longest then
            longest = #choices[i]['text']
        end
    end

    -- Compute width and height of choice box
    local w = BOX_MARGIN*2 + (TEXT_MARGIN_X + FONT_SIZE) * (longest) + 10
    local h = TEXT_MARGIN_Y + (TEXT_MARGIN_Y + FONT_SIZE) * (#choices)

    -- Compute coordinates of choice box
    local rect_x = base_x + BOX_MARGIN + BOX_WIDTH - w
    local rect_y = base_y + BOX_MARGIN*2 + BOX_HEIGHT
    if flip then
        rect_y = base_y - TEXT_MARGIN_Y - (TEXT_MARGIN_Y + FONT_SIZE) * (#choices)
    end

    -- Draw choice box
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle('fill', rect_x, rect_y, w, h)

    -- Draw each option in choice box, character by character
    love.graphics.setColor(1, 1, 1, 1)
    for i=1, #choices do
        for j=1, #choices[i]['text'] do

            -- Get single character
            local c = choices[i]['text']:sub(j,j)

            -- Get position of character
            local x = rect_x + BOX_MARGIN + (FONT_SIZE + TEXT_MARGIN_X) * (j + longest - #choices[i]['text'])
            local y = rect_y + TEXT_MARGIN_Y + (FONT_SIZE + TEXT_MARGIN_Y) * (i-1)

            -- Draw character
            love.graphics.print(c, x, y)
        end
    end

    -- Render selection arrow on the selected option
    local arrow_y = rect_y + TEXT_MARGIN_Y + (FONT_SIZE + TEXT_MARGIN_Y) * (self.selection - 1)
    love.graphics.print(">", rect_x + 15, arrow_y)
end

-- Render dialogue to screen at current position
function Dialogue:render(x, y)

    -- Current page
    local page = self.script[self.page_num]

    -- Render below the player if at the top of a map
    local flip = false
    if y == 0 then
        y = VIRTUAL_HEIGHT - (BOX_HEIGHT + BOX_MARGIN*2)
        flip = true
    end

    -- Render text box
    self:renderTextBox(x, y)

    -- Render speaker name and portrait
    self:renderSpeaker(page['speaker'], page['portrait'], x, y)

    -- Render text up to current character position
    self:renderText(page['text'], x, y)

    -- Render choice and selection arrow if there is a choice to make
    if self:atChoice() and page['length'] == self.character_num then
        local choices = self:getNext()['choices']
        self:renderChoice(choices, x, y, flip)
    end
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
    return lines
end
