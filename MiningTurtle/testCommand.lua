os.loadAPI("/apis/include")

include.clean()
include.path("/swarm/slave/")
include.file("NetManager.lua")

local message = {}
message.type = "TASK"
message.task = "test"
print("Sending task " .. message.task)
NetManager.open(7926, "right")
NetManager.send(11, message)
