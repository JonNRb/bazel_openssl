def failing_executable_test(name, executable):
  native.genrule(
      name = "{}_genrule".format(name),
      outs = ["{}_check_failure.sh".format(name)],
      cmd = "echo '#!/bin/bash'        >> $@;" +
            "echo 'cmd=$$1'            >> $@;" +
            "echo 'shift'              >> $@;" +
            "echo 'if $$cmd $$@; then' >> $@;" +
            "echo '  exit 1'           >> $@;" +
            "echo 'fi'                 >> $@;" +
            "",
      executable = 1,
  )
  native.sh_test(
      name = name,
      srcs = ["{}_check_failure.sh".format(name)],
      args = ["$(location {})".format(executable)],
      data = [executable],
  )

def with_environment_test(name, executable, env={}, args=[], data=[]):
  env_injections = ""
  for var in env:
    env_injections += "echo 'export {}={}' >> $@;".format(var, env[var])
  native.genrule(
      name = "{}_genrule".format(name),
      outs = ["{}_check_failure.sh".format(name)],
      cmd = "echo '#!/bin/bash'    >> $@;" +
            env_injections +
            "echo 'cmd=$$1'        >> $@;" +
            "echo 'shift'          >> $@;" +
            "echo 'exec $$cmd $$@' >> $@;" +
            "",
      executable = 1,
  )
  native.sh_test(
      name = name,
      srcs = ["{}_check_failure.sh".format(name)],
      args = ["$(location {})".format(executable)] + args,
      data = [executable] + data,
  )

def _test_rule(test, suffix, deps, data, args):
  native.cc_test(
      name = "openssl_{}{}".format(
          test.replace("openssl/test/", "").replace(".c", ""), suffix),
      srcs = [test],
      deps = deps,
      data = data,
      args = args,
  )

