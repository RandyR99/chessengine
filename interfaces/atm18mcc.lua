interface = load_interface("avrmax")

function interface.get_module()
	if machine.system.name == "atm18mcc" then
		return "AVR-Max ATM 18 Chess Computer"
	elseif machine.system.name == "cc2schach" then
		return "AVR-Max CC 2 Schachzwerg"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Andre Adrian & H.G. Muller"
end

function interface.is_selected(x, y)
	local ddram = emu.item(machine.devices[':lcd'].items['0/m_ddram'])
	local d0 = ddram:read(0x10) - 0x40
	local d1 = ddram:read(0x11) - 0x30
	local d2 = ddram:read(0x12) - 0x40
	local d3 = ddram:read(0x13) - 0x30
	return (x == d0 and y == d1) or (x == d2 and y == d3)
end

return interface
