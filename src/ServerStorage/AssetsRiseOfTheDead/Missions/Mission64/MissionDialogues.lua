local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

--=
local Dialogues = {
	Joseph={};
};

local missionId = 64;
--==

-- MARK: Joseph Dialogues
Dialogues.Joseph.DialogueStrings = {
	["josephcrossbow_try"]={
		Face="Skeptical"; 
		Say="Is this crossbow what you are talking about?"; 
		Reply="Ahh yes.. I had a build for the crossbow, I've written my build somewhere near my workbench a long time ago and forgotten it, try to figure out how it's built.";
	};
	["josephcrossbow_failBuild"]={
		Face="Skeptical"; 
		Say="Is this how you built your crossbow?"; 
		Reply="Hmm, not quite, something's off. Look around my workbench to see if you can find any clues..";
	};
	["josephcrossbow_corectBuild"]={
		Face="Skeptical"; 
		Say="Is this how you built your crossbow?"; 
		Reply="Well well well, it is perfeect. Here, use this to give it a final touch.";
	};

};

if RunService:IsServer() then
	-- MARK: Joseph Handler
end


return Dialogues;