local shortcuts = {}
shortcuts["f"] = "forward()"
shortcuts["b"] = "back()"
shortcuts["l"] = "turnLeft()"
shortcuts["r"] = "turnRight()"
shortcuts["u"] = "up()"
shortcuts["d"] = "down()"
shortcuts["du"] = "digUp()"
shortcuts["dd"] = "digDown()"
shortcuts["df"] = "dig()"

print("Enter commands")
while true do
    local command = io.read()
    if command == "stop" then
        break
    end
    if shortcuts[command] then
        command = shortcuts[command]
    end
    command = "return turtle." .. command
    local runCommand = loadstring(command)
    if (runCommand == nil) then
        print("Unknown command")
    else
        local result = runCommand()
        if result == nil then
            print(": nil")
        else
            print(": " .. tostring(result))
        end
    end
end