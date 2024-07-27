local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Stan={};
	Patrick={};
};

local missionId = 30;
--==

-- MARK: Stan Dialogues
Dialogues.Stan.Dialogues = function()
	return {			
		{CheckMission=missionId; Tag="pokeTheBear_who"; Face="Suspicious";
			Dialogue="Woah, careful with that thing, I'm just another scavenger. My name's $PlayerName."; 
			Reply="*Exhales with relief* Hm, okay. Sooo, whatchu want?"};

		{Tag="pokeTheBear_help"; Face="Suspicious";
			Dialogue="I need help, I think the bandits kidnapped a friend of mine.";
			Reply="Those bandits.. They attacked my safehouse too. You know what, I'll help you if you help us."};

		{Tag="pokeTheBear_sure"; Face="Happy";
			Dialogue="Alright, what do you need help with?";
			Reply="We'll pay those bandits a visit."};
			
		{Tag="pokeTheBear_mall"; Face="Confident";
			Dialogue="I'm ready.";
			Reply="Alright, let's go."};
		
		{Tag="pokeTheBear_mallInfo"; Face="Grumpy";
			Dialogue="Oh, where's the Bandit Camp?";
			Reply="It's on the top floor, let's go."};
		
		{Tag="pokeTheBear_wait"; Face="Suspicious";
			Dialogue="He will figure out a way to let us in.. But we'll have to wait.";
			Reply="Fine.. I'll head back, you take care."};
			
	};
end

-- MARK: Patrick Dialogues
Dialogues.Patrick.Dialogues = function()
	return {			
	
		{Tag="pokeTheBear_start"; Face="Angry";
			Dialogue="I really need to speak to your leader, you kidnapped our people!";
			Reply="I don't care, you weaklings will probably die out sooner on your own!"};
	
		{Tag="pokeTheBear_A1"; Face="Bored";
			Dialogue="You kidnapped our friend and I will fight to rescue him!";
			Reply="You're up against an army of people buddy, your death would be fast and swift."};
		
		{Tag="pokeTheBear_A2"; Face="Sad";
			Dialogue="How could you do this?! Where's your humanity?";
			Reply="Look, the world has gone down the toilet, everybody's just doing whatever to survive."};
		
		{Tag="pokeTheBear_A3"; Face="Frustrated";
			Dialogue="We're also doing whatever to survive, but you don't see us kidnapping anyone!";
			Reply="Hey, I don't tell you how to survive, so don't tell me how to survive."};
		
		{Tag="pokeTheBear_P1"; Face="Skeptical";
			Dialogue="But why did you kidnap our friend?";
			Reply="Look, I don't know what and why our leader kidnapped who. They put food on the table and that's all it matters to me."};
		
		{Tag="pokeTheBear_P2"; Face="Grumpy";
			Dialogue="You don't need to do this to get food..";
			Reply="Hey, I don't tell you how to find your food, so don't tell me how I should find mine."};
			
		{Tag="pokeTheBear_bribe"; Face="Skeptical";
			Dialogue="Look, what can I do to talk to your leader?";
			Reply="Hmmm.. You know what, get me some food and I will secretly let you in.."};
		
		
		
		{Tag="pokeTheBear_beans1"; Face="Joyful";
			Dialogue="*Give 1 can of Canned Beans*";
			Reply="Alright, this is the good stuff.. Come back later, I can't let you in right now. I'll let you know when I can."};
			
		{Tag="pokeTheBear_beans2"; Face="Joyful";
			Dialogue="*Give 2 can of Canned Beans*";
			Reply="Great. This is the good stuff.. Come back later, I can't let you in right now. I'll let you know when I can."};
			
		{Tag="pokeTheBear_beans3"; Face="Joyful";
			Dialogue="*Give 3 can of Canned Beans*";
			Reply="Amazing! This is the good stuff.. Come back later, I can't let you in right now. I'll let you know when I can."};
		
	};
end


