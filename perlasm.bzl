def _perlasm_cc(ctx, src, deps, opts_str):
  out = ctx.actions.declare_file(src.basename.replace(src.extension, "s"))

  ctx.actions.run_shell(
      outputs = [out],
      inputs = deps + [src],
      arguments = [src.path, opts_str, out.path],
      command = "perl $1 $2 $3",
      mnemonic = 'PerlAsmCompile')

  return out


def _perlasm_rule_impl(ctx):
  deps = [dep for target in ctx.attr.deps
          for dep in target.files.to_list()]
  opts_str = " ".join(ctx.attr.copts)
  asms = [_perlasm_cc(ctx, src, deps, opts_str)
          for target in ctx.attr.srcs
          for src in target.files.to_list()]
  return DefaultInfo(files=depset(asms))


perlasm_sources = rule(
  implementation=_perlasm_rule_impl,
  attrs={
    "srcs": attr.label_list(allow_files=True),
    "deps": attr.label_list(allow_files=True),
    "copts": attr.string_list(),
  })
