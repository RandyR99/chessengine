interface = load_interface("fex68k")

interface.level = "a1"
interface.cur_level = nil

function interface.get_module()
	return "Fidelity Excel Mach IV"
end

function interface.get_author()
	return "Dan & Kathe Spracklen"
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	emu.wait(1)
	send_input(":IN.0", 0x80, 1) -- CLEAR
	emu.wait(1)
	machine.video.throttled = throttled_state
	interface.display_options()
	interface.cur_level = "a1"
	interface.setlevel()
end

return interface
