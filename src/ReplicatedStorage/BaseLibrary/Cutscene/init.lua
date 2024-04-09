local Cutscene = {};
Cutscene.__index = Cutscene;
--== Script;
function Cutscene:Init(super)
	for _, moduleScript in pairs(script:GetChildren()) do
		moduleScript.Parent = super.Script;
	end
end

return Cutscene;