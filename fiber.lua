--- a wrapper around coroutines
-- @classmod fiber

local class = require "class"

local fiber = class "Fiber"
fiber.current = nil

fiber.yield = coroutine.yield

--- create a fiber
-- @function fiber:new
-- @tparam function func
function fiber:init(func)
  self.co = coroutine.create(func)
  self.time = 0
  self.defers = {}
end

--- resume a fiber,
-- @param ... arguments passed to the coroutine
-- @treturn ?nil values returned by the coroutine or nil on timeout
function fiber:resume(...)
  if self.timeout then
    if self.time > self.timeout then
      self:close()
      return
    end
  end
  fiber.current = self
  local start = os.clock()
  local res = { coroutine.resume(self.co, ...) }
  local finish = os.clock()
  self.time = self.time + finish - start
  fiber.current = nil
  return table.unpack(res)
end

--- get the status of a fiber's coroutine
-- @return string
function fiber:status()
  return coroutine.status(self.co)
end

--- close a fiber
function fiber:close()
  for _, d in ipairs(self.defers) do
    local ok, err = pcall(d.func, table.unpack(d.args))
    if not ok then
      io.stderr:write(err .. "\n")
    end
  end
  coroutine.close(self.co)
end

--- pause the current fiber for a given time
-- @number sec the time to sleep in seconds
function fiber.sleep(sec)
  local start = os.clock()
  while os.clock() - start < sec do
    fiber.yield()
  end
end

--- keep yielding until func returns a positive value
-- @tparam function func
-- @param ... arguments passed to func
-- @return the result of func
function fiber.wait(func, ...)
  while true do
    local res = { func(...) }
    if res[1] then
      return table.unpack(res)
    end
    fiber.yield()
  end
end

--- keep yielding until func returns a positive value or the timeout is reached
-- @number time number of seconds to wait for--
-- @tparam function func
-- @return the result of func
function fiber.wait_for(time, func, ...)
  local start = os.clock()
  while true do
    if os.clock() - start > time then
      return
    end
    local res = { func(...) }
    if res[1] then
      return table.unpack(res)
    end
    fiber.yield()
  end
end

local fibers = {}

--- spawn a new fiber
-- @tparam function func
-- @param ...
function fiber.spawn(func, ...)
  local t = fiber:new(func)
  local ok, err = t:resume(...)
  if not ok then
    io.stderr:write(err, "\n")
  end
  if t:status() == "dead" then
    t:close()
  else
    table.insert(fibers, t)
  end
end

local stop = false

--- start the async loop
-- @tparam table t
function fiber.loop(t)
  for _, v in pairs(t) do
    table.insert(fibers, v)
  end
  while not stop do
    for i=#fibers,1,-1 do
      local t = fibers[i]
      local ok, err = t:resume()
      if not ok then
        io.stderr:write(err, "\n")
      end
      if t:status() == "dead" then
        t:close()
        table.remove(fibers, i)
      end
      if stop then break end
    end
  end
end

--- exit the async loop
function fiber.exit()
  stop = true
  fiber.yield()
end

--- return current fiber count
function fiber.count()
  return #fibers
end

--- defer a function to be executed when the fiber quits
-- (possibly due to an error)
-- @tparam function func
-- @param ...
function fiber.defer(func, ...)
  table.insert(
    fiber.current.defers, 1, {
      func = func,
      args = { ... }
    }
  )
end

return fiber
