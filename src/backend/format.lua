local format = {}
local parser = require('src/frontend/parser')
local traversal = parser.traversal
local frog = require('lib/frog')

function format.new(ast)
    local self = {}

    for name, value in pairs(format) do
		self[name] = value
	end

    self.buffer = ''

    format.build(self, ast.body)

    return self.buffer
end

function format:emit(string)
    string = string or ''
    self.buffer = self.buffer .. string .. ' '
end

function format:build(ast)
    if traversal.binary[ast.type] then
        if ast.type == 'expr' then
            self.buffer = self.buffer .. '\n'
        end
        self:emit(traversal.binary[ast.type])
        self:build(ast.left)

        self:build(ast.right)
    elseif ast.type == 'output' then
        self:emit('OUTPUT')
        self:build(ast.argument)
    elseif ast.type == 'dump' then
        self:emit('DUMP')
        self:build(ast.argument)
    elseif ast.type == 'prompt' then
        self:emit('PROMPT')
    elseif ast.type == 'random' then
        self:emit('RANDOM')
    elseif ast.type == 'box' then
        self:emit(',')
        self:build(ast.argument)
    elseif ast.type == 'prime' then
        self:emit('[')
        self:build(ast.argument)
    elseif ast.type == 'ultimate' then
        self:emit(']')
        self:build(ast.argument)
    elseif traversal.unary[ast.type] then
        self:emit(traversal.unary[ast.type])
        self:build(ast.argument)
    elseif ast.type == 'identifier' then
        local name = ast.characters
        self:emit(name)
    elseif ast.type == 'assignment' then
        self:emit('=')
        self:build(ast.name)
        self:build(ast.value)
    elseif ast.type == 'block' then
        self:emit('BLOCK')
        self:build(ast.body)
    elseif ast.type == 'call' then
        self:emit('CALL')
        self:build(ast.name)
    elseif ast.type == 'if' then
        self:emit('IF')
        self:build(ast.condition)
        self:build(ast.body)
        self:build(ast.fallback)
    elseif ast.type == 'while' then
        self:emit('WHILE')
        self:build(ast.condition)
        self:build(ast.body)
    elseif ast.type == 'get' then
        self:emit('GET')
        self:build(ast.start)
        self:build(ast.width)
        self:build(ast.argument)
    elseif ast.type == 'set' then
        self:emit('SET')
        self:build(ast.start)
        self:build(ast.width)
        self:build(ast.value)
		self:build(ast.argument)
    elseif ast.type == 'string' then
        self:emit('"' .. ast.characters .. '"')
    elseif ast.type == 'number' then
        self:emit(ast.characters)
    elseif ast.type == 'null' then
        self:emit('NULL')
    elseif ast.type == 'boolean' then
        if ast.value then
            self:emit('TRUE')
        else
            self:emit('FALSE')
        end
    elseif ast.type == 'list' then
        self:emit('@')
    else
        frog:throw(
            ast.token,
            string.format('Panic during format, recieved unknown node of type %s', ast.type),
            'Please report this as a bug in the issue tracker (https://github.com/synt7x/knightc/issues/new)',
            'Fatal'
        )

        os.exit(1)
    end
end

return format