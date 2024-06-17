local GuiService = game:GetService("GuiService");

local ViewportUtil = {};
--==

function ViewportUtil.RaycastInViewportFrame(viewportFrame: ViewportFrame, x: number, y: number, raycastDistance: number, raycastParams: Ray)
	local camera = viewportFrame.CurrentCamera
	local worldModel = viewportFrame:FindFirstChildWhichIsA("WorldModel")
	local mousePosition = Vector2.new(x,y-GuiService.TopbarInset.Height) - viewportFrame.AbsolutePosition -- account for viewportframe offset
	local relativePosition = ((mousePosition - (viewportFrame.AbsoluteSize/2)) * Vector2.new(1, -1))/(viewportFrame.AbsoluteSize/2) -- get the relative position of the click with center of viewportFrame as origin: -1 is left/bottom and 1 is right/top for X and Y respectively
	local projectedY = math.tan(math.rad(camera.FieldOfView)/2)*raycastDistance -- the projected height of a 2D frame raycastDistance studs from the camera with same aspect ratio
	local projectedX = projectedY * (viewportFrame.AbsoluteSize.X/viewportFrame.AbsoluteSize.Y) -- projected width from aspect ratio
	local projectedPosition = Vector2.new(projectedX, projectedY) * relativePosition -- the projected position of the input on the similar frame
	local worldPosition = (camera.CFrame * CFrame.new(projectedPosition.X, projectedPosition.Y, -raycastDistance)).Position -- the 3d position of said projected position
	return worldModel:Raycast(camera.CFrame.Position, (worldPosition - camera.CFrame.Position).Unit * raycastDistance, raycastParams)
end

function ViewportUtil.ViewportFramePointToRay(viewportFrame, x, y, depth) -- similar to Camera:ScreenPointToRay
	depth = depth or 0
	local camera = viewportFrame.CurrentCamera
	local mousePosition = Vector2.new(x,y-GuiService.TopbarInset.Height) - viewportFrame.AbsolutePosition -- account for viewportframe offset
	local relativePosition = ((mousePosition - (viewportFrame.AbsoluteSize/2)) * Vector2.new(1, -1))/(viewportFrame.AbsoluteSize/2) -- get the relative position of the click with center of viewportFrame as origin: -1 is left/bottom and 1 is right/top for X and Y respectively
	local projectedY = math.tan(math.rad(camera.FieldOfView)/2) * (1 + depth) -- the projected height of a 2D frame 1 + depth studs from the camera with same aspect ratio
	local projectedX = projectedY * (viewportFrame.AbsoluteSize.X/viewportFrame.AbsoluteSize.Y) -- projected width from aspect ratio
	local projectedPosition = Vector2.new(projectedX, projectedY) * relativePosition -- the projected position of the input on the similar frame
	local worldPosition = (camera.CFrame * CFrame.new(projectedPosition.X, projectedPosition.Y, -(1 + depth))).Position -- the 3d position of said projected position
	local rayOrigin = (CFrame.new(camera.CFrame.Position, worldPosition) * CFrame.new(0, 0, -depth)).Position
	local rayDirection = worldPosition - rayOrigin
	return Ray.new(rayOrigin, rayDirection)
end

return ViewportUtil;