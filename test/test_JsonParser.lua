-- Unit tests for the custom trial parser.
-- Note--needs to be run with the KeybindTrainer directory as the current
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

-- Hack: turn on update mode, for ease of updating these tests
-- when the underlying data structures change.
UPDATE = false

TestJsonParser = {} 
    function TestJsonParser:setUp()
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

    -- Reduce repeated code for tests that we expect to fail
    function TestJsonParser:run_err(input)
       local err, bad_in, t
       t = Main:NewCustomTrialFromInput(input)
       err, bad_in = KT_Parser.GetErr()
       if not UPDATE then
          U:Print(err)
          U:Print(bad_in)
          U:Print("TRIAL: "..U:TableToString(t, "\n"))
          assert( t == nil ) -- t should be nil
          U:Print(err) -- Not going to test on err messages.
       end
    end
    
    -- Reduce repeated code for tests that we expect to succeed
    function TestJsonParser:run(input, exp)
       local t = Main:NewCustomTrialFromInput(input)
       if not UPDATE then U:Print("TRIAL: "..U:TableToString(t, "\n")) end
       U:Print(U:TableToString(t))
       if not UPDATE then assertEquals( exp, U:TableToString(t) ) end
    end


    --
    -- Tests
    --

    -- Custom trials are pretty loaded tables.  The easiest way to automate
    -- tests on these is to hardcode serialized expected output and do a 
    -- direct comparison.

    -- Basic functionality
    function TestJsonParser:test_basic()
       self:run([[ {"name":"basic","binds":[{"action":"Spell"},{"action":"Spell 2"}]} ]],
                '_r_func:  < function > _i:  1 _r_func_args: _text:  text:   basic _str:   {"name":"basic","binds":[{"action":"Spell"},{"action":"Spell 2"}]}  _hide:  false _m:  0 _name:   _t:  0 _idxs:  1:   1  2:   2 _is_default:  false _id:  basic _trial_set:  1:   _tuples:    1:     _name:      Spell     _i:      1     _m:      0     _c:      1.5     _t:      0   _i:    1  2:   _tuples:    1:     _name:      Spell 2     _i:      1     _m:      0     _c:      1.5     _t:      0   _i:    1 ')
    end


    -- Test failing with missing name
    function TestJsonParser:test_missing_name()
       self:run_err([[ {"name":"","binds":[{"action":"Spell"},{"action":"Spell 2"}]} ]])
       self:run_err([[{"name":,"binds":[{"action":"Spell"},{"action":"Spell 2"}]} ]])
       self:run_err([[{"binds":[{"action":"Spell"},{"action":"Spell 2"}]} ]])
    end

    -- Test with spell/item ids
    function TestJsonParser:test_ids_basic()
       self:run([[ {"name":"basic","binds":[{"action":"spell:1234"},{"action":"item:1234"}]} ]],
                '_r_func:  < function > _i:  1 _r_func_args: _text:  text:   basic _str:   {"name":"basic","binds":[{"action":"spell:1234"},{"action":"item:1234"}]}  _hide:  false _m:  0 _name:   _t:  0 _idxs:  1:   1  2:   2 _is_default:  false _id:  basic _trial_set:  1:   _tuples:    1:     _name:      spell:1234     _i:      1     _m:      0     _c:      1.5     _t:      0   _i:    1  2:   _tuples:    1:     _name:      item:1234     _i:      1     _m:      0     _c:      1.5     _t:      0   _i:    1 ')
    end

    function TestJsonParser:test_ids_case()
       self:run([[ {"name":"basic","binds":[{"action":"spell:1234"},
                                                 {"action":"SPELL:1234"},
                                                 {"action":"sPeLl:1234"},
                                                 {"action":"item:1234"},
                                                 {"action":"ITEM:1234"},
                                                 {"action":"iTeM:1234"}]} ]],
                                     [[_r_func:  < function > _i:  1 _r_func_args: _text:  text:   basic _str:   {"name":"basic","binds":[{"action":"spell:1234"},
                                                 {"action":"SPELL:1234"},
                                                 {"action":"sPeLl:1234"},
                                                 {"action":"item:1234"},
                                                 {"action":"ITEM:1234"},
                                                 {"action":"iTeM:1234"}]}  _hide:  false _m:  0 _name:   _t:  0 _idxs:  1:   1  2:   2  3:   3  4:   4  5:   5  6:   6 _is_default:  false _id:  basic _trial_set:  1:   _tuples:    1:     _name:      spell:1234     _i:      1     _m:      0     _c:      1.5     _t:      0   _i:    1  2:   _tuples:    1:     _name:      SPELL:1234     _i:      1     _m:      0     _c:      1.5     _t:      0   _i:    1  3:   _tuples:    1:     _name:      sPeLl:1234     _i:      1     _m:      0     _c:      1.5     _t:      0   _i:    1  4:   _tuples:    1:     _name:      item:1234     _i:      1     _m:      0     _c:      1.5     _t:      0   _i:    1  5:   _tuples:    1:     _name:      ITEM:1234     _i:      1     _m:      0     _c:      1.5     _t:      0   _i:    1  6:   _tuples:    1:     _name:      iTeM:1234     _i:      1     _m:      0     _c:      1.5     _t:      0   _i:    1 ]])
    end

    function TestJsonParser:test_ids_fail()
       input = self:run_err([[ {"name":"bob","binds":[{"action":foo:1234},{"action":bar:1234}]} ]])
    end

    -- Test with descriptions
    function TestJsonParser:test_desc()
       self:run([[ {"name":"basic","binds":[{"action":"Spell"},{"action":"Spell 2"}],"desc": "This is a badass test trial.  Whee!"}]],
                '_r_func:  < function > _i:  1 _r_func_args: _text:  text:   basic  tooltipText:   This is a badass test trial.  Whee!  tooltipTitle:   basic _str:   {"name":"basic","binds":[{"action":"Spell"},{"action":"Spell 2"}],"desc": "This is a badass test trial.  Whee!"} _hide:  false _m:  0 _name:   _t:  0 _idxs:  1:   1  2:   2 _is_default:  false _id:  basic _trial_set:  1:   _tuples:    1:     _name:      Spell     _i:      1     _m:      0     _c:      1.5     _t:      0   _i:    1  2:   _tuples:    1:     _name:      Spell 2     _i:      1     _m:      0     _c:      1.5     _t:      0   _i:    1 ')
     end

    -- Test with per-action delays
    function TestJsonParser:test_per_action_delay()
       self:run([[{"name":"basic","binds":[{"action":"spell:1234", "cd": 12},
                            {"action":"Spell", "cd": 1},
                            {"action":"Spell 2", "cd": 1.1},
                            {"action":"spell:1234", "cd": 0},
                            {"action":"item:1234", "cd": 9999}]} ]],
                [[_r_func:  < function > _i:  1 _r_func_args: _text:  text:   basic _str:  {"name":"basic","binds":[{"action":"spell:1234", "cd": 12},
                            {"action":"Spell", "cd": 1},
                            {"action":"Spell 2", "cd": 1.1},
                            {"action":"spell:1234", "cd": 0},
                            {"action":"item:1234", "cd": 9999}]}  _hide:  false _m:  0 _name:   _t:  0 _idxs:  1:   1  2:   2  3:   3  4:   4  5:   5 _is_default:  false _id:  basic _trial_set:  1:   _tuples:    1:     _name:      spell:1234     _i:      1     _m:      0     _c:      12     _t:      0   _i:    1  2:   _tuples:    1:     _name:      Spell     _i:      1     _m:      0     _c:      1     _t:      0   _i:    1  3:   _tuples:    1:     _name:      Spell 2     _i:      1     _m:      0     _c:      1.1     _t:      0   _i:    1  4:   _tuples:    1:     _name:      spell:1234     _i:      1     _m:      0     _c:      0     _t:      0   _i:    1  5:   _tuples:    1:     _name:      item:1234     _i:      1     _m:      0     _c:      9999     _t:      0   _i:    1 ]])
    end
    function TestJsonParser:test_per_action_delay_fail()
       self:run_err([[ {"name":"bob","binds":[{"action":"spell:1234", "cd": "a"}]} ]])
    end
    function TestJsonParser:test_per_action_delay_fail2()
       self:run_err([[ {"name":"bob","binds":[{"action":"spell:1234", "cd": }]} ]]) 
    end

    -- Test general trial delay
    function TestJsonParser:test_trial_delay()
       self:run([[ {"name":"bob", "gcd": 10, "binds":[{"action":"spell:1234"}]} ]],
                '_r_func:  < function > _i:  1 _r_func_args: _text:  text:   bob _str:   {"name":"bob", "gcd": 10, "binds":[{"action":"spell:1234"}]}  _hide:  false _m:  0 _name:   _t:  0 _idxs:  1:   1 _is_default:  false _id:  bob _delay:  10 _trial_set:  1:   _tuples:    1:     _name:      spell:1234     _i:      1     _m:      0     _c:      1.5     _t:      0   _i:    1 ')
    end

    function TestJsonParser:test_trial_delay_random()
       self:run([[ {"name":"bob", "gcd": "random", "binds":[{"action":"spell:1234"}]} ]],
                '_r_func:  < function > _i:  1 _r_func_args: _text:  text:   bob _str:   {"name":"bob", "gcd": "random", "binds":[{"action":"spell:1234"}]}  _hide:  false _m:  0 _name:   _t:  0 _idxs:  1:   1 _is_default:  false _id:  bob _delay:  random _trial_set:  1:   _tuples:    1:     _name:      spell:1234     _i:      1     _m:      0     _c:      1.5     _t:      0   _i:    1 ')
    end

    function TestJsonParser:test_trial_delay_fail()
       self:run_err([[ {"name":"bob", "gcd": "as", "binds":[{"action":"spell:1234"}]} ]])
    end

    -- Test multi action tuples
    function TestJsonParser:test_multi_action()
       self:run([[ {"name":"basic","binds":[ [{"action":"Spell"},{"action":"item:1234"}] ]} ]],
                '_r_func:  < function > _i:  1 _r_func_args: _text:  text:   basic _str:   {"name":"basic","binds":[ [{"action":"Spell"},{"action":"item:1234"}] ]}  _hide:  false _m:  0 _name:   _t:  0 _idxs:  1:   1 _is_default:  false _id:  basic _trial_set:  1:   _tuples:    1:     _name:      Spell     _i:      1     _m:      0     _c:      1.5     _t:      0    2:     _name:      item:1234     _i:      2     _m:      0     _c:      1.5     _t:      0   _i:    1 ')
     end

    -- Test multi-action tuples with delay
    function TestJsonParser:test_multi_action_with_delay()
       self:run([[ {"name":"basic","binds":[ [{"action":"Spell", "cd": 12.3},{"action":"item:1234", "cd": 0}] ]} ]],
                '_r_func:  < function > _i:  1 _r_func_args: _text:  text:   basic _str:   {"name":"basic","binds":[ [{"action":"Spell", "cd": 12.3},{"action":"item:1234", "cd": 0}] ]}  _hide:  false _m:  0 _name:   _t:  0 _idxs:  1:   1 _is_default:  false _id:  basic _trial_set:  1:   _tuples:    1:     _name:      Spell     _i:      1     _m:      0     _c:      12.3     _t:      0    2:     _name:      item:1234     _i:      2     _m:      0     _c:      0     _t:      0   _i:    1 ')
     end

    -- Test multi-action tuples with delay and global delay
    function TestJsonParser:test_multi_action_with_global_delay()
       self:run([[ {"name":"basic", "gcd":10, "binds":[ [{"action":"Spell", "cd": 12.3},{"action":"item:1234", "cd": 0}] ]} ]],
                '_r_func:  < function > _i:  1 _r_func_args: _text:  text:   basic _str:   {"name":"basic", "gcd":10, "binds":[ [{"action":"Spell", "cd": 12.3},{"action":"item:1234", "cd": 0}] ]}  _hide:  false _m:  0 _name:   _t:  0 _idxs:  1:   1 _is_default:  false _id:  basic _delay:  10 _trial_set:  1:   _tuples:    1:     _name:      Spell     _i:      1     _m:      0     _c:      12.3     _t:      0    2:     _name:      item:1234     _i:      2     _m:      0     _c:      0     _t:      0   _i:    1 ')
    end

    -- Test what happens when we have an action name that maps to multiple
    -- ids.
    function TestJsonParser:test_multi_ids_for_name()
       self:run([[ {"name":"basic","binds":[{"action":"Unknown"}]} ]],
                '_r_func:  < function > _i:  1 _r_func_args: _text:  text:   basic _str:   {"name":"basic","binds":[{"action":"Unknown"}]}  _hide:  false _m:  0 _name:   _t:  0 _idxs:  1:   1 _is_default:  false _id:  basic _trial_set:  1:   _tuples:    1:     _name:      Unknown     _i:      1     _m:      0     _c:      1.5     _t:      0   _i:    1 ')
    end


    -- TO WRITE:
    --function TestJsonParser:test_non_us_names()


-- Run all tests unless overriden on the command line.       
LuaUnit:run("TestJsonParser")



