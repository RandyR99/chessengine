interface = load_interface("ccmk1")

function interface.get_module()
	return "DataCash System CompuChess 2"
end

function interface.get_author()
	return "David B. Goodrich"
end

return interface
