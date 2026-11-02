interface = load_interface("mephisto")

interface.turn = true
interface.level = "a3"
interface.cur_level = nil

function interface.get_module()
	return "Mephisto Junior"
end

function interface.setup_machine()
	interface.turn = true
--	send_input(":RESET", 0x01, 0.5)  -- RES
	emu.wait(1.0)
	send_input(":IN.0", 0x01, 0.5) -- CL

	interface.cur_level = "a3"
	interface.setlevel()
end

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

local function digit_square(dx, dy)
	local xval = { 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71, 0x3d, 0x76 }
	local yval = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f }
	local cx = output_value(dx) & 0x7f
	local cy = output_value(dy) & 0x7f
	for x = 1, 8 do
		for y = 1, 8 do
			if xval[x] == cx and yval[y] == cy then
				return x, y
			end
		end
	end
	return nil
end

-- Opening book bug (see brikett.cpp): after 1.e4 e6 2.d4 d5 3.Nd2 c5 4.exd5 the Junior
-- shows Qd1xd5, a move with the WHITE queen. A move between two squares holding pieces of
-- the same color is never legal, so set the position up again: out of the book the Junior
-- computes a real move.
local is_selected = interface.is_selected
function interface.is_selected(x, y)
	if x == 1 and y == 1 then
		local fx, fy = digit_square("digit3", "digit2")
		local tx, ty = digit_square("digit1", "digit0")
		if fx and tx then
			local pf = get_piece_id(fx, fy)
			local pt = get_piece_id(tx, ty)
			if pf ~= 0 and pt ~= 0 and (pf > 0) == (pt > 0) then
				local throttled_state = machine.video.throttled
				machine.video.throttled = false
				send_input(":IN.0", 0x01, 0.5) -- CL
				interface.set_pos(0)
				if pf > 0 then
					interface.set_pos(-1) -- Black to move
				else
					interface.set_pos(1) -- White to move
				end
				emu.wait(1)
				machine.video.throttled = throttled_state
				interface.start_play(false)
				return false
			end
		end
	end
	return is_selected(x, y)
end

function interface.get_options()
	return { { "string", "Level", "a3"}, }
end

return interface
