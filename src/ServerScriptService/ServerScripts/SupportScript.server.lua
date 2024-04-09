local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local reportFormat = '    <b>$Speaker</b>            <font size="16">[$ReportType] [$Branch]</font><br/>    $Message<br/>    $SuspectLink<br/>';
--local reportFormat = [[**$ReportType** ($Branch)
--$Message

--$SuspectLink
--]]

--== Variables;
local DataStoreService = game:GetService("DataStoreService");
local SupportDatastore = DataStoreService:GetDataStore("SupportRequests");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);

local remotes = game.ReplicatedStorage:WaitForChild("Remotes");
local remoteClientReport = remotes:WaitForChild("Interface"):WaitForChild("ClientReport");

local reports = {};
local ReportTypes = {Bug=0; Feedback=1; Exploit=2;};

local bindSubmitDiagnosticsReport = script:WaitForChild("SubmitDiagnosticsReport");

local playerDebounce = {};
local flushingReports = false;
--== Script;
local function GetReportType(id)
	for k, v in pairs(ReportTypes) do
		if v == id then return k, v end;
	end
end

function GetComments(card)
	if card == nil then return end;
	local raw = card:GetComments();
	if raw == nil then return end;
	local comments = {};
	for a=1, #raw do
		table.insert(comments, {Text=raw[a].data.text; Date=raw[a].date; Speaker=raw[a].memberCreator.username});
	end
	return comments;
end

function OnPlayerAdded(player)
	local lastUpdate = 0;
	local function OnCharacterAdded()
		if os.time()-lastUpdate < 6 then return end;
		lastUpdate = os.time();
		wait(1);
	end
	player.CharacterAdded:Connect(OnCharacterAdded);
	OnCharacterAdded();
end

local modEngineCore = require(game.ReplicatedStorage.EngineCore);
modEngineCore:ConnectOnPlayerAdded(script, OnPlayerAdded)

function FlushReports() --GameLog
	if flushingReports then return end;
	
	while #reports > 0 do
		local report = reports[1];
		local playerName = tostring(report.Player and report.Player.Name or "Unknown");
		
		local lastSubmission = 0;
		if #report.Message > 20 and #report.Message < 1024 then
			local canSubmit = false;
			
			if playerName == "MXKhronos" then
				canSubmit = true;
				
			elseif report.ServerReport then
				canSubmit = true;
			else
				pcall(function()
					local suppKey = playerName.."Support";

					SupportDatastore:UpdateAsync(suppKey, function(lS)
						lastSubmission = lS or 0;
						if (os.time() - lastSubmission) >= 60 then
							canSubmit = true;
						end
						return os.time();
					end)
				end)
				
			end
			
			local logStr = "";
			if canSubmit then
				local reportTypeName = GetReportType(report.Type) or report.Type;
				for n, v in pairs(ReportTypes) do if ReportTypes[v] == report.Type then reportTypeName = n; break; end; end;
				
				local suspectName = report.Suspect and report.Suspect.Name;
				local ver = modGlobalVars.GameVersion.."."..modGlobalVars.GameBuild;
				
				logStr = reportFormat
					:gsub("$Speaker", playerName.." ("..report.Player.UserId..")")
					:gsub("$ReportType", reportTypeName)
					:gsub("$Branch", modBranchConfigs.CurrentBranch.Name..":"..ver.." ("..modBranchConfigs.GetWorld()..")")
					:gsub("$Message", report.Message)
					:gsub("$SuspectLink", suspectName and " >> Suspect: ["..suspectName.."](https://www.roblox.com/users/profile?username="..suspectName..")" or "")

				modAnalytics:ReportError("Support", logStr, "debug");
				shared.modGameLogService:Log(logStr, "Reports");
			end
			if report.Player then
				remoteClientReport:FireClient(report.Player, {
					Speaker=playerName;
					Text = logStr;
					Date = os.time();
				}, lastSubmission);
			end
		end
		table.remove(reports, 1);
		task.wait();
	end
	
	flushingReports = false;
end

function ProcessReport(player, reportType, message, suspect)
	table.insert(reports, {Player=player; Type=reportType; Message=message; Suspect=suspect;});
	Debugger:Log("Processing report #"..#reports);
	FlushReports();
end
remoteClientReport.OnServerEvent:Connect(function(player, reportType, message, suspect)
	if typeof(message) ~= "string" or #message <= 0 then return end;
	local playerName = player.Name;
	
	if playerDebounce[playerName] and tick()-playerDebounce[playerName] <= 60 then return end;
	playerDebounce[playerName] = tick(); delay(59.9, function() playerDebounce[playerName] = nil end);
	if GetReportType(reportType) == nil then Debugger:Warn("Invalid report type",reportType); return end;
	if message:match(".") == nil and message:match(",") == nil and message:match("!") == nil and message:match("?") == nil then Debugger:Warn("Improper report formatting",player.Name); return end;
	spawn(function() ProcessReport(player, reportType, message, suspect) end);
end)

bindSubmitDiagnosticsReport.Event:Connect(function(player, reportType, message)
	if player == nil then return end;
	
	table.insert(reports, {Player=player; Type=reportType; Message=message; ServerReport=true;});
	Debugger:Log("Processing report #"..#reports);
	FlushReports();
end)