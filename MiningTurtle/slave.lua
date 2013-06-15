os.loadAPI("/apis/include")

include.clean()
include.path("/swarm/slave/")
include.file("NetManager.lua")
include.file("Swarm.lua")
include.file("ThreadPool.lua")
include.file("Navigation.lua")
include.file("Vector.lua")

local args = { ... }

local masterID = tonumber(args[1])

Navigation.detourFunctions()
Navigation.setOrientation(Direction.NORTH, Vector.new(0, 0, 0))

Swarm.init(masterID, 7926, "right")
Swarm.join()
print("Joined swarm")
Swarm.run()

Navigation.restoreFunctions()