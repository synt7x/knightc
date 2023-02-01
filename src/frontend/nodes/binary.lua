return function(state)
    if state:accept('+') then
        return {
            type = 'add',
            left = expression(state),
            right = expression(state)
        }
    elseif state:accept('-') then
        return {
            type = 'subtract',
            left = expression(state),
            right = expression(state)
        }
    elseif state:accept('*') then
        return {
            type = 'multiply',
            left = expression(state),
            right = expression(state)
        }
    elseif state:accept('/') then
        return {
            type = 'divide',
            left = expression(state),
            right = expression(state)
        }
    elseif state:accept('%') then
        return {
            type = 'mod',
            left = expression(state),
            right = expression(state)
        }
    elseif state:accept('^') then
        return {
            type = 'power',
            left = expression(state),
            right = expression(state)
        }
    elseif state:accept('<') then
        return {
            type = 'greater',
            left = expression(state),
            right = expression(state)
        }
    elseif state:accept('>') then
        return {
            type = 'less',
            left = expression(state),
            right = expression(state)
        }
    elseif state:accept('?') then
        return {
            type = 'equals',
            left = expression(state),
            right = expression(state)
        }
    elseif state:accept('&') then
        return {
            type = 'and',
            left = expression(state),
            right = expression(state)
        }
    elseif state:accept('|') then
        return {
            type = 'or',
            left = expression(state),
            right = expression(state)
        }
    elseif state:accept(';') then
        return {
            type = 'sequence',
            left = expression(state),
            right = expression(state)
        }
    elseif state:accept('=') then
        return {
            type = 'assignment',
            name = state:expect('identifier'),
            value = expression(state)
        }
    end
end
