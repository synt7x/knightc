return function(state)
    if state:accept('S') then
        return {
            type = 'set',
            value = expression(state),
            start = expression(state),
            length = expression(state),
            predicate = expression(state)
        }
    end
end