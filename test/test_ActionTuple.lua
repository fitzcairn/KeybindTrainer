-- Unit tests for ActionTuple objects.
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

-- Focused tests on ActionTuple objects.
TestActionTuple = {} 
    function TestActionTuple:setUp()
       self:SetGlobalState()
    end

    --
    -- Helpers
    --

    function TestActionTuple:SetGlobalState()
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
       SP:Clear()
       SP:AddSlotRange(ABM:GetSlotRangeFor("Action Bar"))
       ABM:GetFilledSlotPool(SP)
    end

    -- Set up a new action.
    function TestActionTuple:CreateAndResetAction(...)
       local a = Main:_NewTestAction(...)
       a:UpdateFromBarState()
       return a
    end

    --
    -- Tests
    --

    function TestActionTuple:test_Creation()
       local t = Main:_NewTestActionTuple()
       t:AddAction(1)
       local a = Main:_NewTestAction(1)
       a:UpdateFromBarState()

       -- Should have only one action in the tuple
       assert(U:TableEqual(t:Get(1), a))
       assertEquals(t:GetNumActions(), 1)
       assertEquals(t:IsMulti(), false)
       assertEquals(t:CurrAction(), t:Get(1))
    end

    function TestActionTuple:test_AddAction()
       local t = Main:_NewTestActionTuple()
       t:AddAction(1)
       t:AddAction(2)
       t:AddAction(3)

       assert(U:TableEqual(t:Get(1), self:CreateAndResetAction(1, nil, nil, 1)))
       assert(U:TableEqual(t:Get(2), self:CreateAndResetAction(2, nil, nil, 2)))
       assert(U:TableEqual(t:Get(3), self:CreateAndResetAction(3, nil, nil, 3)))
    end

    function TestActionTuple:test_JavaIterator()
       local t = Main:_NewTestActionTuple()
       t:AddAction(1)
       t:AddAction(2)
       t:AddAction(3)

       local t1 = self:CreateAndResetAction(1, nil, nil, 1)
       local t2 = self:CreateAndResetAction(2, nil, nil, 2)
       local t3 = self:CreateAndResetAction(3, nil, nil, 3)

       assert(U:TableEqual(t:CurrAction(), t1))
       assertEquals(t:Peek(), true)
       assert(U:TableEqual(t:Next(), t2))
       assert(U:TableEqual(t:CurrAction(), t2))
       assert(U:TableEqual(t:Next(), t3))
       assert(U:TableEqual(t:CurrAction(), t3))
       assertEquals(t:Next(), nil) 
       assertEquals(t:Peek(), false)

       -- Test Reset()
       t:Reset()
       assert(U:TableEqual(t:CurrAction(), t1))
       assertEquals(t:Peek(), true)
       assert(U:TableEqual(t:Next(), t2))
       assert(U:TableEqual(t:CurrAction(), t2))
       assert(U:TableEqual(t:Next(), t3))
       assert(U:TableEqual(t:CurrAction(), t3))
       assertEquals(t:Next(), nil) 
       assertEquals(t:Peek(), false)
    end


    function TestActionTuple:test_LuaIterator()
       local t = Main:_NewTestActionTuple()
       t:AddAction(1)
       t:AddAction(2)
       t:AddAction(3)

       local t1 = self:CreateAndResetAction(1, nil, nil, 1)
       local t2 = self:CreateAndResetAction(2, nil, nil, 2)
       local t3 = self:CreateAndResetAction(3, nil, nil, 3)

       local iter = t:Iter()
       
       assert(U:TableEqual(iter(), t1))
       assert(U:TableEqual(iter(), t2))
       assert(U:TableEqual(iter(), t3))
       assertEquals(iter(), nil) 
       assertEquals(iter(), nil) 

       -- Should be able to get another iterator, and the seq. is reset.
       iter = t:Iter()
       assert(U:TableEqual(iter(), t1))
       assert(U:TableEqual(iter(), t2))
       assert(U:TableEqual(iter(), t3))
       assertEquals(iter(), nil) 
       assertEquals(iter(), nil) 
    end


    -- Test that the iterator will update from global state 
    -- if the actions are unrecognized at first.
    function TestActionTuple:test_LuaIterator_GlobalUpdate()
       local t = Main:_NewTestActionTuple()
       t:AddAction("spell:1")
       t:AddAction("spell:2")
       t:AddAction("spell:3")

       local iter = t:Iter()
       local a = iter() 
       assert(a:GetName() == "test1")
       assert(U:TableEqual(a:GetBind(), { a = 1, d = 1 }))
    end

    -- Same for Java iterator
    function TestActionTuple:test_JavaIterator_GlobalUpdate()
       local t = Main:_NewTestActionTuple()
       t:AddAction("spell:1")
       t:AddAction("spell:2")
       t:AddAction("spell:3")

       assert(U:TableEqual(t:CurrAction():GetBind(), { a = 1, d = 1 } ))
       assertEquals(t:Peek(), true)
       assert(U:TableEqual(t:Next():GetBind(), { b = 1 }))

    end


-- Run all tests unless overriden on the command line.
LuaUnit:run("TestActionTuple")



