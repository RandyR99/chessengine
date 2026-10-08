interface = load_interface("mm4")

interface.level = 1
interface.cur_level = nil
local lastx = 0
local lasty = 0

function interface.get_module()
	if machine.system.name == "rebel5" then
		return "Mephisto Rebell 5.0"
	elseif machine.system.name == "rebel5a" then
		return "Mephisto Rebell 5.0 v2"
	elseif machine.system.name == "rebel5b" then
		return "Mephisto Rebell 5.0 v3"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Ed Schröder"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":KEY.0", 0x10, 1) -- LEV
	local n = tonumber(interface.level)
	interface.setdigit(n)
	send_input(":KEY.0", 0x20, 1) -- ENT
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	ioport.ports[":RESET"]:field(0x01):set_value(1) -- Res 1
	ioport.ports[":RESET"]:field(0x02):set_value(1) -- Res 2
	emu.wait(0.3)
	ioport.ports[":RESET"]:field(0x01):set_value(0) -- RES 1
	ioport.ports[":RESET"]:field(0x02):set_value(0) -- RES 2
	emu.wait(0.5)
	sb_reset_board(":board:board")
	emu.wait(1)
	machine.video.throttled = throttled_state
	interface.cur_level = 1
	interface.setlevel()
end

function interface.is_selected(x, y)
	local xval = {0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71, 0x3d, 0x76}
	local yval = {0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f}
	
	local d0_state = machine.devices[":"]:output("digit0")
	local d1_state = machine.devices[":"]:output("digit1")
	local d2_state = machine.devices[":"]:output("digit2")
	local d3_state = machine.devices[":"]:output("digit3")
	local led_state = machine.devices[":"]:output("led" .. tostring(8 * (y - 1) + (x - 1)))
	
	local d0 = d0_state and (d0_state:get() & 0x7f) or 0
	local d1 = d1_state and (d1_state:get() & 0x7f) or 0
	local d2 = d2_state and (d2_state:get() & 0x7f) or 0
	local d3 = d3_state and (d3_state:get() & 0x7f) or 0
	local led_val = led_state and led_state:get() or 0
	
	return (xval[x] == d0 and yval[y] == d1) or (xval[x] == d2 and yval[y] == d3) or led_val ~= 0
end

function interface.select_piece(x, y, event)
	local d0_state = machine.devices[":"]:output("digit0")
	local d1_state = machine.devices[":"]:output("digit1")
	local d2_state = machine.devices[":"]:output("digit2")
	local d3_state = machine.devices[":"]:output("digit3")
	
	local d0 = d0_state and (d0_state:get() & 0x7f) or 0
	local d1 = d1_state and (d1_state:get() & 0x7f) or 0
	local d2 = d2_state and (d2_state:get() & 0x7f) or 0
	local d3 = d3_state and (d3_state:get() & 0x7f) or 0
	
	if ((d0 == 0x31 and d1 == 0x30 and d2 == 0x37 and d3 == 0x79) or (d0 == 0x77 and d1 == 0x06 and d2 == 0x77 and d3 == 0x06)) then -- 'TIME' or 'A1A1'
		send_input(":KEY.1", 0x01, 0.3) -- CL
	end
	sb_select_piece(":board:board", 1, x, y, event)
	if (event == "get") then
		lastx = x
		lasty = y
	elseif (event == "put" and piece ~= 0) then
		sb_press_square(":board:board", 0.1, lastx, lasty)
	end
end

function interface.get_options()
	return {
		{ "spin", "Level", "1", "0", "9" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 0 or level > 9) then
			return
		end
		interface.level = level
		interface.setlevel()
	end
end

return interface
