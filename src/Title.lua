require 'src.Util'
require 'src.Constants'

require 'src.Game'
require 'src.Chapter'

Title = class('Title')

local T_BYLINE = 4.5
local TITLE_FONT_SIZE = 40
local SUBFONT_SIZE = 18

local SELECT_GAME = 0
local SELECT_DIFF = 1
local SELECT_CONFIRM = 2

-- Initialize title sequence
function Title:initialize(font_file)

    -- Time passed since initialized
    self.t = 0

    -- Fonts
    self.titlefont = love.graphics.newFont(font_file, TITLE_FONT_SIZE)
    self.subfont = love.graphics.newFont(font_file, SUBFONT_SIZE)

    -- Menu state
    self.state = SELECT_GAME
    self.cursor = 0
    self.difficulty = nil

    -- Detect existing saved game
    self.save = nil
    if love.filesystem.getInfo(SAVE_DIRECTORY .. QUICK_SAVE) then
        self.save = Game:new(nil)
        self.save:loadSave(QUICK_SAVE, true)
    elseif love.filesystem.getInfo(SAVE_DIRECTORY .. AUTO_SAVE) then
        self.save = Game:new(nil)
        self.save:loadSave(AUTO_SAVE)
    end
end

function Title:update(dt)

    -- Are we launching the game after this update?
    local launch = nil

    -- Update time
    self.t = self.t + dt

    -- Ignore keyboard inputs until the byline is finished
    if self.t > T_BYLINE + 1 then

        -- How many cursor options?
        local n = 2
        if self.state == SELECT_GAME and not self.save then
            n = 1
        elseif self.state == SELECT_DIFF then
            n = 3
        end

        -- Get keyboard inputs
        local f    = love.keyboard.wasPressed('f')
        local d    = love.keyboard.wasPressed('d')
        local up   = love.keyboard.wasPressed('up')
        local down = love.keyboard.wasPressed('down')

        -- Process inputs
        if f then
            
            -- Process 'select'
            if self.state == SELECT_GAME then
                if self.save and self.cursor == 0 then
                    launch = self.save
                else
                    self.state = SELECT_DIFF
                end
            elseif self.state == SELECT_DIFF then
                self.difficulty = self.cursor + 1
                if not self.save then
                    launch = Game:new(Chapter:new('1-1', self.difficulty))
                else
                    self.state = SELECT_CONFIRM
                end
            else
                if self.cursor == 0 then
                    self.state = SELECT_DIFF
                else
                    launch = Game:new(Chapter:new('1-1', self.difficulty))
                end
            end
            if not launch then
                self.cursor = 0
            end

        elseif d then

            -- Process 'go back'
            self.cursor = 0
            if self.state == SELECT_CONFIRM then
                self.state = SELECT_DIFF
            else
                self.state = SELECT_GAME
            end

        -- Process cursor hover
        elseif down and not up then
            self.cursor = (self.cursor + 1) % n
        elseif up and not down then
            self.cursor = (self.cursor + n - 1) % n
        end
    end
    return launch
end

function Title:render()

    -- Render either byline or title menu, depending on time passed
    if self.t < T_BYLINE then

        -- Render byline
        local s = "A game by Max Levatich"
        local x = (VIRTUAL_WIDTH / ZOOM) / 2 - (#s / 2 * CHAR_WIDTH)
        local y = (VIRTUAL_HEIGHT / ZOOM) / 2 - FONT_SIZE / 2
        local alpha = 1
        if self.t < T_BYLINE / 3 then
            alpha = 1 - (T_BYLINE / 3 - self.t) / (T_BYLINE / 3)
        elseif self.t > T_BYLINE * 2 / 3 then
            alpha = 1 - (self.t - T_BYLINE * 2 / 3) / (T_BYLINE / 3)
        end
        love.graphics.push('all')
        love.graphics.setColor(1, 1, 1, alpha)
        renderString(s, x, y, true)
        love.graphics.pop()
    else

        -- Render title background
        -- TODO

        -- Render game title
        local s = "ABELON"
        local w = TITLE_FONT_SIZE + TEXT_MARGIN_X
        local x = (VIRTUAL_WIDTH / ZOOM) / 2 - (#s / 2 * w) + 9
        love.graphics.push('all')
        love.graphics.setColor(unpack(WHITE))
        love.graphics.setFont(self.titlefont)
        for i = 1, #s do
            printChar(s:sub(i, i), x + w * (i - 1), (VIRTUAL_HEIGHT / ZOOM) / 5)
        end
        love.graphics.pop()

        -- Render controls
        local s1 = "Use the arrow keys to navigate"
        local s2 = "Press F to confirm"
        local s3 = "Press D to go back"
        love.graphics.push('all')
        love.graphics.scale(1 / ZOOM)
        love.graphics.setFont(self.subfont)
        renderString(s1, HALF_MARGIN, HALF_MARGIN)
        renderString(s2, HALF_MARGIN, HALF_MARGIN + LINE_HEIGHT)
        renderString(s3, HALF_MARGIN, HALF_MARGIN + LINE_HEIGHT * 2)

        -- Render menu options
        local vh = VIRTUAL_HEIGHT / 2
        local vw = VIRTUAL_WIDTH / 2
        local xCenter = function(s)
            return vw - CHAR_WIDTH * #s / 2 + 3
        end
        if self.state == SELECT_GAME then
            local s1, s2 = 'Continue', 'New game'
            if self.save then
                renderString('Continue', xCenter(s1), vh + 50)
                renderString('New game', xCenter(s2), vh + 90)
            else
                renderString('New game', xCenter(s2), vh + 70)
            end
        elseif self.state == SELECT_DIFF then
            local s1 = 'Select a difficulty level'
            local s2, s3, s4 = 'Normal', 'Adept ', 'Master'
            renderString(s1, xCenter(s1), vh - 30)
            renderString(s2, xCenter(s2), vh + 30)
            renderString(s3, xCenter(s3), vh + 70)
            renderString(s4, xCenter(s4), vh + 110)
        else
            local s1 = 'Are you sure? This will OVERWRITE your existing saved game!'
            local s2, s3 = 'No ', 'Yes'
            renderString(s1, xCenter(s1), vh - 30)
            renderString(s2, xCenter(s2), vh + 50)
            renderString(s3, xCenter(s3), vh + 90)
        end
        
        -- Render cursor
        if self.t > T_BYLINE + 1 then
            if self.state == SELECT_GAME then
                if self.save then
                    renderString('>', xCenter('Continue') - 20, vh + 50 + self.cursor * 40)
                else
                    renderString('>', xCenter('Continue') - 20, vh + 70)
                end
            elseif self.state == SELECT_DIFF then
                renderString('>', xCenter('Normal') - 20, vh + 30 + self.cursor * 40)
            else
                renderString('>', xCenter('Yes') - 20, vh + 50 + self.cursor * 40)
            end
        end
        love.graphics.pop()

        -- Render fade in
        local bb_alpha = math.max(0, 1 - (self.t - T_BYLINE))
        love.graphics.push('all')
        love.graphics.setColor(0, 0, 0, bb_alpha)
        love.graphics.rectangle('fill', 0, 0, VIRTUAL_WIDTH / ZOOM, VIRTUAL_HEIGHT / ZOOM)
        love.graphics.pop()
    end
end