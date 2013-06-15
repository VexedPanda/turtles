-- For a turtle to run, accepts commands from the taskMaster
require"ryan_api"
local modem = peripheral.wrap("right")
modem.transmit(1, 2, "New slave")
local event, modemSide, senderChanel, replyChannel, message, senderDistance = os.pullEvent("modem_message")
