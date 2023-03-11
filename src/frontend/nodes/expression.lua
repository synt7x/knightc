local path = 'src/frontend/nodes/'
local frog = require('lib/frog')

boolean = require(path .. 'boolean')
literal = require(path .. 'literal')
nullary = require(path .. 'nullary')
unary = require(path .. 'unary')
binary = require(path .. 'binary')
ternary = require(path .. 'ternary')
quarternary = require(path .. 'quarternary')

local function characteristics(node, token)
    node.characters = token.characters
    node.position = token.position

    return node
end

expression = function(state)
    local token = state.token

    local literal = literal(state)
    if literal then return literal end

    local nullary = nullary(state)
    if nullary then return characteristics(nullary, token) end

    local unary = unary(state)
    if unary then return characteristics(unary, token) end

    local binary = binary(state)
    if binary then return characteristics(binary, token) end

    local ternary = ternary(state)
    if ternary then return characteristics(ternary, token) end

    local quarternary = quarternary(state)
    if quarternary then return characteristics(quarternary, token) end

    if state.token then
        frog:throw(
            state.token,
            string.format('Unknown function "%s"', state.token.type),
            'Try using one of the Knight functions (e.g. OUTPUT, LENGTH, +, -)'
        )

        os.exit(1)
    end

    if not state.token and not state.tokens[state.index - 1] then
        os.exit(0)
    end

    frog:throw(
        state.token or state.tokens[state.index - 1],
        'Expected an expression here',
        'Maybe try adding the proper amount of arguments.'
    )

    os.exit(1)
end

return expression