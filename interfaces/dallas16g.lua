interface = load_interface("glasgow")

function interface.get_module()
	return machine.system.description
end

function interface.get_author()
	return "Richard Lang"
end

return interface
