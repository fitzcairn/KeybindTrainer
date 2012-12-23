-- Unit tests for Action objects.
-- This includes tests for binds translation and slot map building.
-- Note--needs to be run with the addon directory as the current
-- working directory.

-- Load up modules for testing.
require("test/TestBase")

-- Create upvalues
local U    = FitzUtils
local Main = KeybindTrainer;
local ABM  = ActionBindManager;
local Def  = Main.ValDefaults;
local C    = Main.Constants;
local SP   = Main.UserSlots;

-- Debug output?
U:Debug(true)

-- Focused tests on Action objects.
TestAction = {} 
    function TestAction:setUp()
       ResetClientTestState()
       
    end

    function TestAction:test_Basic()
       local a = Main:_NewTestAction("id")
       assertEquals(a:GetId(), "id")
       assertEquals(a:GetIdx(),  1)
       assertEquals(a:GetCD(),   C.GCD)
       assertEquals(a:GetBind(), nil)
       assertEquals(a:GetTex(),  nil)
       assertEquals(a:GetMiss(), 0)
       assertEquals(a:GetTime(), 0)
       assertEquals(a:GetStatType(), "action")
       assertEquals(a:GetName(), nil)
    end

    function TestAction:test_ResetForDisplay()
       local a = Main:_NewTestAction("test")
       a:SetTime(30.5)
       assertEquals(a:GetTime(), 30.5)
       assertEquals(a:GetBind(), nil)
       assertEquals(a:GetTex(),  nil)

       a:ResetForDisplay()
       assertEquals(a:GetMiss(), 0)
       assertEquals(a:GetTime(), 0)
       assertEquals(a:GetBind(), nil)
       assertEquals(a:GetTex(),  nil)
    end

    function TestAction:test_UpdateFromBarState()
       local a

       -- Reset API emulation
       ResetClientTestState()

       -- Set up emulated client state
       AddTestAction("spell", 1, "test1")
       AddTestAction("spell", 2, "test2")
       AddTestAction("spell", 3, "test3")

       AddTestActionToSlot(1, "spell", 1)
       AddTestActionToSlot(2, "spell", 2)
       AddTestActionToSlot(3, "spell", 3)
       AddTestActionToSlot(4, "spell", 1) -- Bind test1 to slot 4 also.

       AddTestKeybind(true, 1, "a")
       AddTestKeybind(true, 2, "b")
       AddTestKeybind(true, 3, "c")
       AddTestKeybind(true, 4, "d")

       -- Refresh the emulated user state.
       SP:AddSlotRange(ABM:GetSlotRangeFor("Action Bar"))
       ABM:GetFilledSlotPool(SP)

       -- Test 1: default trial, update from a slot id
       a = Main:_NewTestAction(2, "test2", "spell", 1, 12.12)
       a:UpdateFromBarState()
       assertEquals(a:GetId(), 2)
       assertEquals(a:GetType(), "spell")
       assertEquals(a:GetCD(),  12.12)

       -- Test 1: default trial, update from a slot name
       a = Main:_NewTestAction(nil, "test2", "spell", 1, 12.12)
       a:UpdateFromBarState()
       assertEquals(a:GetId(), "spell:2")
       assertEquals(a:GetType(), "spell")
       assertEquals(a:GetCD(),  12.12)

       -- Test 3: test combining binds from multiple visible 
       -- instances of the same spell bind.
       a = Main:_NewTestAction(nil, "test1", "spell", 1, 12.12)
       a:UpdateFromBarState()
       assertEquals(a:GetId(), "spell:1")
       assertEquals(a:GetType(), "spell")
       assertEquals(a:GetCD(),  12.12)
       assert(U:TableEqual(a:GetBind(), { a = 1, d = 1 }))

       -- Test 4: same as above, but set one of the binds to be not
       -- visible.
       SP:Get(1):Visible(false)
       a = Main:_NewTestAction(nil, "test1", "spell", 1, 12.12)
       a:UpdateFromBarState()
       assertEquals(a:GetId(), "spell:1")
       assertEquals(a:GetType(), "spell")
       assertEquals(a:GetCD(),  12.12)
       assert(U:TableEqual(a:GetBind(), { d = 1 }))    
    end

    function TestAction:test_Time()
       local a = Main:_NewTestAction("test")
       a:SetTime(30.5)
       assertEquals(a:GetTime(), 30.5)
    end

    function TestAction:test_Miss()
       local a = Main:_NewTestAction("test")
       a:IncMiss()
       a:IncMiss()
       a:IncMiss()
       assertEquals(a:GetMiss(), 3)
    end


-- Run all tests unless overriden on the command line.
LuaUnit:run("TestAction")



