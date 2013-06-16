--This is the program that issues commands to available turtles.
os.loadAPI("/apis/include")

--noinspection UnassignedVariableAccess
include.clean()
--noinspection UnassignedVariableAccess
include.path("/swarm/master/")
--noinspection UnassignedVariableAccess
include.file("Swarm.lua")
--noinspection UnassignedVariableAccess
include.file("ThreadPool.lua")
--noinspection UnassignedVariableAccess
include.file("Hook.lua")

local tasks = {}
tasks["test"] = function(slaveId)
    print("New task! Task Worker ID: " .. slaveId)
    --noinspection UnassignedVariableAccess
    sleep(slaveId)
    turtle.up()
    --noinspection UnassignedVariableAccess
    sleep(1.5)
    turtle.down()
    print("Task finished!")
end
tasks["reportLocation"] = function()
    while true do
        --Report position back to me every 10 seconds
        print("sleeping for 10")
        os.sleep(10)
        print("Reporting Location")
        --noinspection UnassignedVariableAccess
        NetManager.send(Swarm.masterID, {
            type = "LOCATION",
            pos = Navigation.pos(),
            dir = Navigation.dir()
        })
        print("yielding")
        coroutine.yield()
    end
end

Hook.add("TurtleJoin", function(event)
    print("Turtle #" .. event.turtle.id .. " has joined the swarm!")
    event.turtle:runbg(tasks["reportLocation"])
end)

Hook.add("TurtleLeave", function(event)
    print("Turtle #" .. event.turtle.id .. " has left the swarm!")
end)

Hook.add("TurtleFree", function(event)
    print("Turtle #" .. event.turtle.id .. " has finished its foreground task and is ready for more!")
end)

Hook.add("NetMessage", function(event)
    if (event.message.type == "TASK") then
        print("Got task, sending to all free turtles:")
        print(event.message.task)
        Swarm.submitTaskToAllFree(tasks[event.message.task])
        return
    end
    if (event.message.type == "LOCATION") then
        print("Turtle " .. event.turtleId .. " has pos " .. event.message.pos.x .. ", " .. event.message.pos.y .. ", "
                .. event.message.pos.z .. " and dir " .. event.message.dir)
        return
    end
end)

Swarm.init(7926, "top")
print("I am master " .. os.getComputerID())
Swarm.run()