return function(state)
    if state:accept('I') then
        return {
            type = 'if',
            condition = expression(state),
            body = expression(state),
            catch = expression(state)
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