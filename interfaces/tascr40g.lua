interface = load_interface("tascr30")

function interface.get_author() return "Ed Schroeder" end

function interface.get_options()
    return {
        {"string", "Level", "40/2:00 moves/hrs"}, {"check", "Ponder", "1"},
        {"combo", "Style", "normal", "defensive\tsolid\tnormal\tactive\toffensive"},
        {"check", "Hash", "1"},
        {"combo", "Strength", "expert", "expert\tstrong\tmoderate\tnovice"},
        {"combo", "Book", "aegon", "normal\taegon\toff"}
    }
end

return interface
