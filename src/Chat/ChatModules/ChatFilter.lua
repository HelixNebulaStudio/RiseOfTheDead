local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local WordsFiltered = {"robux"; "rebux"; "bux"; "buck"; "robuck"; ".gg"; ".io"; ".com"; ".org"};

local function Run(ChatService)
	ChatService:RegisterProcessCommandsFunction("spamfilter", function (speakerName, message, channelName)
		local speaker = game.Players:FindFirstChild(speakerName);
		
		if speaker then
			local hasPermissions = modGlobalVars.IsCreator(speaker);
			if modBranchConfigs.IsWorld("MainMenu") and not hasPermissions then
			
				for a=1, #WordsFiltered do
					if message:lower():find(WordsFiltered[a]:lower()) then
						return true;
					end
				end
			end
		end
		return false;
	end);
end
 
return Run;