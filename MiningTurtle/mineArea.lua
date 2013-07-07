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

    -- We start above the first hole, with an edge on our left
    self.x = 1
    self.y = 1
    self.orientation = "y"
    self.underground = false

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

        -- Seal our source hole so no one falls in.
        if (self:scan() and not self.underground) then
            turtle.select(StatefulTurtle.FILLER)
            turtle.placeUp()
            turtle.select(1)
            self.underground = true
            self.depth = 1
        end
        os.sleep(0)
    end
end

function StatefulTurtle:rise()
    turtle.digUp()
    if (turtle.up()) then
        self.depth = self.depth - 1

        if (not self:scan() and self.depth <= 0 and self.underground) then
            -- We're above where we started, and see a gap around us. Fill the hole so no one falls in
            turtle.select(StatefulTurtle.FILLER)
            turtle.placeDown()
            turtle.select(1)
            self.underground = false
        end
    end
    os.sleep(0)
end

function StatefulTurtle:digHoleDown()
    self:sink()
    while turtle.digDown() do
        self:sink()
    end
end

function StatefulTurtle:digHoleUp()
    while self.depth > 0 do
        self:rise()
    end
    -- keep mining until we're clear of obstructions
    while turtle.detect() do
        self:rise()
    end
end

-- Sees if there's any unusual ores around, and digs them if there is.
-- Returns true if surrounded by stuff
function StatefulTurtle:scan()
    local underground = true
    --noinspection UnusedDef
    for i = 1, 4 do
        -- ensure we have room (including for any block above us this grabs)
        if turtle.getItemCount(15) > 0 then
            me:deposit()
        end
        if not turtle.detect() then
            underground = false
        elseif detectInteresting() then
            turtle.dig()
        end
        self:turnLeft()
    end
    return underground
end

function detectInteresting()
    --empty space isn't interesting
    --    if not turtle.detect() then
    --        return false
    --    end

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

function StatefulTurtle:digHole()
    if self.underground then
        self:digHoleUp()
    else
        self:digHoleDown()
    end

    print("Done hole. Used " .. fuel - turtle.getFuelLevel() .. " fuel")
end

StatefulTurtle.offset = {}
StatefulTurtle.offset[1] = 1
StatefulTurtle.offset[2] = 3
StatefulTurtle.offset[3] = 5
StatefulTurtle.offset[4] = 2
StatefulTurtle.offset[5] = 4

function StatefulTurtle:goToNextHole()
    -- reverse direction every row
    local direction = 1
    if self.y % 2 == 0 then
        direction = -1
    end

    -- The next hole is 5 farther along in the same direction
    local nextY = self.y + direction * 5
    local nextX = self.x

    if nextY < 1 then
        -- We've reached the bounds of the loaded chunks
        -- Start the next row
        nextX = nextX + 1
        local xGroup = nextX % 5
        if xGroup == 0 then
            xGroup = 5
        end
        nextY = StatefulTurtle.offset[xGroup]
    end

    if nextY > 142 then
        -- We've reached the bounds of the loaded chunks
        -- Start the next row
        nextX = nextX + 1
        local xGroup = nextX % 5
        if xGroup == 0 then
            xGroup = 5
        end
        local startingOffset = StatefulTurtle.offset[xGroup]
        --            1, 3, 5, 2, 4
        local available = 142 - startingOffset
        -- 141, 139, 137, 140, 138
        local holeCount = math.floor(available / 5)
        -- 28, 27, 27, 28, 27
        local lastHole = holeCount * 5
        -- 140, 135, 135, 140, 135
        nextY = lastHole + startingOffset
        --            141, 138, 140, 142, 139
    end

    if (nextX > 142) then
        return false
    end

    self:goToCoord({ x = nextX, y = nextY })

    return true
end

function StatefulTurtle:digNextHole()
    if (not self.underground) then
        local fuel = turtle.getFuelLevel()
        if (fuel < 600) then
            print("Too risky. Need more Fuel")
            return false
        end
    end

    if (not me:goToNextHole()) then
        -- There's no next hole
        print("Done!")
        return false
    end
    me:digHole()
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
    --        self:digHoleUp()

    -- Turning takes time, do as little as possible
    if (self.y > destY) then
        self:face("-y")
    elseif (self.y < destY) then
        self:face("y")
    end
    --    print("moving in y")
    while (not (self.y == destY)) do
        self:digAndMoveForward()
    end
    if (self.x > destX) then
        self:face("-x")
    elseif (self.x < destX) then
        self:face("x")
    end
    --    print("moving in x")
    while (not (self.x == destX)) do
        self:digAndMoveForward()
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
local fuel = turtle.getFuelLevel()
if (fuel < 600) then
    print("Too risky. Need more Fuel")
end

me:digHole()

while (me:digNextHole()) do
end
me:goToCoord({ x = 0, y = 0 })
