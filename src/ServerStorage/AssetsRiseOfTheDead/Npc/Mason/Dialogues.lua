local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Face=nil;
		Reply="Hey, you're looking well, need help?";
	};
	["init2"]={
		Face=nil;
		Reply="Hmm, Yes? Do you need some help?";
	};
	["init3"]={
		Face=nil;
		Reply="What a ###### mess... OH hey, what do you need help with?";
	};
	["init4"]={
		Face=nil;
		Reply="How may I help you hmm?";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
	["general_what"]={
		Say="What should I do now?"; 
		Reply="Look around and see if anyone needs help.";
		ReturnToInit=true;
	};
	["general_where"]={
		Say="Where should I go now?"; 
		Reply="I heard there's other safehouses, maybe if you could find them, we could set up a network somehow...";
		ReturnToInit=true;
	};
	["general_how"]={
		Say="How's the car?"; 
		Reply="I'm still trying to fix it, but I'm afraid we're missing some components.";
		ReturnToInit=true;
	};

	-- Guide
	["guide_refillAmmo"]={
		Face="Joyful";
		Say="How do I buy ammo for my weapons?"; 
		Reply="Go to the shop and pick your weapon that you want refilled.";
		ReturnToInit=true;
	};
	["guide_getWeapon"]={
		Face="Happy";
		Say="How do I get new weapons?";
		Reply="The shop sells blueprints for building weapons.";
		ReturnToInit=true;
	};
	["guide_levelUp"]={
		Face="Joyful";
		Say="How do I level up?"; 
		Reply="Kill zombies to level up your weapons and you will level up your mastery level.";
		ReturnToInit=true;
	};
	["guide_getPerks"]={
		Face="Happy";
		Say="How do I get perks?"; 
		Reply="Complete missions, farm zombies or level up weapons. Every 5 level ups, rewards you 10 perks.";
		ReturnToInit=true;
	};
	["guide_invSpace"]={
		Face="Welp";
		Say="How to get more space in my inventory?";
		Reply="You can't, however every safehouse has a storage and you can store your excess items there.";
		ReturnToInit=true;
	};
	["guide_makeMoney"]={
		Face="Happy";
		Say="How to earn money?";
		Reply="You can sell things to the shop for pocket change, but if you really want to earn, you can sell commodity items. Commodity items are usually crafted from a blueprint obtain from bosses.";
		ReturnToInit=true;
	};
	["guide_getMaterials"]={
		Face="Skeptical";
		Say="Where do I find materials I need for building?";
		Reply="You can use the \"/item [itemName]\" command to know where to obtain an item from. For example, try typing this in chat /item Boombox";
		ReturnToInit=true;
	};

	-- Guide Safehome
	["guide_safehomeNpcs"]={
		Face="Confident";
		Say="Where do I look for survivors?"; 
		Reply="Some might stumble upon this place, or I could look for some. But first, this place needs to be sustainable..";
		ReturnToInit=true;
	};
	["guide_safehomeSustain"]={
		Face="Confident";
		Say="How do I make this place sustainable?";
		Reply="Make sure you got food, there should be a freezer somewhere, keep some food there.. As long as you have enough food to feed everyone everyday, you should be good. (1 food per survivor daily)";
		ReturnToInit=true;
	};
};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
		local modEvents = require(game.ServerScriptService.ServerLibrary.Events);
		local modStorage = require(game.ServerScriptService.ServerLibrary.Storage); 
		
		local remotes = game.ReplicatedStorage:WaitForChild("Remotes");
		local remoteSetHeadIcon = remotes:WaitForChild("SetHeadIcon");

		local npcName = dialog.Name;
		local npcModule = dialog:GetNpcModule();
	
		local activeMissionCount = #modMission:GetNpcMissions(player, npcName);
		local profile = shared.modProfile:Get(player);
		local playerSave = profile:GetActiveSave();
	
		local perkCupcakes = modEvents:GetEvent(player, "perkCupcakes");
		
		if perkCupcakes and perkCupcakes.Remaining > 0 then
			local dialogPacket = {
				Face="Happy";
				Say="Can I have a cupcake?";
			}
	
			local inventory = playerSave.Inventory;
			local hasSpace = inventory:SpaceCheck{
				{ItemId="perkscupcake"; Data={Quantity=1}; };
			};
	
			if hasSpace then
				dialogPacket.Reply="Sure, here you go.";
				
			else
				dialogPacket.Reply="You're going to need more space in your inventory.";
				
			end
			
			dialog:AddDialog(dialogPacket, function(dialog)
				if not hasSpace then return end;
				
				inventory:Add("perkscupcake", {Quantity=1;}, function(queueEvent, storageItem)
					modStorage.OnItemSourced:Fire(nil, storageItem,  storageItem.Quantity);
				end);
	
				perkCupcakes.Remaining = perkCupcakes.Remaining -1;
				shared.Notify(player, "You recieved a Perks Cupcake from Mason. Remaining: "..(perkCupcakes.Remaining), "Reward");
	
				modEvents:NewEvent(player, perkCupcakes);
			end);
		end
	
		local hardhatsilver = modEvents:GetEvent(player, "freeHardhatsilver");
		Debugger:StudioLog("Mason activemission count ", activeMissionCount);
		if hardhatsilver == nil and profile.GamePass.DbTinker and activeMissionCount <= 0 then
			dialog:SetInitiate("Hey $PlayerName, I have something for you.");
	
			local dialogPacket = {
				Face="Happy";
				Say="What is it?";
			}
	
			local inventory = playerSave.Inventory;
			local hasSpace = inventory:SpaceCheck{
				{ItemId="hardhatsilver"; Data={Quantity=1}; };
			};
	
			if hasSpace then
				dialogPacket.Reply="Sure, here you go.";
			else
				dialogPacket.Reply="You're going to need more space in your inventory.";
			end
	
			dialog:AddDialog(dialogPacket, function(dialog)
				if not hasSpace then return end;
	
				inventory:Add("hardhatsilver", {Quantity=1;}, function(queueEvent, storageItem)
					modStorage.OnItemSourced:Fire(nil, storageItem,  storageItem.Quantity);
				end);
				shared.Notify(player, "You recieved a Hard Hat Silver from Mason for unlocking Tinkering Commands achievement.", "Reward");
				modEvents:NewEvent(player, {Id="freeHardhatsilver"});
			end);
		end
		
		if modMission:Progress(player, 54) then return end;
		if modMission:IsComplete(player, 2) then
			
			if modBranchConfigs.IsWorld("Safehome") then
				if modMission:IsComplete(player, 54) then
					dialog:AddChoice("guide_safehomeNpcs");
					dialog:AddChoice("guide_safehomeSustain");
	
					if activeMissionCount <= 0 then 
						remoteSetHeadIcon:FireClient(player, 1, npcName, "Guide");
					end
				end
				
			else
				dialog:AddChoice("general_what");
				dialog:AddChoice("general_where");
				dialog:AddChoice("general_how");
				
				dialog:AddChoice("guide_refillAmmo");
				dialog:AddChoice("guide_makeMoney");
				dialog:AddChoice("guide_getWeapon");
				dialog:AddChoice("guide_getPerks");
				dialog:AddChoice("guide_invSpace");
				dialog:AddChoice("guide_getMaterials");
				dialog:AddChoice("guide_levelUp");
	
				if activeMissionCount <= 0 then 
					remoteSetHeadIcon:FireClient(player, 1, npcName, "Guide");
				end;
			end
			
		end
		
		if npcModule.CarLooping then
			dialog:SetExpireTime(workspace:GetServerTimeNow()+10);
		end
	end
	
end

return Dialogues;