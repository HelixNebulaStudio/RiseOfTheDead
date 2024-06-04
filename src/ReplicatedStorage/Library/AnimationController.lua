local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modGarbageHandler = require(game.ReplicatedStorage.Library.GarbageHandler);
local modEventSignal = require(game.ReplicatedStorage.Library.EventSignal);

--== AnimGroup
local AnimGroup = {};
AnimGroup.__index = AnimGroup;

function AnimGroup.new(animController, groupId)
	local self = {
		Id=groupId;
		AnimController=animController;
		CatKeys={};
	};
	
	setmetatable(self, AnimGroup);
	return self;
end

function AnimGroup:LoadAnimation(categoryId, animPrefab)
	local catKey = self.Id..categoryId;
	self.CatKeys[catKey] = categoryId;
	
	local trackData = self.AnimController:LoadAnimation(catKey, animPrefab);
	trackData.GroupId = self.Id;
	
	return trackData;
end

function AnimGroup:Play(categoryId, paramPacket)
	local catKey = self.Id..categoryId;
	return self.AnimController:Play(catKey, paramPacket);
end

-- !outline: AnimGroup:HasAnim(categoryId)
function AnimGroup:HasAnim(categoryId)
	local catKey = self.Id..categoryId;
	return self.AnimController:HasAnim(catKey);
end

function AnimGroup:Stop(categoryId, paramPacket)
	local catKey = self.Id..categoryId;
	self.AnimController:Stop(catKey, paramPacket);
end

function AnimGroup:Destroy()
	for key, catId in pairs(self.CatKeys) do
		self.AnimController:UnloadAnimation(key);
	end
end

-- !outline: AnimGroup:GetTrackData(categoryId, index)
function AnimGroup:GetTrackData(categoryId, index)
	local catKey = self.Id..categoryId;
	return self.AnimController:GetTrackData(catKey, index);
end

--==

local AnimationController = {};
AnimationController.__index = AnimationController;

--==
function AnimationController.new(animator: Animator, rig: Model?)
	local self = {
		Name=(rig and rig.Name or animator.Parent and animator.Parent.Parent and animator.Parent.Parent.Name);
		Rig=rig;
		Animator=animator;
		
		LoadedAnim = {};
		Tracks = {};
		Actives = {};
		Timescale = 1;
		
		AnimatorLogic = nil;
		
		OnUpdate = modEventSignal.new("OnAnimationControllerUpdate");
		Garbage = modGarbageHandler.new();
	}
	
	for k, v in pairs(Enum.AnimationPriority:GetEnumItems()) do
		self.Actives[v.Name] = {};
	end
	
	setmetatable(self, AnimationController);
	
	self.Garbage:Tag(animator.Destroying:Connect(function()
		if self.Destroyed then return end;
		self.Destroyed = true;
		
		table.clear(self.LoadedAnim);
		self.Garbage:Destruct();
		table.clear(self :: any);
	end)) 
	
	return self;
end

function AnimationController:NewGroup(groupId)
	local newGroup = AnimGroup.new(self, groupId);
	return newGroup;
end

-- !outline: AnimationController:LoadAnimation(categoryId, animList, animModule);
function AnimationController:LoadAnimation(categoryId, animList, animModule)
	if self.Destroyed then return end;
	
	animList = typeof(animList) == "table" and animList or {animList};
	
	local firstTrackData;
	
	for _, animation: Animation in pairs(animList) do
		if self.LoadedAnim[animation] then continue end;
		self.LoadedAnim[animation] = categoryId;

		local track: AnimationTrack = self.Animator:LoadAnimation(animation);
		local _priority = animation:GetAttribute("AnimationPriority") or 0;
		local chance = animation:GetAttribute("Chance") or 1;
		
		local trackData = {
			CategoryId = categoryId;
			
			Name = animation.Name;
			Track = track;
			Chance = chance;
			Weight = 1;
			
			LoopStart = nil;
			LoopEnd = nil;
		};

		self.Garbage:Tag(track);

		if track.Looped == false then
			self.Garbage:Tag(track.Stopped:Connect(function()
				local priorityName = trackData.Track.Priority.Name;

				local i = table.find(self.Actives[priorityName], trackData);
				if i == nil then return end;
				
				table.remove(self.Actives[priorityName], i);
				if i <= 1 then
					self:Update();
				end
			end))
		end
		
		track:GetMarkerReachedSignal("Loop"):Connect(function(paramString)
			if paramString == "Start" then
				if trackData.LoopStart == nil then
					trackData.LoopStart = track.TimePosition;
				end
				
			elseif paramString == "End" then
				if trackData.LoopEnd == nil then
					trackData.LoopEnd = track.TimePosition;
				end
				if trackData.LoopStart then
					track.TimePosition = trackData.LoopStart;
				end
				
			end
		end)
		
		if self.Tracks[categoryId] == nil then
			self.Tracks[categoryId] = {};
		end
		table.insert(self.Tracks[categoryId], trackData);
		
		if firstTrackData == nil then
			firstTrackData = trackData;
		end
	end
	
	local _tracksGroup = self.Tracks[categoryId];
	
	return firstTrackData;
