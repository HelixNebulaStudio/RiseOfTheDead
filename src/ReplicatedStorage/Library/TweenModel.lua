local module = {}
module.__index = module

local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local function CalculatePosition(part1,part2)
	return CFrame.new(part1.Position):ToObjectSpace(CFrame.new(part2.Position)).Position
end

function module.TweenModulePosition(Model,Tweeninfo,PPosition)
	if typeof(Model) ~= "Instance" then error(Model.." isnt a instance") end
	if not Model:IsA("Model") then error(Model.Name.." isnt a model") end
	if not Model.PrimaryPart then Model.PrimaryPart = Model:FindFirstChildWhichIsA("BasePart") end


	task.spawn(function()
		local Primary = Model.PrimaryPart
		local AnchorState = Primary.Anchored

		local TW = TS:Create(Primary,Tweeninfo,{Position = PPosition})
		
		for _,v in pairs(Model:GetDescendants()) do
			if v:IsA("BasePart") and v ~= Primary then
				local T = TS:Create(v,Tweeninfo,{Position = PPosition + CalculatePosition(Primary,v)})
				T:Play()
				
				local anchord = v.Anchored
				v.Anchored = true 
				task.spawn(function()
					TW.Completed:Wait()
					v.Anchored = anchord
				end)
			end

			if v:IsA("Weld") or v:IsA("WeldConstraint") or v:IsA("ManualWeld") or v:IsA("Motor6D") then
				if v.Name ~= "TweenWeld" then
					v.Enabled = false
					task.spawn(function()
						TW.Completed:Wait()

						v.Enabled = true
					end)
				end
			end
		end

		TW:Play()
		TW.Completed:Wait()
		
		Primary.Anchored = AnchorState
	end)
	return
end

function module.TweenModuleScale(Model,Tweeninfo,Size)
	if typeof(Model) ~= "Instance" then error(Model.." isnt a instance") end
	if not Model:IsA("Model") then error(Model.Name.." isnt a model") end
	if not Model.PrimaryPart then Model.PrimaryPart = Model:FindFirstChildWhichIsA("BasePart") end

	task.spawn(function()
		local Primary = Model.PrimaryPart
		local AnchorState = Primary.Anchored

		local TW = TS:Create(Primary,Tweeninfo,{Size = Primary.Size * Size})

		for _,v in pairs(Model:GetDescendants()) do
			if v:IsA("BasePart") and v ~= Primary then
				local state = v.Anchored
				v.Anchored = true
				local T = TS:Create(v,Tweeninfo,{Size = v.Size * Size;Position = v.Position + (CalculatePosition(Primary,v) * (Size-1))})
				
				task.spawn(function()
					TW:GetPropertyChangedSignal("PlaybackState"):Wait()
					if v:FindFirstChildWhichIsA("SpecialMesh") then
						local mesh = v:FindFirstChildWhichIsA("SpecialMesh")
						TS:Create(mesh,Tweeninfo,{Scale = mesh.Scale * Size}):Play()
					end
					T:Play()
					v.Anchored = state
				end)
			end

			if v:IsA("Weld") or v:IsA("WeldConstraint") or v:IsA("ManualWeld") or v:IsA("Motor6D") then
				if v.Name ~= "TweenWeld" then
					v.Enabled = false
					task.spawn(function()
						TW.Completed:Wait()
						v.Enabled = true
					end)
				end
			end
		end

		TW:Play()
		TW.Completed:Wait()

		Primary.Anchored = AnchorState
	end)

	return
end

function module.TweenModuleOrientation(Model,Tweeninfo,oOrinetation)
	if typeof(Model) ~= "Instance" then error(Model.." isnt a instance") end
	if not Model:IsA("Model") then error(Model.Name.." isnt a model") end
	if not Model.PrimaryPart then Model.PrimaryPart = Model:FindFirstChildWhichIsA("BasePart") end

	task.spawn(function()
		local Primary = Model.PrimaryPart
		local AnchorState = Primary.Anchored

		local TW = TS:Create(Primary,Tweeninfo,{CFrame = Primary.CFrame * CFrame.Angles(math.rad(oOrinetation.X),math.rad(oOrinetation.Y),math.rad(oOrinetation.Z))})

		for _,v in pairs(Model:GetDescendants()) do
			if v:IsA("BasePart") and v ~= Primary then
				local weld
				if not v:FindFirstChild("TweenWeld") then
					weld = Instance.new("WeldConstraint")
					weld.Part0 = Primary
					weld.Part1 = v
					weld.Parent = v
					weld.Name = "TweenWeld"
				else
					weld = v:FindFirstChild("TweenWeld")
					weld.Enabled = true
				end

				local anchord = v.Anchored
				v.Anchored = false
				task.spawn(function()
					TW.Completed:Wait()

					weld.Enabled = false
					v.Anchored = anchord
				end)
				
				continue
			end
			if v:IsA("Weld") or v:IsA("WeldConstraint") or v:IsA("ManualWeld") or v:IsA("Motor6D") then
				if v.Name ~= "TweenWeld" then
					v.Enabled = false
					task.spawn(function()
						TW.Completed:Wait()

						v.Enabled = true
					end)
				end
				
				continue
			end
			
			task.wait()
		end

		TW:Play()
		TW.Completed:Wait()

		Primary.Anchored = AnchorState
	end)
	return
end

function module.TweenModuleTransparency(Model,Tweeninfo,Transparency)
	if typeof(Model) ~= "Instance" then error(Model.." isnt a instance") end
	if not Model:IsA("Model") then error(Model.Name.." isnt a model") end
	for _,v in ipairs(Model:GetDescendants()) do
		if v:IsA("BasePart") then
			TS:Create(v,Tweeninfo,{Transparency = Transparency}):Play()
		end
	end
end

function module.TweenModuleColor(Model,Tweeninfo,ColorR)
	if typeof(Model) ~= "Instance" then error(Model.." isnt a instance") end
	if not Model:IsA("Model") then error(Model.Name.." isnt a model") end
	for _,v in ipairs(Model:GetDescendants()) do
		if v:IsA("BasePart") then
			TS:Create(v,Tweeninfo,{Color = ColorR}):Play()
		end
	end
end

return module