if RunService:IsServer() then
	-- MARK: Stan Handler
	Dialogues.Stan.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 2 then -- Available
			dialog:SetInitiate("Yo! Stop right there.. Who are you?", "Angry");
			dialog:AddChoice("pokeTheBear_who", function(dialog)
				dialog:AddChoice("pokeTheBear_help", function(dialog)
					dialog:AddChoice("pokeTheBear_sure", function(dialog)
						modMission:StartMission(player, missionId);
					end)
				end)
			end)
			
		elseif mission.Type == 1 then -- Active
			if mission.ProgressionPoint == 2 then
				dialog:SetInitiate("We're going to the Wrighton Dale Mall, I heard the Bandits set up camp there. They took over the place. You ready?", "Confident");
				dialog:AddChoice("pokeTheBear_mall", function(dialog)
					modMission:Progress(player, missionId, function(mission)
						if mission.ProgressionPoint <= 2 then
							mission.ProgressionPoint = 3;
						end;
					end)
				end);
				
			elseif mission.ProgressionPoint == 4 then
				dialog:SetInitiate("Welcome to the Wrighton Dale Mall.. If the apocalypse didn't happen, the mall would've been completed by now.", "Sad");
				dialog:AddChoice("pokeTheBear_mallInfo", function(dialog)
					modMission:Progress(player, missionId, function(mission)
						if mission.ProgressionPoint <= 4 then
							mission.ProgressionPoint = 5;
						end;
					end)
				end);
				
			elseif mission.ProgressionPoint == 9 then
				dialog:SetInitiate("Is he going to let us in?", "Joyful");
				dialog:AddChoice("pokeTheBear_wait", function(dialog)
					modMission:Progress(player, missionId, function(mission)
						if mission.ProgressionPoint <= 9 then
							mission.ProgressionPoint = 10;
						end;
					end)
				end);
			end
			
		end
	end

	
	-- MARK: Patrick Handler
	Dialogues.Patrick.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			if mission.ProgressionPoint == 7 then
				dialog:SetInitiate("What do you want?!", "Angry");
				dialog:AddChoice("pokeTheBear_start", function(dialog)
					local function bribe(dialog, isAggressive)
						dialog:AddChoice("pokeTheBear_bribe", function(dialog)
							
							data:Set("pokeTheBeat_isAggressive", isAggressive == true);
							modMission:Progress(player, missionId, function(mission)
								if mission.ProgressionPoint <= 7 then
									mission.ProgressionPoint = 8;
								end;
							end)
						end);
					end
					
					data:Set("pokeTheBear_A", 1);
					data:Set("pokeTheBear_P", 1);
				
					local function loadChoices(dialog)
						local AState = data:Get("pokeTheBear_A") or 1;
						local PState = data:Get("pokeTheBear_P") or 1;
						dialog:AddChoice("pokeTheBear_A"..AState, function(dialog)
							data:Set("pokeTheBear_A", AState+1);
							if AState >= 3 then
								bribe(dialog, true);
							else
								loadChoices(dialog);
							end
						end);
						dialog:AddChoice("pokeTheBear_P"..PState, function(dialog)
							data:Set("pokeTheBear_P", PState+1);
							if PState >= 2 then
								bribe(dialog, false);
							else
								loadChoices(dialog);
							end
						end);
					end
					
					loadChoices(dialog);
				end);
				
			elseif mission.ProgressionPoint == 8 then
				local profile = shared.modProfile:Get(player);
				local playerSave = profile:GetActiveSave();
				local inventory = playerSave.Inventory;
				local total, itemList = inventory:ListQuantity("cannedbeans", 3);
				
				dialog:SetInitiate("Well? Got any food or not?", "Skeptical");
				if total > 0 then
					local function giveFood(amt)
						total, itemList = inventory:ListQuantity("cannedbeans", amt);
						if itemList then
							data:Set("pokeTheBear_beans", amt);
							for a=1, #itemList do
								inventory:Remove(itemList[a].ID, itemList[a].Quantity);
								shared.Notify(player, ("$AmountCanned Beans removed from your Inventory."):gsub("$Amount", itemList[a].Quantity > 1 and itemList[a].Quantity.." " or ""), "Negative");
							
							end
							modMission:Progress(player, missionId, function(mission)
								if mission.ProgressionPoint <= 8 then
									mission.ProgressionPoint = 9;
								end;
							end)
						else
							shared.Notify(player, ("Unable to find items from inventory."), "Negative");
						end
					end
					
					dialog:AddChoice("pokeTheBear_beans1", function(dialog)
						giveFood(1);
					end)
					if total > 1 then
						dialog:AddChoice("pokeTheBear_beans2", function(dialog)
							giveFood(2);
						end)
						if total > 2 then
							dialog:AddChoice("pokeTheBear_beans3", function(dialog)
								giveFood(3);
							end)
						end
					end
				end
				
			end
			
		end

	end

end


return Dialogues;