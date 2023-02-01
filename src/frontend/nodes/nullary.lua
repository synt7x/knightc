return function(state)
    if
        state:test('T') or
        state:test('F')
    then
        return boolean(state)
    elseif state:accept('@') then
        return { type = 'array' }
    elseif state:accept('P') then
        return { type = 'prompt' }
    elseif state:accept('R') then
        return { type = 'random' }
    end
end