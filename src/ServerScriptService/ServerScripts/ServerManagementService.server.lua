local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Dependencies;
repeat task.wait() until shared.MasterScriptInit == true;
local modServerManager = require(game.ServerScriptService.ServerLibrary.ServerManager);

--== Variables;

--== Script;
game.Players.PlayerRemoving:Connect(modServerManager.OnPlayerRemoving);

local modEngineCore = require(game.ReplicatedStorage.EngineCore);
modEngineCore:ConnectOnPlayerAdded(script, modServerManager.OnPlayerAdded);