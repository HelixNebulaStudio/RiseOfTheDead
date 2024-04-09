--[=[
	
	Created by boatbomber --------------------------- https://twitter.com/BoatbomberRBLX
		© 2019
		
	Explanation, full example place, documentaion, and discussion here:
	
	https://devforum.roblox.com/t/bounds-constrained-highlighter/259577
	
	------------------------------------------------------------------------------------
	Module Description:
	
	Inspired by Apex Legends, this module is used to easily create a sight that
	highlights enemy humanoids using only a few lines of code on your end. It highlights
	models that are unobstructed and visible within the specified bounds of the sight.
	
	------------------------------------------------------------------------------------
	Module API:
		
	function	BoundsHighlighter:Start()
		Description:
			Enables the highlighter
		Note:
			Cannot be called until a BoundsPart is set via :SetBoundsPart()
	
	
	function	BoundsHighlighter:Stop()
		Description:
			Disables the highlighter
		Note:
			None
		
			
	function	BoundsHighlighter:Render(Model)
		Description:
			Adds a model to the rendering process
		Note:
			Designed for standard Humanoids, so it won't do Parts inside of Parts
		
			
	function	BoundsHighlighter:AddToIgnoreList(Instance)
		Description:
			Adds an instance to the ignore list of the visibility checks
		Note:
			None
		
			
	function	BoundsHighlighter:SetBoundsPart(BasePart)
		Description:
			Sets the part that will be used to calculate the bounds
		Note:
			The part's Front face must be facing the camera (at least mostly)
			
			
	------------------------------------------------------------------------------------
	Example Usage:
		
	for i, npc in pairs(workspace.NPCs:GetChildren()) do
		BoundsHighlighter:Render(npc)
	end
	
	BoundsHighlighter:SetBoundsPart(FPSViewModel.Sight)
	BoundsHighlighter:AddToIgnoreList(FPSViewModel)
	
	BoundsHighlighter:Start()
	
	------------------------------------------------------------------------------------
	
		
--]=]


-- Variables

	-- Services
local RunService	= game:GetService("RunService")

	-- Core objects
local Camera		= workspace.CurrentCamera

	-- Localizations
local cf,ray,v2,v3			= CFrame.new,Ray.new,Vector2.new,Vector3.new
local WorldToViewportPoint	= Camera.WorldToViewportPoint
local pickReturn			= select
local ToOrientation			= cf().ToOrientation

	-- Gui
local ScreenGui		= Instance.new("ScreenGui")
	ScreenGui.IgnoreGuiInset	= true
	ScreenGui.Name				= "HighlightSight"
	
local ViewportFrame	= Instance.new("ViewportFrame")
	ViewportFrame.CurrentCamera	= Camera
	ViewportFrame.Size			= UDim2.new(1,0,1,0)
	ViewportFrame.BackgroundTransparency	= 1
	ViewportFrame.Parent		= ScreenGui
	
ScreenGui.Parent	= game.Players.LocalPlayer:WaitForChild("PlayerGui")

	-- Module related
local Highlighter	= {};

local Enabled			= false
local BoundsPart	= nil
local IgnoreList		= {}

local RenderModels	= {};

local BoundsPos, BoundsSize	= v2(), v2()
-- These actually don't need to be updated every single frame.
-- I've tested, and you get acceptable results with a simple wait() loop
-- and it has a lower performance cost.

spawn(function()
	while wait() do
		if Enabled and BoundsPart then
			
			local cframe,size = BoundsPart.CFrame,BoundsPart.Size
	
			-- This is why it's not worth doing every frame; this area calculation isn't too cheap
			local tR	= WorldToViewportPoint(Camera,	cframe * v3(-size.x/2,  size.y/2, -size.z/2))
			local bR	= WorldToViewportPoint(Camera,	cframe * v3(-size.x/2, -size.y/2, -size.z/2))
			local tL	= WorldToViewportPoint(Camera,	cframe * v3( size.x/2,  size.y/2, -size.z/2))
			local p		= WorldToViewportPoint(Camera,BoundsPart.Position)
			
			
			BoundsSize	= v2(
				(v3(tR.X,tR.Y,0)-v3(tL.X,tL.Y,0)).magnitude,
				(v3(tR.X,tR.Y,0)-v3(bR.X,bR.Y,0)).magnitude
			)
			BoundsPos	= v2(p.X-(BoundsSize.X/2),p.Y-(BoundsSize.Y/2))
		end
	end
end)

	-- Functions for the module's usage
local function InBounds(Object)
	
	-- This function DOES NOT account for rotation.
	-- However, it provides results that are close enough
	-- to fulfill our basic usage cases. Calculating
	-- rotation makes the module slower and take roughly
	-- double the CPU power. If you know of a good method,
	-- please let me know!
	
	local ObjectPos	= WorldToViewportPoint(Camera, Object.Position)
	
	if (ObjectPos.X<BoundsPos.X) or (ObjectPos.X>(BoundsPos.X+BoundsSize.X)) then
		-- Out of it left/right
		return false
	end
	
	if (ObjectPos.Y<BoundsPos.Y) or (ObjectPos.Y>(BoundsPos.Y+BoundsSize.Y)) then
		-- Out of it top/bottom
		return false
	end
	
	-- Passed all checks
	return true
	
end

