local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

-- Variables;
local localPlayer = game.Players.LocalPlayer;
local playerScripts = localPlayer:WaitForChild("PlayerScripts");
local playerGui = localPlayer:WaitForChild("PlayerGui");

-- Script;
local function LoadPlayerScript(new)
	local playerScr = playerScripts:FindFirstChild(new.Name);
	if playerScr == nil then
		local newClone = new:Clone();
		if newClone then
			newClone.Parent = playerScripts;
			if newClone:IsA("BaseScript") then
				newClone.Enabled = true;
			end
		end
		
	else
		if playerScr:IsA("BaseScript") then
			playerScr.Enabled = true;
		end
		
	end
end

local function LoadPlayerGui(new) -- playerGui:FindFirstChild(new.Name) == nil and
	if new:IsA("ScreenGui") and new.Archivable == true then
		Debugger:Log("Loading", new);
		
		for _, obj in pairs(playerGui:GetChildren()) do
			if obj:IsA("ScreenGui") and obj.Name == new.Name then
				obj:Destroy();
			end
		end
		
		local newClone = new:Clone();
		newClone.Parent = playerGui;
	end
end


if not script:IsDescendantOf(playerGui) then Debugger:Warn("Cancelled.") return end;
Debugger:Warn("Initialized");


game.StarterPlayer.StarterPlayerScripts.ChildAdded:Connect(LoadPlayerScript)
for _, child in pairs(game.StarterPlayer.StarterPlayerScripts:GetChildren()) do
	LoadPlayerScript(child);
end


--game.StarterGui.ChildAdded:Connect(LoadPlayerGui)
function shared.ReloadGui()
	for _, child in pairs(game.ReplicatedStorage.PlayerGui:GetChildren()) do
		LoadPlayerGui(child);
	end
end
shared.ReloadGui();
