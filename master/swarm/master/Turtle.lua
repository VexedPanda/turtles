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

function Turtle:run(workerID, task)
    NetManager.send(self.id, {
        type = "RUN",
        workerID = workerID,
        byteCode = string.dump(task)
    })
end

function Turtle:runbg(task)
    NetManager.send(self.id, {
        type = "RUNBG",
        byteCode = string.dump(task)
    })
end