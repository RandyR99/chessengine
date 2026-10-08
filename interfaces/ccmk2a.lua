interface = load_interface("ccmk2")

function interface.get_module()
	return "Chess Champion MK II v2"
end

function interface.get_author()
	return "Peter Jennings"
end

return interface