end

-- !outline: AnimationController:SetAnimationMeta(categoryId, moduleSrc, basePacket)
function AnimationController:SetAnimationMeta(categoryId, moduleSrc, baseValues)
	if not moduleSrc:IsA("ModuleScript") then return end;
	
	local animationMeta = require(moduleSrc);
	
	self:LoopTracks(categoryId, function(trackData)
		trackData.Values = baseValues;
		setmetatable(trackData, animationMeta);
	end)
end

function AnimationController:ConnectMarker(categoryId, markerId, func)
	self:LoopTracks(categoryId, function(trackData)
		local track: AnimationTrack = trackData.Track;
		track:GetMarkerReachedSignal(markerId):Connect(function(...)
			func(trackData, ...);
		end)
	end)
end

function AnimationController:UnloadAnimation(categoryId)
	local tracksGroup = self.Tracks[categoryId];
	if tracksGroup == nil then return end;
	

	if self.Debug == true then
		Debugger:Warn("UnloadAnimation", categoryId);
	end
	for priorityName, activeList in pairs(self.Actives) do
		for a=1, #tracksGroup do
			local i = table.find(activeList, tracksGroup[a]);
			if i then
				table.remove(activeList, i);
			end
		end
	end
	self.Tracks[categoryId] = nil;
	
	self:Update();
end

function AnimationController:IsLoaded(animPrefab)
	return self.LoadedAnim[animPrefab] == true;
end

-- !outline :HasAnim(category)
function AnimationController:HasAnim(categoryId)
	local tracksGroup = self.Tracks[categoryId];
	return tracksGroup ~= nil;
end

function AnimationController:IsPlaying(categoryId)
	for priorityName, activeList in pairs(self.Actives) do
		local activeTrack = activeList[1];
		if activeTrack and activeTrack.CategoryId == categoryId then
			return true;
		end
	end
	return false;
end

