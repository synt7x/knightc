local frog = require('lib/frog')

local cli = require('src/cli')
local flags, inputs = cli(arg)

frog:print(
    string.format(
        '%s => %s @ %s-%s:%s',
        table.concat(inputs, ', '), flags.o, flags.t, flags.f,
        flags.P
    )
)