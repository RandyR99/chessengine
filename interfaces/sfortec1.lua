interface = load_interface("sfortec")

function interface.get_module()
	return "Novag Super Forte C v2"
end

function interface.get_author()
	return "David Kittinger"
end

return interface
