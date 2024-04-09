local ReplicatedStorage = game:GetService("ReplicatedStorage")

local wallyInstanceManager = {}

function wallyInstanceManager.add(project: Instance, targetInstance: Instance)
	if not ReplicatedStorage:FindFirstChild(project.Name) then
		local folder = Instance.new("Folder")
		folder.Name = project.Name
		folder.Parent = ReplicatedStorage
	end

	targetInstance.Parent = ReplicatedStorage:FindFirstChild(project.Name)
end

function wallyInstanceManager.get(project: Instance, instanceName: string)
	return if ReplicatedStorage:FindFirstChild(project.Name) ~= nil
		then ReplicatedStorage[project.Name]:FindFirstChild(instanceName)
		else nil
end

function wallyInstanceManager.waitForInstance(project: Instance, instanceName: string, maxTimeout: number)
	local projectFolder = ReplicatedStorage:WaitForChild(project.Name)

	return projectFolder:WaitForChild(instanceName, maxTimeout or 1)
end

return wallyInstanceManager
