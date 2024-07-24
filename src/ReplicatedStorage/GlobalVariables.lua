local mxkhronosUserId = 16170943;
local Vars = {
	GameVersion="2.1.21";
	GameBuild="2"; 
	
	EngineMode="RiseOfTheDead";
	ModeVerLabel = "$UpTime";
	
	--VoteKey = "sfc23";
	
	BaseFocusKills=30;
	FocusLinearScale=10;
	
	MaxLevels=560;
	MaxMoney=100000;
	MaxPerks=10000;
	MaxTweakPoints=999;
	
	StudioTestersIds = {
		mxkhronosUserId; -- MXKhronos;
	};
	PrivateBetaIds = {
		1; -- Roblox
	};
	
	ItemDropsTypes = {
		Blueprint="Blueprint";
		Tool="Tool";
		Money="Money";
		Mod="Mod";
		
		Metal="metal";
		Glass="glass";
		Wood="wood";
		Cloth="cloth";
		Screws="screws";
		Adhesive="adhesive";
		
		MetalPipes="metalpipes";
		Igniter="igniter";
		GasTank="gastank";
		Battery="battery";
		Wires="wires";
		Motor="motor";
		Rope="rope";
		
		Coal="coal";
		PurpleLemon="purplelemon";
		NekronScales="nekronscales";
		
		Crate="Crate";
		
		HalloweenCandy="halloweencandy";
	};
	Punishments = setmetatable({
		SoloMode = 1;
		FocusLevelPenalty = 2;
		AmmoCostPenalty = 3;
		ChatDisablePenalty = 4;
	}, {__index={
		"Banned from playing with other players";
		"Double Focus level kill requirement penalty"; -- 22831007, 1128109167
		"Double ammo cost penalty"; -- 630450717, 583577867
		"Chat disabled penalty"; -- 1354244869, 3146794576, 509692137
	}});
	Cache={
		Group={};
		Support={};
	};
	
}
Vars.EngineVersion = Vars.GameVersion.."."..Vars.GameBuild;

function Vars.IsCreator(player)
	if player == nil then return false; end;
	if player.UserId < 0 then
		return true;
	elseif player.UserId == mxkhronosUserId then -- MXKhronos
		return true;
	end
	return false;
end


function Vars.IsStaff(player, rank)
	if Vars.IsCreator(player) then return true end;
	if Vars.Cache.Group[player.Name] == nil then
		pcall(function()
			Vars.Cache.Group[player.Name] = player:GetRankInGroup(4573862);
		end)
	end;
	if Vars.Cache.Group[player.Name] == nil or Vars.Cache.Group[player.Name] <= 100 then
		return false;
	else
		if rank and Vars.Cache.Group[player.Name] < rank then
			return false;
		end
		return true;
	end
end

function Vars.IsTester(player)
	if Vars.IsCreator(player) then return true end;
	for a=1, #Vars.StudioTestersIds do
		if player.UserId == Vars.StudioTestersIds[a] then return true; end;
	end
	return Vars.IsStaff(player, 101);
	--if player:IsFriendsWith(mxkhronosUserId) then return true; end;
end

function Vars.HasGameAccess(player)
	if Vars.IsTester(player) then return true end;
	for a=1, #Vars.PrivateBetaIds do
		if player.UserId == Vars.PrivateBetaIds[a] then return true; end;
	end
	return false;
end

