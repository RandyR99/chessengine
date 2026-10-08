interface = load_interface("berl32t8p")

function interface.get_module()
	return "Mephisto Vancouver 68030"
end

function interface.get_author()
	return "Richard Lang"
end

return interface
