local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	["Mysterious Engineer"]={};
};

local MISSION_ID = 77;
--==

-- !outline: Mysterious Engineer Dialogues
Dialogues["Mysterious Engineer"].DialogueStrings = {
	["bofb_init"]={
		Face="Confident"; 
		Reply="Oh, it's you again..";
	};

	["bofb_start"]={
		Say="So I found this piece of blueprint form the SunkenShip Chests. It says something about a turret, any clue about this?";
		Face="Surprise"; Reply="Oh wow! You found a piece?! I have a piece too and I've been searching for weeks for the rest but couldn't find them.";
	};
	["bofb_start2"]={
		Say="I could try to find the rest.";
		Face="Skeptical"; 
		Reply="Hmmm alright.. Looking at your piece and mine, it seems we're just missing 3 other pieces. I think I know where the other pieces are..";
	};
	["bofb_start3"]={
		Say="Where?";
		Face="Serious"; 
		Reply="Belly of the beast.. Hahah..\nI'm serious. I am 90% certain they are inside Elder Vexron.";
	};
	["bofb_start4"]={
		Say="...";
		Face="Happy"; 
		Reply="Well, do you want to enter the belly of the beast??";
	};

	["bofb_startNo"]={
		Say="Yeah... never mind.";
		Face="Happy"; 
		Reply="Hahaha, understandable. I wouldn't want to go in that thing either.";
	};
	["bofb_startYes"]={
		Say="You know what, I'll go.";
		Face="Surprise";
		Reply="Wait, you serious?..\n\nIn that case, bring Vexlings, with those little vexs, it'll have a reason to swallow you. They eat their spawns for some reason. And also a gas mask!";
	};
	

	["bofb_1how"]={
		Say="Ummm.. So how do I get eaten by the Elder Vexeron again?";
		Face="Happy"; 
		Reply="Bring Vexlings, it won't swallow you without it. And also a gas mask, it's literally toxic in there!";
	};
	
	["bofb_4init"]={
		Face="Confident"; 
		Reply="I can't believe you actually did it..";
	};
	["bofb_4washed"]={
		Say="I managed to find these two pieces but that's all. I don't think the last piece is inside the Elder Vexeron.";
		Face="Surprise"; 
		Reply="Hmmm.. The only other possible place may be on the seabed near shore..";
	};
	["bofb_4washed2"]={
		Say="Near the harbor?";
		Face="Surprise"; 
		Reply="Yeah, so if you're going diving anytime soon, you can look for it.";
	};

	["bofb_6init"]={
		Face="Surprise"; 
		Reply="Could it actually be?..";
	};
	["bofb_6found"]={
		Say="I found the final piece of the blueprint.";
		Face="Confident"; 
		Reply="Wow, these are schematics for an auto turret! Although, it's a bit primitive for me.. Hold on, I'll make some changes and redraft the blueprint for you. I'll keep a copy of course.";
	};
	["bofb_6found2"]={
		Say="Sure.. *waits*";
		Face="Happy"; 
		Reply="Alright, it is done! I call it the Portable Auto Turret.";
	};
	["bofb_6found3"]={
		Say="Portable auto turret?..";
		Face="Happy"; 
		Reply="That's right, you can wear it and mount a gun on it. Tinker it to your use case. Here you go..";
	};

	["bofb_6takeFail"]={
		Say="*Take Portable Auto Turret Blueprint* Wow, thanks!";
		Face="Happy"; 
		Reply="Looks like you need to expand your storage.";
	};
	["bofb_6take"]={
		Say="*Take Portable Auto Turret Blueprint* Wow, thanks!";
		Face="Happy"; 
		Reply="*Rubs hands together* Hah.. There's so much more I can do with these schem--Oh you're still here..\nErr, you're welcome!";
	};

	["bofb_hint"]={
		Say="Why do you have so many SunkenShip Chests?";
		Face="Confident"; 
		Reply="I have a fish catching machine, sometimes it devours random chests it finds. I've opened a bunch of them before, but they're mostly junk to me. If you do find something interesting, let me know!";
	}
};