function AnimationController:Play(categoryId, paramPacket)
	if self.Destroyed then return end;
	paramPacket = paramPacket or {};
	
	local tracksGroup = self.Tracks[categoryId];
	if tracksGroup == nil then
		Debugger:Warn("Play missing animation (",self.Name,")", categoryId);
		return;
	end;
	
	local animId = paramPacket.AnimId;
	local trackData = nil;
	
	if animId then
		for a=1, #tracksGroup do
			if tracksGroup[a].Id == animId then
				trackData = tracksGroup[a];
				break;
			end
		end
		
	else
		local rollTable = {};
		local totalChance = 0;
		
		for a=1, #tracksGroup do
			if tracksGroup[a].UpdateTrackChance then
				tracksGroup[a]:UpdateTrackChance();
			end
			
			if tracksGroup[a].Chance > 0 then
				totalChance = totalChance + tracksGroup[a].Chance;
				table.insert(rollTable, {
					Value=tracksGroup[a];
					Range=totalChance;
				})
			end
		end

		--trackData = tracksGroup[math.random(1, #tracksGroup)];
		local roll = math.random(0, totalChance*1000)/1000;
		for a=1, #rollTable do
			if rollTable[a].Range >= roll then
				trackData = rollTable[a].Value;
				break;
			end
		end
		
	end
	
	if trackData == nil then
		Debugger:Warn("No trackdata viable to be played. (",self.Name,")", categoryId);
		return;
	end
	
	local priority = trackData.Track.Priority;
	local activeList = self.Actives[priority.Name];
	
	local alreadyActiveIndex = nil;
	for a=1, #activeList do
		if activeList[a].CategoryId == categoryId then
			trackData = activeList[a];
			alreadyActiveIndex = a;
			
			break;
		end
	end
	
	local track = trackData.Track;

	if self.Debug then
		Debugger:Warn(":Play(", categoryId, track, activeList);
	end
	
	if alreadyActiveIndex and alreadyActiveIndex > 1 then
		table.remove(activeList, alreadyActiveIndex);
	end

	if activeList[1] == nil or activeList[1].Track.Looped ~= true then
		activeList[1] = trackData;

	elseif activeList[1] ~= trackData then
		table.insert(activeList, 1, trackData);

	end
	
	if self.Debug then
		Debugger:Warn(":Play)", track, activeList);
	end
	
	trackData.FadeTime = paramPacket.FadeTime;
	trackData.Length = paramPacket.Length;
	trackData.Speed = paramPacket.Speed;
	trackData.Weight = paramPacket.Weight;
	
	if trackData.BindSpeed then
		trackData.Speed = trackData:BindSpeed();
	end
	
	self:Update();
end

function AnimationController:Stop(categoryId, paramPacket)
	paramPacket = paramPacket or {};
	local tracksGroup = self.Tracks[categoryId];
	
	if tracksGroup then
		if self.Debug == true then
			Debugger:Warn("StopRequest", categoryId);
		end
		for a=1, #tracksGroup do
			local track = tracksGroup[a].Track;
			local priorityName = track.Priority.Name;
			
			local activeList = self.Actives[priorityName];
			for b=#activeList, 1, -1 do
				if activeList[b] == tracksGroup[a] then
					table.remove(activeList, b);
					break;
				end
			end
			
			if not track.IsPlaying then continue end;

			tracksGroup[a].Track:Stop(paramPacket.FadeTime);
		end
		
	end
	
	self:Update();
end

function AnimationController:StopAll()
	for k, v in pairs(self.Actives) do
		if self.Debug == true then
			Debugger:Warn("StopAll", k);
		end
		table.clear(self.Actives[k]);
	end
	self:Update();
end

function AnimationController:GetTrackGroup(categoryId)
	return self.Tracks[categoryId];
end

-- !outline: :GetTrackData(categoryId, index)
function AnimationController:GetTrackData(categoryId, index)
	local tracksList = self:GetTrackGroup(categoryId);
	if #tracksList <= 0 then return end;

	if index and index > 0 and index < #tracksList then
		return tracksList[index];
	end

	return tracksList[math.random(1, #tracksList)];
end

-- !outline: :LoopTracks(categoryId, loopFunc)
function AnimationController:LoopTracks(categoryId, loopFunc)
	local tracksGroup = self:GetTrackGroup(categoryId);
	if tracksGroup == nil then return end;
	
	for a=1, #tracksGroup do
		loopFunc(tracksGroup[a]);
	end
end

-- !outline: :Update()
function AnimationController:Update()
	local activeTracks = {};
	
	for priorityName, activeList in pairs(self.Actives) do
		for a=1, #activeList do
			local trackData = activeList[a];
			local track = trackData.Track;
			
			if a == 1 then
				table.insert(activeTracks, track);
				
				if not track.IsPlaying then
					if self.Debug == true then
						Debugger:Warn(self.testCount,"Play", track, activeTracks);
					end
					track:Play(trackData.FadeTime);
				end
				
				local animSpeed = 1;
				if trackData.Length then
					animSpeed = track.Length/trackData.Length;

				elseif trackData.Speed then
					animSpeed = trackData.Speed;
	
				end
				
				if trackData.CustomSpeed ~= true then
					track:AdjustSpeed(animSpeed * self.Timescale);
				end

				if trackData.Weight then
					track:AdjustWeight(trackData.Weight);
				end
				
			else
				if track.IsPlaying then
					if self.Debug == true then
						Debugger:Warn("Stop index=a", track, activeTracks);
					end
					track:Stop();
				end
				
			end
		end
	end

	local activeAnimationTracks = self.Animator:GetPlayingAnimationTracks();
	for a=1, #activeAnimationTracks do
		local track = activeAnimationTracks[a];
		if table.find(activeTracks, track) == nil then
			if self.Debug == true then
				Debugger:Warn("Stop Active", track, activeTracks);
			end
			track:Stop();
		end
	end
	
	
	self.OnUpdate:Fire();
end

function AnimationController:SetTimescale(v)
	self.Timescale = v or 1;
	
	self.Animator:SetAttribute("Timescale", self.Timescale);
	
	self:Update();
end

AnimationController.AnimGroup = AnimGroup;
return AnimationController;