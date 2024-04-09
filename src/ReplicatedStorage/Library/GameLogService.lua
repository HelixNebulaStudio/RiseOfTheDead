local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local GameLogService = {}
GameLogService.__index = GameLogService;

GameLogService.Verbose = true;
GameLogService.LastUpload = tick();
GameLogService.LogCount = 0;
--==
local RunService = game:GetService("RunService");
local HttpService = game:GetService("HttpService");
local DataStoreService = game:GetService("DataStoreService");
local logDatabase = DataStoreService:GetDataStore("GameLogs");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local gameVersion = (modGlobalVars.GameVersion.."."..modGlobalVars.GameBuild);
--== Script;
function GameLogService:Log(log, logScope)
	task.spawn(function()
		self.LogCount = self.LogCount +1;
		
		local keyName = logScope or "Logs"
		
		if self[keyName] == nil then
			self[keyName] = {};
		end
		
		log = "["..gameVersion.."]:["..os.date().."]    "..tostring(log);
		table.insert(self[keyName], log);
		
		if self.Verbose then
			warn(logScope..">>  "..log);
		end
		
		local logPerMinute = self.LogCount/math.ceil(workspace.DistributedGameTime/60);
		
		if tick()-GameLogService.LastUpload >= math.clamp(logPerMinute, 10, 600) then
			GameLogService.LastUpload = tick();
			
			pcall(function()
				if RunService:IsStudio() then return end;
				
				
				Debugger:Log("Submitting log for (",(logScope or "Logs"),")");
				
				logDatabase:UpdateAsync(keyName, function(oldData, dataInfo)
					local decodeOld = oldData and HttpService:JSONDecode(oldData) or {};
					
					local a = 1;
					repeat
						if #decodeOld > 64 then
							table.remove(decodeOld, 1);
						end
						table.insert(decodeOld, self[keyName][a]);
						
						a = a +1;
					until a >= #self[keyName];
					
					local encodedData = HttpService:JSONEncode(decodeOld);
					return encodedData;
				end)
				GameLogService.LastUpload = tick();
				
				self[keyName] = {};
			end)
		end
	end)
end

shared.modGameLogService = GameLogService;
return GameLogService;