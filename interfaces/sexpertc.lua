interface = load_interface("sexpertb")

interface.sel = 5
interface.cur_sel = 5

function interface.get_module()
	return "Novag Super Expert C"
end

function interface.get_author()
	return "David Kittinger"
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	emu.wait(5)
	send_input(":IN.7", 0x01, 0.6) -- New Game
	emu.wait(1)
	machine.video.throttled = throttled_state
	interface.cur_level = "a1"
	interface.cur_sel = 5
	interface.setlevel()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	emu.wait(1)
	send_input(":IN.1", 0x01, 1) -- Set Level
	send_input(":IN.5", 0x02, 0.3) -- Sound
	ddram = emu.item(machine.devices[':hd44780'].items['0/m_ddram']):read_block(0x00, 0x80)
	if string.upper(ddram:sub(65,65)) == "F" then
		send_input(":IN.5", 0x02, 0.3)
	end
	send_input(":IN.0", 0x01, 1) -- Go
	machine.video.throttled = throttled_state
end

return interface
