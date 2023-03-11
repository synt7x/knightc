local inference = {}
local frog = require('lib/frog')
local json = require('lib/json')

function inference.new(ast, symbols)
    local self = {}
    for name, value in pairs(inference) do
        self[name] = value    
    end
    
    self.symbols = symbols
    self:walk(ast)

    return ast, symbols
end

local function find(node, search)
    local child = false
    for i, value in pairs(node) do
        if type(value) == 'table' then
            local result = find(value, search)
            if result then
                child = result
            end
        end
    end

    if node.types and node.types[search] and not child then
        return node
    elseif child then
        return child
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

function inference:getReference(name)
    local reference = self.symbols[name] or {}
    reference.types = reference.types or {}
    return reference
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
                'Maybe change this to a number.'
            )
        end   
    elseif node.type == 'subtract' or node.type == 'divide' or node.type == 'mod' then
        if t1.types.number then
            add(node.types, 'number')
        else
            frog:throw(
                t1,
                'The ' .. node.type .. ' (' .. (node.type == 'mod' and '%' or node.type == 'divide' and '/' or '-') ..
                ') operator expects a number as its first argument.', 'Maybe change this to a number.'
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
        if t1.types.number or t1.types.boolean or t1.types.string or t1.types.list then
            add(node.types, 'boolean')
        else
            frog:throw(
                t1,
                'The ' .. node.type .. ' (' .. (node.type == 'less' and '<' or '>') ..
                ') operator expects a number, boolean, string, or list as its first argument.',
                'Maybe change this to a number, boolean, string, or a list.'
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

function inference:unary(node)
    local t1 = self:expression(node.value)
    if node.type == 'length' then
        if t1.type == 'block' then
            frog:throw(
                t1,
                'The length (L) operator does not accept block statements as arguments.',
                'Try replacing this token with a number in order to fulfill the argument types.'
            )
        else
            add(node.types, 'number')
        end
    elseif node.type == 'exit' then
        if t1.type == 'block' then
            frog:throw(
                t1,
                'The exit (Q) operator does not accept block statements as arguments.',
                'Try replacing this token with a number in order to fulfill the argument types.'
            )
        else
            add(node.types, 'null')
        end
    elseif node.type == 'output' or node.type == 'dump' then
        add(node.types, 'null')
    elseif node.type == 'not' then
        if t1.types.block then
            frog:throw(
                t1,
                'The not (!) operator does not accept block statements as arguments.',
                'Try replacing this token with a number in order to fulfill the argument types.'
            )
        else
            add(node.types, 'boolean')
        end
    elseif node.type == 'negate' then
        if t1.types.block then
            frog:throw(
                t1,
                'The negate (~) operator does not accept block statements as arguments.',
                'Try replacing this token with a number in order to fulfill the argument types.'
            )
        else
            add(node.types, 'number')
        end
    elseif node.type == 'asci' then
        for i, v in ipairs(node.types) do print(v) end
        if not t1.types.number and not t1.type.string then
            frog:throw(
                t1,
                'The ASCII (A) operator expects a number or a string, and accepts no other types.',
                'Since ASCII does not coerce its arguments, maybe try using a value that produces a string or integer.'
            )
        end
    elseif node.type == 'call' then
        if not t1.types.block then
            frog:throw(
                t1,
                'Called value will never be a block.',
                'Try replacing this value with a block or variable that contains a block.'
            )
        end
    elseif node.type == 'box' then
        add(node.types, 'list')
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
    elseif node.type == 'assignment' then
        local t1 = self:expression(node.value)
        add(self:getReference(node.name.characters).types, t1.types)
        add(node.types, t1.types)
    elseif node.type == 'while' then
        self:expression(node.condition)
        self:expression(node.body)
        add(node.types, 'null')
    elseif node.name then
        self:expression(node.value, node)
    elseif not node.length and node.value then
        self:unary(node)
    elseif node.type == 'block' then
        self:expression(node.body, node)
        add(node.types, 'block')
    elseif node.type == 'if' then
        self:expression(node.condition, node)

        local e1 = self:expression(node.body, node)
        local e2 = self:expression(node.catch, node)
        add(node.types, e1.types)
        add(node.types, e2.types)
    elseif node.type == 'identifier' then
        add(node.types, self:getReference(node.characters).types)
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