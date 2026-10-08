interface = load_interface("conc")

function interface.get_module()
	return "Conchess Princhess Glasgow"
end

function interface.get_author()
	return "Ulf Rathsman"
end

function interface.setup_machine()
	sb_reset_board(":board")
	emu.wait(1)
	interface.cur_level = "P2"
	interface.setlevel()
end

function interface.get_options()
	return {
		{ "string", "Level", "L2" },
	}
end

return interface
