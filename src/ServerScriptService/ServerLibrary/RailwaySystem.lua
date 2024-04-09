local RailwaySystem = {};
RailwaySystem.__index = RailwaySystem;
RailwaySystem.Trains = {};

local Train = {};
Train.__index = Train;
Train.ClassName = "Train";
Train.AccelerateSpeed = 10;
--==
local PhysicsService = game:GetService("PhysicsService");
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modEventSignal = require(game.ReplicatedStorage.Library:WaitForChild("EventSignal"));

local trainPath = {};
local tracks = 0;

local zeroVec = Vector3.new(0, 0, 0);
--==

function Train.new(prefab)
	local self = {
		Enabled = true;
		Speed = 0;
		Index = 0;
		Prefab = prefab;
		
		Distance = 0;
		Displacement = 0;
		
		Compartments = {};
	};
	
	self.BasePart = prefab.PrimaryPart;
	--self.OldCframe = self.BasePart.CFrame;
	
	self.EngineSound = modAudio.Play("TrainLoop", self.BasePart);
	self.EngineSound.Volume = 0;
	
	self.OnSpeedSet = modEventSignal.new("OnRailwaySpeedSet");
	
	setmetatable(self, Train);
	return self;
end

function Train:SetSpeed(newSpeed, accelerateSpeed)
	self.NewSpeed = newSpeed;
	self.AccelerateSpeed = accelerateSpeed;
	
	self.OnSpeedSet:Fire();
end

function Train:Reset()
	self.Index = 0;
	self.Distance = 0;
end

function Train:AddCompartment(prefab)
	
end

function RailwaySystem:NewTrain(prefab)
	local train = Train.new(prefab);
	self:AddTrain(train);
	return train;
end

function RailwaySystem:GetTrain(prefab)
	for a=1, #self.Trains do
		if self.Trains[a].Prefab == prefab then
			return self.Trains[a];
		end
	end
end

function RailwaySystem:AddTrain(trainObject)
	if trainObject.ClassName ~= "Train" then return end;
	table.insert(self.Trains, trainObject);
end

function RailwaySystem:RemoveTrain(trainObject)
	for a=#self.Trains, 1, -1 do
		if self.Trains[a] == trainObject then
			table.remove(self.Trains, a);
		end
	end
end

function RailwaySystem.init()
	local gamePrefabs = workspace:WaitForChild("Environment"):WaitForChild("Game");
	local trainTrackPrefab = gamePrefabs:WaitForChild("TrainPath");
	
	--if trainTrackPrefab:GetAttribute("TrackType") == "Tracks" then
	for _, obj in pairs(trainTrackPrefab:GetChildren()) do
		obj.Transparency = 1;
		trainPath[obj.Name] = obj;
		tracks = tracks +1;
	end
	
	RunService.Stepped:Connect(function(totalTime, delta)
		for a=1, #RailwaySystem.Trains do
			local train = RailwaySystem.Trains[a];
			
			if train.OnStepped then
				train:OnStepped(delta);
			end
			
			if train.NewSpeed then
				local addSpeed = train.NewSpeed > train.Speed;
				train.Speed = train.Speed + (addSpeed and train.AccelerateSpeed or -train.AccelerateSpeed) * delta;
				
				if math.abs(train.Speed-train.NewSpeed) <= 1 then
					train.Speed = train.NewSpeed;
					train.NewSpeed = nil;
				end
			end
			
			local speed = train.Speed;
			if train.Enabled == false then
				speed = 0;
			end
			
			if train.Silent then
				train.EngineSound.Volume = 0;
				
			else
				train.EngineSound.Volume = math.clamp(speed/25, 0, 1);
				train.EngineSound.PlaybackSpeed = math.clamp(speed/100, 0.3, 1.2);
				
			end
			
			if speed > 0 then
				if train.Displacement >= train.Distance then
					train.Index = train.Index +1;
					if train.Index >= tracks then train.Index = 1; end;
					train.PrevTrack = trainPath[tostring(train.Index)];
					train.NextTrack = trainPath[tostring(train.Index+1)];
					
					
					if train.PrevTrack:GetAttribute("SetSpeed") then
						train:SetSpeed(train.PrevTrack:GetAttribute("SetSpeed"));
					end
					
					if train.PrevTrack:GetAttribute("PauseTrack") then
						train.PauseTrack = tick()+train.PrevTrack:GetAttribute("PauseTrack");
					end
					
					local attachTrack = train.PrevTrack:GetAttribute("AttachTrack");
					if attachTrack then
						local trackPrefab = gamePrefabs:FindFirstChild(attachTrack);
						if trackPrefab then
							local defaultCfTag = trackPrefab:FindFirstChild("DefaultCFrame");
							if defaultCfTag == nil then
								defaultCfTag = Instance.new("CFrameValue");
								defaultCfTag.Name = "DefaultCFrame";
								defaultCfTag.Value = trackPrefab:GetPrimaryPartCFrame();
								defaultCfTag.Parent = trackPrefab;
							end
							
							local newWeld = Instance.new("Weld");
							newWeld.Name = "AttachWeld";
							
							newWeld.Parent = trackPrefab.PrimaryPart;
							newWeld.Part0 = train.BasePart;
							newWeld.Part1 = trackPrefab.PrimaryPart
							
							newWeld.C0 = trackPrefab.PrimaryPart.CFrame:ToObjectSpace(train.PrevTrack.CFrame);
							
							trackPrefab.PrimaryPart.Anchored = false;
						end
					end
					
					local detachTrack = train.PrevTrack:GetAttribute("DetachTrack");
					if detachTrack then
						local trackPrefab = gamePrefabs:FindFirstChild(detachTrack);
						if trackPrefab then
							local defaultCfTag = trackPrefab:FindFirstChild("DefaultCFrame");
							
							for _, obj in pairs(trackPrefab.PrimaryPart:GetChildren()) do
								if obj.Name == "AttachWeld" then
									obj:Destroy();
								end
							end
							trackPrefab.PrimaryPart.Anchored = true;
							
							if defaultCfTag then
								delay(10, function()
									local tweenInfo = TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0)
									TweenService:Create(trackPrefab.PrimaryPart, tweenInfo, {
										CFrame=defaultCfTag.Value;
									}):Play();
								end)
							end
						end
					end
					
					local nextTrackOverwrite = train.PrevTrack:GetAttribute("NextTrackOverwrite");
					if nextTrackOverwrite then
						train.Index = 1;
						train.NextTrack = trainPath[tostring(nextTrackOverwrite)];
					end
					
					if train.NextTrack:GetAttribute("TrackOverwriteDistance") then
						train.Distance = train.NextTrack:GetAttribute("TrackOverwriteDistance");
					else
						train.Distance = (train.PrevTrack.CFrame.p - train.NextTrack.CFrame.p).Magnitude;
					end
					train.Displacement = 0;
					
				end
				
				if train.PauseTrack then
					if tick()> train.PauseTrack then
						train.PauseTrack = nil;
					end
				else
					train.Displacement = train.Displacement + (delta * speed);
					train.CFrame = train.PrevTrack.CFrame:Lerp(train.NextTrack.CFrame, math.clamp(train.Displacement/train.Distance, 0, 1));
					
					local tweenInfo = TweenInfo.new(delta, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0)
					TweenService:Create(train.BasePart, tweenInfo, {
						CFrame=train.CFrame;
					}):Play();
					
					train.Prefab:SetAttribute("DynamicPlatformVelocity", speed);
				end
				
				train.BasePart.Velocity = zeroVec;
			end
		end
	end)
end

RailwaySystem.Train = Train;
return RailwaySystem;
