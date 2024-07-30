local MarkupFormatter = {};
MarkupFormatter.TestString = "## Revived 1.5.9 Update\n\n```\nDev Log: Press [F1] in-game to open update logs.\n```\n\n**1.5.9.36**\n\n### **New:**\n\n• New rare mod, **Rocketman**. For weapons with the rocket tag, currently only the **AT4**. Gives the weapon the ability to fire without reloading while player is in the air.\n\n• New survival system. **Normal** & **Endless** modes. Normal mode completes in 5 or less waves while Endless is endless. There are now **objectives and hazards** during each waves and they have their own chances of occuring. Different combination of objectives and hazard creates a different challenge every wave. **Currently, the new survival system is only available in the new survival map, Community: Fission Bay.**\n• New map, Community: Fission Bay. A survival map by **Omega913**. Survive hazards and zombies on an abandoned offshore port, surrounded by the cruel and contaminated ocean... let's hope luck is on your side. Purchasable in Gold Shop.\n• New Head Clothing, **Hard Hat**. A construction hard hat, provides light to the surrounding. Obtainable from Community Crate: Alpha.\n• Pathoroth now has a chance to drop **Annihilation Soda**.\n\n### **Changes:**\n\n• Night Vision Goggles will now light up dark spots brighter based on the outdoor ambient.\n• Updated molotov AOE highlight."

function MarkupFormatter.Format(essay)
	local head = false;

	essay = string.gsub(essay, `(%[%[.-%](.-)%])`, "");

	essay = string.gsub(essay, "[%*][%*]", function(s)
		head = not head;
		if head then
			return '<b><font color="rgb(255,255,255)">'..s:sub(#s+2, #s);
		else
			return '</font></b>'..s:sub(#s+2, #s);
		end
	end)
	head = false;
	
	essay = string.gsub(essay, "[%*]", function(s)
		head = not head;
		if head then
			return "<i>"..s:sub(#s+2, #s);
		else
			return "</i>"..s:sub(#s+2, #s);
		end
	end)
	head = false;

	essay = string.gsub(essay, "_", function(s)
		head = not head;
		if head then
			return "<i>"..s:sub(#s+1, #s);
		else
			return "</i>"..s:sub(#s+1, #s);
		end
	end)
	
	essay = string.gsub(essay, "```", function(s)
		head = not head;
		if head then
			return "<!--"..s:sub(#s+1, #s);
		else
			return "-->"..s:sub(#s+1, #s);
		end
	end)
	
	local function newheader(str, pat, func)
		local lines = string.split(str, "\n");
		for a=1, #lines do
			if lines[a]:sub(0, #pat) == pat then
				lines[a] = func(lines[a]:sub(#pat+1, #lines[a]));
			end
		end

		return table.concat(lines, "\n");
	end

	essay = newheader(essay, "---", function(lineText)
		return `\n<s>{string.rep(" ", 128)}</s>`;
	end)
	essay = newheader(essay, "- ", function(lineText)
		if #lineText <= 3 then
			return '\n';
		end
		return '\n    • '.. lineText .. '';
	end)
	essay = newheader(essay, "  - ", function(lineText)
		return '\n         • '.. lineText .. '';
	end)
	essay = newheader(essay, "    - ", function(lineText)
		return '\n              • '.. lineText .. '';
	end)
	essay = newheader(essay, "      - ", function(lineText)
		return '\n                   • '.. lineText .. '';
	end)
	
	
	essay = newheader(essay, "###", function(lineText)
		return '\n\n<font size="20" color="rgb(255,255,255)">'.. lineText .. '</font>';
	end)

	essay = newheader(essay, "##", function(lineText)
		return '\n<font size="24" color="rgb(255,255,255)">'.. lineText .. '</font>';
	end)
	
	essay = newheader(essay, "#", function(lineText)
		return '<font size="32" color="rgb(255,255,255)">'.. lineText .. '</font>';
	end)

	return essay;
end

return MarkupFormatter;