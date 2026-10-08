interface = load_interface("polgar")

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
	-- Map names exactly to the old logic strings: (x-1).0 and (y-1).1
	local col_name = tostring(x - 1) .. ".0"
	local row_name = tostring(y - 1) .. ".1"
	
	local col_output = machine.devices[":"]:output(col_name)
	local row_output = machine.devices[":"]:output(row_name)
	
	local col_active = col_output and col_output:get() ~= 0
	local row_active = row_output and row_output:get() ~= 0
	
	-- A square is selected only when both its row and column lines intersect
	return col_active and row_active
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

