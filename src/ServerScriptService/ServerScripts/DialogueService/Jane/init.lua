local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modBlueprints = require(game.ServerScriptService.ServerLibrary.Blueprints);

return function(player, dialog, dialogueData)
	if dialogueData:Get("FirstMet") == nil then
		dialog:SetInitiate("Thank you so much for rescuing Robert. We couldn't afford to lose another survivor..");
		dialog:AddChoice("thanks_noproblem", function(dialog)
			dialog:AddChoice("thanks_othersafehouse", function(dialog)
				dialog:AddChoice("thanks_dontmindstaying", function(dialog)
					dialogueData:Set("FirstMet", true);
				end)
			end)
		end);
	end
	
--	dialog:AddChoice("general_radio");
--	dialog:AddChoice("general_where");
--	dialog:AddChoice("general_how");
end