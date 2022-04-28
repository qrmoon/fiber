# fiber

wrapper around Lua coroutines for easier asynchronous programming

## examples

basic example

```lua
local fiber = require "fiber"

local hello = fiber:new(function()
  while true do
    print "Hello"
    fiber.sleep(1)
  end
end)

local world = fiber:new(function()
  while true do
    print "World"
    fiber.sleep(2)
  end
end)

fiber.loop { hello, world }
```

asynchronous sockets

```lua
local fiber = require "fiber"
local socket = require "socket"

local fetcher = fiber:new(function()
  local sock = sock.connect("127.0.0.1", 5000)
  sock:settimeout(0)
  sock:send "hello"

  local line, err = fiber.wait_for(10, sock.receive, sock, "*l")
  print(line or err)
  sock:close()
end)

local other = fiber:new(function()
  for i=1,1000 do
    print(i)
    fiber.sleep(1)
  end
end)

fiber.loop { fetcher, other }
```
