interface = load_interface("berlinp")

function interface.get_module()
	if machine.system.name == "berl16" then
		return "Mephisto Berlin (16 Bit)"
	elseif machine.system.name == "berl16a" then
		return "Mephisto Berlin (16 Bit) v2"
	elseif machine.system.name == "berl16l" then
		return "Mephisto Berlin (London)"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Richard Lang"
end

-- show_info: berlinp (the programmable info display set up in setup_machine, read from the LCD)

return interface
