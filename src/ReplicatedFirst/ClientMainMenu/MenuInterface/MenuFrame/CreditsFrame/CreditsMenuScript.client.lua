local RunService = game:GetService("RunService");
local HttpService = game:GetService("HttpService");
local contentFrame = script.Parent:WaitForChild("Content");
local pauserFrame = script.Parent:WaitForChild("PauserFrame");

local pause = false;

local peak, timer = 0, tick();
function autoscroll(delta)
	if not script.Parent.Visible or pause then return end;
	if contentFrame.CanvasPosition.Y > peak then peak = contentFrame.CanvasPosition.Y; timer=tick(); end;
	if tick()-timer > 2 then peak=0; timer=tick(); contentFrame.CanvasPosition = Vector2.new(0, 0); end;
	contentFrame.CanvasPosition = Vector2.new(0, contentFrame.CanvasPosition.Y+delta*35);
end

RunService:BindToRenderStep("CreditsAutoScroll", Enum.RenderPriority.Camera.Value, autoscroll);
wait(2);
pauserFrame.MouseEnter:Connect(function()
	pause = true;
end)
pauserFrame.MouseMoved:Connect(function()
	pause = true;
end)

pauserFrame.MouseLeave:Connect(function()
	peak, timer = 0, tick();
	pause = false;
end)

repeat until script.Parent.Visible or not wait(0.5);
local creditsFrameTemplate = script:WaitForChild("FrameTemplate");
local creditsRoleTemplate = script:WaitForChild("RoleTemplate");
local creditsNameTemplate = script:WaitForChild("NameTemplate");
local creditsJson = workspace:GetAttribute("CreditsJson");

for a=1, 5 do
	if creditsJson then
		continue;
	end
	creditsJson = workspace:GetAttribute("CreditsJson");
	task.wait(10);
end
local creditsTable = HttpService:JSONDecode(creditsJson or {LoadingError={}});

local totalY = 340;
for a=1, #creditsTable do
	for title, credits in pairs(creditsTable[a]) do
		local newFrame = creditsFrameTemplate:Clone();
		local titleLabel = newFrame:WaitForChild("Title");
		titleLabel.Text = title;
		local nameList = titleLabel:WaitForChild("NameList");
		local creditList = titleLabel:WaitForChild("CreditList");
		local frameTotalSize = 45;
		local order = 1;
		local success, e = pcall(function()
			for b=1, #credits do
				local memberCredits = credits[b].Credits;
				local memberName = credits[b].Name;
				print("Name:", memberName, #memberCredits, memberCredits)
				for c=1, #memberCredits do
					print(c..". ",memberCredits[c]);

					local newName = creditsNameTemplate:Clone();
					newName.LayoutOrder = order;
					newName.Parent = nameList;
					if c == 1 then
						newName.Text = memberName;
					else
						newName.Text = "";
					end
					local newRole = creditsRoleTemplate:Clone();
					newRole.LayoutOrder = order;
					newRole.Text = memberCredits[c];
					newRole.Parent = creditList;
					frameTotalSize = frameTotalSize +25
					order = order +1;
				end
			end
		end)
		if not success then 
			titleLabel.Text = title.."Error loading..";
			error(e);
		end
		newFrame.LayoutOrder = a;
		newFrame.Size = UDim2.new(1, 0, 0, frameTotalSize);
		newFrame.Parent = contentFrame;
		totalY = totalY + newFrame.AbsoluteSize.Y+40;
	end
end
contentFrame.CanvasSize = UDim2.new(0, 0, 0, totalY+340)