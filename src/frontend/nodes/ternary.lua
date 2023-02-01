return function(state)
    if state:accept('I') then
        return {
            type = 'if',
            condition = expression(state),
            left = expression(state),
            right = expression(state)
        }
    elseif state:accept('G') then
        return {
            type = 'get',
            value = expression(state),
            start = expression(state),
            length = expression(state)
        }
    end
end