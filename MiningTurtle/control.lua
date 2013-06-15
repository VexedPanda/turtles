print("Enter commands")
while true do
    local command = io.read()
    if command == "stop" then
        break
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
            print(": "..tostring(result))
        end
    end
end