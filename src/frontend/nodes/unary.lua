return function(state)
    local node = {}

    if state:accept('B') then
        return {
            type = 'block',
            body = expression(state)
        }
    elseif state:accept('C') then
        node.value = expression(state)
        node.type = 'call'
        return node
    elseif state:accept('Q') then
        node.value = expression(state)
        node.type = 'exit'
        return node
    elseif state:accept('D') then
        node.value = expression(state)
        node.type = 'dump'
        return node
    elseif state:accept('O') then
        node.value = expression(state)
        node.type = 'output'
        return node
    elseif state:accept('L') then
        node.value = expression(state)
        node.type = 'length'
        return node
    elseif state:accept('!') then
        node.value = expression(state)
        node.type = 'not'
        return node
    elseif state:accept('~') then
        node.value = expression(state)
        node.type = 'negate'
        return node
    elseif state:accept('A') then
        node.value = expression(state)
        node.type = 'asci'
        return node
    elseif state:accept(',') then
        node.value = expression(state)
        node.type = 'box'
        return node
    elseif state:accept('[') then
        node.value = expression(state)
        node.type = 'head'
        return node
    elseif state:accept(']') then
        node.value = expression(state)
        node.type = 'tail'
        return node
    end
end