if RunService:IsServer() then
	local modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);
	local modRichFormatter = shared.require(game.ReplicatedStorage.Library.UI.RichFormatter);
	
	-- !outline: Mysterious Engineer Handler
	Dialogues["Mysterious Engineer"].DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);


		local profile = shared.modProfile:Get(player);
		local inventory = profile.ActiveInventory;
		
		local bpPiecesDesc = modRichFormatter.H3Text("\nMission: ").."Ask the Mysterious Engineer about this.";
		local bp2PiecesDesc = modRichFormatter.H3Text("\nMission: ").."There only seem to be two pieces of the blueprint inside Elder Vexeron.";
		local blueprintFinalDesc = modRichFormatter.H3Text("\nMission: ").."Finally, now the Mysterious Engineer can help make something out of these schematics.";

		local itemsList = inventory:ListByItemId("blueprintpiece", function(storageItem)
			local customName = storageItem:GetCustomName();
			local extendedDesc = storageItem:GetValues("DescExtend");

			return customName == "Turret Blueprint Piece" 
				or customName == "Turret Blueprint Piece 1/2"
				or customName == "Turret Blueprint Piece 2/2"
				or customName == "Final Turret Blueprint Piece"
				or extendedDesc == bpPiecesDesc
				or extendedDesc == bp2PiecesDesc
				or extendedDesc == blueprintFinalDesc;
		end);
		
		if mission.Type == 2 then -- Available;
			if #itemsList > 0 then
				dialog:SetInitiateTag("bofb_init");
				
				dialog:AddChoice("bofb_start", function(dialog)
					dialog:AddChoice("bofb_start2", function(dialog)
						dialog:AddChoice("bofb_start3", function(dialog)
							dialog:AddChoice("bofb_start4", function(dialog)
								
								dialog:AddChoice("bofb_startNo");
								dialog:AddChoice("bofb_startYes", function(dialog)
									
									for a=1, #itemsList do
										inventory:Remove(itemsList[a].ID);
										shared.Notify(player, `{itemsList[a]:GetCustomName() or itemsList[a].Library.Name} was removed from your Inventory.`, `Negative`);
									end
									
									modMission:StartMission(player, MISSION_ID);
								end)
								
							end)
						end)
					end)
				end)

			elseif modEvents:GetEvent(player, "freeDivingSuit") then
				dialog:AddChoice("bofb_hint");

			end
			
			
		elseif mission.Type == 1 then -- Active
			if mission.ProgressionPoint == 1 then
				dialog:AddChoice("bofb_1how");
				
			elseif mission.ProgressionPoint == 4 then
				dialog:SetInitiateTag("bofb_4init");

				dialog:AddChoice("bofb_4washed", function(dialog)
					dialog:AddChoice("bofb_4washed2", function(dialog)
						modMission:Progress(player, MISSION_ID, function(mission)
							if mission.ProgressionPoint <= 5 then
								mission.ProgressionPoint = 5;
							end
						end);

						for a=1, #itemsList do
							inventory:Remove(itemsList[a].ID);
							shared.Notify(player, `{itemsList[a]:GetCustomName() or itemsList[a].Library.Name} was removed from your Inventory.`, `Negative`);
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
									for a=1, #itemsList do
										inventory:Remove(itemsList[a].ID);
										shared.Notify(player, `{itemsList[a]:GetCustomName() or itemsList[a].Library.Name} was removed from your Inventory.`, `Negative`);
									end
									
									inventory:Add("portableautoturretbp");
									shared.Notify(player, `Portable Auto Turret Blueprint was added to your Inventory.`, `Inform`);
									
									modMission:CompleteMission(player, MISSION_ID);
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
					Say="I found some extra blueprint pieces, and I don't need them..";
					Reply="I'll take those off your hands, thanks!";
				}, function(dialog)
					for a=1, #itemsList do
						inventory:Remove(itemsList[a].ID);
						shared.Notify(player, `{itemsList[a]:GetCustomName() or itemsList[a].Library.Name} was removed from your Inventory.`, `Negative`);
					end
				end)
			end

		elseif mission.Type == 4 then -- Failed
			
		end
	end

end


return Dialogues;