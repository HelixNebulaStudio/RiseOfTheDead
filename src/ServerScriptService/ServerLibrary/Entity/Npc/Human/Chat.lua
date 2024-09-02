local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TextChatService = game:GetService("TextChatService");

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modDialogueLibrary = require(game.ReplicatedStorage.Library.DialogueLibrary);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local random = Random.new();

local Human = {};

local ChatService = game:GetService("Chat");

local bubbleFrame = script:WaitForChild("Bubble");

function Human.new(self)
	local selfBubble = bubbleFrame:Clone();
	local bubbleLabel = selfBubble:WaitForChild("ImageLabel"):WaitForChild("TextBubble");
	selfBubble.Enabled = false;
	selfBubble.Parent = self.Head;
	local closeTick = tick();
	local aSize = Vector2.new(216, 60);
	
	return function(target, message, chatColor, maxRange)
		maxRange = maxRange or 60;
		target = target or game.Players:GetPlayers();
		--if target == nil then Debugger:Warn("NpcChat>> No target. (",message,")"); return end;
		
		message = message and tostring(message) or nil;
		-- if message and message:match("_") then
		-- 	local choiceData = modDialogueLibrary.GetByTag(self.Name, message);
		-- 	if choiceData then
		-- 		message = choiceData.Reply;
				
		-- 		if choiceData.Face and self.AvatarFace then
		-- 			self.AvatarFace:Set(choiceData.Face);
		-- 		end
		-- 	end
		-- end
		
		message = message or "";
		--bubbleLabel.Text = message;
		
		if not self.Head:IsDescendantOf(workspace) then return end;
		if #message > 0 then
			if self.Head then
				ChatService:Chat(self.Head, message, Enum.ChatColor.White);
			end
			
			local targets = {};
			if type(target) == "table" then
				for a=1, #target do
					table.insert(targets, target[a]);
				end
			else
				table.insert(targets, target);
			end
			
			if modBranchConfigs.WorldInfo.Type ~= modBranchConfigs.WorldTypes.Cutscene then
				for a=#targets, 1, -1 do
					if targets[a]:IsA("Player") and targets[a]:DistanceFromCharacter(self.Head.Position) > maxRange then
						table.remove(targets, a);
					end
				end
			end
			
			local modNpcProfileLibrary = require(game.ReplicatedStorage.BaseLibrary.NpcProfileLibrary);
			local npcLib = modNpcProfileLibrary:Find(self.Name);
			if npcLib and modNpcProfileLibrary.ClassColors[npcLib.Class] then
				local nc = modNpcProfileLibrary.ClassColors[npcLib.Class];
				local classColor = "rgb("..math.floor(nc.R*255)..","..math.floor(nc.G*255)..","..math.floor(nc.B*255)..")";
				shared.Notify(targets, '<b><font size="16" color="'..classColor..'">'..self.Name..'</font></b>: '..message, "Message");
			else
				shared.Notify(targets, '<b><font size="16" color="'.. (chatColor or '#ddcbb2') ..'">'..self.Name..'</font></b>: '..message, "Message");
			end
		end
	end
end

return Human;