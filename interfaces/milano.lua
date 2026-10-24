interface = load_interface("polgar")

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.get_module()
	if machine.system.name == "milano" then
		return "Mephisto Milano"
	elseif machine.system.name == "milanoa" then
		return "Mephisto Milano v2"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Ed Schröder"
end

function interface.setup_machine()
	sb_reset_board(":board")
	emu.wait(1)
	interface.cur_level = ""
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":KEY", 0x08, 0.5) -- POS
		send_input(":KEY", 0x01, 0.5) -- TRN
		machine.video.throttled = throttled_state
		return (":board")
	else
		local piece = 1
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
					sb_press_square(":board", 0.5, x, 9 - y)
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

function interface.is_selected(x, y)
	local xval = output_value((x - 1) .. ".0") ~= 0
	local yval = output_value((y - 1) .. ".1") ~= 0
	return xval and yval
end

function interface.select_piece(x, y, event)
	sb_select_piece(":board", 1, x, y, event)
end

function interface.promote(x, y, piece)
    sb_promote(":board", x, y, piece)
    if     (piece == "q") then send_input(":KEY", 0x10, 1)
    elseif (piece == "r") then send_input(":KEY", 0x08, 1)
    elseif (piece == "b") then send_input(":KEY", 0x04, 1)
    elseif (piece == "n") then send_input(":KEY", 0x02, 1)
    end
end

return interface
