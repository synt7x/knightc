local intermediate = {}

function intermediate.new(flags, ast, symbols)
    local self = {}
    for name, value in pairs(intermediate) do
        self[name] = value
    end

    self.ir = {
        format = flags.f,
        target = flags.t,
        imports = {},
        constants = {
            true,
            false,
        },
        body = {}
    }

    self.symbols = symbols
    self.register = 0

    self.tree = self.ir
    self.ancestory = {}
	self.node = self.tree

    self:enter(self.tree, self.tree.body)
    self:expression(ast.body)
    self:exit()

    table.insert(self.ir.body, {
        type = 'ret'
    })

    return self.ir
end


function intermediate:enter(node, body)
	table.insert(self.ancestory, {
		self.tree,
		self.node
	})

	self.tree = body
	self.node = node
end

function intermediate:exit()
	local ancestor = table.remove(self.ancestory)

	self.tree = ancestor[1]
	self.node = ancestor[2]
end

function intermediate:getSymbol(identifier)
    return self.symbols[identifier.characters]
end

function intermediate:getRegister()
    self.register = self.register + 1
    return self.register
end

function intermediate:assignment(node)
    
end

function intermediate:block(node)
    
end

function intermediate:condition(node, register)
    return {
        type = 'condition',
        uses = register
    }
end

function intermediate:branch(node, store)
    local register = self:getRegister()
    table.insert(self.tree, self:condition(node.condition, register))
    local position = #self.tree + 1

    table.insert(self.tree, {
        type = 'catch'
    })


    table.insert(self.tree, {
        type = 'body'
    })

    local body = #self.tree + 1

    table.insert(self.tree, position, {
        type = 'je',
        right = { type = 'constant', index = 1 },
        left = { type = 'register', register = register },
        position = body
    })

    table.insert(self.tree, body, {
        type = 'j',
        position = #self.tree + 2
    })
end

function intermediate:conditionloop(node)
    local body = #self.tree + 2
    
    self:expression(node.body)

    local condition = #self.tree + 2
    local register = self:getRegister()

    table.insert(self.tree, self:condition(node.condition, register))
    table.insert(self.tree, {
        type = 'je',
        right = { type = 'constant', index = 1 },
        left = { type = 'register', register = register },
        position = body
    })

    table.insert(self.tree, body - 1, {
        type = 'j',
        position = condition
    })
end

function intermediate:expression(node)
    if node.type == 'sequence' then
        self:expression(node.left)
        self:expression(node.right)
    elseif node.type == 'assignment' then
        self:assignment(node)
    elseif node.type == 'block' then
        self:block(node)
    elseif node.type == 'while' then
        self:conditionloop(node)
    elseif node.type == 'if' then
        self:branch(node)
    else
        print(node.type)
    end
end

return intermediate