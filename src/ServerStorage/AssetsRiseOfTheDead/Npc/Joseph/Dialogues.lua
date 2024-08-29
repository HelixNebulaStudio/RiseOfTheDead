local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="These crops can keep us going for years.";
	};
	["init2"]={
		Reply="Christ.. I forgot to water the crops..";
	};
	["init3"]={
		Reply="One step closer to becoming self sustainable..";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
	["heal_request"]={
		Face="Confident";
		Say="Can you heal me please?";
		Reply="Cmon' closer and I'll patch you up.";
	};
};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
		local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
		
		if modBranchConfigs.IsWorld("TheInvestigation") then return end;
		dialog:AddChoice("heal_request", function()
			if not dialog.InRange() then return end;
			modStatusEffects.FullHeal(player, 0.1);
			modOnGameEvents:Fire("OnMedicHeal", player, dialog.Name);
		end)
	
		if #modMission:GetNpcMissions(player, script.Name) > 0 then
			Debugger:Warn("Joseph has missions");
			return
		end;
		
		if modMission:GetMission(player, 64) == nil then
			--== Joseph's Crossbow
			local profile = shared.modProfile:Get(player);
	
			local playerSave = profile:GetActiveSave();
			local playerLevel = playerSave:GetStat("Level") or 0;
	
			if playerLevel >= 500 then
				dialog:InitDialog{
					Reply="If you ever come across a crossbow, please show it to me.";
					Face="Suspicious";
				}
	
				local isCrossBow = false;
				if profile.EquippedTools.WeaponModels == nil then return end;
	
				for a=1, #profile.EquippedTools.WeaponModels do
					if profile.EquippedTools.WeaponModels[a]:IsA("Model") and profile.EquippedTools.WeaponModels[a]:GetAttribute("ItemId") == "arelshiftcross" then
						isCrossBow = true;
						break;
	
					end
				end
	
				if isCrossBow then
					dialog:AddChoice("josephcrossbow_try", function(dialog)
						modMission:StartMission(player, 64);
					end)
				end
			end
		end
	end

	-- MARK: EquipmentDialogueHandler
	Dialogues.EquipmentDialogueHandler = function(player, dialog, data)
		local itemId = dialog.EquippedTools.ItemId;

		if itemId == "fotlcardgame" then
			local modCardGame = require(game.ReplicatedStorage.Library.CardGame);
			
			local function StartCardGame(dialog)
				local npcPrefab = dialog.Prefab;
				
				local cardGameLobby = modCardGame.NewLobby(npcPrefab);
				local npcTable = cardGameLobby:GetPlayer(npcPrefab);
	
				local npcModule = dialog:GetNpcModule();
	
	
				local npcQuips = {
					CaughtNotBluffing = {
						"Nice try kiddo.";
						"Did it looked like a bluff?";
					};
					CaughtBluffing = {
						"Haha, what was my tell?";
						"How did you tell?";
					};
					CardLoss = {
						"Darnit";
						"Owell";
					};
					FailAccuse = {
						"Looks like I made a miscalculation here";
						"I must've missed something..";
						"Hmmmm";
					};
					CallBluff = {
						"Haha, something tells me you're bluffing..";
						"I smell a bluff..";
						"I'd laugh if you aren't bluffing.";
					};
					PlayerDefeated = {
						"Good game, $PlayerName";
						"Want a rematch? $PlayerName";
					};
				};
	
				local function cardGameQuips(quipType, param)
					param = param or {};
	
					local quipsList = npcQuips[quipType];
					if quipsList == nil then return end;
	
					local pickQuip = quipsList[math.random(1, #quipsList)];
					pickQuip = string.gsub(pickQuip, "$PlayerName", (param.PlayerName or "pal"));
	
					npcModule.Chat(game.Players:GetPlayers(), pickQuip);
				end
	
				-- MARK: Cooper Fotl Agent
				npcTable.ComputerAutoPlay = modCardGame.NewComputerAgentFunc(npcPrefab, cardGameLobby, {
					BluffChance=0.5;
					CheatChance=0.5;
					Actions = {
						Scavenge = {Genuine=0.3;};
						RogueAttack = {CallBluff=0.75; Genuine=0.5; Bluff=0.5;};
						BanditRaid = {CallBluff=0.7; Genuine=0.8; Bluff=0.3;};
						RatSmuggle = {CallBluff=0.6; Genuine=0.7; Bluff=0.4;};
						BioXSwap = {CallBluff=0.5; Genuine=0.5; Bluff=0.5;};
						ZombieBlock = {CallBluff=0.4; Bluff=0.5;};
					};
					OnCaughtNotBluffing=function()
						cardGameQuips("CaughtNotBluffing");
					end;
					OnCaughtBluffing=function()
						cardGameQuips("CaughtBluffing");
					end;
					OnCardLoss=function()
						cardGameQuips("CardLoss");
					end;
					OnCallBluff=function()
						cardGameQuips("CallBluff");
					end;
					OnFailAccuse=function()
						cardGameQuips("FailAccuse");
					end;
					OnPlayerDefeated=function(defeatedPlayer)
						cardGameQuips("CardLoss", {
							PlayerName=defeatedPlayer and defeatedPlayer.Name;
						});
					end;
				});
	
	
				cardGameLobby:Join(player, true);
				cardGameLobby:Start();
	
				dialog:SetExpireTime(workspace:GetServerTimeNow()+2);
			end
	
			dialog:SetInitiate("Heh, Fall of the Living? I used to play that a lot.", "Smirk");

			dialog:AddDialog({
				Face="Smirk";
				Say="Let's play Fall of the Living?";
				Reply="Sure *Hands you two cards*";
				
			}, StartCardGame);
		end
	end
	
end

return Dialogues;