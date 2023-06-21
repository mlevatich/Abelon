require 'Util'
require 'Constants'

require 'Scripts'

Scene = class('Scene')

PAUSE_CHARS = {'. ', '! ', '? ', '.', '!', '?'}
BREATHE_CHARS = {', ', ',', '* ', '*'}
PAUSE_WEIGHT = 10
BREATHE_WEIGHT = 3

-- Initialize a new dialogue
function Scene:initialize(scene_id, player, chapter, returnToBattle)

    -- Retrieve scene by id
    self.id = scene_id
    self.script = deepcopy(scripts[scene_id])
    self.chapter = chapter
    self.returnToBattle = returnToBattle

    -- Retrieve scene participants from the map
    local getSp = function(sp) return self.chapter:getSprite(sp) end
    self.player = player
    self.participants = mapf(getSp, self.script['ids'])
    self.update_render = false
    self.flip = false

    -- Scene camera
    self.cam_lock = self.player
    self.cam_offset_x = 0
    self.cam_offset_y = 0
    self.cam_speed = 300

    -- Start scene from the first event in the script
    self.event = 1
    self.active_events = {}
    self.blocked_by = nil
    self.text_state = nil
    self.await_input = false
    self:play()
end

function Scene:play()
    while not self.await_input and not self.blocked_by
          and self.event <= #self.script['events'] do
        self.script['events'][self.event](self)
        self.event = self.event + 1
    end
end

function Scene:over()
    local script_finished = self.event > #self.script['events']
    return script_finished and not self.await_input and not self.blocked_by
end

-- End the scene
function Scene:close()

    -- Fire action that returns us to the battle
    -- or give control back to the player if there is no battle
    if self.returnToBattle then
        self.player:changeMode('battle')
        self.returnToBattle()
    else
        for i = 1, #self.participants do
            self.participants[i]:atEase()
        end
        self.player:changeMode('free')
    end

    -- Process scene results
    self:processResult(self.script['result'])
end

function Scene:release(label)
    self.active_events[label] = nil
    if self.blocked_by and self.blocked_by == label then
        self.blocked_by = nil
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
    if result['state'] then
        self.chapter.state[result['state']] = true
    end
    if result['callback'] then
        self.chapter.callbacks[self.id] = result['callback']
    end
    if result['do'] then
        result['do'](self.chapter)
    end
end

function Scene:updateGroupY()
    get_y_center = function(sp)
        local x, y = sp:getPosition()
        local w, h = sp:getDimensions()
        return y + h / 2
    end
    self.group_y = avg(mapf(get_y_center, self.participants))
end

-- Take a choice based on selection and propogate its effects
function Scene:choose()

    -- Assume the choice is on the following page
    local choice = self.text_state['selection']

    -- Effects of choice is to change impressions, awareness, callback, etc
    self:processResult(self.text_state['choice_result'][choice])

    -- Response to the choice is inserted as events into current script
    addEvents(self, self.text_state['choice_events'][choice], self.event)
end

-- Called when the player hits space while talking,
-- returns ending track if is dialogue over or nil otherwise
function Scene:advance()

    if self.text_state then

        -- Check if the current dialogue is still rendering
        if self.text_state['length'] ~= self.text_state['cnum'] then

            -- If not already at the end, jump to the end of the line
            self.text_state['cnum'] = self.text_state['length']

        elseif self.await_input then

            -- If we're waiting at choice, then make choice based on selection
            if self.text_state['choices'] then
                self:choose()
            end

            -- Clear text state
            self.text_state = nil
            self.await_input = false
        end
    end
end

-- Called when player presses up or down while talking to hover a selection
function Scene:hover(dir)
    if self.text_state and self.text_state['selection'] then

        -- self.selection determines where the selection arrow is rendered
        local n = #self.text_state['choices']
        if dir == UP then
            self.text_state['selection'] = math.max(1,
                self.text_state['selection'] - 1)
        elseif dir == DOWN then
            self.text_state['selection'] = math.min(n,
                self.text_state['selection'] + 1)
        end
    end
end

function Scene:getTwoChars()
    local line_num = 1
    local char_num = 0
    for _=1, self.text_state['cnum'] do

        -- Increment character count
        char_num = char_num + 1

        -- If character count overflows, go to next line
        if char_num > #self.text_state['text'][line_num] then
            line_num = line_num + 1
            char_num = 1
        end
    end

    char_num = math.max(char_num, 1)
    return self.text_state['text'][line_num]:sub(char_num, char_num + 1)

end

function Scene:updateWithWeight(weight)
    local text = self.text_state
    if text['cweight'] == weight then
        text['cnum'] = math.min(text['length'], text['cnum'] + 1)
        text['cweight'] = 0
    else
        text['cweight'] = text['cweight'] + 1
    end
end

