local frog = require('lib/frog')

function tokenize(node, token)
    node.token = token
    return node
end

function expression(state)
    local token = state.token

    local literal = literal(state)
    if literal then return tokenize(literal, token) end

    local unary = unary(state)
    if unary then return tokenize(unary, token) end

    local binary = binary(state)
    if binary then return tokenize(binary, token) end

    local ternary = ternary(state)
    if ternary then return tokenize(ternary, token) end

    local quaternary = quaternary(state)
    if quaternary then return tokenize(quaternary, token) end

    if state.token then
        frog:throw(
            state.token,
            "Unexpected token: " .. state.token.type .. " '" .. state.token.characters .. "'",
            "Expected an expression, but got: " .. state.token.type .. " '" .. state.token.characters .. "'"
        )

        os.exit(1)
    end

    return {}
end

function literal(state)
    if state:test('string') then
        return state:accept('string')
    elseif state:test('number') then
        return state:accept('number')
    elseif state:test('identifier') then
        return state:accept('identifier')
    elseif state:accept('TRUE') then
        local node = {
            type = 'boolean',
            value = true,
        }

        return node
    elseif state:accept('FALSE') then
        local node = {
            type = 'boolean',
            value = false,
        }

        return node
    elseif state:accept('NULL') then
        local node = {
            type = 'null',
        }

        return node
    elseif state:accept('@') then
        local node = {
            type = 'array',
        }

        return node
    elseif state:accept('PROMPT') then
        local node = {
            type = 'prompt',
        }

        return node
    elseif state:accept('RANDOM') then
        local node = {
            type = 'random',
        }

        return node
    end
end

function unary(state)
    if state:accept('BLOCK') then
        local node = {
            type = 'block',
            body = expression(state)
        }

        return node
    elseif state:accept('CALL') then
        local node = {
            type = 'call',
            name = expression(state),
        }

        return node
    elseif state:accept('QUIT') then
        local node = {
            type = 'quit',
            argument = expression(state),
        }

        return node
    elseif state:accept('OUTPUT') then
        local node = {
            type = 'output',
            argument = expression(state)
        }

        return node
    elseif state:accept('DUMP') then
        local node = {
            type = 'dump',
            argument = expression(state)
        }

        return node
    elseif state:accept('LENGTH') then
        local node = {
            type = 'length',
            argument = expression(state)
        }

        return node
    elseif state:accept('!') then
        local node = {
            type = 'not',
            argument = expression(state)
        }

        return node
    elseif state:accept('~') then
        local node = {
            type = 'negative',
            argument = expression(state)
        }

        return node
    elseif state:accept('ASCII') then
        local node = {
            type = 'ascii',
            argument = expression(state)
        }

        return node
    elseif state:accept(',') then
        local node = {
            type = 'box',
            argument = expression(state)
        }

        return node
    elseif state:accept('[') then
        local node = {
            type = 'prime',
            argument = expression(state),
        }

        return node
    elseif state:accept(']') then
        local node = {
            type = 'ultimate',
            argument = expression(state),
        }

        return node
    end
end

function binary(state)
    if state:accept('+') then
        local node = {
            type = 'add',
            left = expression(state),
            right = expression(state)
        }

        return node
    elseif state:accept('-') then
        local node = {
            type = 'subtract',
            left = expression(state),
            right = expression(state)
        }

        return node
    elseif state:accept('*') then
        local node = {
            type = 'multiply',
            left = expression(state),
            right = expression(state)
        }

        return node
    elseif state:accept('/') then
        local node = {
            type = 'divide',
            left = expression(state),
            right = expression(state)
        }

        return node
    elseif state:accept('%') then
        local node = {
            type = 'modulus',
            left = expression(state),
            right = expression(state)
        }

        return node
    elseif state:accept('^') then
        local node = {
            type = 'exponent',
            left = expression(state),
            right = expression(state)
        }

        return node
    elseif state:accept('<') then
        local node = {
            type = 'less',
            left = expression(state),
            right = expression(state)
        }

        return node
    elseif state:accept('>') then
        local node = {
            type = 'greater',
            left = expression(state),
            right = expression(state)
        }

        return node
    elseif state:accept('?') then
        local node = {
            type = 'exact',
            left = expression(state),
            right = expression(state)
        }

        return node
    elseif state:accept('&') then
        local node = {
            type = 'and',
            left = expression(state),
            right = expression(state)
        }

        return node
    elseif state:accept('|') then
        local node = {
            type = 'or',
            left = expression(state),
            right = expression(state)
        }

        return node
    elseif state:accept(';') then
        local node = {
            type = 'expr',
            left = expression(state),
            right = expression(state)
        }

        return node
    elseif state:accept('=') then
        local node = {
            type = 'assignment',
            name = state:expect('identifier'),
            value = expression(state)
        }

        return node
    elseif state:accept('WHILE') then
        local node = {
            type = 'while',
            condition = expression(state),
            body = expression(state)
        }

        return node
    end
end

function ternary(state)
    if state:accept('IF') then
        local node = {
            type = 'if',
            condition = expression(state),
            body = expression(state),
            fallback = expression(state)
        }

        return node
    elseif state:accept('GET') then
        local node = {
            type = 'get',
            argument = expression(state),
            start = expression(state),
            width = expression(state)
        }

        return node
    end
end

function quaternary(state)
    if state:accept('SET') then
        local node = {
            type = 'set',
            argument = expression(state),
            start = expression(state),
            width = expression(state),
            value = expression(state)
        }

        return node
    end
end

return expression