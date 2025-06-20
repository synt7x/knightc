local typecheck = {}

local frog = require('lib/frog')
local json = require('lib/json')

function typecheck.new(symbols, ast)
    local self = {}
    for name, value in pairs(typecheck) do
        self[name] = value
    end

    self.symbols = symbols
    print(self.format(self:infer(ast.body)))

    return
end

function typecheck.try(callback)
    local ok, result = pcall(callback)
    if ok then return result end
end

function typecheck.coerce(from, to)
    from = typecheck.prune(from)
    to = typecheck.prune(to)

    if typecheck.equals(from, to) then
        return true
    end

    if from.kind == 'number' then
        if to.kind == 'string' or to.kind == 'boolean' then
            return to
        elseif to.kind == 'list' then
            local list = typecheck.kind('list', from.token)
            list.children = from
            return list
        end
    elseif from.kind == 'string' then
        if to.kind == 'number' or to.kind == 'boolean' then
            return to
        elseif to.kind == 'list' then
            local list = typecheck.kind('list', from.token)
            list.children = from
            return list
        end
    elseif from.kind == 'boolean' then
        if to.kind == 'number' or to.kind == 'string' then
            return to
        end
    elseif from.kind == 'list' then
        if to.kind == 'number' or to.kind == 'string' or to.kind == 'boolean' then
            return to
        elseif to.kind == 'list' then
            to.children = typecheck.union(to.children, from.children)
            return to
        end
    elseif from.kind == 'null' then
        if to.kind == 'number' or to.kind == 'string' or to.kind == 'boolean' or to.kind == 'list' then
            return to
        end
    end

    return false
end

function typecheck.format(type, seen)
    type = type or {}
    seen = seen or {}

    type = typecheck.prune(type)

    if type.kind == 'number' then
        return 'number'
    elseif type.kind == 'string' then
        return 'string'
    elseif type.kind == 'boolean' then
        return 'boolean'
    elseif type.kind == 'null' then
        return 'null'
    elseif type.kind == 'block' then
        return '(() => ' .. typecheck.format(type.children, seen) .. ')'
    elseif type.kind == 'list' then
        return 'list[' .. typecheck.format(type.children, seen) .. ']'
    elseif type.kind == 'union' then
        local parts = {}
        for _, t in ipairs(type.types) do
            table.insert(parts, typecheck.format(t, seen))
        end
        return '(' .. table.concat(parts, ' | ') .. ')'
    elseif type.kind == 'var' then
        if seen[type.id] then
            return 'T (recursive)'
        end
        seen[type.id] = true
        return 'T'
    else
        return '<unknown type>'
    end
end

function typecheck.kind(type, token)
    return { kind = type, token = token }
end

function typecheck.var(token)
    local var = typecheck.kind('var', token)
    var.id = tostring(var)

    return var
end

function typecheck.prune(t)
    while t.kind == 'var' and t.instance do
        t.instance = typecheck.prune(t.instance)
        t = t.instance
    end

    return t
end

function typecheck.contains(v, t)
    t = typecheck.prune(t)
    if v == t then
        return true
    end

    if t.kind == 'list' then
        return typecheck.contains(v, t.children)
    end

    if t.kind == 'var' and t.instance then
        return typecheck.contains(v, t.instance)
    end

    return false
end

function typecheck.unify(t1, t2)
    t1, t2 = typecheck.prune(t1), typecheck.prune(t2)
    if t1 == t2 then
        return
    end

    if t1.kind == 'var' then
        t1.instance = t2
        return
    end

    if t2.kind == 'var' then
        return typecheck.unify(t2, t1)
    end

    if t1.kind ~= t2.kind then
        error(
            string.format('Type mismatch: %s and %s are not the same type', self.format(t1), self.format(t2))
        )
    end

    if t1.kind == 'list' then
        return typecheck.unify(t1.children, t2.children)
    end
end

function typecheck.union(t1, t2)
    t1, t2 = typecheck.prune(t1), typecheck.prune(t2)

    if t1.kind == 'union' then
        for _, subtype in ipairs(t1.types) do
            if typecheck.equals(subtype, t2) then
                return t1
            end
        end

        table.insert(t1.types, t2)
        return t1
    end

    if t2.kind == 'union' then
        return typecheck.union(t2, t1)
    end

    if not typecheck.equals(t1, t2) then
        local union = typecheck.kind('union')
        union.types = { t1, t2 }
        return union
    else
        return t1
    end
end

function typecheck.equals(t1, t2)
    t1, t2 = typecheck.prune(t1), typecheck.prune(t2)

    if t1 == t2 then
        return true
    end

    if t1.kind == 'var' and t1.instance then
        return typecheck.equals(t1.instance, t2)
    end

    if t2.kind == 'var' and t2.instance then
        return typecheck.equals(t1, t2.instance)
    end

    if t1.kind ~= t2.kind then
        return false
    end

    if t1.kind == 'list' then
        return typecheck.equals(t1.children, t2.children)
    end

    return false
end