RunService.RenderStepped:Connect(function()
	--Each render step, we perform our highlight checks
	
	if Enabled and BoundsPart then
	
		local SightPos = (BoundsPart or Camera).CFrame.Position
		
		for i=1, #RenderModels do
			-- Handle each model
			local RenderMod	= RenderModels[i]
			
			local Model		= RenderMod[1][2]:FindFirstAncestorOfClass("Model")
			local Folder	= RenderMod[1][3]
			
			--Optimized FoV check
			local v do
				local x1, y1	= ToOrientation(Camera.CFrame)
				local newcf		= cf(Camera.CFrame.Position, ((Model.PrimaryPart and Model.PrimaryPart.Position) or Model:GetModelCFrame()).Position)
				local x2, y2	= ToOrientation(newcf)
				v = (57.295779513082 * (y1-y2)) + (57.295779513082 * (x1-x2))
				v = v >= 0 and v or 0 - v
				v = v*2
			end
			if (v)<(Camera.FieldOfView+35) then
				-- We only check each part if the model is within FoV.
				-- If it isn't within FoV, 99% of the time the parts
				-- won't be in the sight
				
				for x=1, #RenderMod do
					-- Handle each object in the model
					local RenderObj			= RenderMod[x]
					local Clone, WorldPart	= RenderObj[1], RenderObj[2]
					
					-- Raycast visibility check
					local hit = workspace:FindPartOnRayWithIgnoreList(ray(SightPos,(WorldPart.Position - SightPos).unit * ((WorldPart.Position - SightPos).magnitude + 0.5)), IgnoreList)
						-- Note that the ray will size according to the distance, ensuring it is as small as we can get it
						-- Raycast performance is heavily dependant on length, so this should help a lot
					if hit and hit:IsDescendantOf(Model) then
						-- Hitting the model means it's visible
						if InBounds(WorldPart) then
							-- Object is visible and in the sight
							Clone.CFrame		= WorldPart.CFrame
							Clone.Transparency	= 0
						else
							-- Visible but not in the sight
							Clone.Transparency	= 1
						end
					else
						--In FoV but not visible
						Clone.Transparency	= 1
					end
				end	
					
			else
				-- Model isn't in FoV, hide all parts
				for x=1, #RenderMod do
					RenderMod[x][1].Transparency = 1
				end					
			end
			
		end
		
	end
end)

-- Module methods

	-- Set the boundspart
function Highlighter:SetBoundsPart(Object)
	assert(
		(Object) and (typeof(Object) == "Instance") and (Object:IsA("BasePart")),
		"Invalid BoundsPart. Must be an existing BasePart"
	)
	
	BoundsPart = Object
end
	-- Highlighted enabled inside given object
function Highlighter:Start()
	assert(BoundsPart, "Cannot start without valid BoundsPart. Set one via :SetBoundsPart(Object) before calling :Start()")
	
	Enabled = true
end;
	-- Disable highlighting
function Highlighter:Stop()
	Enabled = false
	
	for i=1, #RenderModels do
		-- Hide each model
		local RenderMod	= RenderModels[i]
		for x=1, #RenderMod do
			RenderMod[x][1].Transparency = 1
		end
	end
		
end;
	--Add to IgnoreList
function Highlighter:AddToIgnoreList(Object)
	assert(
		(Object) and (typeof(Object) == "Instance"),
		"Invalid ignore object. Must be an existing Instance"
	)
	
	IgnoreList[#IgnoreList+1] = Object
end;
	-- Add model to the renderer
function Highlighter:Render(Model)
	assert(
		(Model) and (typeof(Model) == "Instance") and (Model:IsA("Model")),
		"Invalid render object. Must be an existing Model"
	)
	
	local RenderMod	= {}
	
	
	local Folder	= Instance.new("Folder")
		Folder.Name		= Model.Name
		
	for i, WorldPart in pairs(Model:GetChildren()) do
		if WorldPart:IsA("BasePart") and WorldPart.Transparency < 0.98 then
			local Clone = WorldPart:Clone()
			
				for i, cChild in pairs(Clone:GetChildren()) do
					if not cChild:IsA("SpecialMesh") then
						-- Get rid of textures and scripts and stuff
						cChild:Destroy()
					else
						-- Remove mesh textures
						cChild.TextureId = ''
					end
				end
				
				if Clone:IsA("MeshPart") then
					-- Remove mesh textures
					Clone.TextureID = ''
				end
				
				-- Highlight color
				Clone.Color = Color3.new(0.9,0,0)
				Clone.Transparency	= 1
				
			Clone.Parent = Folder
				
				--Add object to array
				RenderMod[#RenderMod+1] = {Clone,WorldPart,Folder}
			
		elseif WorldPart:IsA("Accoutrement") then
			if WorldPart:FindFirstChild("Handle") then
				if WorldPart.Handle:IsA("BasePart") then
					local Clone =  WorldPart.Handle:Clone()
					
						for i, cChild in pairs(Clone:GetChildren()) do
							if not cChild:IsA("SpecialMesh") then
								-- Get rid of textures and scripts and stuff
								cChild:Destroy()
							else
								-- Remove mesh textures
								cChild.TextureId = ''
							end
						end
						
						-- Highlight color
						Clone.Color = Color3.new(0.9,0,0)
						Clone.Transparency	= 1
						
					Clone.Parent = Folder
						
						--Add object to array
						RenderMod[#RenderMod+1] = {Clone,WorldPart.Handle,Folder}
				end
			end
		end
	end
	
	RenderModels[#RenderModels+1] = RenderMod
		
	Folder.Parent	= ViewportFrame
	
end;

return Highlighter
