require 'Util'
require 'Constants'
require 'Scripts'

Scene = Class{}

-- Initialize a new dialogue
function Scene:init(scene_id, map, player)

    -- Retrieve scene by id
    self.id = scene_id
    self.script = deepcopy(scripts[scene_id])

    -- Retrieve scene participants from the map
    self.player = player
    self.participants = {}
    sps = map:getSprites()
    for i=1, #self.script['ids'] do
        sp_id = find(mapf(function(s) return s.id end, sps), self.script['ids'][i])
        table.insert(self.participants, sps[sp_id])
    end

    -- Start scene from the first event in the script
    self.event = 1
    self:play()
end

function Scene:play()
    self.state = nil
    self.wait = false
    while not self.wait do
        if self.event > #self.script['events'] then
            return true
        end
        self.script['events'][self.event](self)
        self.event = self.event + 1
    end
    return false
end

-- End the scene
function Scene:close()

    -- Return participants to resting behavior
    for i = 1, #self.participants do
        self.participants[i]:atEase()
    end
end

function Scene:processResult(result)
    if result['impressions'] then
        for i = 1, #result['impressions'] do
            self.participants[i]:changeImpression(result['impressions'][i])
        end
    end
    if result['awareness'] then
        for i = 1, #result['awareness'] do
            self.participants[i]:changeAwareness(result['awareness'][i])
        end
    end
    if result['callback'] then
        local new_script = {
            ['ids'] = self.script['ids'],
            ['trigger'] = nil,
            ['events'] = result['callback'],
            ['result'] = {}
        }
        scripts[self.id] = new_script
    end
end

-- Take a choice based on selection and propogate its effects
function Scene:choose()

    -- Assume the choice is on the following page
    local choice = self.state['selection']

    -- Effects of choice is to change impressions, awareness, callback, etc
    self:processResult(self.state['choice_result'][choice])

    -- Response to the choice is inserted as events into current script
    events = self.state['choice_events'][choice]
    for i = 1, #events do
        table.insert(self.script['events'], self.event, events[#events + 1 - i])
    end
end

-- Called when the player hits space while talking,
-- returns ending track if is dialogue over or nil otherwise
function Scene:advance()
    if self.state then

        -- Check if the current dialogue is still rendering
        if self.state['length'] ~= self.state['cnum'] then

            -- If not already at the end, jump to the end of the line
            self.state['cnum'] = self.state['length']

        else

            -- If we're waiting at choice, then make choice based on selection
            if self.state['choices'] then
                self:choose()
            end

            -- Continue playing events
            if self:play() then
                self:processResult(self.script['result'])
                return true
            end
        end
    end

    -- Return false if scene is not over
    return false
end

-- Called when player presses up or down while talking to hover a selection
function Scene:hover(dir)
    if self.state and self.state['selection'] then

        -- self.selection determines where the selection arrow is rendered
        if dir == UP then
            self.state['selection'] = math.max(1, self.state['selection'] - 1)
        elseif dir == DOWN then
            self.state['selection'] = math.min(2, self.state['selection'] + 1)
        end
    end
end

-- Increment time and move to the next character
function Scene:update(dt)
    if self.state then

        -- Update time passed
        self.state['timer'] = self.state['timer'] + dt

        -- Iteratively subtract interval from timer and increment char count
        while self.state['timer'] > TEXT_INTERVAL do
            self.state['timer'] = self.state['timer'] - TEXT_INTERVAL
            self.state['cnum'] = math.min(self.state['length'],
                                          self.state['cnum'] + 1)
        end
    end
end

-- Render a black text box at the given position
function Scene:renderTextBox(x, y)

    -- Render black text box
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle('fill', x + BOX_MARGIN, y + BOX_MARGIN, BOX_WIDTH, BOX_HEIGHT)
end

-- Render the speaker's name and portrait
function Scene:renderSpeaker(sp, pid, x, y)

    -- Render name of current speaker
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(sp:getName(), x + BOX_MARGIN*2, y + BOX_MARGIN + TEXT_MARGIN_Y)

    -- Render portrait of current speaker
    if sp.ptexture then
        love.graphics.draw(sp.ptexture, sp.portraits[pid], x + BOX_MARGIN, y + BOX_MARGIN*3, 0, 1, 1, 0, 0)
    end
end

-- Render text in dialogue box up to current character position
function Scene:renderText(text, base_x, base_y)

    -- Determine starting location of text
    love.graphics.setColor(1, 1, 1, 1)
    local x_beginning = base_x + BOX_MARGIN*2 + PORTRAIT_SIZE
    local y_beginning = base_y + BOX_MARGIN + TEXT_MARGIN_Y + 20

    -- Iterate over lines and characters in the text, printing one-by-one
    local line_num = 1
    local char_num = 1
    for _=1, self.state['cnum'] do

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
function Scene:renderChoice(choices, base_x, base_y, flip)

    -- Get the length of the longest option
    local longest = 0
    for i=1, #choices do
        if #choices[i] > longest then
            longest = #choices[i]
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
        for j=1, #choices[i] do

            -- Get single character
            local c = choices[i]:sub(j,j)

            -- Get position of character
            local x = rect_x + BOX_MARGIN + (FONT_SIZE + TEXT_MARGIN_X) * (j + longest - #choices[i])
            local y = rect_y + TEXT_MARGIN_Y + (FONT_SIZE + TEXT_MARGIN_Y) * (i-1)

            -- Draw character
            love.graphics.print(c, x, y)
        end
    end

    -- Render selection arrow on the selected option
    local arrow_y = rect_y + TEXT_MARGIN_Y + (FONT_SIZE + TEXT_MARGIN_Y) * (self.state['selection'] - 1)
    love.graphics.print(">", rect_x + 15, arrow_y)
end

-- Render dialogue to screen at current position
function Scene:render(x, y)
    if self.state then

        -- Render below the player if at the top of a map
        local flip = false
        if y == 0 then
            y = VIRTUAL_HEIGHT - (BOX_HEIGHT + BOX_MARGIN*2)
            flip = true
        end

        -- Render text box
        self:renderTextBox(x, y)

        -- Render speaker name and portrait
        self:renderSpeaker(self.state['speaker'], self.state['portrait'], x, y)

        -- Render text up to current character position
        self:renderText(self.state['text'], x, y)

        -- Render choice and selection arrow if there is a choice to make
        if self.state['choices'] and self.state['length'] == self.state['cnum'] then
            self:renderChoice(self.state['choices'], x, y, flip)
        end
    end
end