function typecheck:infer(ast, parent)
    if not ast then
        frog:throw(
            parent.token,
            string.format('Panic during typecheck, recieved nil child while walking node %s', parent.type),
            'Please report this as a bug in the issue tracker (https://github.com/synt7x/knightc/issues/new)',
            'Fatal'
        )

        os.exit(1)
    end

    if ast.type == 'add' then
        local left = self:infer(ast.left, ast)
        local right = self:infer(ast.right, ast)

        local result = self.try(function()
            self.unify(left, right)
            return left
        end)

        if result then return result end

        local coerced = self.coerce(right, left)
        if coerced then
            return coerced
        end

        frog:throw(
            right.token or ast.right.token,
            string.format(
                'Could not coerce %s to %s in addition operation',
                self.format(right),
                self.format(left)
            ),
            'The right side of the addition operation must be coercible to the left side',
            'Types'
        )
    elseif ast.type == 'subtract' then
    elseif ast.type == 'multiply' then
    elseif ast.type == 'divide' then
    elseif ast.type == 'modulus' then
    elseif ast.type == 'exponent' then
    elseif ast.type == 'and' then
        local left = self:infer(ast.left, ast)
        local right = self:infer(ast.right, ast)

        local result = self.union(left, right)
        return result
    elseif ast.type == 'or' then
        local left = self:infer(ast.left, ast)
        local right = self:infer(ast.right, ast)

        local result = self.union(left, right)
        return result
    elseif ast.type == 'expr' then
    elseif ast.type == 'exact' then
    elseif ast.type == 'less' then
    elseif ast.type == 'greater' then
    elseif ast.type == 'output' or  ast.type == 'dump' then
        self:infer(ast.argument, ast)
        return self.kind('null', ast.token)
    elseif ast.type == 'prompt' then
        return self.kind('string', ast.token)
    elseif ast.type == 'random' then
    elseif ast.type == 'box' then
        local children = self:infer(ast.argument, ast)
        local type = self.kind('list', ast.token)
        type.children = children
        return type
    elseif ast.type == 'prime' then
        local array = self.prune(self:infer(ast.argument, ast))
        if array.kind == 'list' then
            return array.children
        elseif array.kind == 'string' then
            return array
        elseif array.kind == 'union' then
            local types = {}
            for _, t in ipairs(array.types) do
                if t.kind == 'list' then
                    table.insert(types, t.children)
                elseif t.kind == 'string' then
                    table.insert(types, t)
                else
                    frog:throw(
                        t.token or ast.argument.token,
                        string.format('Argument for prime is not guaranteed to be a list or string, can possibly be of type %s', self.format(t)),
                        'Consider using a different variable to store this value',
                        'Warn'
                    )
                end
            end

            if #types == 1 then
                return types[1]
            elseif #types > 1 then
                local union = types[1]
                for i = 2, #types do
                    union = self.union(union, types[i])
                end

                return union
            end

            frog:throw(
                array.token or ast.argument.token,
                string.format('Expected a list or string, got %s', self.format(array)),
                'You can only get the first element of a non-empty list or string',
                'Types'
            )
        else
            frog:throw(
                array.token or ast.argument.token,
                string.format('Expected a list or string, got %s', self.format(array)),
                'You can only get the first element of a non-empty list or string',
                'Types'
            )
        end
    elseif ast.type == 'ultimate' then

    elseif ast.type == 'ascii' then
    elseif ast.type == 'length' then
    elseif ast.type == 'not' then
    elseif ast.type == 'negative' then
    elseif ast.type == 'quit' then
    elseif ast.type == 'identifier' then
    elseif ast.type == 'assignment' then
    elseif ast.type == 'block' then
        local type = self.kind('block', ast.token)
        type.children = self:infer(ast.body, ast)

        return type
    elseif ast.type == 'call' then
        local block = self:infer(ast.name, ast)

        if block.kind == 'block' then
            return block.children
        elseif block.kind == 'union' then
            local types = {}

            for _, t in ipairs(block.types) do
                if t.kind == 'block' then
                    table.insert(types, t.children)
                else
                    frog:throw(
                        t.token or ast.name.token,
                        string.format('Argument for call is not guaranteed to be a block, can possibly be of type %s', self.format(t)),
                        'Consider using a different variable to store this value',
                        'Warn'
                    )
                end
            end
            
            if #types == 1 then
                return types[1]
            elseif #types > 1 then
                local union = types[1]
                for i = 2, #types do
                    union = self.union(union, types[i])
                end

                return union
            end

            frog:throw(
                ast.argument.token,
                string.format('Expected a block, got %s', self.format(block)),
                'You can only call blocks',
                'Types'
            )
        end
    elseif ast.type == 'if' then
    elseif ast.type == 'while' then
    elseif ast.type == 'get' then
    elseif ast.type == 'set' then
    elseif
        ast.type == 'string'
        or ast.type == 'number'
        or ast.type == 'null'
        or ast.type == 'boolean' 
    then
        return self.kind(ast.type, ast.token)
    elseif ast.type == 'list' then
        local type = self.kind('list', ast.token)
        type.children = self.var()
        return type
    else
        frog:throw(
            ast.token,
            string.format('Panic during typecheck, recieved unknown node of type %s', ast.type),
            'Please report this as a bug in the issue tracker (https://github.com/synt7x/knightc/issues/new)',
            'Fatal'
        )

        os.exit(1)
    end
end

return typecheck
