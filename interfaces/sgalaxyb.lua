interface = load_interface("sgalaxy")

function interface.get_module()
	return "CXG Sphinx Galaxy v1.03"
end

function interface.get_author()
	return "Frans Morsch"
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		local level = value:lower():match("^%s*(.-)%s*$"):gsub("%s%s+"," ") -- trim
		if (level:match("^[a-d][1-8]$") or level:match("^e[12]$")) then
			interface.level = level
			interface.setlevel()
		end
	end
end

return interface
