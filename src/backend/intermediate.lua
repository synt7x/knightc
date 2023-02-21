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
    self.reg = 0

    self.tree = self.ir
    self.ancestory = {}
	self.node = self.tree

    self:enter(self.tree, self.tree.body)
    self:expression(ast.body, self:getRegister())
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

function intermediate:isLiteral(node)
    if node.type == 'number' or node.type == 'string' then
        return true
    end

    return false
end

function intermediate:register(reg)
    return {
        type = 'register',
        value = reg
    }
end

function intermediate:constant(index)
    return {
        type = 'constant',
        value = index
    }
end

function intermediate:literal(node)
    table.insert(self.ir.constants, node)

    return #self.ir.constants
end

function intermediate:move(imm, reg)
    table.insert(self.tree, {
        type = 'move',
        immediate = imm,
        register = reg
    })
end

function intermediate:getSymbol(identifier)
    return self.symbols[identifier.characters]
end

function intermediate:getRegister()
    self.reg = self.reg + 1
    return self.reg
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
    local root = #self.tree + 1
    local register = self:getRegister()
    table.insert(self.tree, self:condition(node.condition, register))

    local condition = #self.tree + 1

    table.insert(self.tree, {
        type = 'catch'
    })

    local position = #self.tree

    table.insert(self.tree, {
        type = 'body'
    })


    table.insert(self.tree, condition, {
        type = 'je',
        right = { type = 'constant', index = 1 },
        left = { type = 'register', register = register },
        position = #self.tree + 1 - root
    })

    table.insert(self.tree, position + 2, {
        type = 'j',
        position = #self.tree - root - 1
    })
end

function intermediate:conditionloop(node)
    local root = #self.tree + 1
    local body = #self.tree + 2
    
    self:expression(node.body)

    local condition = #self.tree + 2
    local register = self:getRegister()

    table.insert(self.tree, self:condition(node.condition, register))
    table.insert(self.tree, {
        type = 'je',
        right = { type = 'constant', index = 1 },
        left = { type = 'register', register = register },
        position = root - #self.tree - 1
    })

    table.insert(self.tree, body - 1, {
        type = 'j',
        position = condition - root
    })
end

function intermediate:add(node, register)
    local literals = 0

    local reg1 = 0
    local reg2 = 0

    if self:isLiteral(node.left) then
        literals = literals + 1

        local constant = self:literal(node.left)
        self:move(self:constant(constant), self:register(self:getRegister()))
        reg1 = self.reg
    else
        reg1 = self:getRegister()
        self:expression(node.left, reg1)
    end
    
    if self:isLiteral(node.right) then
        literals = literals + 1

        local constant = self:literal(node.right)
        self:move(self:constant(constant), self:register(self:getRegister()))
        reg2 = self.reg
    else
        reg2 = self:getRegister()
        self:expression(node.right, reg2)
    end

    table.insert(self.tree, {
        type = 'add',
        reg1 = reg1,
        reg2 = reg2
    })

    self:move(self:register(reg1), self:register(register))
end

function intermediate:expression(node, register)
    if node.type == 'add' then
        self:add(node, register)
    end
end

return intermediate