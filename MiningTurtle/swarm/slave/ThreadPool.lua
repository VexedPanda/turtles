ThreadPool = {}
ThreadPool.__index = ThreadPool

function ThreadPool.new()
    local self = {}
    setmetatable(self, ThreadPool)
    self.threads = {}
    self.eventFilters = {}
    self.eventData = {}
    self.networkListenerThread = nil
    self.foregroundThread = nil
    return self
end


-- Runs a thread in this ThreadPool
function ThreadPool:runThread(thread)
    if not self.eventFilters[thread] or self.eventFilters[thread] == self.eventData[1] or self.eventData[1] == "terminate" then
        local ok, param = coroutine.resume(thread, unpack(self.eventData))

        if ok then
            self.eventFilters[thread] = param
        else
            error(param)
        end

        if coroutine.status(thread) == "dead" then
            return false
        end
    end
    return true
end

-- Runs the threads, passing event data to each one
-- the network listener never aborts, don't allow the system to loop forever.
--function ThreadPool:waitForAll()
--    while #self.threads > 0 do
--        self:runOnce()
--    end
--end

-- Runs the threads once and returns
function ThreadPool:runOnce()
    if (self.networkListenerThread ~= nil and not self:runThread(self.networkListenerThread)) then
        self.networkListenerThread = nil
    end
    if (self.foregroundThread ~= nil and not self:runThread(self.foregroundThread)) then
        self.foregroundThread = nil
    end
    for i = 1, #self.threads do
        if (not self:runThread(self.threads[i])) then
            table.remove(self.threads, i)
        end
    end

    self.eventData = { os.pullEventRaw() }
end

-- Adds a thread to this ThreadPool
function ThreadPool:add(func)
    local thread = coroutine.create(func)
    table.insert(self.threads, thread)
    self:runThread(thread)
end

function ThreadPool:setForegroundTask(func)
    local thread = coroutine.create(func)
    self.foregroundThread = thread
    self:runThread(thread)
end

function ThreadPool:setNetworkListener(func)
    local thread = coroutine.create(func)
    self.networkListenerThread = thread
    self:runThread(thread)
end