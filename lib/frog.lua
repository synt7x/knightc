local frog = {}
local json = require('lib/json')

frog.line = 0
frog.char = 0
frog.lines = {}
frog.options = {
    ['q'] = false,
    ['Q'] = false,
}

function frog:setOptions(options)
    self.options = options
end

function frog:character()
    self.char = self.char + 1
end

function frog:getLines()
    return self.lines
end

function frog:newline()
    self.char = 0
    self.line = self.line + 1
end

function frog:print(...)
    if self.options['q'] or self.options['Q'] then return self end
    print(...)
    return self
end

function frog:printf(...)
    return self:print(string.format(...))
end

function frog:croak(message)
    if self.options['Q'] then return self end
    print(message)
    return self
end

function frog:throw(token, error, hint)
    self
        :croak('Error: ' .. error)
        :croak('| ' .. self.lines[token.position[1] + 1])

    self:croak('| ' .. string.rep('-', token.position[2]) .. string.rep('^', token.characters and #token.characters or 1))
    self:croak('Help: ' .. hint .. '\n')
end

function frog:dump(stage, object)
    if self.options['P'] == stage then
        local file = io.open(self.options['o'], 'w')

        if file then
            file:write(json(object))
        else
            self:error('Could not open file: ' .. self.opions['o'])
        end

        os.exit(0)
    end
end

return frog