local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface = {};

local localplayer = game.Players.LocalPlayer;
local modData = require(localplayer:WaitForChild("DataModule"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);

local remotes = game.ReplicatedStorage.Remotes;
local remoteGameModeExit = modRemotesManager:Get("GameModeExit");
	
local mainframe = script.Parent.Parent:WaitForChild("AccessoryHud");
local mainlabel = mainframe:WaitForChild("TextLabel");

local cache = {};
local clockConn;
--== Script;
function Interface.init(modInterface)
	setmetatable(Interface, modInterface);

	local window = Interface.NewWindow("AccessoryHud", mainframe);
	
	Interface.Update();
	return Interface;
end;

function Interface.Update()
	if modData.Settings.DisableAccessoryHud == 1 then
		mainframe.Visible = false;
		return;
	end
	
	local text = "";
	
	local watchItem = cache.Watch and modData.GetItemById(cache.Watch.ID, true);
	if watchItem == nil then watchItem = modData.FindItemIdFromCharacter("watch"); end
	cache.Watch = watchItem;
	if watchItem then
		text = text.."Time: "..game.Lighting.TimeOfDay;
	end
	
	mainlabel.Text = text;
	mainframe.Visible = #text > 0;
end

function Interface.disconnect()
	if clockConn then
		clockConn:Disconnect();
	end
end

clockConn = modSyncTime.GetClock():GetPropertyChangedSignal("Value"):Connect(function()
	Interface.Update();
end)

script.AncestryChanged:Connect(function(c, p)
	if c == script and p == nil and Interface.disconnect then
		Interface.disconnect();
	end
end)
return Interface;