local randomIdCache = {};
function Vars.UseRandomId(userId)
	--if true then return mxkhronosUserId end;
	if userId and randomIdCache[tostring(userId)] then return randomIdCache[tostring(userId)]; end;
	local a = Vars.StudioTestersIds[math.random(1, #Vars.StudioTestersIds)];
	local b = Vars.PrivateBetaIds[math.random(1, #Vars.PrivateBetaIds)];
	local c = math.random(1, 2) == 1 and a or b;
	if userId then randomIdCache[tostring(userId)] = c end;
	return c
end

function Vars.GetFocusLevel(playerLevel, lvl) -- Get kills required for focus level
	return math.clamp(Vars.BaseFocusKills + math.floor(playerLevel/Vars.FocusLinearScale)*Vars.BaseFocusKills - (lvl-1)*Vars.BaseFocusKills, Vars.BaseFocusKills, math.huge);
end

function Vars.GetLevelToFocus(playerLevel)
	playerLevel = math.clamp(playerLevel, 0, Vars.MaxLevels);
	return math.clamp(math.floor(playerLevel/Vars.FocusLinearScale), 0, playerLevel);
end

function Vars.CloneTable(tb)
	if tb == nil then return end;
	if typeof(tb) ~= "table" then return tb end;
	
	local n = table.clone(tb);
	
	for k, v in pairs(n) do
		n[k] = Vars.CloneTable(v);
	end
	
	return n;
end

function Vars.ScaleModel(model, scale)
	local primary = model.PrimaryPart
	if primary == nil then return end;
	local primaryCf = primary.CFrame

	for _,v in pairs(model:GetDescendants()) do
		if (v:IsA("BasePart")) then
			v.Anchored = true;
			v:BreakJoints();
			
			local originalSize = v:GetAttribute("OriginalSize");
			if originalSize == nil then
				v:SetAttribute("OriginalSize", v.Size);
				originalSize = v.Size;
			end
			
			v.Size = (originalSize * scale);
			
			if (v ~= primary) then
				local rotation =  (v.CFrame - v.Position);
				v.CFrame = (primaryCf + (primaryCf:inverse() * v.Position * scale)) * rotation;
			end
		end
	end

	return model
end

function Vars.GetAngleFront(base, target)
	local relativeCframe = base:ToObjectSpace(target).Position.Unit;
	local dirAngle = math.deg(math.atan2(relativeCframe.X, -relativeCframe.Z));
	return dirAngle;
end

local function trim(s)
	local from = s:match"^%s*()"
	return from > #s and "" or s:match(".*%S", from)
end

function Vars.CleanTextInput(text)	
	text = trim(text);
	
	text = text:gsub("[\r\n]", "`n");
	local hasNewLines = false;
	local c = 0;
	repeat
		hasNewLines = false;
		if text:sub(1, 2) == "`n" then
			text = text:sub(3, #text);
			hasNewLines = true;
		end
		if text:sub(#text-1, #text) == "`n" then
			text = text:sub(1, #text-2);
			hasNewLines = true;
		end
		c = c + 1;
		if c > 1000 then break; end;
	until not hasNewLines;
	text = text:gsub("`n", "\n");
	
	return text;
end

function Vars.IsNan(v)
	return not rawequal(v, v)
end
shared.IsNan = Vars.IsNan;

function Vars.GetPlayersExlude(exclude)
	exclude = typeof(exclude) == "table" and exclude or {exclude};
	
	local players = game.Players:GetPlayers();
	for a=#players, 1, -1 do
		if table.find(exclude, players[a]) then
			table.remove(players, a);
		end
	end
	
	return players;
end

function Vars.IsMobile()
	return game:GetService("UserInputService").TouchEnabled and game:GetService("UserInputService").KeyboardEnabled == false;
end

function Vars.DeepClearTable(tb)
	if tb == nil then return end;
	for k, v in pairs(tb) do
		if type(v) == "table" then
			Vars.DeepClearTable(v);
		end
		tb[k] = nil;
	end
end

function Vars.TableContains(searchTable, keywordsTable)
	for a=1, #searchTable do
		for b=1, #keywordsTable do
			if searchTable[a] == keywordsTable[b] then
				return true;
			end
		end
	end
	return false;
end

function Vars.MaxDiff(...)
	local groups = {...};
	local difs = {};
	
	for a=1, #groups do
		local sets = groups[a];
		
		local max = math.max(sets[1], sets[2]);
		local min = math.min(sets[1], sets[2]);
		
		local dif = max-min;
		table.insert(difs, dif);
	end
	
	return math.max(unpack(difs));
end

function Vars.CleanUnitVec(posA, posB)
	local unit = (posA - posB).Unit;
	
	if rawequal(unit, unit) == false then
		return Vector3.zero;
	end
	
	return unit;
end
shared.CleanUnitVec = Vars.CleanUnitVec;

function Vars.GaussianRandom() -- ~ -2.5 to ~ 2.5;
	return math.sqrt(-2*math.log(1 - math.random()))*math.cos(2*math.pi*math.random());
end

local modBitFlags = require(game.ReplicatedStorage.Library.BitFlags);
--==

Vars.FactionPermissions = modBitFlags.new();
Vars.FactionPermissions:AddFlag("CanChat", "Use Faction Chat");
Vars.FactionPermissions:AddFlag("CanViewSettings", "View Faction Settings"); --View settings
Vars.FactionPermissions:AddFlag("KickUser", "Kick Lower Ranks");
Vars.FactionPermissions:AddFlag("AssignRole", "Assign Roles");
Vars.FactionPermissions:AddFlag("ConfigRole", "Configure Roles");
Vars.FactionPermissions:AddFlag("EditInfo", "Edit Faction Info");
Vars.FactionPermissions:AddFlag("HandleJoinRequests", "Handle Join Requests");
Vars.FactionPermissions:AddFlag("HandleMission", "Handle Missions");
Vars.FactionPermissions:AddFlag("CustomizeHq", "Customize Headquarters");


Vars.EngineMode = game.ReplicatedFirst:FindFirstChild("EngineMode") and game.ReplicatedFirst.EngineMode.Value or Vars.EngineMode;

return Vars;