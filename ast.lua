{
  a = {
    deps = {},
    revdeps = {
      next_arg = 2
    },
    tag = 4,
    types = <1>{ "string" }
  },
  next_arg = {
    deps = {
      a = 4
    },
    revdeps = {
      next_integer = 1
    },
    tag = 2,
    types = { "block",
      block = <table 1>
    }
  },
  next_integer = {
    deps = {
      next_arg = 2,
      to_integer = 3
    },
    revdeps = {},
    tag = 1,
    types = { "block",
      block = <2>{ "number" }
    }
  },
  to_integer = {
    deps = {},
    revdeps = {
      next_integer = 1
    },
    tag = 3,
    types = { "block",
      block = <table 2>
    }
  }
}