-- Increment time and move to the next character
function Scene:update(dt)
    local text = self.text_state
    if text then

        -- Update time passed
        text['timer'] = text['timer'] + dt

        -- Iteratively subtract interval from timer and increment char count
        while text['timer'] > TEXT_INTERVAL do
            text['timer'] = text['timer'] - TEXT_INTERVAL

            local c = self:getTwoChars()
            if find(PAUSE_CHARS, c) then
                self:updateWithWeight(PAUSE_WEIGHT)
            elseif find(BREATHE_CHARS, c) then
                self:updateWithWeight(BREATHE_WEIGHT)
            else
                self:updateWithWeight(0)
            end
        end

        if text['length'] == text['cnum'] and
           self.blocked_by and self.blocked_by == 'text' then
            self.blocked_by = nil
        end
    end

    -- Update wait timer
    evs = self.active_events
    if evs['wait'] then
        evs['wait'] = evs['wait'] - dt
        if evs['wait'] <= 0 then
            self:release('wait')
        end
    end

    self:play()
end

-- Render a black text box at the given position
function Scene:renderTextBox(y)

    -- Render black text box
    love.graphics.setColor(0, 0, 0, RECT_ALPHA)
    love.graphics.rectangle('fill',
        BOX_MARGIN, y + BOX_MARGIN, BOX_WIDTH, BOX_HEIGHT
    )
end

-- Render the speaker's name and portrait
function Scene:renderSpeaker(sp, pid, y)
    if sp then

        -- Render name of current speaker
        love.graphics.setColor(unpack(WHITE))
        local base_y = y + BOX_MARGIN + TEXT_MARGIN_Y
        renderString(sp:getName(), BOX_MARGIN * 2, base_y)

        -- Render portrait of current speaker
        if sp:getPtexture() then
            love.graphics.draw(sp:getPtexture(), sp:getPortrait(pid),
                BOX_MARGIN * 1.5,
                y + BOX_MARGIN * 2,
                0, 1, 1, 0, 0
            )
        end
    end
end

-- Render text in dialogue box up to current character position
function Scene:renderText(text, base_y)

    -- Determine starting location of text
    love.graphics.setColor(unpack(WHITE))
    local x_beginning = BOX_MARGIN*2 + PORTRAIT_SIZE
    local y_beginning = base_y + BOX_MARGIN + TEXT_MARGIN_Y + 20

    -- Iterate over lines and characters in the text, printing one-by-one
    local line_num = 1
    local char_num = 1
    for _ = 1, self.text_state['cnum'] do

        -- Position of current character
        local x = x_beginning + CHAR_WIDTH * (char_num - 1)
        local y = y_beginning + LINE_HEIGHT * (line_num - 1)

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
function Scene:renderChoice(choices, base_y, flip)

    -- Get the length of the longest option
    local longest = max(mapf(string.len, choices))

    -- Compute width and height of choice box
    local w = BOX_MARGIN * 2 + CHAR_WIDTH * (longest) + HALF_MARGIN
    local h = HALF_MARGIN + LINE_HEIGHT * (#choices)

    -- Compute coordinates of choice box
    local rect_x = BOX_MARGIN + BOX_WIDTH - w
    local rect_y = base_y + BOX_MARGIN + BOX_HEIGHT + TEXT_MARGIN_Y
    if flip then
        rect_y = base_y
               - LINE_HEIGHT * (#choices)
               + TEXT_MARGIN_Y
    end

    -- Draw choice box
    love.graphics.setColor(0, 0, 0, RECT_ALPHA)
    love.graphics.rectangle('fill', rect_x, rect_y, w, h)

    -- Draw each option in choice box, character by character
    love.graphics.setColor(unpack(WHITE))
    for i=1, #choices do
        local x = rect_x + BOX_MARGIN + CHAR_WIDTH * (1 + longest - #choices[i])
        local y = rect_y + TEXT_MARGIN_Y + 2 + LINE_HEIGHT * (i-1)
        renderString(choices[i], x, y)
    end

    -- Render selection arrow on the selected option
    local arrow_y = rect_y + TEXT_MARGIN_Y + 2 + LINE_HEIGHT
                  * (self.text_state['selection'] - 1)
    love.graphics.print(">", rect_x + 15, arrow_y)
end

-- Render small indicator that current page is done
function Scene:renderAdvanceIndicator(y)
    local indicator_x = BOX_MARGIN + BOX_WIDTH - 7
    local indicator_y = y + BOX_MARGIN + BOX_HEIGHT - 7
    love.graphics.setColor(unpack(WHITE))
    love.graphics.print("^", indicator_x, indicator_y, math.pi)
end

-- Render dialogue to screen at current position
function Scene:render()

    -- Update where text is rendered when asked
    if self.update_render then
        self:updateGroupY()
        self.flip = VIRTUAL_HEIGHT / 3 > self.group_y
        self.update_render = false
    end

    -- If there's text, render it
    if self.text_state then

        -- Flip if need to
        local y = 0
        if self.flip then
            y = VIRTUAL_HEIGHT - (BOX_HEIGHT + BOX_MARGIN * 3.5)
        end

        -- Render text box
        self:renderTextBox(y)

        -- Render speaker name and portrait
        self:renderSpeaker(self.text_state['speaker'], self.text_state['portrait'], y)

        -- Render text up to current character position
        self:renderText(self.text_state['text'], y)

        -- Render choice and selection arrow if there is a choice to make, or
        -- render indicator that text is finished if there's no choice
        if self.text_state['cnum'] == self.text_state['length'] then
            if self.text_state['choices'] then
                self:renderChoice(self.text_state['choices'], y, self.flip)
            end
            self:renderAdvanceIndicator(y)
        end
    end
end
