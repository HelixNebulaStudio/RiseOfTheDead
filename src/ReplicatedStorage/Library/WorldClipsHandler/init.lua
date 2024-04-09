local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local WorldClipsHandler = {};
WorldClipsHandler.__index = WorldClipsHandler;

WorldClipsHandler.ClipsLibrary = {};
--==

function WorldClipsHandler:LoadClipId(clipId)
	if self.ClipsLibrary[clipId] == nil then
		local clipModule = script:FindFirstChild(clipId);
		self.ClipsLibrary[clipId] = clipModule and require(clipModule) or nil;
	end
end

function WorldClipsHandler:LoadClip(basePart)
	local clipId = basePart.Name;
	
	if self.ClipsLibrary[clipId] == nil then
		local clipModule = script:FindFirstChild(clipId);
		self.ClipsLibrary[clipId] = clipModule and require(clipModule) or nil;
	end
	
	if self.ClipsLibrary[clipId] then
		self.ClipsLibrary[clipId]:Load(basePart);
		return true;
	end
	
	return false;
end


return WorldClipsHandler;
