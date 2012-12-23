-- A small hook to just try stuff with the json parser.  Not
-- really intended to test much yet.
-- Note--needs to be run with the addon directory as the current
-- working directory.

-- Load up modules for testing.
require("test/TestBase")

-- Create upvalues
local U    = FitzUtils

-- Debug output?
U:Debug(true)

-- A few focused tests on json4lua
TestJSON = {} 
    function TestJSON:setUp()
    end

    -- Test UTF8 in the parser
    function TestJSON:test_non_ascii()
       local test = {
          ["name"] = "øh nø!",
          ["binds"] = {
             {  ["action"] = "øh nø!"
             },
          },
       }
       local test_str = '{"name":"øh nø!","binds":[{"action":"øh nø!"}]}'

       assertEquals(test_str, json.encode(test))
       assert(U:TableEqual(test, json.decode(test_str)))
    end

  
-- Run all tests unless overriden on the command line.
LuaUnit:run("TestJSON")



