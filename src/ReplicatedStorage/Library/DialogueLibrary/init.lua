local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local DialogueLibrary = {};
--==

function DialogueLibrary:Get(name, tag)
	return self[name] and self[name][tag];
end

function DialogueLibrary:Load(name, tag, dialoguePacket)
	if self[name] == nil then
		self[name] = {};
	end

	self[name][tag] = dialoguePacket;
end

return DialogueLibrary;