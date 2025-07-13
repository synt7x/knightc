local ir = {}
local frog = require('lib/frog')

-- import targets
local bytecode = require('src/backend/targets/bytecode')

local targets = {
    bytecode = bytecode
}

function ir.new(ast)
    local self = {}

    for name, value in pairs(ir) do
		self[name] = value
	end

    self.ast = ast.body
    self.code = {}
    self.constants = {}
    self.data = {}

    return self
end

function ir:generate()
    self.code = self:compile(self.ast)
    return self.code, self.constants, self.data
end

function ir:compile(ast)
    if not ast then
        frog:throw(
            parent.token,
            string.format("Panic during IR construction, recieved nil child while walking node %s", parent.type),
            "Please report this as a bug in the issue tracker (https://github.com/synt7x/knightc/issues/new)",
            "Fatal"
        )

        os.exit(1)
    end

    if ast.type == 'call' then

    elseif ast.type == 'quit' then

    elseif ast.type == 'output' then

    elseif ast.type == 'dump' then

    elseif ast.type == 'length' then

    elseif ast.type == 'not' then

    elseif ast.type == 'negative' then

    elseif ast.type == 'ascii' then

	elseif ast.type == 'box' then

	elseif ast.type == 'prime' then

	elseif ast.type == 'ultimate' then

	elseif ast.type == 'add' then    

	elseif ast.type == 'subtract' then

	elseif ast.type == 'multiply' then

	elseif ast.type == 'divide' then

	elseif ast.type == 'modulus' then

	elseif ast.type == 'exponent' then

	elseif ast.type == 'less' then

	elseif ast.type == 'greater' then

	elseif ast.type == 'exact' then

    elseif ast.type == 'and' then

    elseif ast.type == 'or' then

    elseif ast.type == 'expr' then

    elseif ast.type == 'assignment' then

    elseif ast.type == 'if' then

    elseif ast.type == 'get' then

    elseif ast.type == 'set' then

    elseif ast.type == 'while' then

    elseif ast.type == 'prompt' then

    elseif ast.type == 'random' then
        
	elseif ast.type == 'block' then

    elseif ast.type == 'identifier' then

    elseif ast.type == 'number' then

    elseif ast.type == 'string' then

    elseif ast.type == 'list' then

    elseif ast.type == 'boolean' then

    elseif ast.type == 'null' then

    else
        frog:throw(
            ast.token,
            string.format('Panic during IR construction, unhandled node of type %s', ast.type),
            'Please report this as a bug in the issue tracker (https://github.com/synt7x/knightc/issues/new)',
            'Fatal'
        )
    end
end

function ir:transform(transformer)
    if not targets[transformer] then
        frog:throw(
            nil,
            'Target "' .. transformer .. '" not found',
            'Try using a different target or check the spelling'
        )
    end
end

return ir