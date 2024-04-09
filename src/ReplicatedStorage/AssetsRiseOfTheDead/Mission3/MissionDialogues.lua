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
Dialogues.Stephanie.Dialogues = function()
	return {
		{Tag="pre_findBook"; 
			Face="Suspicious"; Dialogue="Hello, I'm new here."; Reply="Ummm, okay."};

		{Tag="findBook_found?";
			Face="Suspicious"; Reply="Have you found the book yet?";};
		
		{Tag="findBook_letMeHelp"; CheckMission=missionId; Dialogue="Umm no, but I can help you find it."; 
			Face="Skeptical"; Reply="It's an odd looking blue book, please try to find it, it's important.";
			FailResponses = {
				{Reply="You're too new here, come back once you're more familiar with the place."};
			};
		};
		{Tag="findBook_foundBook"; Dialogue="Found it, here you go..."; 
			Face="Happy"; Reply="Thanks a lot!"};
		{Tag="findBook_whatsInTheBook"; Dialogue="What did you need this book for anyways?";
			Face="Surprise"; Reply="Well, this book might have information on how to build something better to get rid of the zombies. I will tell you if I find anything useful in this book, thanks again."};
		{Tag="findBook_helper"; Dialogue="Where could the book be?"; 
			Face="Suspicious"; Reply="Maybe it's upstairs somewhere, not sure..."};

		{Tag="post_findBook"; Dialogue="Found anything from the book yet?";
			Face="Confident"; Reply="No, I will tell you when I do."};
	};
end

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
			
			local mission = modMission:GetMission(player, missionId);
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
			
		elseif mission.Type == 4 then -- Failed
			
		end
	end

end


return Dialogues;
