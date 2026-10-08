interface = load_interface("chesstrv")

function interface.get_module()
	return "Saitek International Traveler"
end

function interface.get_author()
	return "Mike Johnson"
end

return interface
