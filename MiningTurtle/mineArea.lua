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
    self.hole = {}
    self.hole[1] = { x = 0, y = 0, orientation = "x" }
    self.hole[2] = { x = 2, y = 4, orientation = "y" }
    self.hole[3] = { x = 1, y = 7, orientation = "-y" }
    self.hole[4] = { x = 4, y = 8, orientation = "y" }
    self.hole[5] = { x = 7, y = 9, orientation = "-y" }
    self.hole[6] = { x = 8, y = 6, orientation = "y" }
    self.hole[7] = { x = 5, y = 5, orientation = "-y" }
    self.hole[8] = { x = 6, y = 2, orientation = "y" }
    self.hole[9] = { x = 3, y = 1, orientation = "-y" }
    self.hole[10] = { x = 8, y = 1, orientation = "x" }
    self.nextHole = 1
    self.groupStart = {}
    self.groupStart[1] = 0
    self.groupStart[2] = 2
    self.groupStart[3] = 5
    self.groupStart[4] = 10
    self.groupStart[5] = 17
    self.groupStart[6] = 26
    self.groupStart[7] = 37
    self.groupStart[8] = 50
    self.groupNum = 1

    -- We start above the chest facing -y (a wall the chest is against that we can be placed next to)
    self.x = -1
    self.y = -1
    self.chest = { x = -1, y = -1 }
    self.orientation = "-y"

    return self
end

--TODO: Support groups
--TODO: Read group from stone count

function StatefulTurtle:turnRight()
    if (self.orientation == "y") then
        self.orientation = "-x"
    elseif (self.orientation == "-x") then
        self.orientation = "-y"
    elseif (self.orientation == "-y") then
        self.orientation = "x"
    elseif (self.orientation == "x") then
        self.orientation = "y"
    end
    turtle.turnRight()
    print("Now facing " .. self.orientation)
end

function StatefulTurtle:turnLeft()
    if (self.orientation == "y") then
        self.orientation = "x"
    elseif (self.orientation == "x") then
        self.orientation = "-y"
    elseif (self.orientation == "-y") then
        self.orientation = "-x"
    elseif (self.orientation == "-x") then
        self.orientation = "y"
    end
    turtle.turnLeft()
    print("Now facing " .. self.orientation)
end

function StatefulTurtle:sink()
    while turtle.down() do
        self.depth = self.depth + 1
        print("sunk to " .. self.depth)
        -- Seal our source hole so no one falls in. This considers the chest to be resting on ground level
        if (self.depth == 3) then
            turtle.select(6)
            turtle.placeUp()
            turtle.select(1)
        end
        os.sleep(0)
        self:scan()
    end
end

function StatefulTurtle:rise()
    turtle.digUp()
    if (turtle.up()) then
        self.depth = self.depth - 1
        print("rose to " .. self.depth)
        self:scan()
    end
    os.sleep(0)
end

--function StatefulTurtle:findHighGround()
--    while turtle.detect() do
--        self:rise()
--    end
--end

function StatefulTurtle:digHoleDown()
    self:sink()
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
function StatefulTurtle:scan()
    print("scanning")
    --noinspection UnusedDef
    for i = 1, 4 do
        if detectInteresting() then
            print("Found something interesting")
            turtle.dig()
        end
        self:turnLeft()
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
    digThroughFallingBlocks()
    self:goForward()
end

function digThroughFallingBlocks()
    while (turtle.detect()) do
        turtle.dig()
        os.sleep(0.5)
    end
end

function StatefulTurtle:goForward()
    if (self.orientation == "y") then
        self.y = self.y + 1
    elseif (self.orientation == "-y") then
        self.y = self.y - 1
    elseif (self.orientation == "x") then
        self.x = self.x + 1
    elseif (self.orientation == "-x") then
        self.x = self.x - 1
    end
    digThroughFallingBlocks()
    while (not turtle.forward()) do
        turtle.dig()
    end
    os.sleep(0)
    print("Now at " .. self.x .. ", " .. self.y)
end

