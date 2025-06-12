local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");
local RunService = game:GetService("RunService");

local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

local Dialogues = {};
--==

-- MARK: PromptProfile
Dialogues.PromptProfile = {
	World=[[
	I'm held up in a safehouse called "The Warehouse".
	It's a old carshop warehouse with red brick walls.
	It is completely fenced off from the outside and is pretty safe inside.
	]];
	Role=[[
	I am a Survivor.
	I am a 38 year old mid-western man who was a pawn shop owner and mechanics as a hobby.
	I have good faith morals and well tempered.
	I am confident, patient and trust worthy.
	I am the main scavenger for my group.
	I am trying to fix up a car that broke down after I rescued $PlayerName from the exploding Wrighton Dale East bridge.
	I am light hearted and am generally serious even in silly situations, and won't get involved.
	I may utter a short joke if the situation is wholesome. 
	]];
	Appear=[[
	I have really dark blue hair and a brown beard.
	I wear a leather jacket and a belt.
	I have a Revolver454 holstered and a M4A4 straped to my back.
	My M4A4 is pretty rusty and not as reliable as my revolver.
	]];
	Relations=[[
	I rescued $PlayerName lying unconscious on the bridge during a scout.
	After rescuing $PlayerName and getting the car working from the bridge, I drove back to the safehouse.
	Unfortunately, the car broke down and now I'm figuring out how to fix it.
	$PlayerName seem to not quite remember what happened before then, thus I'm more likely to trust them as they have no pre-existing intensions.
	I raided the Factory with $PlayerName to scavenge for food.
	I know Dr. Deniski since the start of the apocalypse. He patched me up when we first stumble onto this safehouse. He is a medic and seems to be really good at medical research.
	I know Stephanie because she was a frequent customer in my pawn shop. I let her stay in the safehouse when she broke into our safehouse looking for shelter.
	Nick is a really social person, without him around, there will be noone here to settle arguements.
	I know Russell the least, he is quite reserved and but Stephanie vouches for him.
	Jesse is a R.A.T. member and they are known to be non-hostile and has a vendor shop in the safehouse.
	]];
};

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
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
		local modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);
		local modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage); 
		
		local remotes = game.ReplicatedStorage:WaitForChild("Remotes");
		local remoteSetHeadIcon = remotes:WaitForChild("SetHeadIcon");

		local npcName = dialog.Name;
		local npcModule = dialog:GetNpcModule();
		local npcClass: NpcClass = dialog:GetNpcClass();
	
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
				Say="<b>[Tinkering Commands]</b> What is it?";
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
		
		if modBranchConfigs.CurrentBranch.Name == "Dev" then
			local function addDialog(say, reply, func)
				dialog:AddDialog({
					Say=say;
					Reply=reply;
				}, func);
			end

			addDialog("Equip revolver454", "Okie dokie", function(dialog)
				local wieldComp: WieldComp = npcClass.WieldComp;
				if wieldComp == nil then
					Debugger:Warn(`Missing wield comp`);
					return;
				end

				wieldComp:Equip({
					ItemId = "revolver454";
					OnSuccessFunc = function(toolHandler: ToolHandlerInstance)
						if toolHandler.EquipmentClass == nil then return end;
						local equipmentClass: EquipmentClass = toolHandler.EquipmentClass;

						local modifier: ConfigModifier = equipmentClass.Configurations.newModifier("npcDmg");
						modifier.SetValues.Damage = 25;
						modifier.Priority = 999;
						equipmentClass.Configurations:AddModifier(modifier, true);
					end;
				});
			end)

			addDialog("Equip boombox and use", "Okie dokie", function(dialog)
				local wieldComp: WieldComp = npcClass.WieldComp;
				if wieldComp == nil then
					Debugger:Warn(`Missing wield comp`);
					return;
				end

				wieldComp:Equip({
					ItemId = "boombox";
					OnSuccessFunc = function(toolHandler: ToolHandlerInstance)
						if toolHandler.EquipmentClass == nil then return end;
						
						wieldComp:InvokeToolAction(
							"ActionEvent",
							{ActionIndex=1; IsActive=true;}
						);
					end;
				});
			end)
			
			if npcClass.Properties.IsProtectActive then
		addDialog("Stand down", "Okie dokie", function(dialog)
			npcClass.Properties.IsProtectActive = nil;
		end)

			else
		addDialog("Stay alert for Zombies", "Okie dokie", function(dialog)
			local wieldComp: WieldComp = npcClass.WieldComp;

			if npcClass.Owner ~= player then
				npcClass.Owner = player;
				Debugger:StudioWarn(`Set owner for {npcName}`);
			end

			local protectOwnerComp = npcClass:GetComponent("ProtectOwner");
			if protectOwnerComp then
				Debugger:Warn(`Activate protect owner`);
				protectOwnerComp:Activate();
				return;
			end
			
			local targetHandlerComp = npcClass:GetComponent("TargetHandler");

			if wieldComp.ItemId == nil then
				Debugger:Warn(`No gun equipped`);
				return;
			end


			npcClass.Properties.IsProtectActive = true;

			local tagInstanceConn;
			tagInstanceConn = CollectionService:GetInstanceAddedSignal("DummyZombie"):Connect(function(model)
				if npcClass.Properties.IsProtectActive ~= true and tagInstanceConn then
					tagInstanceConn:Disconnect();
					tagInstanceConn = nil;
					return;
				end

				targetHandlerComp:AddTarget(model);
			end)
			local dumZombiesList = CollectionService:GetTagged("DummyZombie");
			for a=1, #dumZombiesList do
				targetHandlerComp:AddTarget(dumZombiesList[a]);
			end

			task.spawn(function()
				while npcClass.Properties.IsProtectActive == true do
					task.wait(0.1);

					local activeTarget = targetHandlerComp:MatchFirstTarget(function(targetData)
						if targetData.HealthComp == nil then return end;
						local targetNpcClass: NpcClass = targetData.HealthComp.CompOwner;
						
						return targetNpcClass.HumanoidType == "Zombie" and targetData.HealthComp.IsDead == false;
					end);

					if activeTarget then
						if activeTarget and activeTarget.HealthComp then
							Debugger:StudioLog(`Active target=`, activeTarget, activeTarget.HealthComp.IsDead, activeTarget.SortValue);
						else
							Debugger:StudioLog(`Active target=`, activeTarget);
						end

						local equipmentClass: EquipmentClassRotd = wieldComp.EquipmentClass :: EquipmentClassRotd;
						if equipmentClass.Properties.Ammo <= 0 then
							Debugger:Warn(`Out of ammo`, equipmentClass.Properties.Ammo);

							wieldComp:InvokeToolAction(
								"ReloadRequest"
							);
						end

						local healthComp: HealthComp = activeTarget.HealthComp;
						local enemyNpcClass: NpcClass = healthComp.CompOwner;

						npcClass.Move:HeadTrack(enemyNpcClass.RootPart, 2);
						npcClass.Move:Face(enemyNpcClass.RootPart.Position);

						local shootDirection = (enemyNpcClass.RootPart.Position - npcClass.RootPart.Position).Unit;
						
						wieldComp:InvokeToolAction(
							"PrimaryFireRequest", 
							shootDirection, 
							enemyNpcClass.Humanoid
						);
					end

				end
			end)
		end)
			end
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
			dialog:SetExpireTime(workspace:GetServerTimeNow()+60);
		end
	end
	
end

return Dialogues;