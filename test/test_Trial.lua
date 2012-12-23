-- Unit tests for Trial objets.
-- Note--needs to be run with the addon directory as the current
-- working directory.

-- Load up modules for testing.
require("test/TestBase")

-- Create upvalues
local U    = FitzUtils
local FL   = FitzUtilsFifoList;
local Main = KeybindTrainer;
local ABM  = ActionBindManager;
local Def  = Main.ValDefaults;
local C    = Main.Constants;
local SP   = Main.UserSlots;

-- Debug output?
U:Debug(true)


-- Focused tests on Trial objects
TestTrial = {} 
    function TestTrial:setUp()
       ResetClientTestState()
       -- Set up emulated client state
       AddTestAction("spell", 1, "test1")
       AddTestAction("spell", 2, "test2")
       AddTestAction("spell", 3, "test3")

       AddTestActionToSlot(1, "spell", 1)
       AddTestActionToSlot(2, "spell", 2)
       AddTestActionToSlot(3, "spell", 3)

       AddTestKeybind(true, 1, "a")
       AddTestKeybind(true, 2, "b")
       AddTestKeybind(true, 3, "c")

       -- Refresh the emulated user state.
       SP:Clear()
       SP:AddSlotRange(ABM:GetSlotRangeFor("Action Bar"))
       ABM:GetFilledSlotPool(SP)

       -- For setting up test trials.
       self.prefix = "spell"
    end

    --
    -- Helpers
    --
    
    -- Get an action tuple with a single action.
    function TestTrial:getActionTuple(id)
       if not id then id = "" end
       local at = Main:_NewTestActionTuple()
       at:AddAction(self.prefix..":"..id)
       return at
    end

    -- Run iteration
    function TestTrial:run(t)
       -- Create expected set
       local prefix = self.prefix
       local testset = { self:getActionTuple(1),
                         self:getActionTuple(2),
                         self:getActionTuple(3) }
       
       -- Test iteration 
       assert(U:TableEqual(t:CurrTuple():Get(1), testset[1]:Get(1)))
       assertEquals(t:Peek(), 1)
       assert(U:TableEqual(t:Next():Get(1), testset[2]:Get(1)))
       assert(U:TableEqual(t:CurrTuple():Get(1), testset[2]:Get(1)))
       assertEquals(t:Peek(), 1)
       assert(U:TableEqual(t:Next():Get(1), testset[3]:Get(1)))
       assert(U:TableEqual(t:CurrTuple():Get(1), testset[3]:Get(1)))
       assertEquals(t:Peek(), nil)
       assertEquals(t:Next(), nil)
    end


    --
    -- Tests
    --

    function TestTrial:test_CreateDefault()
       local t = Main:NewDefaultTrial("test")
       assert(U:TableEqual(t:GetMenuText(), {}))
       assertEquals(t:GetID(), "test")
       assertEquals(t:GetName(), '')
       assertEquals(t:GetStr(), nil)
       assertEquals(t:GetTime(), 0)
       assertEquals(t:GetMiss(), 0)
       assertEquals(t:GetStatType(), "trial")
       assertEquals(t:IsDefault(), true)
       assertEquals(t:IsRandomDelay(), false)
       assertEquals(t:GetDelay(), nil)
    end

    -- Note: for parser tests, see test_CustomParser.lua
    function TestTrial:test_CreateCustom()
       local t = Main:NewCustomTrial("test", "custom", "[]")
       assert(U:TableEqual(t:GetMenuText(), {text = "test", tooltipTitle = "test", tooltipText = "custom"}))
       assertEquals(t:GetID(), "test")
       assertEquals(t:GetName(), "test")
       assertEquals(t:GetStr(), "[]")
       assertEquals(t:GetTime(), 0)
       assertEquals(t:GetMiss(), 0)
       assertEquals(t:GetStatType(), "trial")
       assertEquals(t:IsDefault(), false)
       assertEquals(t:IsRandomDelay(), false)
       assertEquals(t:GetDelay(), 0)
    end

    function TestTrial:test_SetFuncs()
       local t = Main:NewCustomTrial("test", "custom", "[]")
       assertEquals(t:GetDelay(), 0)
       assertEquals(t:GetName(), "test")
       t:SetDelay(12.3)
       t:SetName("test2")
       assertEquals(t:GetDelay(), 12.3)
       assertEquals(t:GetName(), "test2")
       t:SetDelay(C.RANDOM)
       assertEquals(t:IsRandomDelay(), true)  
    end

    function TestTrial:test_TestStats()
       local t = Main:NewDefaultTrial("test")
       assertEquals(t:GetTime(), 0)
       assertEquals(t:GetMiss(), 0)
       t:EndTrial(12.4)
       assertEquals(t:GetTime(), 12.4)
       t:IncMiss()
       t:IncMiss()
       assertEquals(t:GetMiss(), 2)
       t:StartTrial()
       assertEquals(t:GetTime(), 0)
       assertEquals(t:GetMiss(), 0)   

       -- Same behavior req'd for custom trials
       t = Main:NewCustomTrial("test", "custom", "[]")
       assertEquals(t:GetTime(), 0)
       assertEquals(t:GetMiss(), 0)
       t:EndTrial(12.4)
       assertEquals(t:GetTime(), 12.4)
       t:IncMiss()
       t:IncMiss()
       assertEquals(t:GetMiss(), 2)
       t:StartTrial()
       assertEquals(t:GetTime(), 0)
       assertEquals(t:GetMiss(), 0)   
    end

    function TestTrial:test_TestIterCustom()
       local t = Main:NewCustomTrial("test", "custom", "[]")
       t:AddActionTuple(self:getActionTuple(1))
       t:AddActionTuple(self:getActionTuple(2))
       t:AddActionTuple(self:getActionTuple(3))
       
       self:run(t)

       -- Test Reset
       t:Reset()
       self:run(t)

       -- Temporarily redefine math.random, and test ResetRandom
       local mr = math.random
       math.random = function (i,n) return i end
       t:ResetRandom()
       math.random = mr
       self:run(t)
    end


    -- Test iteration for default trials.
    function TestTrial:test_TestIterDefault()
       local t = Main:NewDefaultTrial("test")
       t:AddActionTuple(self:getActionTuple(1))
       t:AddActionTuple(self:getActionTuple(2))
       t:AddActionTuple(self:getActionTuple(3))

       -- Test iteration
       t:Reset()
       self:run(t)
       
       -- Temporarily redefine math.random, and test ResetRandom
       local mr = math.random
       math.random = function (i,n) return i end
       t:ResetRandom()
       math.random = mr
       --self:run(t)
    end


-- Run all tests unless overriden on the command line.
LuaUnit:run("TestTrial")



