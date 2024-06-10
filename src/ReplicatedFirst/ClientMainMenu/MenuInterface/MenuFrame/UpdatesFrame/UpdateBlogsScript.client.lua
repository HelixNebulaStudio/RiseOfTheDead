while shared.ReviveEngineLoaded ~= true do task.wait() end;
local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local HttpService = game:GetService("HttpService");
local TextService = game:GetService("TextService");

local listArchiveCopy = script:WaitForChild("listArchive");
local scrollList = script.Parent:WaitForChild("UpdatesScreen"):WaitForChild("slotsBackground"):WaitForChild("List");

local updatesFrame = script.Parent;
local textLabel = scrollList:WaitForChild("notes"):WaitForChild("textLabel");

local modRemotesManager = require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("RemotesManager"));
local remoteApiRequest = modRemotesManager:Get("ApiRequest");

--== Script;
local function refresh()
	local modMarkupFormatter = require(game.ReplicatedStorage.Library.MarkupFormatter);
	
	local updateLogText = remoteApiRequest:InvokeServer("updatelog");
	local success, message = pcall(function()
		textLabel.Text = modMarkupFormatter.Format(updateLogText);
	end)
	if not success then
		Debugger:Warn("Failed to fetch update logs:",message);
	end
end

updatesFrame:GetPropertyChangedSignal("Visible"):Connect(function()
	if updatesFrame.Visible then
		refresh();
	end
end)