def _make_test(test):
  args = []
  data = []
  deps = [
      ":test_headers",
      ":testutil",
      ":openssl_apps_headers",
      ":ssl",
      ":crypto",
  ]

  if test == "openssl/test/aborttest.c":
    native.cc_binary(
        name = "openssl_aborttest_bin",
        srcs = [test],
        deps = deps,
        data = data,
        args = args,
        testonly = 1,
    )
    failing_executable_test(
        name = "openssl_aborttest",
        executable = ":openssl_aborttest_bin",
    )
    return
  elif test == "openssl/test/asynctest.c" or \
      test == "openssl/test/memleaktest.c":
    deps.remove(":testutil")
  elif test == "openssl/test/asynciotest.c":
    data.append("openssl/apps/server.pem")
    args.append("$(location :openssl/apps/server.pem)")
    args.append("$(location :openssl/apps/server.pem)")
  elif test == "openssl/test/clienthellotest.c":
    data.append("openssl/test/session.pem")
    args.append("openssl/test/session.pem")
  elif test == "openssl/test/ct_test.c":
    native.cc_binary(
        name = "openssl_ct_test_bin",
        srcs = [test],
        deps = deps,
        testonly = 1,
    )
    with_environment_test(
        name = "openssl_ct_test",
        executable = ":openssl_ct_test_bin",
        env = {
          "CTLOG_FILE": "openssl/test/ct/log_list.conf",
          "CT_DIR": "openssl/test/ct",
          "CERTS_DIR": "openssl/test/certs",
        },
        args = args + ["ct", "ec"],
        data = data + [
            "openssl/test/ct/log_list.conf",
            "openssl/test/ct/tls1.sct",
        ] + native.glob(["openssl/test/certs/*"]),
    )
    return
  elif test == "openssl/test/d2i_test.c":
    # this test has a bunch of cases

    f = "openssl/test/d2i-tests/bad_cert.der"
    args = ["X509", "decode", f]
    _test_rule(test, "_bad_cert", deps, data + [f], args)

    f = "openssl/test/d2i-tests/bad_generalname.der"
    args = ["GENERAL_NAME", "decode", f]
    _test_rule(test, "_bad_generalname", deps, data + [f], args)

    f = "openssl/test/d2i-tests/bad_bio.der"
    args = ["ASN1_ANY", "BIO", f]
    _test_rule(test, "_bad_bio", deps, data + [f], args)

    f = "openssl/test/d2i-tests/high_tag.der"
    args = ["ASN1_ANY", "OK", f]
    _test_rule(test, "_high_tag", deps, data + [f], args)

    f = "openssl/test/d2i-tests/high_tag.der"
    args = ["ASN1_INTEGER", "decode", f]
    _test_rule(test, "_high_tag_decode", deps, data + [f], args)

    f = "openssl/test/d2i-tests/int0.der"
    args = ["ASN1_INTEGER", "OK", f]
    _test_rule(test, "_int0_int_ok", deps, data + [f], args)

    f = "openssl/test/d2i-tests/int1.der"
    args = ["ASN1_INTEGER", "OK", f]
    _test_rule(test, "_int1_int_ok", deps, data + [f], args)

    f = "openssl/test/d2i-tests/intminus1.der"
    args = ["ASN1_INTEGER", "OK", f]
    _test_rule(test, "_intminus1_int_ok", deps, data + [f], args)

    f = "openssl/test/d2i-tests/int0.der"
    args = ["ASN1_ANY", "OK", f]
    _test_rule(test, "_int0_any_ok", deps, data + [f], args)

    f = "openssl/test/d2i-tests/int1.der"
    args = ["ASN1_ANY", "OK", f]
    _test_rule(test, "_int1_any_ok", deps, data + [f], args)

    f = "openssl/test/d2i-tests/intminus1.der"
    args = ["ASN1_ANY", "OK", f]
    _test_rule(test, "_intminus1_any_ok", deps, data + [f], args)

    f = "openssl/test/d2i-tests/bad-int-pad0.der"
    args = ["ASN1_INTEGER", "decode", f]
    _test_rule(test, "_bad_int_pad0", deps, data + [f], args)

    f = "openssl/test/d2i-tests/bad-int-padminus1.der"
    args = ["ASN1_INTEGER", "decode", f]
    _test_rule(test, "_bad_int_padminus1", deps, data + [f], args)

    return
  elif test == "openssl/test/danetest.c":
    data += ["openssl/test/danetest.pem", "openssl/test/danetest.in"]
    args += ["example.com", "openssl/test/danetest.pem",
             "openssl/test/danetest.in"]
  elif test == "openssl/test/dtlstest.c":
    data.append("openssl/apps/server.pem")
    args.append("openssl/apps/server.pem")
    args.append("openssl/apps/server.pem")
  elif test == "openssl/test/evp_test.c":
    base = "openssl/test/recipes/30-test_evp_data/"
    for f in ["evpciph", "evpdigest", "evpencod", "evpkdf", "evpmac", "evppbe",
              "evppkey"]:
      full = base + f + ".txt"
      _test_rule(test, f, deps, data + [full], args + [full])
    return
  elif test == "openssl/test/sslapitest.c" or \
       test == "openssl/test/sslbuffertest.c" or \
       test == "openssl/test/sslcorrupttest.c":
    data.append("openssl/apps/server.pem")
    args.append("openssl/apps/server.pem")
    args.append("openssl/apps/server.pem")
  elif test == "openssl/test/ssl_test_ctx_test.c":
    data.append("openssl/test/ssl_test_ctx_test.conf")
    args.append("openssl/test/ssl_test_ctx_test.conf")
  elif test == "openssl/test/uitest.c":
    deps.append(":openssl_ui")
  elif test == "openssl/test/recordlentest.c":
    data.append("openssl/apps/server.pem")
    args.append("openssl/apps/server.pem")
    args.append("openssl/apps/server.pem")
  elif test == "openssl/test/shlibloadtest.c":
    # no trivial way to port this i think
    return
  elif test == "openssl/test/v3ext.c":
    data.append("openssl/test/certs/pathlen.pem")
    args.append("openssl/test/certs/pathlen.pem")
  elif test == "openssl/test/verify_extra_test.c":
    data.append("openssl/test/certs/roots.pem")
    args.append("openssl/test/certs/roots.pem")
    data.append("openssl/test/certs/untrusted.pem")
    args.append("openssl/test/certs/untrusted.pem")
    data.append("openssl/test/certs/bad.pem")
    args.append("openssl/test/certs/bad.pem")
  elif test == "openssl/test/x509aux.c":
    data.append("openssl/test/certs/roots.pem")
    args.append("openssl/test/certs/roots.pem")
    data.append("openssl/test/certs/root+anyEKU.pem")
    args.append("openssl/test/certs/root+anyEKU.pem")
    data.append("openssl/test/certs/root-anyEKU.pem")
    args.append("openssl/test/certs/root-anyEKU.pem")
    data.append("openssl/test/certs/root-cert.pem")
    args.append("openssl/test/certs/root-cert.pem")
  elif test == "openssl/test/x509_check_cert_pkey_test.c":
    base = "openssl/test/certs/"

    f = [base + i for i in ["servercert.pem", "serverkey.pem"]]
    args = f + ["cert", "ok"]
    _test_rule(test, "_rsa", deps, data + f, args)

    f = [base + i for i in ["servercert.pem", "wrongkey.pem"]]
    args = f + ["cert", "failed"]
    _test_rule(test, "_mismatched_rsa", deps, data + f, args)

    f = [base + i for i in ["server-dsa-cert.pem", "server-dsa-key.pem"]]
    args = f + ["cert", "ok"]
    _test_rule(test, "_dsa", deps, data + f, args)

    f = [base + i for i in ["server-ecdsa-cert.pem", "server-ecdsa-key.pem"]]
    args = f + ["cert", "ok"]
    _test_rule(test, "_ecc", deps, data + f, args)

    f = [base + i for i in ["x509-check.csr", "x509-check-key.pem"]]
    args = f + ["req", "ok"]
    _test_rule(test, "_rsa_req", deps, data + f, args)

    f = [base + i for i in ["x509-check.csr", "wrongkey.pem"]]
    args = f + ["req", "failed"]
    _test_rule(test, "_mismatched_rsa_req", deps, data + f, args)

    return
  elif test == "openssl/test/x509_dup_cert_test.c":
    data.append("openssl/test/certs/leaf.pem")
    args.append("openssl/test/certs/leaf.pem")

  # default
  _test_rule(test, "", deps, data, args)

def gen_tests():
  test_dir = native.glob(["openssl/test/*.c"])
  tests = []
  test_utils = []
  for src in test_dir:
    if src.endswith("test.c") or src.endswith("x509aux.c") or \
        src.endswith("v3ext.c"):
      tests.append(src)
    elif not src.endswith("ssltest_old.c"):
      test_utils.append(src)

  native.cc_library(
      name = "testutil_impl",
      srcs = native.glob([
          "openssl/test/*.h",
          "openssl/test/testutil/*.h",
          "openssl/test/testutil/*.c",
      ]) + [
          "openssl/e_os.h",
      ] + test_utils,
      deps = [
          ":crypto",
          ":ssl",
      ]
  )

  native.cc_library(
      name = "testutil",
      hdrs = native.glob([
          "openssl/test/*.h",
          "openssl/test/testutil/*.h",
      ]),
      strip_include_prefix = "openssl/test",
      deps = [":testutil_impl"],
  )

  native.cc_library(
      name = "test_headers",
      hdrs = native.glob(["openssl/test/*.h"]),
      strip_include_prefix = "openssl/test",
  )

  for test in tests:
    _make_test(test)

