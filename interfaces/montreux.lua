interface = load_interface("risc2500")

function interface.get_module()
	return "Mephisto Montreux"
end

function interface.get_author()
	return "Johan de Koning"
end

return interface
