ThreadPool = {}
ThreadPool.__index = ThreadPool

function ThreadPool.new()
    local self = {}
    setmetatable(self, ThreadPool)
    self.threads = {}
    self.eventFilters = {}
    self.eventData = {}
    self.foregroundThread = nil
    return self
end


-- Runs a thread in this ThreadPool
function ThreadPool:runThread(thread)
    -- Ensure that if the thread was paused for a specified reason (a filter was supplied), we don't resume it early
    -- Also be sure to pass along any event data we do receive with that filter
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
-- the network listener never aborts, and we don't allow the system to loop forever, so don't call this
function ThreadPool:waitForAll()
    while #self.threads > 0 do
        self:runOnce()
    end
end

-- Runs the threads once and returns
function ThreadPool:runOnce()
    if (self.foregroundThread ~= nil and not self:runThread(self.foregroundThread)) then
        self.foregroundThread = nil
    end
    for i = 1, #self.threads do
        if (not self:runThread(self.threads[i])) then
            self.threads[i] = nil
        end
    end

    -- Clean up any now-dead threads (there are situations where they aren't cleaned in runThread)
    if self.foregroundThread and coroutine.status(self.foregroundThread) == "dead" then
        self.foregroundThread = nil
    end
    for i = 1, #self.threads do
        if (coroutine.status(self.threads[i]) == "dead") then
            self.threads[i] = nil
        end
    end


    -- TODO: Only run this if one of our threads is expecting an event in order to support one using yield directly
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