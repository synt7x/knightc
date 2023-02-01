local frog = require('lib/frog')
local lexer = {
    symbols = {
        ['!'] = '!', [','] = ',', ['['] = '[', [']'] = ']',
        ['+'] = '+', ['-'] = '-', ['*'] = '*', ['/'] = '/',
        ['%'] = '%', ['^'] = '^', ['<'] = '<', ['>'] = '>',
        ['?'] = '?', ['&'] = '&', ['|'] = '|', [';'] = ';',
        ['='] = '=', ['@'] = '@', ['~'] = '~'
    }
}

function lexer.new(input)
    local self = {}
    for name, value in pairs(lexer) do
        self[name] = value
    end

    self.tokens = {}
    self.token = {}
    self.comments = {}

    if not input then return {} end

    for i = 1, #input do
        self:step(input:sub(i, i))
    end


    if self.token.type then
        if self.token.type == 'string' then
            frog:throw(
                'Unclosed string value reaching to end of file.',
                'Try inserting a closing quote where it needs to be.'
            )
        elseif self.token.type == 'comment' then
            table.insert(self.comments, self.token)
        else
            if self.token.type == 'reserved' then
                self.token.type = self.token.characters:sub(1, 1)
            end

            table.insert(self.tokens, self.token)
        end
    end

    return self.tokens, self.comments
end

function lexer:step(character)
    if not self.token.type then
        self:create(character)
    else
        self:continue(character)
    end
end

function lexer:create(character)
    local code = string.byte(character)
    self.token = {}

    if 
        character == ' ' or character == '\t' or
        character == '(' or character == ')' or
        character == '{' or character == '}' or
        character == ':'
    then
        return
    elseif character == '\n' or character == '\r' then
        frog:newline()
        return
    elseif
        character == '_' or
        code >= 97 and code <= 122
    then
        self.token.type = 'identifier'
        self.token.characters = character
    elseif code >= 65 and code <= 90 then
        self.token.type = 'reserved'
        self.token.characters = character
    elseif code >= 48 and code <= 57 then
        self.token.type = 'number'
        self.token.characters = character
    elseif character == '"' or character == '\'' then
        self.token.type = 'string'
        self.token.characters = ''
        self.token.delimiter = character
    elseif character == '#' then
        self.token.type = 'comment'
        self.token.characters = ''
    elseif self.symbols[character] then
        table.insert(self.tokens, {
            type = self.symbols[character],
            characters = character
        })
    else
        frog:throw(
            string.format('Unexpected character "%s"', character),
            'Maybe removing the character will solve the issue.'
        )
    end

    frog:character()
end

function lexer:continue(character)
    local code = string.byte(character)
    if self.token.type == 'identifier' then
        if
            character == '_' or
            code >= 97 and code <= 122 or
            code >= 48 and code <= 57
        then
            self.token.characters = self.token.characters .. character
        else
            table.insert(self.tokens, self.token)
            return self:create(character)
        end
    elseif self.token.type == 'reserved' then
        if code >= 65 and code <= 90 or character == '_' then
            self.token.characters = self.token.characters .. character
        else
            self.token.type = self.token.characters:sub(1, 1)
            table.insert(self.tokens, self.token)
            return self:create(character)
        end
    elseif self.token.type == 'number' then
        if code >= 48 and code <= 57 then
            self.token.characters = self.token.characters .. character
        else
            table.insert(self.tokens, self.token)
            return self:create(character)
        end
    elseif self.token.type == 'string' then
        if character ~= self.token.delimiter then
            self.token.characters = self.token.characters .. character
        else
            self.token.delimiter = nil
            table.insert(self.tokens, self.token)
            self.token = {}
        end
    elseif self.token.type == 'comment' then
        if character ~= '\n' then
            self.token.characters = self.token.characters .. character
        else
            table.insert(self.comments, self.token)
            self.token = {}
        end
    end

    frog:character()
end

return lexer