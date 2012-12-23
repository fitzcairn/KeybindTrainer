-- Set up the unit test environment for addon code.
-- This file should be included in all unit tests.

--
-- Set Path and Load Modules
--

-- Get current working directory for require path (from lua-users.org)
function getcwd()
   local pipe = io.popen('cd', 'r')
   local cdir = pipe:read('*l')
   pipe:close()
   return cdir
end

-- Set the path
cwd = getcwd()
package.path = "?;"..cwd.."/?;"..cwd.."/?.lua;"..cwd.."/test/?.lua;"..cwd.."/lib/FitzUtils/?.lua"

-- Load unit test library
require('luaunit/luaunit')

-- Load up modules for testing.
require("lib/FitzUtils/Util")
require("lib/FitzUtils/TestUtil")
require("lib/FitzUtils/ApiEmulation")

-- Init from the toc file.
LoadForUnitTest("KeybindTrainer.toc")

