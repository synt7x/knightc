local frog = require('lib/frog')
local json = require('lib/json')

local lexer = require('src/frontend/lexer')
local parser = require('src/frontend/parser')
local symbols = require('src/frontend/symbols')

local cli = require('src/cli')
local flags, inputs = cli(arg)

frog:printf(
    '%s => %s @ %s-%s:%s',
    table.concat(inputs, ', '), flags.o, flags.t, flags.f,
    flags.P
)

for i, name in ipairs(inputs) do
    local file = io.open(name, 'r')

    if not file then
        file = io.open(name .. '.kn', 'r')
    end

    if file then
        local text = file:read('*a')
        file:close()

        local tokens, comments = lexer.new(text)
        frog:dump('tokens', tokens)

        local ast = parser.new(flags, tokens, comments)
        frog:dump('ast', ast)

        local symboltable = symbols.new(ast)
        frog:dump('symboltable', symboltable)
    else
        frog:croak(
            string.format(
                'Unable to locate file "%s" (tried %s and %s)',
                name, name, name .. '.kn'
            )
        )
    end
end