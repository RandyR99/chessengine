interface = load_interface("fexcel")

function interface.get_module()
	if machine.system.name == "fexcelp" then
		return "Fidelity Par Excellence"
	elseif machine.system.name == "fexcelpa" then
		return "Fidelity Par Excellence v2"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Dan & Kathe Spracklen"
end

return interface
