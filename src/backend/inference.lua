local inference = {}
local frog = require('lib/frog')

function inference.new(ast, symbols)
    local self = {}
    for name, value in pairs(inference) do
        self[name] = value    
    end
    
    self.symbols = symbols
    self:walk(ast)

    return ast
end

local function find(node, search)
    for key, value in pairs(node) do
        if key == 'type' and value == search then
            return node
        elseif type(value) == 'table' then
            local result = find(value, search)
            if result then return result end
        end
    end

    return false
end

local function add(array, node)
    if type(node) == 'string' then
        array[node] = true
        return array
    end

    for type, _ in pairs(node) do
        array[type] = true
    end

    return array
end

function inference:binary(node)
    local t1 = self:expression(node.left, node)
    local t2 = self:expression(node.right, node)

    if node.type == 'multiply' or node.type == 'add' then
        if t1.types.list or t1.types.string or t1.types.number then
            add(node.types, t1.types)
        else
            frog:throw(
                t1,
                'The ' .. node.type .. ' (' .. (node.type == 'add' and '+' or '*') ..
                ') operator expects a number, string, or list as its first argument.',
                'Maybe change this to a number'
            )
        end
    elseif node.type == 'subtract' or node.type == 'divide' or node.type == 'mod' then
        if t1.types.number then
            add(node.types, 'number')
        else
            frog:throw(
                t1,
                'The ' .. node.type .. ' (' .. (node.type == 'mod' and '%' or node.type == 'divide' and '/' or '-') ..
                ') operator expects a number as its first argument.'
            )
        end
    elseif node.type == 'power' then
        if t1.types.number or t1.types.list then
            add(node.types, t1.types)
        else
            frog:throw(
                t1,
                'The power (^) operator expects a number or list as its first argument.',
                'Maybe replace this with a number'
            )
        end
    elseif node.type == 'greater' or node.type == 'less' then
        if node.types.number or node.types.boolean or node.types.string or node.types.list then
            add(node.types, 'boolean')
        else
            frog:throw(
                t1,
                'The ' .. node.type .. ' (' .. (node.type == 'less' and '<' or '>') ..
                ') operator expects a number, boolean, string, or list as its first argument.',
                'Maybe change this to a number'
            )
        end
    elseif node.type == 'equals' then
        if not t1.types.block and not t2.types.block then
            add(node.types, 'boolean')
        else
            frog:throw(
                node,
                'You cannot use a block with an equals (?) operator.'
            )
        end
    elseif node.type == 'and' or node.type == 'or' then
        add(node.types, t1.types)
        add(node.types, t2.types)
    elseif node.type == 'sequence' then
        add(node.types, t2.types)
    else
        print(node.type)
    end
end

function inference:expression(node, parent)
    node.types = {}

    if #node == 1 or node.type == 'string'
    or node.type == 'number'
    or node.type == 'list'
    or node.type == 'boolean'
    or node.type == 'null' then
        add(node.types, node.type)
        return node
    end

    if node.left then
        self:binary(node)
    elseif node.type == 'while' then
        self:expression(node.condition)
        self:expression(node.body)
        add(node.types, 'null')
    elseif node.name then
       
        self:expression(node.value, node)
    elseif node.value then
        self:expression(node.value, node)
    elseif node.type == 'block' then
        self:expression(node.body, node)
        add(node.types, 'block')
    elseif node.type == 'if' then
        self:expression(node.condition, node)
        self:expression(node.body, node)
        self:expression(node.catch, node)
    elseif node.type == 'identifier' then
        --self:reference(parent, node)
    end

    return node
end

function inference:walk(ast)
    self.parent = ast.body
    local exit = self:expression(ast.body, ast.body)

    for type, _ in pairs(exit.types) do
        if type ~= 'null' and type ~= 'number' and type ~= 'boolean' then
            if #exit.types == 1 then
                frog:throw(
                    find(exit, type),
                    'Expected the program to return either a boolean, number, or null, but it returns '
                    .. type .. '.',
                    'Maybe try removing this token or altering control flow to remove it as a return result.'
                )
            else
                frog:throw(
                    find(exit, type),
                    'Expected the program to return either a boolean, number, or null, but it can return '
                    .. type .. '.',
                    'Maybe try removing this token or altering control flow to remove it as a return result.'
                )
            end
        end
    end

    return exit
end

return inference