local StatefulTurtle = {}
StatefulTurtle.__index = StatefulTurtle
setmetatable(StatefulTurtle, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function StatefulTurtle.new(initialDepth)
    local self = setmetatable({}, StatefulTurtle)
    self.depth = initialDepth
    return self
end

function StatefulTurtle:sink()
    while turtle.down() do
        self.depth = self.depth + 1
        print("sunk to " .. self.depth)
        -- Seal our source hole so no one falls in
        if (self.depth == 2) then
            turtle.select(6)
            turtle.placeUp()
            turtle.select(1)
        end

        scan()
    end
end

function StatefulTurtle:rise()
    turtle.digUp()
    if (turtle.up()) then
        self.depth = self.depth - 1
        print("rose to " .. self.depth)
        scan()
    end
end

function StatefulTurtle:findHighGround()
    while turtle.detect() do
        self:rise()
    end
end

function StatefulTurtle:digHoleDown()
    self:sink()
    -- TODO: Block entrance with cobblestone (slot 6)
    while turtle.digDown() do
        print("dug down")
        self:sink()
    end
end

function StatefulTurtle:digHoleUp()
    while self.depth > 0 do
        self:rise()
        if (turtle.digUp()) then
            print("dug up")
        end
    end
end

-- Sees if there's any unusual ores around, and digs them if there is.
function scan()
    print("scanning")
    for i = 1, 4 do
        if detectInteresting() then
            print("Found something interesting")
            turtle.dig()
        end
        turtle.turnLeft()
    end
end

function detectInteresting()
    --empty space isn't interesting
    if not turtle.detect() then
        return false
    end

    --The first 6 slots are filled with uninteresting things
    for j = 1, 6 do
        turtle.select(j)
        if turtle.compare() then
            --Select slot 1 so things are auto-stacked
            turtle.select(1)
            return false
        end
    end

    --Select slot 1 so things are auto-stacked
    turtle.select(1)

    return true
end

function StatefulTurtle:digAndMoveForward()
    while (turtle.detect() and not turtle.dig()) do
        print("Can't move forward")
        -- There's something in front of us but we can't dig it out (bedrock)
        -- Move up and try again
        self:rise()
    end
    --wait for gravel to fall after digging
    os.sleep(0.5)
    while (turtle.detect()) do
        turtle.dig()
        os.sleep(0.5)
    end
    turtle.forward()
end

function StatefulTurtle:digAndAdvance()
    local fuel = turtle.getFuelLevel()
    if (fuel < 600) then
        print("Too risky. Need more Fuel")
        return false
    end

    self:digHoleDown()
    -- Move to the next hole
    self:digAndMoveForward()
    turtle.turnRight()
    self:digAndMoveForward()
    self:digAndMoveForward()
    turtle.turnLeft()
    -- Ensure there's nothing we can get access to farther down
    self:digHoleDown()
    --Then dig up
    self:digHoleUp()

    self:findHighGround()
    -- Fill our hole
    turtle.select(6)
    turtle.placeDown()
    turtle.select(1)
    -- Go forward one and right 2, so we're doing an efficient scan pattern
    turtle.forward()
    turtle.turnRight()
    self:findHighGround()
    turtle.forward()
    self:findHighGround()
    turtle.forward()
    -- Rest on the ground
    self:sink()
    -- Consider this our new base
    self.depth = 0
    turtle.turnLeft()
    print("Done hole. Used " .. fuel - turtle.getFuelLevel() .. " fuel")
    return true
end

me = StatefulTurtle(0)
print("Dig a hole?")
while (io.read() == "y") do
    me:digAndAdvance()
    print("Dig another hole?")
end
