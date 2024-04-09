local SearchBar = {}

function SearchBar.CreateSearchBar(textbox, database, templateSearch, Select)
	local queryList = {};
	
	local function refreshSearchSuggestions()
		textbox:ClearAllChildren();
		if next(queryList) ~= nil then
			local c = 1;
			for name, data in pairs(queryList) do
				local Name = name;
				local Data = data;
				local new = templateSearch:Clone();
				new.Parent = textbox;
				new.Text = name;
				new.Position = UDim2.new(0, 0, c, 0);
				c = c +1;
				new.MouseButton1Click:Connect(function()
					queryList = {};
					textbox.Text = Name;
					Select(name, Data);
					refreshSearchSuggestions();
				end)
			end
		end
	end
	
	textbox:GetPropertyChangedSignal("Text"):Connect(function()
		queryList = {};
		if #textbox.Text > 0 then
			for name, data in pairs(database) do
				if name:lower() == textbox.Text:lower() then
					queryList = {};
					Select(name, data);
					break;
				elseif name:lower():match(textbox.Text:lower()) ~= nil then
					queryList[name] = data; 
				end 
			end
		end
		refreshSearchSuggestions();
	end)
end

return SearchBar;
