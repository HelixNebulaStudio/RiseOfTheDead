local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local ZSharp = {};

function ZSharp.Load(zSS, zEnv)
	local function outputConsole(...)
		print(...);
		
		local toStringify = {};
		for _, v in pairs({...}) do
			table.insert(toStringify, tostring(v));
		end
		local str = table.concat(toStringify, " ");
		
		zSS.ConsoleOutput:Fire(str);
	end
	
	zEnv.log = function(...)
		local str = Debugger:Stringify(...);
		local logPrefix = zEnv.ScriptName..">>  ";
		outputConsole(logPrefix, str);
	end
	
	zEnv.print = function(...)
		local logPrefix = zEnv.ScriptName..">>  ";
		outputConsole(logPrefix, ...);
	end
	
	zEnv.help = function(hierachy)
		
		local function printTable(t)
			local str = "";
			local sorted = {};
			for key, v in pairs(t) do
				table.insert(sorted, key);
			end
			table.sort(sorted);
			
			for a=1, #sorted do
				local key = sorted[a];
				local v = t[key];
				
				local hintV;
				pcall(function()
					hintV = t["hint"..key];
				end)
				hintV = hintV or "Missing hint.";

				str = str.."\n   <b>"..key.."</b>: ".. "<i>".. typeof(v) .."</i>"..(hintV and "    -- "..hintV or "");
			end
			
			table.clear(sorted);
			return str;
		end
		
		if hierachy then
			hierachy = tostring(hierachy);
			
			local keys = string.split(hierachy,".");
			local currDir = "";
			
			local currEnv = zEnv;
			
			for a=1, #keys do
				local dir = keys[a];
				currDir = currDir..dir..(a==#keys and "" or ".");
				
				if typeof(currEnv[dir]) ~= "table" then
					local descV;
					pcall(function()
						descV = currEnv["desc"..dir];
					end)
					descV = descV or "Missing description.";

					outputConsole("zss.help>>  \nFunction:", currDir," \[\[\n   ",descV,"\n\]\]\n");
					
					return;
					
				elseif currEnv[dir] == nil then
					outputConsole("zss.help>>  Unknown library (".. currDir ..").");
					return;
					
				else
					currEnv = currEnv[dir];
				end
			end
			
			outputConsole("zss.help>>  \nLibrary:", currDir,"= {",printTable(currEnv),"\n}\n");

			return;
		end
		
		
		local helpStr = [[<b>Welcome to ZSharp script. Here you can write scripts with lua.</b>]];
		
		helpStr = helpStr.."\n\n<b>getfenv():</b> -- Available keys in this environment.";
		
		local envStr = printTable(zEnv);		
		outputConsole("zss.help>>  \n",helpStr..envStr,"\n\nUse the <b>help</b>(path: <i>string</i>) function to see more. E.g. help(\"Audio.Play\")\n");
	end
end

return ZSharp;