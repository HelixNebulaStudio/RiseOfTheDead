local Interactable = require(game.ReplicatedStorage.Library.Interactables);

local button = Interactable.Trigger("RatsRecruitment_SectorF", "[Rats Recruitment] Enter Sector F");
button.Script = script;

button.Prompt = {
	Title="You are about to leave this world";
	Description="Are you sure you want to travel to Sector F?";
}

local RunService = game:GetService("RunService");
if RunService:IsServer() then
	print("RatsRecruitment_SectorF");
	
	
end;

return button;