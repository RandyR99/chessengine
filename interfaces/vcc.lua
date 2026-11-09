interface = load_interface("cc10")

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.get_module()
	return "Fidelity Voice Chess Challenger"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local lcd_num = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x67, 0x76 }
	local presses = 0
	repeat
		send_input(":IN.0", 0x02, 0.5) -- LV
		presses = presses + 1
	until output_value("digit3") == lcd_num[interface.level] or presses > 25
	send_input(":IN.2", 0x01, 0.5) -- CL
end

local greeting = 8.5 -- the spoken introduction after a reset, in seconds
local first_setup = true

-- cc10's edit_game(false) calls setup_machine to clear the machine before the final position
local cc10_edit_game = interface.edit_game
function interface.edit_game(on)
	interface.clearing = not on
	cc10_edit_game(on)
	interface.clearing = false
end

function interface.setup_machine()
	interface.invert = false
	interface.turn = true
	if interface.clearing then
		-- RE: edit_game needs a clean board (in Problem Mode EN toggles the color of a piece already there)
		send_input(":RESET", 0x01, 1)  -- RE
		emu.wait(6.0) -- spoken introduction
	elseif first_setup then
		-- just powered on: let the greeting finish instead of starting it again with RE
		local left = greeting - machine.time:as_double()
		if left > 0 then
			emu.wait(left)
		end
	else
		-- init.lua soft-resets the machine (same as RE) before this call
		emu.wait(greeting)
	end
	first_setup = false
	interface.set = false
	interface.stm = 1

	interface.cur_level = 1
	interface.setlevel()
end

function interface.start_play(init)
	interface.turn = false
	send_input(":IN.2", 0x01, 0.5) -- CL
	send_input(":IN.1", 0x02, 0.5) -- DM
	send_input(":IN.2", 0x02, 0.5) -- PB
end

return interface
