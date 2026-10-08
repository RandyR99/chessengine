interface = load_interface("polgar")

function interface.get_module()
	if machine.system.name == "academy" then
		return "Mephisto Academy"
	elseif machine.system.name == "academyg" then
		return "Mephisto Academy (deutsch)"
	elseif machine.system.name == "academyga" then
		return "Mephisto Academy (deutsch) v2"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Ed Schröder"
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":KEY", 0x08, 0.5) -- POS
		send_input(":KEY", 0x40, 0.5) -- ENT
		machine.video.throttled = throttled_state
		return (":board:board")
	else
		local piece = 6
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if math.abs(p) ~= math.abs(piece) then
						send_input(":KEY", 0x01 << (6 - math.abs(p)), 0.5)
					end
					if p * piece < 0 then
						send_input(":KEY", 0x01 << (6 - math.abs(p)), 0.5)
					end
					sb_press_square(":board:board", 0.5, x, 9 - y)
					piece = p
				end
			end
		end
		if mode * piece < 0 then
			send_input(":KEY", 0x01 << (6 - math.abs(piece)), 0.5)
		end
		send_input(":KEY", 0x80, 0.5) -- CL
	end
	machine.video.throttled = throttled_state
end

return interface
