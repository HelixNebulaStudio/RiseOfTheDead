local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local module = {
	Tagged = {};
};

function module.Tag(victim, tagger, isHead)
	if victim == nil then Debugger:Log("Missing victim.", victim, tagger, isHead); return end;
	if tagger == nil then Debugger:Log("Missing tagger.", victim, tagger, isHead); return end;
	
	local parent = victim;
	local humanoid = parent:FindFirstChildWhichIsA("Humanoid");
	for a=1, 3 do
		if humanoid == nil then
			parent = parent.Parent;
			if parent == nil then return end;
			
			humanoid = parent:FindFirstChildWhichIsA("Humanoid");
		else
			break;
		end
	end
	
	victim = humanoid and humanoid.Parent or nil;
	if victim == nil then Debugger:Log("Missing victim.", victim, tagger, isHead); return end;
	
	local tag = module.Tagged[victim];
	if tag == nil then
		local tagMeta = {};
		tagMeta.__index = tagMeta;
		tagMeta.LastTag = tick();
		
		tagMeta.Refresh = function() tagMeta.LastTag = tick(); end;
		
		tagMeta.Destroy = function()
			if tick()-tag.LastTag >= 10 then
				module.Tagged[victim] = nil;
				tag = nil;
			else
				delay(10, tag.Destroy);
			end 
		end
		
		tag = setmetatable({}, tagMeta);
		delay(10, tag.Destroy);
		module.Tagged[victim] = tag;
	end;
	
	for a=#module.Tagged[victim], 1, -1 do
		if module.Tagged[victim][a].Tagger == tagger then
			table.remove(tag, a);
		end
	end
	table.insert(tag, {Tagger=tagger; Headshot=isHead;});
	tag.Refresh();
end

return module;
