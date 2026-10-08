interface = load_interface("mm4")

function interface.get_module()
	if machine.system.name == "mm5" then
		return "Mephisto MM V"
	elseif machine.system.name == "mm5a" then
		return "Mephisto MM V v2"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Ed Schröder"
end

return interface
