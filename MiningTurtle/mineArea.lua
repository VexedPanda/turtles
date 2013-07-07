local StatefulTurtle = {}
StatefulTurtle.__index = StatefulTurtle
setmetatable(StatefulTurtle, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

StatefulTurtle.JUNK_START = 1
StatefulTurtle.JUNK_END = 4
StatefulTurtle.FILLER = 4
StatefulTurtle.CHEST = 5
StatefulTurtle.DESIRED_FUEL_LEVEL = 5000

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

    -- We start above the chest facing y
    self.x = -1
    self.y = -1
    self.chest = { x = -1, y = -1 }
    self.orientation = "y"

    return self
end

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
    --    print("Now facing " .. self.orientation)
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
    --    print("Now facing " .. self.orientation)
end

function StatefulTurtle:sink()
    while turtle.down() do
        self.depth = self.depth + 1
        --        print("sunk to " .. self.depth)
        -- Seal our source hole so no one falls in. This considers the chest to be resting on ground level
        if (self.depth == 3) then
            turtle.select(StatefulTurtle.FILLER)
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
        --        print("rose to " .. self.depth)
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
        --        print("dug down")
        self:sink()
    end
end

function StatefulTurtle:digHoleUp()
    while self.depth > 0 do
        self:rise()
        if (turtle.digUp()) then
            --            print("dug up")
        end
    end
end

-- Sees if there's any unusual ores around, and digs them if there is.
function StatefulTurtle:scan()
    --    print("scanning")
    --noinspection UnusedDef
    for i = 1, 4 do
        if detectInteresting() then
            --            print("Found something interesting")
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

    --The first 4 slots are filled with uninteresting things
    for j = StatefulTurtle.JUNK_START, StatefulTurtle.JUNK_END do
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
        --        print("Can't move forward")
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
    --    print("Now at " .. self.x .. ", " .. self.y)
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
    turtle.select(StatefulTurtle.FILLER)
    turtle.placeDown()
    turtle.select(1)
    print("Done pair of holes. Used " .. fuel - turtle.getFuelLevel() .. " fuel")
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
        print("Done!")
        return false
    end
    if (not me:digPairOfHoles()) then
        -- Not enough fuel
        print("Out of Fuel!")
        return false
    end
    return true
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

    --    print("Going to " .. destX .. ", " .. destY)

    -- get to depth 0
    self:digHoleUp()

    -- Turning takes time, do as little as possible
    if (self.y > destY) then
        self:face("-y")
    elseif (self.y < destY) then
        self:face("y")
    end
    --    print("moving in y")
    while (not (self.y == destY)) do
        self:goForward()
    end
    if (self.x > destX) then
        self:face("-x")
    elseif (self.x < destX) then
        self:face("x")
    end
    --    print("moving in x")
    while (not (self.x == destX)) do
        self:goForward()
    end
end

function StatefulTurtle:deposit()
    --Place the chest above us
    while turtle.detectUp() do
        turtle.digUp()
    end
    turtle.select(StatefulTurtle.CHEST)
    turtle.placeUp()

    local need
    for i = StatefulTurtle.JUNK_START, StatefulTurtle.JUNK_END do
        if (i == StatefulTurtle.FILLER) then
            need = 2
        else
            need = 1
        end

        -- Only keep as many as we need
        if turtle.getItemCount(i) > need then
            turtle.select(i)
            while (not turtle.dropUp(turtle.getItemCount(i) - need)) do
                -- wait for the player to clear the chest
                os.sleep(1)
            end
        end
    end

    for i = StatefulTurtle.CHEST + 1, 16 do
        -- drop all of these
        if turtle.getItemCount(i) > 0 then
            turtle.select(i)
            --refuel with this if necessary
            local fuelLevel = turtle.getFuelLevel()
            local fuelNeeded = StatefulTurtle.DESIRED_FUEL_LEVEL - fuelLevel
            if fuelNeeded > 0 and turtle.refuel(0) then
                -- This slot contains fuel we need
                turtle.refuel(1)
                local newFuelLevel = turtle.getFuelLevel()
                local fuelValue = newFuelLevel - fuelLevel
                -- Use only as much of it as we need to top up
                turtle.refuel(math.ceil(fuelNeeded / fuelValue))
            end

            while (not turtle.dropUp(turtle.getItemCount(i))) do
                -- wait for the player to clear the chest
                os.sleep(1)
            end
        end
    end

    -- Recover the chest
    turtle.select(StatefulTurtle.CHEST)
    turtle.digUp()

    turtle.select(1)
end

me = StatefulTurtle(0)
while (me:digNextHoles()) do
    me:deposit()
end
me:goToCoord({ x = 0, y = 0 })
