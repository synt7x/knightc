return function(state)
    if state:accept('T') then
        return {
            type = 'boolean',
            boolean = true
        }
    elseif state:accept('F') then
        return {
            type = 'boolean',
            boolean = false
        }
    end
end