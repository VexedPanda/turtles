include.file("NetManager.lua")

Turtle = {}
Turtle.__index = Turtle

function Turtle.new(id)
    local self = {}
    setmetatable(self, Turtle)
    self.id = id
    return self
end

function Turtle:run(workerID, func)
    NetManager.send(self.id, {
        type = "RUN",
        workerID = workerID,
        byteCode = string.dump(func)
    })
end

function Turtle:runbg(func)
    NetManager.send(self.id, {
        type = "RUNBG",
        byteCode = string.dump(func)
    })
end