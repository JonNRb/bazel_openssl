def run_configure():
  native.genrule(
      name = "run_configure",
      srcs = [
          "openssl/Configure",
          "openssl/include/openssl/opensslv.h",
      ] + native.glob([
          "openssl/Configurations/*",
          "openssl/**/build.info",
          "openssl/util/*.pl",
          "openssl/util/**/*.pm",
          "openssl/external/**/*.pm",
      ]),
      tools = ["openssl/config"],
      outs = ["openssl/configdata.pm"],
      cmd = "bazel_root=$$(pwd);" +
            "cd $$(dirname $(location :openssl/config));" +
            "./config > /dev/null;" +
            "mv configdata.pm $$bazel_root/$(location :openssl/configdata.pm);" +
            "",
  )

def gen_headers():
  native.genrule(
      name = "gen_headers",
      srcs = [
          "openssl/configdata.pm",
          "openssl/crypto/include/internal/bn_conf.h.in",
          "openssl/crypto/include/internal/dso_conf.h.in",
          "openssl/include/openssl/opensslconf.h.in",
      ] + native.glob([
          "openssl/apps/*",
          "openssl/util/*.pl",
          "openssl/util/**/*.pm",
          "openssl/external/**/*.pm",
      ]),
      outs = [
          "openssl/apps/progs.h",
          "openssl/crypto/include/internal/bn_conf.h",
          "openssl/crypto/include/internal/dso_conf.h",
          "openssl/crypto/buildinf.h",
          "openssl/include/openssl/opensslconf.h",
      ],
      cmd = "bazel_root=$$(pwd);" +
            "cd $$(dirname $(location :openssl/crypto/include/internal/bn_conf.h.in))/../../..;" +
            "cp -n $$bazel_root/$(location openssl/configdata.pm) .;" +
            "perl apps/progs.pl apps/openssl" +
            "  > $$bazel_root/$(location :openssl/apps/progs.h);" +
            "perl -I. -Mconfigdata util/dofile.pl -oMakefile" +
            "  $$bazel_root/$(location openssl/crypto/include/internal/bn_conf.h.in)" +
            "  > $$bazel_root/$(location :openssl/crypto/include/internal/bn_conf.h);" +
            "perl -I. -Mconfigdata util/dofile.pl -oMakefile" +
            "  $$bazel_root/$(location openssl/crypto/include/internal/dso_conf.h.in)" +
            "  > $$bazel_root/$(location :openssl/crypto/include/internal/dso_conf.h);" +
            "perl -I. -Mconfigdata util/dofile.pl -oMakefile" +
            "  $$bazel_root/$(location openssl/include/openssl/opensslconf.h.in)" +
            "  > $$bazel_root/$(location :openssl/include/openssl/opensslconf.h);" +
            "perl util/mkbuildinf.pl \"\\\"http://bazel.build/\\\"\"" +
            "  > $$bazel_root/$(location :openssl/crypto/buildinf.h);" +
            "",
  )
