interface = load_interface("berl32t8p")

function interface.get_module()
	return "Mephisto London TM"
end

function interface.get_author()
	return "Richard Lang"
end

return interface
