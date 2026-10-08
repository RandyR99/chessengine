interface = load_interface("glasgow")

function interface.get_module()
	return "Mephisto Amsterdam v2"
end

function interface.get_author()
	return "Richard Lang"
end

return interface
