local fiber = require "fiber"

local f = fiber:new(function()
  fiber.defer(print, "Goodbye, World!")

  while true do
    print "Hello, World!"
    fiber.sleep(1)
  end
end)

fiber.loop { f }
