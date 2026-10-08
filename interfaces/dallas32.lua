interface = load_interface("amsterd")

function interface.get_module()
	if machine.system.name == "dallas16" then
		return "Mephisto Dallas (16 Bit)"
	elseif machine.system.name == "dallas32" then
		return "Mephisto Dallas (32 Bit)"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Richard Lang"
end

return interface
