local path = 'src/frontend/nodes/'
local frog = require('lib/frog')

boolean = require(path .. 'boolean')
literal = require(path .. 'literal')
nullary = require(path .. 'nullary')
unary = require(path .. 'unary')
binary = require(path .. 'binary')

expression = function(state)
    local literal = literal(state)
    local nullary = nullary(state)
    local unary = unary(state)
    local binary = binary(state)

    if
        not literal and
        not nullary and
        not unary and
        not binary
    then
        if state.token then
            frog:throw(
                string.format('Unknown function "%s"', state.token.type),
                'Try using one of the Knight functions (e.g. OUTPUT, LENGTH, +, -)'
            )

            os.exit(1)
        end

        frog:throw(
            'Expected an expression here',
            'Maybe try adding the proper amount of arguments.'
        )

        os.exit(1)
    end

    return literal or nullary or unary or binary
end

return expression