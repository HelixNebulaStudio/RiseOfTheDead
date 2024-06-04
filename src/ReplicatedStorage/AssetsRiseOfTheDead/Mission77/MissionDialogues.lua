local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	["Mysterious Engineer"]={};
};

local missionId = 77;
local cache = {};

--==

-- !outline: Mysterious Engineer Dialogues
Dialogues["Mysterious Engineer"].Dialogues = function()
	return {
		{Tag="bofb_init";
			Face="Confident"; Reply="Oh, it's you again..";};

		{Tag="bofb_start"; Dialogue="So I found this piece of blueprint form the SunkenShip Chests. It says something about a turret, any clue about this?"; --CheckMission=missionId; 
			Face="Surprise"; Reply="Oh wow! You found a piece?! I have a piece too and I've been searching for weeks for the rest but couldn't find them."};
		{Tag="bofb_start2"; Dialogue="I could try to find the rest.";
			Face="Skeptical"; Reply="Hmmm alright.. Looking at your piece and mine, it seems we're just missing 3 other pieces. I think I know where the other pieces are.."};
		{Tag="bofb_start3"; Dialogue="Where?";
			Face="Serious"; Reply="Belly of the beast.. Hahah..\nI'm serious. I am 90% certain they are inside Elder Vexron."};
		{Tag="bofb_start4"; Dialogue="...";
			Face="Happy"; Reply="Well, do you want to enter the belly of the beast??"};

		{Tag="bofb_startNo"; Dialogue="Yeah... never mind.";
			Face="Happy"; Reply="Hahaha, understandable. I wouldn't want to go in that thing either."};
		{Tag="bofb_startYes"; Dialogue="You know what, I'll go.";
			Face="Surprise"; Reply="Wait, you serious?..\n\nIn that case, bring Vexlings, with those little vexs, it'll have a reason to swallow you. They eat their spawns for some reason. And also a gas mask!"};
		

		{Tag="bofb_1how"; Dialogue="Ummm.. So how do I get eaten by the Elder Vexeron again?";
			Face="Happy"; Reply="Bring Vexlings, it won't swallow you without it. And also a gas mask, it's literally toxic in there!"};
		
		{Tag="bofb_4init";
			Face="Confident"; Reply="I can't believe you actually did it..";};
		{Tag="bofb_4washed"; Dialogue="I managed to find these two pieces but that's all. I don't think the last piece is inside the Elder Vexeron.";
			Face="Surprise"; Reply="Hmmm.. The only other possible place may be on the seabed near shore.."};
		{Tag="bofb_4washed2"; Dialogue="Near the harbor?";
			Face="Surprise"; Reply="Yeah, so if you're going diving anytime soon, you can look for it."};

		{Tag="bofb_6init";
			Face="Surprise"; Reply="Could it actually be?..";};
		{Tag="bofb_6found"; Dialogue="I found the final piece of the blueprint.";
			Face="Confident"; Reply="Wow, these are schematics for an auto turret! Although, it's a bit primitive for me.. Hold on, I'll make some changes and redraft the blueprint for you. I'll keep a copy of course."};
		{Tag="bofb_6found2"; Dialogue="Sure.. *waits*";
			Face="Happy"; Reply="Alright, it is done! I call it the Portable Auto Turret."};
		{Tag="bofb_6found3"; Dialogue="Portable auto turret?..";
			Face="Happy"; Reply="That's right, you can wear it and mount a gun on it. Tinker it to your use case. Here you go.."};

		{Tag="bofb_6takeFail"; Dialogue="*Take Portable Auto Turret Blueprint* Wow, thanks!";
			Face="Happy"; Reply="Looks like you need to expand your storage."};
		{Tag="bofb_6take"; Dialogue="*Take Portable Auto Turret Blueprint* Wow, thanks!";
			Face="Happy"; Reply="*Rubs hands together* Hah.. There's so much more I can do with these schem--Oh you're still here..\nErr, you're welcome!"};
	};
