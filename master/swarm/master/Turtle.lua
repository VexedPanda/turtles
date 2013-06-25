include.file("NetManager.lua")

Turtle = {}
Turtle.__index = Turtle

function Turtle.new(id)
    local self = {}
    setmetatable(self, Turtle)
    self.id = id
    self.queuedTasks = {}
    self.isFree = true
    --TODO: Store location and orientation
    return self
end

function Turtle:run(workerID, func, params)
    params = params or {}
    NetManager.send(self.id, {
        type = "RUN",
        workerID = workerID,
        byteCode = string.dump(func),
        params = params
    })
end

function Turtle:runbg(func, params)
    params = params or {}
    NetManager.send(self.id, {
        type = "RUNBG",
        byteCode = string.dump(func),
        params = params
    })
end