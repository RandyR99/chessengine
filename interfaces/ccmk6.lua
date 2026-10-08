interface = load_interface("ccmk5")

function interface.get_module()
	return "SciSys Chess Champion Mark VI"
end

function interface.get_author()
	return "David Broughton & Mark Taylor"
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	emu.wait(5)
	if ioport.ports[":IN.6"]:read() & 0x20 ~= 0 then
		ioport.ports[":IN.6"]:field(0x20):set_value(1)
		machine:soft_reset()
	end
	interface.turn = true
	interface.color = "B"
	emu.wait(2)
	send_input(":IN.0", 0x02, 0.5) -- New Game
	emu.wait(0.5)
	send_input(":IN.3", 0x08, 0.5) -- Yes
	emu.wait(0.5)
	machine.video.throttled = throttled_state
	interface.cur_level = ""
	interface.setlevel()
end

return interface
