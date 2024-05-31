local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local remotes = game.ReplicatedStorage:WaitForChild("Remotes");

--local PlayerScriptsScript = script:WaitForChild("PlayerScripts");
local scriptsStorage = game.ServerStorage.LocalScripts;

local localPlayerScripts = script:WaitForChild("LocalPlayerScripts");
--== Script;
function shared.ReloadCharacter(player)
	local character = player.Character;
	
	for _, s in pairs(scriptsStorage.CharacterScripts:GetChildren()) do
		local existingScript = character:FindFirstChild(s.Name);
		if existingScript then 
			if existingScript:GetAttribute("CantReload") == true then
				continue;
			else
				existingScript.Enabled = false;
				existingScript:Destroy()
			end
		end;

		local new = s:Clone();
		new.Parent = character;
		new.Archivable = false;
		
		if new.ClassName == "LocalScript" then new.Disabled = false; end
	end
end

local function OnPlayerAdded(player)
	if modBranchConfigs.IsWorld("MainMenu") and player.PlayerGui:FindFirstChild("ClientMainMenu") == nil then
		local new = game.ReplicatedFirst.ClientMainMenu:Clone();
		new.Parent = player.PlayerGui
		new.Disabled = false;
	end
	
	for _, scr in pairs(script:GetChildren()) do
		if scr.ClassName == "LocalScript" then
			local new = scr:Clone();
			new.Parent = player:WaitForChild("PlayerGui");
			new.Disabled = false;
			new.Archivable = false;
		end
	end

	local newPlayerScripts = localPlayerScripts:Clone();
	newPlayerScripts.Parent = player;
	newPlayerScripts.Enabled = true;
	
	local function OnCharacterAdded(character)
		shared.ReloadCharacter(player);
	end
	
	if player.Character then
		shared.ReloadCharacter(player);
	end
	player.CharacterAdded:Connect(OnCharacterAdded);
end

local modEngineCore = require(game.ReplicatedStorage.EngineCore);
modEngineCore:ConnectOnPlayerAdded(script, OnPlayerAdded, 5);