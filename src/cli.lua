local config = require('config')
local frog = require('lib/frog')
local highlight = require('lib/highlight')
local recommendation = require('lib/recommendation')

local defaults = {
    -- String values
    ['O'] = 1, -- Optimization level
    ['o'] = recommendation:output(), -- File to output to
    ['P'] = 'codegen', -- Halt and output at given pass
    ['f'] = recommendation:format(), -- Format of output (ELF, PE)
    ['t'] = recommendation:target(), -- Target of output (x64, x86, arm, aarch64)

    -- Boolean values
    ['v'] = false, -- Version
    ['h'] = false, -- Display help message
    ['q'] = false, -- Silent mode
    ['Q'] = false, -- Quiet mode
    ['C'] = false, -- Cat mode

    ['no-color'] = false, -- Disable colors in output
    ['no-ansi'] = false, -- Disable ANSI escape codes in output
}

local function getflags(args)
    local flags = defaults
    local inputs = {}
    local last

    for i = 1, #args do
        local argument = args[i]

        if argument:sub(1, 1) == '-' and not last then
            local char = argument:sub(2, 2)

            if char == 'o' then
                if char == 'o' and #argument > 2 then
                    flags['o'] = argument:sub(3, #argument)
                else
                    last = 'o'
                end
            elseif char == 'O' then
                if #argument > 2 then
                    local level = argument:sub(3, #argument)
                    if level == '1' then
                        flags['O'] = 1
                    elseif level == '2' then
                        flags['O'] = 2
                    elseif level == '3' then
                        flags['O'] = 3
                    end
                end
            elseif char == 'v' or argument == '--version' then
                flags['v'] = true
            elseif char == 'h' or argument == '--help' then
                flags['h'] = true
            elseif char == 'Q' or argument == '--silent' then
                flags['Q'] = true
            elseif char == 'q' or argument == '--quiet' then
                flags['q'] = true
            elseif char == 'C' or argument == '--cat' then
                flags['C'] = true 
            elseif char == 'P' or argument == '--pass' then
                if char == 'P' and #argument > 2 then
                    flags['P'] = argument:sub(3, #argument)
                else
                    last = 'P'
                end
            elseif char == 'f' or argument == '--format' then
                if char == 'f' and #argument > 2 then
                    flags['f'] = argument:sub(3, #argument)
                else
                    last = 'f'
                end
            elseif char == 't' or argument == '--target' then
                if char == 't' and #argument > 2 then
                    flags['t'] = argument:sub(3, #argument)
                else
                    last = 't'
                end
            elseif argument == '-no-color' or argument == '--no-color' then
                flags['no-color'] = true
            elseif argument == '-no-ansi' or argument == '--no-ansi' then
                flags['no-ansi'] = true
            else
                flags[argument] = true
            end
        elseif last then
            if type(flags[last]) == 'table' then
                table.insert(flags[last], argument)
            else
                flags[last] = argument
            end

            last = nil
        else
            table.insert(inputs, argument)
        end
    end

    return flags, inputs
end

return function(args)
    local flags, inputs = getflags(args)

    frog:setOptions(flags)

    if flags.h then
        frog:print(
            string.format(
                'Usage: %s [options] [files]\n       %s\n',
                string.lower(config.name), config.description
            )
        )

        frog:print('Options:')
            :print('  -h, --help            Display extended help')
            :print('  -v, --version         Display version information')
            :print('  -q, --silent          Disable all output')
            :print('  -Q, --quiet           Disable all output except errors\n')
            :print('  --no-color            Disable colors in output')
            :print('  --no-ansi             Disable ANSI escape codes in output\n')
            :print('Compiler:')
            :print('  -o                    Output to <file>')
            :print('  -O<level>             Set optimization level to <1, 2, 3>')
            :print('  -P, --pass <pass>     Halt and output at <tokens, ast, symbols, intermediate, codegen>')
            :print('  -f, --format <format> Set output format to <elf, pe>')
            :print('  -t, --target <target> Set output target to <x64, x86, arm, aarch64>')
        os.exit(0)
    elseif flags.v then
        frog:printf(
            '%s v%s (%s)',
            config.name,
            config.version,
            config.branch
        )

        frog:printf(
            '%s => %s targeting %s-%s:%s',
            #inputs > 0 and table.concat(inputs, ', ') or '(none)', flags.o, flags.t, flags.f,
            flags.P
        )

        os.exit(0)
    elseif flags.C then
        for i = 1, #inputs do
            local file = io.open(inputs[i], 'r')

            if not file then
                file = io.open(inputs[i] .. '.kn', 'r')
            end

            if file then
                local text = file:read('*a')
                file:close()

                if not flags.Q and not flags.q then
                    print(highlight(text, flags))
                end
            else
                frog:croak(
                    string.format(
                        'Unable to locate file "%s" (tried %s and %s)',
                        inputs[i], inputs[i], inputs[i] .. '.kn'
                    )
                )
            end
        end
    elseif #inputs == 0 then
        frog:print(
            string.format(
                'Usage: %s [options] [files]',
                string.lower(config.name)
            )
        )

        frog:print('       -h, --help          Display extended help')
            :print('       -v, --version       Display version information')
        os.exit(0)
    end

    return flags, inputs
end