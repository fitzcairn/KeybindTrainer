-- Unit tests for Config functionality.
-- Note--needs to be run with the addon directory as the current
-- working directory.

-- Load up modules for testing.
require("test/TestBase")

-- Create upvalues
local U    = FitzUtils
local Main = KeybindTrainer;
local Def  = Main.ValDefaults;

-- Debug output?
U:Debug(true)

-- Focused tests on generic config functionality that doesn't
-- involve WoW UI objects/properties.
TestConfig = {} 
    function TestConfig:setUp()
    end

    -- Todo: test UI callbacks
    function TestConfig:test_Cbs()
       assert(true)
    end

    function TestConfig:test_Vars() 
       -- Test setting and getting
       Main:SetVar("test1", false)
       Main:SetVar("test2", 0)
       Main:SetVar("test3", "string")
       Main:SetVar("test4", {})

       assertEquals(Main:GetVar("test1"), false)
       assertEquals(Main:GetVar("test2"), 0)
       assertEquals(Main:GetVar("test3"), "string")
       assert(U:TableEqual(Main:GetVar("test4"), {}))
       assertEquals(Main:GetVar("test5"), nil)

       -- Test defaulting
       Def.test5 = 6
       Def.test6 = "bob"
       Def.test7 = false
       Def.test8 = {}

       assertEquals(Main:GetVar("test5", true), 6)
       assertEquals(Main:GetVar("test6", true), "bob")
       assertEquals(Main:GetVar("test7", true), false)
       assert(U:TableEqual(Main:GetVar("test8", true), {}))
       assertEquals(Main:GetVar("test9", true), nil)
    end

-- Run all tests unless overriden on the command line.
LuaUnit:run("TestConfig")



