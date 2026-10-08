interface = load_interface("supercon")

function interface.get_module()
	if machine.system.name == "const" then
		return "Novag Constellation"
	elseif machine.system.name == "const36" then
		return "Novag Constellation 3.6"
	elseif machine.system.name == "const36a" then
		return "Novag Constellation 3.6 v2"
	elseif machine.system.name == "constq" then
		return "Novag Constellation Quattro"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "David Kittinger"
end

return interface
