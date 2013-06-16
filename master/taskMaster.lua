--This is the program that issues commands to available turtles.
os.loadAPI("/apis/include")

include.clean()
include.path("/swarm/master/")
include.file("Swarm.lua")
include.file("ThreadPool.lua")
include.file("Hook.lua")

--local function exampleTask(slaveId)
--    print("New task! Task Worker ID: " .. slaveId)
--    sleep(slaveId)
--    turtle.up()
--    sleep(1.5)
--    turtle.down()
--    print("Task finished!")
--end

Hook.add("TurtleJoin", function(event)
    print("Turtle #" .. event.turtle.id .. " has joined the swarm!")
--TODO: Add a task to report position every 10 sec
--    local turtles = Swarm.allocTurtles(1)
--    if turtles then
--        print("Allocated " .. #turtles .. " turtles!")
--        Swarm.submitTask(exampleTask, turtles)
--        print("Told them to do the exampleTask")
--    end
end)

Hook.add("TurtleLeave", function(event)
    print("Turtle #" .. event.turtle.id .. " has left the swarm!")
end)

Hook.add("TurtleFree", function(event)
    print("Turtle #" .. event.turtle.id .. " has finished its tasks and is ready for more!")
end)

local tasks = {}
tasks["test"] = function(slaveId)
    print("New task! Task Worker ID: " .. slaveId)
    sleep(slaveId)
    turtle.up()
    sleep(1.5)
    turtle.down()
    print("Task finished!")
end

Hook.add("NetMessage", function(event)
    if (event.message.type == "TASK") then
        print("Got task, sending to all free turtles:")
        print(event.message.task)
        Swarm.submitTaskToAllFree(tasks[event.message.task])
    end
end)

Swarm.init(7926, "top")
print("I am master " .. os.getComputerID())
Swarm.run()