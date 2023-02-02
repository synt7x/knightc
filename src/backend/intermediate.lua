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
        constants = {},
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

function intermediate:swapRegister()
    self.register = self.register + 1
end

function intermediate:assignment(node)
    self:swapRegister()
    self:expression(node.value)

    local node = {
        id = self:getSymbol(node.name).id,
        type = 'move',
        register = self.register
    }

    table.insert(self.tree, node)
end

function intermediate:expression(node)
    if node.type == 'sequence' then
        self:expression(node.left)
        self:expression(node.right)
    elseif node.type == 'assignment' then
        self:assignment(node)
    else
        print(node.type)
    end

    return {}
end

return intermediate