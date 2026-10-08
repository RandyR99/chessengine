interface = load_interface("mm4")

interface.level = "1"
interface.cur_level = nil

function interface.get_module()
	return "Mephisto MM IV Rebel"
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
	if (interface.level:sub(1,1) == "8") then
		interface.setdigit(8)
		for i = 3, 5 do
			interface.setdigit(tonumber(interface.level:sub(i,i)))
		end
		send_input(":KEY.0", 0x20, 1) -- ENT
		send_input(":KEY.0", 0x01, 1) -- CL
	else
		interface.setdigit(tonumber(interface.level))
		send_input(":KEY.0", 0x20, 1) -- ENT
	end
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	sb_reset_board(":board:board")
	emu.wait(1)
	interface.cur_level = "le 1"
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":KEY.0", 0x02, 0.5) -- POS
		send_input(":KEY.0", 0x20, 0.5) -- ENT
		machine.video.throttled = throttled_state
		return (":board:board")
	else
		send_input(":KEY.0", 0x20, 0.5) -- ENT
		local piece = 0
		for p = 1, 12 do
			if p < 7 then
				piece = p
			else
				piece = 6 - p
			end
			for y = 1, 8 do
				for x = 1, 8 do
					if get_piece_id(x, 9 - y) == piece then
						sb_press_square(":board:board", 0.5, x, 9 - y)
					end
				end
			end
			if math.abs(piece) ~= 1 then
				send_input(":KEY.0", 0x20, 0.5) -- ENT
			end
		end
		if mode == 1 then
			interface.setdigit(0) -- White
		else
			interface.setdigit(9) -- Black
		end
		send_input(":KEY.0", 0x20, 0.5) -- ENT
		send_input(":KEY.0", 0x01, 0.5) -- CL
	end
end

function interface.is_selected(x, y)
	local led_idx = (y - 1) * 8 + (x - 1)
	local led_name = "led" .. tostring(led_idx)
	local led_state = machine.devices[":"]:output(led_name)
	
	return led_state and led_state:get() ~= 0
end

function interface.get_options()
	return {
		{ "string", "Level", "1" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		if (string.match(value,"%d") and value:len() == 1) then
			if (value == "8") then
				value = "8 600"
			end
		elseif (string.find(value .. string.char(0),"8[-,;:/%s%.]%d%d?%d?%z") == 1) then
			if (value:len() == 3) then
				value = "8 00" .. value:sub(3,3)
			elseif (value:len() == 4) then
				value = "8 0" .. value:sub(3,4)
			else
				value = "8 " .. value:sub(3,5)
			end
		else
			return
		end
		interface.level = value
		interface.setlevel()
	end
end

return interface
