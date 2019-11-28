require 'Util'

Animation = Class{}

-- Initialize a new set of frames
function Animation:init(params)

    -- Time per frame and total time elapsed
    self.interval = params.interval
    self.timer = 0

    -- Images corresponding to each frame, index into frames
    self.frames = params.frames
    self.currentFrame = 1
end

-- Return the current quad to render
function Animation:getCurrentFrame()
    return self.frames[self.currentFrame]
end

-- Start over the animation
function Animation:restart()
    self.timer = 0
    self.currentFrame = 1
end

-- Increment time and move to the appropriate frame
function Animation:update(dt)

    -- Update time passed
    self.timer = self.timer + dt

    -- Iteratively subtract interval from timer
    while self.timer > self.interval do
        self.timer = self.timer - self.interval
        self.currentFrame = (self.currentFrame + 1) % (#self.frames + 1)
        if self.currentFrame == 0 then self.currentFrame = 1 end
    end
end
