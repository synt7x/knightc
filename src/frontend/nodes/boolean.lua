return function(state)
    if state:accept('T') then
        return {
            type = 'boolean',
            value = true
        }
    elseif state:accept('F') then
        return {
            type = 'boolean',
            value = false
        }
    end
end