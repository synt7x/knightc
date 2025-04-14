local typecheck = {
    types = {
        ['null'] = 'null', ['number'] = 'number', ['string'] = 'string',
        ['list'] = 'list', ['boolean'] = 'boolean'
    }
}

local frog = require('lib/frog')
local json = require('lib/json')
local parser = require('src/frontend/parser')
local traversal = parser.traversal


function typecheck.new(symbols, ast)
    local self = {}
    for name, value in pairs(typecheck) do
        self[name] = value
    end

    self.symbols = symbols

    return self:walk(ast.body)
end

function typecheck:add(node, types)
    if not node.types then
        node.types = {}
    end

    for type, value in pairs(types) do
        node.types[type] = value
    end
end

function typecheck:as(node, type)
    if not node.types then
        node.types = {}
    end

    node.types[type] = type
end

function typecheck:link(identifier, types)
    local name = identifier.characters
    if not self.symbols[name] then
        frog:printf('Invalid symbol "%s" while reading identifier', name)
    end

    for type, value in pairs(types) do
        self.symbols[name].types[type] = value
    end
end

function typecheck:format(values)
    local result = ""
    local i = 1

    for k, name in pairs(values) do
        if #values > 2 then
            if i == #values then
                result = result .. ', or '
            elseif i > 1 then
                result = result .. ', '
            end
        elseif #values == 2 then
            if i == #values then
                result = result .. ' or '
            end
        end

        result = result .. name
        i = i + 1
    end

    return result
end

function typecheck:expect(parent, node, types)
    if not node.types then
        frog:printf('Invalid typechecking sequence for node "%s"', node.type)
        os.exit(1)
    end

    local contains = false

    for i, value in ipairs(types) do
        if node.types[value] then
            contains = true
        end
    end

    if not contains then
        frog:throw(
            node.token,
            string.format('Expected %s to be of type %s but got %s',
            parent.type, self:format(types), self:format(node.types) or 'none'),
            'Change this type to a ' .. self:format(types)
        )
    end
end

function typecheck:binary(ast)
    if ast.type == 'add' then
        local type = self:walk(ast.left)
        self:walk(ast.right)
        self:add(ast, type)

        self:expect(ast, ast.right, { self.types.string, self.types.number, self.types.list })
        self:expect(ast, ast.left, { self.types.string, self.types.number, self.types.list })
        return ast.types
    elseif ast.type == 'subtract' then
        local type = self:walk(ast.left)
        self:walk(ast.right)
        self:add(ast, type)
    
        self:expect(ast, ast.left, { self.types.number })
        return ast.types
    
    elseif ast.type == 'expr' then
        self:walk(ast.left)
        local type = self:walk(ast.right)

        self:add(ast, type)
        return ast.types
    end
end

function typecheck:walk(ast, parent)
    if traversal.binary[ast.type] then
        self:binary(ast)
        return ast.types
    elseif ast.type == 'identifier' then
        self:as(ast, self.types.null)
        return ast.types
    elseif ast.type == 'assignment' then
        local type = self:walk(ast.value, ast)
        self:add(ast, type)
        self:link(ast.name, type)

        return ast.types
    elseif ast.type == 'block' then
        local type = self:walk(ast.body, ast)
        self:add(ast, type)

        return ast.types
    elseif ast.type == 'call' then
        local type = self:walk(ast.name, ast)
        self:add(ast, type)

        return ast.types
    elseif traversal.unary[ast.type] then
        local type = self:walk(ast.argument, ast)
        self:add(ast, type)

        return ast.types
    elseif ast.type == 'if' then
        self:walk(ast.condition, ast)
        local type1 = self:walk(ast.body, ast)
        local type2 = self:walk(ast.fallback, ast)

        self:add(ast, type1)
        self:add(ast, type2)
        return ast.types
    elseif ast.type == 'while' then
        self:walk(ast.condition, ast)
        self:walk(ast.body, ast)

        self:as(ast, self.types.null)
        return ast.types
    elseif ast.type == 'get' then
        self:walk(ast.argument, ast)
        self:walk(ast.start, ast)
        self:walk(ast.width, ast)

        self:as(ast, self.types.null)

        return ast.types
    elseif ast.type == 'set' then
        local type = self:walk(ast.argument, ast)
        self:walk(ast.start, ast)
        self:walk(ast.width, ast)
        self:walk(ast.value, ast)

        self:as(ast, self.types.null)
        return ast.types
    elseif ast.type == 'random' then
        self:as(ast, self.types.number)
        return ast.types
    elseif ast.type == 'prompt' then
    elseif traversal.literal[ast.type] then
        self:as(ast, ast.type)
        return ast.types
    else
        frog:printf('Unexpected node type "%s" encountered during typechecking', ast.type)
        os.exit(1)
    end

    return self.map
end

return typecheck