function StatefulTurtle:digPairOfHoles()
    local fuel = turtle.getFuelLevel()
    if (fuel < 600) then
        print("Too risky. Need more Fuel")
        return false
    end

    self:digHoleDown()
    -- Move to the next hole
    self:digAndMoveForward()
    self:turnRight()
    self:digAndMoveForward()
    self:digAndMoveForward()
    self:turnLeft()
    -- Ensure there's nothing we can get access to farther down
    self:digHoleDown()
    --Then dig up
    self:digHoleUp()

    --    self:findHighGround()
    -- Fill our hole
    turtle.select(6)
    turtle.placeDown()
    turtle.select(1)
    print("Done holes. Used " .. fuel - turtle.getFuelLevel() .. " fuel")
    return true
end

function StatefulTurtle:goToNextHole()
    if (self.nextHole == 11) then
        return false
    end
    local hole = self.hole[self.nextHole];
    self:goToCoord({ x = hole.x, y = hole.y })
    self:face(hole.orientation)
    self.nextHole = self.nextHole + 1
    return true
end

function StatefulTurtle:digNextHoles()
    if (not me:goToNextHole()) then
        -- There's no next hole
        return false
    end
    if (not me:digPairOfHoles()) then
        -- Not enough fuel
        return false
    end
    return true
end

function StatefulTurtle:goToChest()
    self:goToCoord({ x = self.chest.x, y = self.chest.y })
end

function StatefulTurtle:face(destOrientation)
    if (destOrientation == "-y" and self.orientation == "y") or (destOrientation == "-x" and self.orientation == "x") or
            (destOrientation == "y" and self.orientation == "-y") or (destOrientation == "x" and self.orientation == "-x") then
        self:turnRight()
        self:turnRight()
        return
    end
    if (destOrientation == "-x" and self.orientation == "y") or (destOrientation == "y" and self.orientation == "x") or
            (destOrientation == "x" and self.orientation == "-y") or (destOrientation == "-y" and self.orientation == "-x") then
        self:turnRight()
    end
    if (destOrientation == "x" and self.orientation == "y") or (destOrientation == "-y" and self.orientation == "x") or
            (destOrientation == "-x" and self.orientation == "-y") or (destOrientation == "y" and self.orientation == "-x") then
        self:turnLeft()
    end
end

function StatefulTurtle:goToCoord(coord)
    local destX = coord.x
    local destY = coord.y

    print("Going to " .. destX .. ", " .. destY)

    -- get to depth 0
    self:digHoleUp()

    -- Turning takes time, do as little as possible
    if (self.y > destY) then
        self:face("-y")
    elseif (self.y < destY) then
        self:face("y")
    end
    print("moving in y")
    while (not (self.y == destY)) do
        self:goForward()
    end
    if (self.x > destX) then
        self:face("-x")
    elseif (self.x < destX) then
        self:face("x")
    end
    print("moving in x")
    while (not (self.x == destX)) do
        self:goForward()
    end
end

function StatefulTurtle:deposit()
    for i = 1, 5 do
        -- drop all but one of these
        if turtle.getItemCount(i) > 1 then
            turtle.select(i)
            while (not turtle.dropDown(turtle.getItemCount(i) - 1)) do
                -- wait for the player to clear the chest
                os.sleep(1)
            end
        end
    end
    -- drop all but two of these
    if turtle.getItemCount(6) > 2 then
        turtle.select(6)
        while (not turtle.dropDown(turtle.getItemCount(6) - 2)) do
            -- wait for the player to clear the chest
            os.sleep(1)
        end
    end
    for i = 7, 16 do
        -- drop all of these
        if turtle.getItemCount(i) > 0 then
            turtle.select(i)
            while (not turtle.dropDown(turtle.getItemCount(i))) do
                -- wait for the player to clear the chest
                os.sleep(1)
            end
        end
    end
    turtle.select(1)
end

me = StatefulTurtle(0)
while (me:digNextHoles()) do
    me:goToChest()
    me:deposit()
end
me:goToChest()
