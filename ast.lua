{
  fibonacci = {
    defs = { {
        name = {
          characters = "fibonacci",
          position = { 9, 5,
            file = "examples/fib.kn"
          },
          type = "identifier",
          types = <1>{ "block",
            block = <2>{ "number" }
          }
        },
        token = {
          characters = "=",
          position = { 9, 3 },
          type = "="
        },
        type = "assignment",
        types = { "null" },
        value = {
          body = {
            body = <3>{
              characters = "n",
              position = { 11, 5,
                file = "examples/fib.kn"
              },
              tag = 2,
              token = <table 3>,
              type = "identifier",
              types = <4>{ "number" }
            },
            condition = {
              left = <5>{
                characters = "n",
                position = { 10, 8,
                  file = "examples/fib.kn"
                },
                tag = 2,
                token = <table 5>,
                type = "identifier",
                types = <table 4>
              },
              right = <6>{
                characters = "2",
                position = { 10, 10,
                  file = "examples/fib.kn"
                },
                token = <table 6>,
                type = "number",
                types = { "number" }
              },
              token = {
                characters = "<",
                position = { 10, 6 },
                type = "<"
              },
              type = "less",
              types = { "boolean" }
            },
            fallback = {
              left = <7>{
                name = {
                  characters = "n",
                  position = { 13, 7,
                    file = "examples/fib.kn"
                  },
                  tag = 2,
                  type = "identifier",
                  types = <table 4>
                },
                token = {
                  characters = "=",
                  position = { 13, 5 },
                  type = "="
                },
                type = "assignment",
                types = { "null" },
                value = {
                  left = <8>{
                    characters = "n",
                    position = { 13, 11,
                      file = "examples/fib.kn"
                    },
                    tag = 2,
                    token = <table 8>,
                    type = "identifier",
                    types = <table 4>
                  },
                  right = <9>{
                    characters = "1",
                    position = { 13, 13,
                      file = "examples/fib.kn"
                    },
                    token = <table 9>,
                    type = "number",
                    types = { "number" }
                  },
                  token = {
                    characters = "-",
                    position = { 13, 9 },
                    type = "-"
                  },
                  type = "subtract",
                  types = { "number" }
                }
              },
              right = {
                left = <10>{
                  name = {
                    characters = "n",
                    position = { 18, 7,
                      file = "examples/fib.kn"
                    },
                    tag = 2,
                    type = "identifier",
                    types = <table 4>
                  },
                  token = {
                    characters = "=",
                    position = { 18, 5 },
                    type = "="
                  },
                  type = "assignment",
                  types = { "null" },
                  value = {
                    left = <11>{
                      characters = "n",
                      position = { 18, 11,
                        file = "examples/fib.kn"
                      },
                      tag = 2,
                      token = <table 11>,
                      type = "identifier",
                      types = <table 4>
                    },
                    right = {
                      left = <12>{
                        name = {
                          characters = "tmp",
                          position = { 18, 19,
                            file = "examples/fib.kn"
                          },
                          tag = 3,
                          type = "identifier",
                          types = <13>{ "number" }
                        },
                        token = {
                          characters = "=",
                          position = { 18, 17 },
                          type = "="
                        },
                        type = "assignment",
                        types = { "null" },
                        value = {
                          name = <14>{
                            characters = "fibonacci",
                            position = { 18, 28,
                              file = "examples/fib.kn"
                            },
                            tag = 1,
                            token = <table 14>,
                            type = "identifier",
                            types = <table 1>
                          },
                          token = {
                            characters = "CALL",
                            position = { 18, 23,
                              file = "examples/fib.kn"
                            },
                            type = "CALL"
                          },
                          type = "call",
                          types = <table 2>
                        }
                      },
                      right = <15>{
                        characters = "1",
                        position = { 18, 39,
                          file = "examples/fib.kn"
                        },
                        token = <table 15>,
                        type = "number",
                        types = <16>{ "number" }
                      },
                      token = {
                        characters = ";",
                        position = { 18, 14 },
                        type = ";"
                      },
                      type = "expr",
                      types = <table 16>
                    },
                    token = {
                      characters = "-",
                      position = { 18, 9 },
                      type = "-"
                    },
                    type = "subtract",
                    types = { "number" }
                  }
                },
                right = {
                  left = <17>{
                    characters = "tmp",
                    position = { 19, 7,
                      file = "examples/fib.kn"
                    },
                    tag = 3,
                    token = <table 17>,
                    type = "identifier",
                    types = <table 13>
                  },
                  right = {
                    name = <18>{
                      characters = "fibonacci",
                      position = { 19, 16,
                        file = "examples/fib.kn"
                      },
                      tag = 1,
                      token = <table 18>,
                      type = "identifier",
                      types = <table 1>
                    },
                    token = {
                      characters = "CALL",
                      position = { 19, 11,
                        file = "examples/fib.kn"
                      },
                      type = "CALL"
                    },
                    type = "call",
                    types = <table 2>
                  },
                  token = {
                    characters = "+",
                    position = { 19, 5 },
                    type = "+"
                  },
                  type = "add",
                  types = <19>{ "number" }
                },
                token = {
                  characters = ";",
                  position = { 18, 3 },
                  type = ";"
                },
                type = "expr",
                types = <table 19>
              },
              token = {
                characters = ";",
                position = { 13, 3 },
                type = ";"
              },
              type = "expr",
              types = <table 19>
            },
            token = {
              characters = "IF",
              position = { 10, 2,
                file = "examples/fib.kn"
              },
              type = "IF"
            },
            type = "if",
            types = <20>{ "number" }
          },
          token = {
            characters = "BLOCK",
            position = { 9, 15,
              file = "examples/fib.kn"
            },
            type = "BLOCK"
          },
          type = "block",
          types = { "block",
            block = <table 20>
          }
        }
      } },
    deps = {
      n = 2,
      tmp = 3
    },
    revdeps = {
      n = 2,
      tmp = 3
    },
    tag = 1,
    types = <table 1>
  },
  n = {
    defs = { <table 7>, <table 10>, {
        name = {
          characters = "n",
          position = { 23, 5,
            file = "examples/fib.kn"
          },
          tag = 2,
          type = "identifier",
          types = <table 4>
        },
        token = {
          characters = "=",
          position = { 23, 3 },
          type = "="
        },
        type = "assignment",
        types = { "null" },
        value = <21>{
          characters = "35",
          position = { 23, 7,
            file = "examples/fib.kn"
          },
          token = <table 21>,
          type = "number",
          types = { "number" }
        }
      } },
    deps = {
      fibonacci = 1,
      tmp = 3
    },
    resolved = true,
    revdeps = {
      fibonacci = 1
    },
    tag = 2,
    types = <table 4>
  },
  tmp = {
    defs = { <table 12> },
    deps = {
      fibonacci = 1
    },
    resolved = true,
    revdeps = {
      fibonacci = 1,
      n = 2
    },
    tag = 3,
    types = <table 13>
  }
}