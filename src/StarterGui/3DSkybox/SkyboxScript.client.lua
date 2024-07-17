--[[
	
	This allows you to create a simple "3D Skybox" using ViewportFrames.
	
	Simply place a creation under the 'ViewportFrame' object, and then the game runs, you will see the object.
	
--]]
	

-- Settings

--local SKYBOX_DISTANCE = 10000							-- The distance where the skybox gui plane is.
--local SKYBOX_ORIGIN = Vector3.new(0, 0, 0)				-- The origin for the camera used by the skybox.
--
--local SKYBOX_ALLOW_MOVEMENT = true						-- This allows the skybox to 'move' as if it were actuallying in the workspace.
--local SKYBOX_MOVEMENT_SCALE = 2500						-- This is the scale for movement, use math.huge for no movement.

local SKYBOX_DISTANCE = 10000							-- The distance where the skybox gui plane is.
local SKYBOX_ORIGIN = Vector3.new(0, 0, 0)				-- The origin for the camera used by the skybox.

local SKYBOX_ALLOW_MOVEMENT = false						-- This allows the skybox to 'move' as if it were actuallying in the workspace.
local SKYBOX_MOVEMENT_SCALE = 2500						-- This is the scale for movement, use math.huge for no movement.


-- Setup Variables
local modConfigurations = require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("Configurations"));
if modConfigurations.Disable3DSkybox == true then return end;

local Player = game:GetService("Players").LocalPlayer
local Skybox = script.Parent
local Viewport = Skybox:WaitForChild("ViewportFrame")
local Camera = game.Workspace.CurrentCamera


-- Creates the Skybox Camera
local SkyboxCamera = Instance.new("Camera")
SkyboxCamera.Parent = Skybox


-- Creates the CamPart to adorn the skybox gui to.
local CamPart = Instance.new("Part")
CamPart.Anchored = true
CamPart.Transparency = 1
CamPart.CanCollide = false
CamPart.Parent = SkyboxCamera


-- Sets the viewport's camera to the skybox camera.
Viewport.CurrentCamera = SkyboxCamera


-- Adorns the Skybox Gui to the CameraPart and enables it.
Skybox.Adornee = CamPart
Skybox.Enabled = true


-- Update the dimensions of the gui if the game window size updates.
Skybox.Size = UDim2.new(0, Camera.ViewportSize.X, 0, Camera.ViewportSize.Y)
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	Skybox.Size = UDim2.new(0, Camera.ViewportSize.X, 0, Camera.ViewportSize.Y)
end)


-- Starts a loop to keep updating the skybox camera.
game:GetService("RunService").RenderStepped:Connect(function()
	if game.Lighting:GetAttribute("OutdoorAmbient") then
		Viewport.ImageColor3 = game.Lighting:GetAttribute("OutdoorAmbient");
	end

	local camPos = SKYBOX_ORIGIN	-- Sets the Skybox Camera's position to the SKYBOX_ORIGIN.
	
	-- Checks to see if SKYBOX_ALLOW_MOVEMENT is enabled.
	if SKYBOX_ALLOW_MOVEMENT then
		camPos = SKYBOX_ORIGIN + (Camera.CFrame.Position / SKYBOX_MOVEMENT_SCALE)		-- Overrides the camPos and scales movement.
	end
	
	SkyboxCamera.FieldOfView = Camera.FieldOfView;
	
	CamPart.CFrame = Camera.CFrame * CFrame.new(0, 0, -SKYBOX_DISTANCE)	-- Sets the camerapart to be the correct distance.
	
	SkyboxCamera.CFrame = CFrame.fromMatrix(camPos, Camera.CFrame.RightVector, Camera.CFrame.UpVector)	-- Sets skybox Camera CFrame.
	
end)