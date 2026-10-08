interface = load_interface("feas")

function interface.get_module()
	if machine.system.name == "fpres" then
		return "Fidelity Prestige"
	elseif machine.system.name == "fpresbu" then
		return "Fidelity Prestige Budapest"
	elseif machine.system.name == "fpresgla" then
		return "Fidelity Prestige Glasgow"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Dan & Kathe Spracklen"
end

return interface
