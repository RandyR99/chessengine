interface = load_interface("sdtor")

function interface.get_module()
	return "CXG Sphinx Commander"
end

function interface.get_author()
	return "Frans Morsch"
end

return interface
