local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local DialogueSave = {};

--== Script;
function DialogueSave.new(player)
	local meta = {};
	meta.__index = meta;
	
	local Dialogues = setmetatable({}, meta);
	
	local activeDialogues = {};
	
	function meta:Get(npcName)
		return activeDialogues[npcName];
	end

	function meta.new(npcName)
		local npcDialogData = {};
		npcDialogData.__index = npcDialogData;
		
		local dialogueObject = {};
		
		function npcDialogData:ListData()
			return Dialogues[npcName] or {};
		end

		function npcDialogData:Get(key)
			return Dialogues[npcName] and Dialogues[npcName][key];
		end
		
		function npcDialogData:Set(key, value)
			if Dialogues[npcName] == nil then Dialogues[npcName] = {} end;
			Dialogues[npcName][tostring(key)] = value;
		end
		
		activeDialogues[npcName] = setmetatable(dialogueObject, npcDialogData);
		return activeDialogues[npcName];
	end
	
	function meta:Load(rawData)
		for name, value in pairs(rawData) do
			Dialogues[name] = value;
		end
		return Dialogues;
	end
	
	return Dialogues;
end

function DialogueSave:Get(player, npcName)
	local profile = shared.modProfile:Get(player);
	local activeSave = profile and profile:GetActiveSave();
	local dialoguesSave = activeSave and activeSave.Dialogues;
	
	if npcName then
		return dialoguesSave and dialoguesSave:Get(npcName) or dialoguesSave.new(npcName);
	end

	return dialoguesSave;
end

return DialogueSave;