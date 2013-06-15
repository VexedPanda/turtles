-- TODO: Add support for hops

local Slave = {}
Slave.__index = Slave
setmetatable(Slave, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function Slave.new(modem)
    local self = setmetatable({}, Slave)
    self.id = math.random(65534)+1
    self.modem = modem
    modem.open(self.id) -- allow messages to be received
    self.secret = "hta!i780'dbja8p#093$jmh{*320u8jkbtn$#danmj"
    return self
end


function Slave:sendMessageToMaster(message)
    self.modem.transmit(1, self.id, message)
end