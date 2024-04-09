--== Configuration;

--== Variables;
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
	
	local blogTable = remoteApiRequest:InvokeServer("updatelog") or {};
	local success, message = false, "";
	if blogTable.name ~= nil then
		success, message = pcall(function()
			textLabel.Text = modMarkupFormatter.Format(blogTable.desc);
		end)
	end
	
end

updatesFrame:GetPropertyChangedSignal("Visible"):Connect(function()
	if updatesFrame.Visible then
		refresh();
	end
end)