end

if RunService:IsServer() then
	local modRichFormatter = require(game.ReplicatedStorage.Library.UI.RichFormatter);
	
	-- !outline: Mysterious Engineer Handler
	Dialogues["Mysterious Engineer"].DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		local playerSave = shared.modProfile:Get(player):GetActiveSave();

		local profile = shared.modProfile:Get(player);
		local inventory = profile.ActiveInventory;
		
		local blueprintDesc = modRichFormatter.H3Text("\nMission: ").."Ask the Mysterious Engineer about this.";
		local itemsList = inventory:ListByItemId("blueprintpiece", function(storageItem)
			return storageItem:GetCustomName() == "Turret Blueprint Piece" or storageItem:GetValues("DescExtend") == blueprintDesc;
		end);
		
		if mission.Type == 2 and #itemsList > 0 then -- Available;
			dialog:SetInitiateTag("bofb_init");
			
			dialog:AddChoice("bofb_start", function(dialog)
				dialog:AddChoice("bofb_start2", function(dialog)
					dialog:AddChoice("bofb_start3", function(dialog)
						dialog:AddChoice("bofb_start4", function(dialog)
							
							dialog:AddChoice("bofb_startNo");
							dialog:AddChoice("bofb_startYes", function(dialog)
								
								for a=1, #itemsList do
									inventory:Remove(itemsList[a].ID);
								end
								
								modMission:StartMission(player, missionId);
							end)
							
						end)
					end)
				end)
			end)
			
			
		elseif mission.Type == 1 then -- Active
			if mission.ProgressionPoint == 1 then
				dialog:AddChoice("bofb_1how");
				
			elseif mission.ProgressionPoint == 4 then
				dialog:SetInitiateTag("bofb_4init");

				dialog:AddChoice("bofb_4washed", function(dialog)
					dialog:AddChoice("bofb_4washed2", function(dialog)

						local itemsList = inventory:ListByItemId("blueprintpiece", function(storageItem)
							return storageItem:GetCustomName() == "Turret Blueprint Piece" or storageItem:GetValues("DescExtend") == blueprintDesc;
						end);
						
						modMission:Progress(player, missionId, function(mission)
							if mission.ProgressionPoint <= 5 then
								mission.ProgressionPoint = 5;
							end
						end);

						for a=1, #itemsList do
							inventory:Remove(itemsList[a].ID);
						end
					end)
				end)
				
			elseif mission.ProgressionPoint == 6 then
				dialog:SetInitiateTag("bofb_6init");

				dialog:AddChoice("bofb_6found", function(dialog)
					dialog:AddChoice("bofb_6found2", function(dialog)
						dialog:AddChoice("bofb_6found3", function(dialog)
							local hasSpace = inventory:SpaceCheck{{ItemId="portableautoturretbp"}};
							if not hasSpace then
								dialog:AddChoice("bofb_6takeFail")
								
							else
								dialog:AddChoice("bofb_6take", function(dialog)
									local itemsList = inventory:ListByItemId("blueprintpiece", function(storageItem)
										return string.find(storageItem.CustomName, "Turret Blueprint Piece") ~= nil;
									end);
									for a=1, #itemsList do
										inventory:Remove(itemsList[a].ID);
									end
									
									inventory:Add("portableautoturretbp");
									
									modMission:CompleteMission(player, missionId);
								end)
								
							end
							
						end)
					end)
				end)
			end
			
		elseif mission.Type == 3 then -- Complete

			if itemsList and #itemsList > 0 then
				dialog:AddDialog({
					Face="Serious";
					Dialogue="I found some extra blueprint pieces, and I don't need them..";
					Reply="I'll take those off your hands, thanks!";
				}, function(dialog)
					for a=1, #itemsList do
						inventory:Remove(itemsList[a].ID);
					end
				end)
			end

		elseif mission.Type == 4 then -- Failed
			
		end
	end

end


return Dialogues;