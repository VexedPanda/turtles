include.file("NetManager.lua")
include.file("ThreadPool.lua")
include.file("Navigation.lua")

Swarm = {}

local threadPool = ThreadPool.new()

function Swarm.run()
    while true do
        threadPool:runOnce()
    end
end

function Swarm.free()
    NetManager.send(Swarm.masterID, { type = "FREE" })
end

function Swarm.init(masterID, channel, modemSide)
    NetManager.open(channel, modemSide)
    Swarm.masterID = masterID
end

function Swarm.join()
    NetManager.send(Swarm.masterID, {
        type = "JOIN"
    })
end

function Swarm.leave()
    NetManager.send(Swarm.masterID, {
        type = "LEAVE"
    })
end

-- This runs in a background thread since it doesn't interfere with normal operations
threadPool:add(function()
    while true do
        local message = NetManager.receive()
        if message.type == "RUN" then
            threadPool:setForegroundTask(function()
                loadstring(message.byteCode)(message.workerID, message.params)
                Swarm.free()
            end)
        elseif message.type == "RUNBG" then
            threadPool:add(function()
                loadstring(message.byteCode)()
            end)
        end
    end
end)