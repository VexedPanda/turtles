os.loadAPI("/apis/include")

include.clean()
include.path("/swarm/slave/")
include.file("NetManager.lua")

local message = {}
message.type = "QUEUE_TASK"
message.task = "test"
message.turtleId = 9

NetManager.open(7926, "top")

NetManager.send(11, message)
NetManager.send(11, message)
