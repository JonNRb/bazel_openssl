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
      cmd = "cd openssl;" +
            "./config;" +
            "mv configdata.pm ../$(location :openssl/configdata.pm);" +
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
      cmd = "cp $(location openssl/configdata.pm) openssl/;" +
            "cd openssl;" +
            "perl apps/progs.pl apps/openssl" +
            "  > ../$(location :openssl/apps/progs.h);" +
            "perl -I. -Mconfigdata util/dofile.pl -oMakefile" +
            "  ../$(location openssl/crypto/include/internal/bn_conf.h.in)" +
            "  > ../$(location :openssl/crypto/include/internal/bn_conf.h);" +
            "perl -I. -Mconfigdata util/dofile.pl -oMakefile" +
            "  ../$(location openssl/crypto/include/internal/dso_conf.h.in)" +
            "  > ../$(location :openssl/crypto/include/internal/dso_conf.h);" +
            "perl -I. -Mconfigdata util/dofile.pl -oMakefile" +
            "  ../$(location openssl/include/openssl/opensslconf.h.in)" +
            "  > ../$(location :openssl/include/openssl/opensslconf.h);" +
            "perl util/mkbuildinf.pl \"\\\"http://bazel.build/\\\"\"" +
            "  > ../$(location :openssl/crypto/buildinf.h);" +
            "",
  )
