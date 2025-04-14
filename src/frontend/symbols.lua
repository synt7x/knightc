local json = require('lib/json')
local parser = require('src/frontend/parser')
local traversal = parser.traversal

local symbols = {}

function symbols.new(ast)
    local self = {}
    for name, value in pairs(symbols) do
        self[name] = value
    end

    self.map = {}

    return self:walk(ast.body)
end

function symbols:add(identifier, parent)
    local name = identifier.characters

    if self.map[name] then
        identifier.tag = self.map[name].tag
        table.insert(self.map[name].nodes, parent)
        table.insert(self.map[name].identifiers, identifier)

        if self.map[name].volatile then
            parent.volatile = true
            identifier.volatile = true
        end
    else
        self.tag = (self.tag or 0) + 1
        self.map[name] = { tag = self.tag, types = {}, nodes = { parent }, identifiers = { identifier } }
    end
end

function symbols:volatile(parent, identifier)
    local name = identifier.characters

    if not self.map[name] then
        return
    end

    if parent.volatile then
        self.map[name].volatile = true

        for i, node in ipairs(self.map[name].nodes) do
            node.volatile = true
        end

        for i, node in ipairs(self.map[name].identifiers) do
            node.volatile = true
        end
    end
end

function symbols:poison(parent, child)
    if child.volatile and parent then
        parent.volatile = true
    end
end

function symbols:walk(ast, parent)
    if traversal.binary[ast.type] then
        self:walk(ast.left, ast)
        self:walk(ast.right, ast)
    elseif ast.type == 'identifier' then
        self:add(ast, parent)
    elseif ast.type == 'assignment' then
        self:add(ast.name, parent)
        self:walk(ast.value, ast)

        self:volatile(ast, ast.name)
    elseif ast.type == 'block' then
        self:walk(ast.body, ast)
    elseif ast.type == 'call' then
        self:walk(ast.name, ast)
    elseif traversal.unary[ast.type] then
        self:walk(ast.argument, ast)
    elseif ast.type == 'if' then
        self:walk(ast.condition, ast)
        self:walk(ast.body, ast)
        self:walk(ast.fallback, ast)
    elseif ast.type == 'while' then
        self:walk(ast.condition, ast)
        self:walk(ast.body, ast)
    elseif ast.type == 'get' then
        self:walk(ast.argument, ast)
        self:walk(ast.start, ast)
        self:walk(ast.width, ast)
    elseif ast.type == 'set' then
        self:walk(ast.argument, ast)
        self:walk(ast.start, ast)
        self:walk(ast.width, ast)
        self:walk(ast.value, ast)
    elseif ast.type == 'random' or ast.type == 'prompt' then
        parent.volatile = true
        ast.volatile = true
    elseif traversal.literal[ast.type] then
        return
    else
        print(ast.type)
    end

    return self.map
end

return symbols