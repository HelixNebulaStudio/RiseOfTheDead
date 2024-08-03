local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Stephanie={};
};

local missionId = 3;
--==

-- !outline: Stephanie Dialogues
Dialogues.Stephanie.DialogueStrings = {
	["pre_findBook"]={
		Face="Suspicious"; 
		Say="Hello, I'm new here."; 
		Reply="Ummm, okay.";
	};

	["findBook_found"]={
		Face="Suspicious"; 
		Reply="Have you found the book yet?";
	};
	
	["findBook_letMeHelp"]={
		CheckMission=missionId; 
		Say="Umm no, but I can help you find it."; 
		Face="Skeptical"; Reply="It's an odd looking blue book, please try to find it, it's important.";
		FailResponses = {
			{Reply="You're too new here, come back once you're more familiar with the place."};
		};
	};
	["findBook_foundBook"]={
		Say="Found it, here you go..."; 
		Face="Happy"; 
		Reply="Thanks a lot!";
	};
	["findBook_whatsInTheBook"]={
		Say="What did you need this book for anyways?";
		Face="Surprise"; 
		Reply="Well, this book might have information on how to build something better to get rid of the zombies. I will tell you if I find anything useful in this book, thanks again.";
	};
	["findBook_helper"]={
		Say="Where could the book be?"; 
		Face="Suspicious"; 
		Reply="Maybe it's upstairs somewhere, not sure...";
	};

	["post_findBook"]={
		Say="Found anything from the book yet?";
		Face="Confident"; 
		Reply="No, I will tell you when I do.";
	};

	["post_extrabook"]={
		Say="I found an extra blue book, do you want it?";
		Face="Confident"; 
		Reply="Sure! Some pages from my book is torn out so this would help..";
	};
};

if RunService:IsServer() then
	-- !outline: Stephanie Handler
	Dialogues.Stephanie.DialogueHandler = function(player, dialog, data, mission)
		local remotes = game.ReplicatedStorage:WaitForChild("Remotes");
		local remoteSetHeadIcon = remotes:WaitForChild("SetHeadIcon");
		
		local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 2 then -- Available;
			dialog:SetInitiate("Hey, have you seen an odd looking blue book?..");
			dialog:AddChoice("findBook_letMeHelp", function(dialog)
				modMission:StartMission(player, missionId, function(successful)
					if successful then
						task.delay(300, function()
							if not modMission:IsComplete(player, missionId) then
								remoteSetHeadIcon:FireClient(player, 1, "Stephanie", "Guide");
							end
						end)
					end
				end);
			end);
			
		elseif mission.Type == 1 then -- Active
			dialog:SetInitiateTag("findBook_found?");
			
			local item, storage = modStorage.FindItemIdFromStorages("oddbluebook", player);

			if item then
				remoteSetHeadIcon:FireClient(player, 0, "Stephanie", "Guide");
				dialog:AddChoice("findBook_foundBook", function(dialog)
					dialog:AddChoice("findBook_whatsInTheBook")
					storage:Remove(item.ID);
					modMission:CompleteMission(player, missionId);
				end);
				
			elseif (os.time()-mission.StartTime) > 300 then
				dialog:AddChoice("findBook_helper");
				
			end
			
		elseif mission.Type == 3 then
			local item, storage = modStorage.FindItemIdFromStorages("oddbluebook", player);

			if item then
				dialog:AddChoice("post_extrabook", function(dialog)
					storage:Remove(item.ID);
				end);
			end
			
		elseif mission.Type == 4 then -- Failed
			
		end
	end

end


return Dialogues;