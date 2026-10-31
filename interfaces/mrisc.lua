interface = load_interface("polgar")

-- Helper function to read a specific range of characters from DDRAM
local function read_lcd_range(start_idx, end_idx)
    local dev = machine.devices[':display:hd44780']
    if not dev then return "" end
    
    local state_item = dev.items["0/m_ddram"]
    if not state_item then return "" end
    
    local wrapped_mem = emu.item(state_item)
    local str = ""
    for i = start_idx, end_idx do
        str = str .. string.char(wrapped_mem:read(i))
    end
    return str
end

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

function interface.show_info(on)
	if on and interface.searching_display() then -- from polgar.lua
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		send_input(":KEY", 0x80, 0.2) -- CL
		send_input(":KEY", 0x02, 0.2) -- INFO
		
		local ddram = read_lcd_range(0x00, 0x7F)
		local raw_score = ""
		local raw_depth = ""
		local raw_pv = ""

		if ddram:sub(1,4) == "-PB-" then
			raw_score = ddram:sub(65,66) .. ddram:sub(68,69):gsub(" ", "")
			raw_depth = ddram:sub(71,72):gsub(" ", "")
			raw_pv = string.lower(ddram:sub(7,20))
		elseif ddram:sub(2,3) ~= "nr" then
			raw_score = ddram:sub(1,2) .. ddram:sub(4,5):gsub(" ", "")
			raw_depth = ddram:sub(7,8):gsub(" ", "")
			raw_pv = string.lower(ddram:sub(77,112))
		end

		-- Fallback Sanitization: Ensure score or depth are numeric/valid 
		-- to prevent malformed text strings like "G-F" from parsing out.
		if raw_score:match("^%s*$") or raw_score:match("[A-Za-z]") then
			machine.video.throttled = throttled_state
			return nil -- Returning nil skips this specific intermittent log line safely
		end

		interface.score = raw_score
		interface.depth = raw_depth
		interface.pv = raw_pv

		machine.video.throttled = throttled_state
		return "info score cp " .. interface.score .. " depth " .. interface.depth .. " pv " .. interface.pv
	end
end
-- off: show_info presses keys while the machine searches, and a press can land just as the move appears and hide it
-- (as on montec/mm4); to come back once the info can be read from RAM without key presses
interface.show_info = nil

-- the RISC program runs on the ARM coprocessor: polgar's RAM reader doesn't apply
interface.show_info = nil

return interface

