interface = load_interface("ggm_morphy")

function interface.get_module()
	return "GGM Sandy Edition"
end

function interface.get_author()
	return "John Aker"
end

return interface
