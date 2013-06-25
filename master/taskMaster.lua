--This is the program that issues commands to available turtles.
os.loadAPI("/apis/include")

--noinspection UnassignedVariableAccess
include.clean()
--noinspection UnassignedVariableAccess
include.path("/swarm/master/")
--noinspection UnassignedVariableAccess
include.file("Swarm.lua")
--noinspection UnassignedVariableAccess
include.file("ThreadPool.lua")
--noinspection UnassignedVariableAccess
include.file("Hook.lua")

local tasks = {}
tasks["test"] = function(slaveId)
    local subfunction = function()
        print("Ran Subfunction")
    end
    print("New task! Task Worker ID: " .. slaveId)
    --noinspection UnassignedVariableAccess
    sleep(slaveId)
    turtle.up()
    --noinspection UnassignedVariableAccess
    sleep(1.5)
    turtle.down()
    subfunction()
    print("Task finished!")
end
tasks["reportLocation"] = function()
    while true do
        --Report position back to me every 10 seconds
        os.sleep(10)
        --noinspection UnassignedVariableAccess
        NetManager.send(Swarm.masterID, {
            type = "LOCATION",
            pos = Navigation.pos(),
            dir = Navigation.dir()
        })
    end
end
--noinspection UnusedDef
tasks["digHoles"] = function(slaveId)
    local detectInteresting = function()
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
    local scan = function()
    --noinspection UnusedDef
        for i = 1, 4 do
            if detectInteresting() then
                print("Found something interesting")
                turtle.dig()
            end
            turtle.turnLeft()
        end
    end
    local digHoleDown = function()
    -- dig until we hit something we can't dig through
        while turtle.mineDown() do
            -- Seal our source hole so no one falls in. This considers the chest to be resting on ground level
            if (Navigation.pos().z == -3) then
                turtle.select(6)
                turtle.placeUp()
                turtle.select(1)
            end
            scan()
        end
    end
    local digHoleUp = function()
    -- Navigation Defined on slave
        while Navigation.pos().z < 0 do
            turtle.mineUp()
            scan()
        end
    end
    local digTwoHoles = function()
        local fuel = turtle.getFuelLevel()
        if (fuel < 600) then
            print("Too risky. Need more Fuel")
            return false
        end

        digHoleDown()
        -- Move to the next hole
        turtle.mineForward(true)
        turtle.turnRight()
        turtle.mineForward(true)
        turtle.mineForward(true)
        turtle.turnLeft()
        -- Ensure there's nothing we can get access to farther down
        digHoleDown()
        --Then dig up
        digHoleUp()

        -- Fill our hole
        turtle.select(6)
        turtle.placeDown()
        turtle.select(1)
        print("Done holes. Used " .. fuel - turtle.getFuelLevel() .. " fuel")
        return true
    end
    digTwoHoles()
end

local turtlePositions = {}
local turtleCount = 0


function getY(turtleId)
    turtleId = tonumber(turtleId)
    if not turtlePositions[turtleId] then
        turtleCount = turtleCount + 1
        turtlePositions[turtleId] = turtleCount
    end
    return turtlePositions[turtleId]
end

function printAt(x, y, string)
    local oldx, oldy = term.getCursorPos()
    term.setCursorPos(x, y)
    term.write(string)
    term.setCursorPos(oldx, oldy)
end


function printLocation(turtleId, pos, dir)
    printAt(36, getY(turtleId), pos.x .. "," .. pos.y .. "," .. pos.z .. " " .. dir)
end

function printStatus(turtleId, status)
    printAt(48, getY(turtleId), status)
end

function printId(turtleId)
    printAt(30, getY(turtleId), turtleId)
end


Hook.add("TurtleJoin", function(event)
    printId(event.turtle.id)
    printStatus(event.turtle.id, "free")

    event.turtle:runbg(tasks["reportLocation"])
end)

Hook.add("TurtleLeave", function(event)
    printStatus(event.turtle.id, "left")
--    turtlePositions[tonumber(event.turtle.id)] = nil
end)

Hook.add("TurtleFree", function(event)
    printStatus(event.turtle.id, "free")
end)

Hook.add("NetMessage", function(event)
    if (event.message.type == "TASK") then
        print(event.message.task)
        Swarm.submitTaskToAllFree(tasks[event.message.task], event.message.params)
        return
    end
    if event.message.type == "QUEUE_TASK" then
        Swarm.queueTask(event.message.turtleId, tasks[event.message.task], event.message.params)
        printStatus(event.message.turtleId, "busy")
        return
    end
    if (event.message.type == "LOCATION") then
        printLocation(event.turtleId, event.message.pos, event.message.dir)
        return
    end
end)

local console = function()
    while true do
        term.setCursorPos(1, 2)
        print("                                 ")
        print("                                 ")
        print("                                 ")
        term.setCursorPos(1, 1)
        print("What turtle?")
        local turtleId = tonumber(io.read())
        if not turtlePositions[turtleId] then
            print("Unkwown Turtle")
        else
            --TODO: Switch to what job (automated task assigners)
            print("What task?")
            local task = io.read()
            printStatus(turtleId, "busy")
            -- TODO: Support parameters
            Swarm.queueTask(turtleId, tasks[task], {})
        end
    end
end

local jobManager = function()
    while true do
    end
end

Swarm.init(7926, "top")
term.clear()
printAt(35, 18, "I am master " .. os.getComputerID())
parallel.waitForAll(Swarm.run, console)
