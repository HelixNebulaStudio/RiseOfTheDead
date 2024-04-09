-- This module displays a radial (circular) progress indicator based on images and config information
-- that is generated at https://eryn.io/RadialSpriteSheetGenerator/
-- @readme https://github.com/evaera/RadialSpriteSheetGenerator/blob/master/README.md
-- @author evaera

local HttpService = game:GetService("HttpService")

local RadialImage = { _version = 1 }
RadialImage.__index = RadialImage

local ConfigurationProperties = {
	version = "number";
	size = "number";
	count = "number";
	columns = "number";
	rows = "number";
	images = "table";
}

function RadialImage.new(config, label)
	if type(config) == "string" then
		config = HttpService:JSONDecode(config)
	elseif type(config) ~= "table" then
		error("Argument #1 (configuration) must be a JSON string or table.", 2)
	end

	for k, v in pairs(config) do
		if ConfigurationProperties[k] == nil then
			error(("Invalid property name in Radial Image configuration: %s"):format(k), 2)
		end

		if type(v) ~= ConfigurationProperties[k] then
			error(("Invalid property type %q in Radial Image configuration: must be a %s."):format(k, ConfigurationProperties[k]), 2)
		end
	end

	if config.version ~= RadialImage._version then
		error(("Passed configuration version does not match this module's version (which is %d)"):format(RadialImage._version), 2)
	end

	local self = { config = config; label = label }
	setmetatable(self, RadialImage)
	
	return self
end

function RadialImage:GetFromAlpha(alpha)
	if type(alpha) ~= "number" then
		error("Argument #1 (alpha) to GetFromAlpha must be a number.", 2)
	end

	local count, size, columns, rows = self.config.count, self.config.size, self.config.columns, self.config.rows
	local index = alpha >= 1 and count - 1 or math.floor(alpha * count)
	local page = math.floor(index / (columns * rows)) + 1
	local pageIndex = index - (columns * rows * (page - 1))
	local x = (pageIndex % columns) * size
	local y = math.floor(pageIndex / rows) * size

	return x, y, page
end

function RadialImage:UpdateLabel(alpha, label)
	label = label or self.label

	if type(alpha) ~= "number" then
		error("Argument #1 (alpha) to UpdateLabel must be a number.", 2)
	end

	if typeof(label) ~= "Instance" or not (label:IsA("ImageLabel") or label:IsA("ImageButton")) then
		error("Attempt to update label but no label has been given. Either pass the label as argument #2 to \"new\", or as argument #2 to \"UpdateLabel\".", 2)
	end

	local x, y, page = self:GetFromAlpha(alpha)

	label.ImageRectSize = Vector2.new(self.config.size, self.config.size)
	label.ImageRectOffset = Vector2.new(x, y)
	label.Image = alpha <= 0 and "" or self.config.images[page]
end

return RadialImage