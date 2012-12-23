-- Unit tests for Stats functionality.
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

-- Focused tests on the bounded FIFO list
TestStats = {} 
    function TestStats:setUp()
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

       -- Create a test action
       self.a = Main:_NewTestAction("spell:1")
       self.a:UpdateFromBarState()

       -- Create a test trial
       self.t = Main:NewCustomTrial("test", "custom", "[]")

       -- Shortcut to field ids.
       self.f = C.STAT_FIELDS

       -- Get a common list
       self.e = FL:New(C.STAT_SAMPLE_LIMIT)

       -- Turn off random
       Main:SetVar("KT_RandomOrder", false)
    end


    --
    -- Helpers
    --

    function TestStats:reset()
       -- Clear stats 
       Main:ClearStats()
       self.e = FL:New(C.STAT_SAMPLE_LIMIT)
       self.a = Main:_NewTestAction("spell:1")
       self.a:UpdateFromBarState()
    end

    -- Record a trial time of duration d, with m misses
    function TestStats:record_trial(d, m)
       self.t:StartTrial()
       self.t:EndTrial(d)
       for i = 1,m,1 do self.t:IncMiss() end
       Main:RecordStats(self.t)
       FL:Push(self.e, 
               Main:CreateStatRecord(self.t:GetTime(),
                                     self.t:GetMiss()))
    end

    -- Record an action time of duration d, with m misses
    function TestStats:record_action(d, m, id)
       if id then 
          -- New action, clear list.
          self.e = FL:New(C.STAT_SAMPLE_LIMIT)
          self.a = Main:_NewTestAction("spell:"..id)
          self.a:UpdateFromBarState()
       end
       self.a:ResetForDisplay()

       self.a:SetTime(d)
       for i = 1,m,1 do self.a:IncMiss() end
       Main:RecordStats(self.a)
       FL:Push(self.e, 
                     Main:CreateStatRecord(self.a:GetTime(),
                                           self.a:GetMiss()))
    end


    --
    -- Tests
    --

    function TestStats:test_CreateStatId()
       assertEquals(Main:CreateStatId("x", "y"),
                    "x"..C.STAT_ID_DELIM.."y")
    end

    function TestStats:test_CreateStatRecord()
       assert(U:TableEqual(Main:CreateStatRecord(1,2),
                      {
                         [C.STAT_FIELDS.LIST_TIME] = 1,
                         [C.STAT_FIELDS.LIST_MISS] = 2
                      }))
    end

    function TestStats:test_RecordStatsTrial()
       local t,f       = self.t,self.f
       local exp_stats = {}

       -- Test 1: Single trial
       self:reset()
       self:record_trial(20.3,9)
       exp_stats = {
          trials = {
             [Main:CreateStatId(t:GetName(), "false")] = {
                [f.NAME]      = t:GetName(),
                [f.INFO]      = "false",
                [f.LIST]      = self.e,
                [f.LIST_SUMS] = Main:CreateStatRecord(20.3,9),
                [f.LIST_MAX]  = Main:CreateStatRecord(20.3,9)
             },
          },
          actions= {}
       }
       assert(U:TableEqual(exp_stats, KT_Stats))

       -- Test 2: Multiple trials
       self:reset()
       self:record_trial(0.5, 1)
       self:record_trial(1.5, 2)
       self:record_trial(5.0, 3)
       exp_stats = {
          trials = {
             [Main:CreateStatId(t:GetName(), "false")] = {
                [f.NAME]      = t:GetName(),
                [f.INFO]      = "false",
                [f.LIST]      = self.e,
                [f.LIST_SUMS] = Main:CreateStatRecord(7.0,6),
                [f.LIST_MAX]  = Main:CreateStatRecord(5.0,3)
             },
          },
          actions= {}
       }
       assert(U:TableEqual(exp_stats, KT_Stats))
    end

    function TestStats:test_RecordStatsAction()
       local a,f       = self.a,self.f
       local exp_stats = {}

       -- Test 1: Simple 3 action run
       self:reset()
       self:record_action(1,1)
       self:record_action(1,1)
       self:record_action(1,1)
       exp_stats = {
          actions = {
             [Main:CreateStatId(a:GetMacroDisplayName(), a:GetTex())] = {
                [f.NAME]      = a:GetMacroDisplayName(),
                [f.INFO]      = a:GetTex(),
                [f.LIST]      = self.e,
                [f.LIST_SUMS] = Main:CreateStatRecord(3,3),
                [f.LIST_MAX]  = Main:CreateStatRecord(1,1)
             },
          },
          trials  = {}
       }
       assert(U:TableEqual(exp_stats, KT_Stats))

       -- Test 2: Simple 3 action run, only one miss
       self:reset()
       self:record_action(1,1)
       self:record_action(1,0)
       self:record_action(1,0)
       exp_stats = {
          actions = {
             [Main:CreateStatId(a:GetMacroDisplayName(), a:GetTex())] = {
                [f.NAME]      = a:GetMacroDisplayName(),
                [f.INFO]      = a:GetTex(),
                [f.LIST]      = self.e,
                [f.LIST_SUMS] = Main:CreateStatRecord(3,1),
                [f.LIST_MAX]  = Main:CreateStatRecord(1,1)
             },
          },
          trials  = {}
       }
       assert(U:TableEqual(exp_stats, KT_Stats))

       -- Test 3: 5 action run
       self:reset()
       self:record_action(1,1)
       self:record_action(2,0)
       self:record_action(1,2)
       self:record_action(4,0)
       self:record_action(6,1)
       exp_stats = {
          actions = {
             [Main:CreateStatId(a:GetMacroDisplayName(), a:GetTex())] = {
                [f.NAME]      = a:GetMacroDisplayName(),
                [f.INFO]      = a:GetTex(),
                [f.LIST]      = self.e,
                [f.LIST_SUMS] = Main:CreateStatRecord(14,4),
                [f.LIST_MAX]  = Main:CreateStatRecord(6,2)
             },
          },
          trials  = {}
       }
       assert(U:TableEqual(exp_stats, KT_Stats))
    end


    -- Test available stats fetching on both trials and actions
    -- Tested for actions as we only display stats on that currently.
    function TestStats:test_GetSortedStatList()
       local f        = self.f
       local exp_list = {}
       local t        = "actions"

       -- Helper to reduce repeated code
       local add_exp_action = function(exp, lsum, lmax)
                                 table.insert(exp, {
                                                 [f.NAME]      = self.a:GetMacroDisplayName(),
                                                 [f.INFO]      = self.a:GetTex(),
                                                 [f.LIST]      = self.e,
                                                 [f.LIST_SUMS] = lsum,
                                                 [f.LIST_MAX]  = lmax,
                                              })                                 
                              end

       -- Test: Simple 3 action run over 2 trials.
       self:reset()
       self:record_action(1,1,1)
       self:record_action(1,3) -- add to previous action. sums now 2,4, max now 1,3
       add_exp_action(exp_list, Main:CreateStatRecord(2,4), Main:CreateStatRecord(1,3))
       self:record_action(2,1,2)
       add_exp_action(exp_list, Main:CreateStatRecord(2,1), Main:CreateStatRecord(2,1))
       self:record_action(3,4,3)       
       add_exp_action(exp_list, Main:CreateStatRecord(3,4), Main:CreateStatRecord(3,4))

       -- Correct order for Max time is 3-2-1
       assert(U:TableEqual(Main:GetSortedStatList(t, f.LIST_TIME, KT_GetStatMax),
                      {exp_list[3], exp_list[2], exp_list[1]}))
       -- Correct order for Avg time is 3-2-1
       assert(U:TableEqual(Main:GetSortedStatList(t, f.LIST_TIME, KT_GetStatAvg),
                      {exp_list[3], exp_list[2], exp_list[1]}))
       -- Correct order for Last time is 3-2-1
       assert(U:TableEqual(Main:GetSortedStatList(t, f.LIST_TIME, KT_GetStatLast),
                      {exp_list[3], exp_list[2], exp_list[1]}))

       -- Correct order for Max miss is 3-1-2
       assert(U:TableEqual(Main:GetSortedStatList(t, f.LIST_MISS, KT_GetStatMax),
                      {exp_list[3], exp_list[1], exp_list[2]}))
       -- Correct order for Avg miss  is 3-1-2
       assert(U:TableEqual(Main:GetSortedStatList(t, f.LIST_MISS, KT_GetStatAvg),
                      {exp_list[3], exp_list[1], exp_list[2]}))
       -- Correct order for Last miss is 3-1-2
       assert(U:TableEqual(Main:GetSortedStatList(t, f.LIST_MISS, KT_GetStatLast),
                      {exp_list[3], exp_list[1], exp_list[2]}))
    end




-- Run all tests unless overriden on the command line.
LuaUnit:run("TestStats")



