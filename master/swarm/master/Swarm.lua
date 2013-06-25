include.file("NetManager.lua")
include.file("Turtle.lua")
include.file("Hook.lua")

Swarm = {}

local MessageHandler = {}

local turtles = {}
local freeTurtles = {}
local busyTurtles = {}
local tasks = {}
local idTurtleMap = {}
local turtleIndexMap = {}

local function handleNet()
    local message = NetManager.receive()

    if message.type == "JOIN" then
        MessageHandler.onJoin({ turtleID = message.__SENDER })
    elseif message.type == "LEAVE" then
        MessageHandler.onLeave({ turtleID = message.__SENDER })
    elseif message.type == "FREE" then
        MessageHandler.onFree({ turtleID = message.__SENDER })
    else
        Hook.call("NetMessage", { message = message, turtleId = message.__SENDER })
    end
end

function Swarm.run()
    while true do
        handleNet()
    end
end

function Swarm.init(channel, modemSide)
    NetManager.open(channel, modemSide)
end

function Swarm.allocTurtles(amount)
    if #freeTurtles < amount then return end

    local turtles = {}
    for i = 1, amount do
        local turtle = table.remove(freeTurtles)
        table.insert(turtles, turtle)
        table.insert(busyTurtles)
    end

    return turtles
end

--TODO track how many turtles are on tasks, allow others to be added. Ensure they have a unique worker id

function Swarm.submitTask(func, params, turtles)
    for i = 1, #turtles do
        local turtle = turtles[i]
        turtle:run(i, func, params)
        turtle.isFree = false
    end
end

function Swarm.submitTaskToAllFree(func, params)
    print("Submitting")
    local turtles = Swarm.allocTurtles(#freeTurtles)
    for i = 1, #turtles do
        print("to turtle " .. i)
        local turtle = turtles[i]
        turtle:run(i, func, params)
    end
end

function MessageHandler.onJoin(event)
    local turtle = Turtle.new(event.turtleID)
    idTurtleMap[event.turtleID] = turtle
    turtles[turtle] = turtle
    table.insert(freeTurtles, turtle)
    Hook.call("TurtleJoin", { turtle = turtle })
end

function MessageHandler.onLeave(event)
    Hook.call("TurtleLeave", { turtle = idTurtleMap[event.turtleID] })
    turtles[idTurtleMap[event.turtleID]] = nil
    idTurtleMap[event.turtleID] = nil
end

function Swarm.queueTask(turtleId, func, params)
    local turtle = idTurtleMap[turtleId]
    if turtle.isFree then
        Swarm.submitTask(func, params, { turtle })
    else
        table.insert(turtle.queuedTasks, 1, { func = func, params = params })
    end
end

function Swarm.dequeueTask(turtle)
    return table.remove(turtle.queuedTasks)
end

function MessageHandler.onFree(event)
    local freeTurtle = idTurtleMap[event.turtleID]
    if #freeTurtle.queuedTasks == 0 then
        Hook.call("TurtleFree", { turtle = freeTurtle })
        busyTurtles[freeTurtle] = nil
        table.insert(freeTurtles, freeTurtle)
        freeTurtle.isFree = true
        return
    end
    -- This turtle has a queued task, perform it.
    local newTask = Swarm.dequeueTask(freeTurtle)
    Swarm.submitTask(newTask.func, newTask.params, { freeTurtle })
end