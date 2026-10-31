interface = load_interface("polgar")

function interface.get_module()
	if machine.system.name == "mrisc" then
		return "Mephisto Risc"
	elseif machine.system.name == "mrisc2" then
		return "Mephisto Risc II"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Ed Schröder"
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	emu.wait(12)
	machine.video.throttled = throttled_state
	interface.cur_level = ""
	interface.setlevel()
end

function interface.select_piece(x, y, event)
	-- the 2.5 MHz main CPU polls the board slowly: a 1 s press without a pause sometimes lost the put of a capture
	sb_select_piece(":board:board", 1.5, x, y, event)
	emu.wait(1)
end

-- show_info: the RISC program runs on the ARM coprocessor, but the main CPU keeps what it receives for the INFO
-- display in RAM like the Polgar program: the main line as square pairs (file * 10 + rank) at 0x0120 (copy at
-- 0x01b0) and the evaluation for the machine as text at 0x0148 ("-8.94"), both updated when the search finds a new
-- best move (found by RAM dumps during the search). Read with mega4's reader, no key presses; no depth found.
local mega4 = load_interface("mega4")
mega4.pv_ram = 0x0120
mega4.score_ram = nil
mega4.score_text_ram = 0x0148
mega4.depth_ram = nil
interface.show_info = mega4.show_info
interface.info_every = 1 -- show_info only reads RAM

return interface

