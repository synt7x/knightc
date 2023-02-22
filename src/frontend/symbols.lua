local symbols = {}
local json = require('lib/json')

function symbols.new(ast)
    local self = {}
    for name, value in pairs(symbols) do
        self[name] = value    
    end

    self.table = {}
    self.index = 1
    
    self:walk(ast)

    return self.table
end

function symbols:reference(node, identifier)
    if not self.table[identifier.characters] then
        self.table[identifier.characters] = {
            assignments = {},
            references = { node },
            id = self.index
        }

        self.index = self.index + 1
    else
        table.insert(
            self.table[identifier.characters].references,
            node
        )
    end
end

function symbols:assignment(node, identifier)
    if not self.table[identifier.characters] then
        self.table[identifier.characters] = {
            assignments = { node },
            references = {},
            id = self.index
        }

        self.index = self.index + 1
    else
        table.insert(
            self.table[identifier.characters].assignments,
            node
        )
    end
end

function symbols:binary(node)
    self:expression(node.left, node)
    self:expression(node.right, node)
end

function symbols:expression(node, parent)
    if #node == 1 or node.type == 'string' or node.type == 'number' then return end

    if node.left then
        self:binary(node)
    elseif node.name then
        self:assignment(node, node.name)
        self:expression(node.value, node)
    elseif #node == 2 and node.value then
        self:expression(node.value, node)
    elseif node.type == 'block' then
        self:expression(node.body, node)
    elseif node.type == 'if' then
        self:expression(node.condition, node)
        self:expression(node.body, node)
        self:expression(node.catch, node)
    elseif node.type == 'identifier' then
        self:reference(parent, node)
    elseif node.type == 'get' then
        self:expression(node.value, node)
        self:expression(node.start, node)
        self:expression(node.length, node)
    elseif node.type == 'set' then
        self:expression(node.value, node)
        self:expression(node.start, node)
        self:expression(node.length, node)
        self:expression(node.predicate, node)
    end
end

function symbols:walk(ast)
    self.parent = ast.body
    return self:expression(ast.body, ast.body)
end

return symbols