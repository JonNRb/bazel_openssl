load("//:perlasm.bzl", "perlasm_library")

CFLAGS = [
    "-DDSO_DLFCN",
    "-DHAVE_DLFCN_H",
    "-DNDEBUG",
    "-DOPENSSL_THREADS",
    "-DOPENSSL_NO_STATIC_ENGINE",
    "-DOPENSSL_PIC",
    "-DOPENSSL_IA32_SSE2",
    "-DOPENSSL_BN_ASM_MONT",
    "-DOPENSSL_BN_ASM_MONT5",
    "-DOPENSSL_BN_ASM_GF2m",
    "-DSHA1_ASM",
    "-DSHA256_ASM",
    "-DSHA512_ASM",
    "-DRC4_ASM",
    "-DMD5_ASM",
    "-DAES_ASM",
    "-DVPAES_ASM",
    "-DBSAES_ASM",
    "-DGHASH_ASM",
    "-DECP_NISTZ256_ASM",
    "-DPADLOCK_ASM",
    "-DPOLY1305_ASM",
    "-DOPENSSLDIR=\\\".\\\"",
    "-DENGINESDIR=\\\".\\\"",
    "-D_REENTRANT",
    "-DL_ENDIAN",
]

PERLASM_SCHEME = "macosx"

def _module_hdrs_and_srcs(module):
  srcs_include, srcs_exclude, hdrs_include, hdrs_exclude = [], [], [], []

  if module == "aes":
    srcs_exclude.append("openssl/crypto/aes/aes_cbc.c")
    srcs_exclude.append("openssl/crypto/aes/aes_core.c")
    srcs_exclude.append("openssl/crypto/aes/aes_x86core.c")
  elif module == "des":
    hdrs_include.append("openssl/crypto/des/ncbc_enc.c")
    srcs_exclude.append("openssl/crypto/des/ncbc_enc.c")
  elif module == "ec":
    srcs_exclude.append("openssl/crypto/ec/ecp_nistz256_table.c")
  elif module == "engine":
    srcs_exclude.append("openssl/crypto/engine/eng_devcrypto.c")

  srcs = native.glob([
      "openssl/crypto/{}/*.c".format(module),
      "openssl/crypto/{}/arch/*_posix.c".format(module),
  ] + srcs_include, exclude=srcs_exclude)

  hdrs = native.glob(hdrs_include, exclude=hdrs_exclude)

  return hdrs, srcs

def openssl_crypto(name, modules=[]):
  native.cc_inc_library(
      name = "openssl_crypto_internal_headers",
      hdrs = native.glob(["openssl/crypto/include/internal/*.h"]) + [
          "openssl/crypto/include/internal/bn_conf.h",
          "openssl/crypto/include/internal/dso_conf.h",
      ],
      prefix = "openssl/crypto/include",
  )

  header_libs = []
  libs = []

  for module in modules:
    inc_headers = native.glob([
        "openssl/crypto/{}/*.h".format(module),
        "openssl/crypto/{}/arch/*.h".format(module),
    ])
    if len(inc_headers) != 0:
      lib = "openssl_crypto_{}_include_noprefix".format(module)
      native.cc_inc_library(
          name = lib,
          hdrs = inc_headers,
          deps = [
              ":openssl_crypto_internal_headers",
              ":openssl_public_headers",
              ":openssl_internal_headers",
          ],
          prefix = "openssl/crypto/{}".format(module),
      )
      header_libs.append(":" + lib)
    lib = "openssl_crypto_{}_include".format(module)
    native.cc_library(
        name = lib,
        hdrs = inc_headers,
        deps = [
            ":openssl_crypto_internal_headers",
            ":openssl_public_headers",
            ":openssl_internal_headers",
        ],
    )
    header_libs.append(":" + lib)

  for module in modules:
    lib = "openssl_crypto_{}".format(module)
    hdrs, srcs = _module_hdrs_and_srcs(module)
    native.cc_library(
        name = lib,
        hdrs = hdrs,
        srcs = srcs,
        deps = [
            ":openssl_crypto_internal_headers",
            ":openssl_public_headers",
            ":openssl_internal_headers",
        ] + header_libs,
        copts = CFLAGS,
        linkstatic = 1,
    )
    libs.append(":" + lib)

    # compile perlasm sources for each included module
    asm_srcs = native.glob(["openssl/crypto/{}/asm/*-x86_64.pl".format(module)])
    if len(asm_srcs) != 0:
      asm_lib = "openssl_crypto_{}_asm".format(module)
      perlasm_library(
          name = asm_lib,
          srcs = asm_srcs,
          deps = native.glob([
              "openssl/crypto/perlasm/*.pl",
              "openssl/crypto/{}/*.c".format(module),
          ]),
          perl_copts = [PERLASM_SCHEME],
          copts = CFLAGS,
          linkstatic = 1,
      )
      libs.append(":" + asm_lib)

  perlasm_library(
      name = "openssl_crypto_asm",
      srcs = [
          "openssl/crypto/x86_64cpuid.pl"
      ],
      deps = native.glob(["openssl/crypto/perlasm/*.pl"]),
      perl_copts = [PERLASM_SCHEME],
      copts = CFLAGS,
      linkstatic = 1,
  )

  native.cc_inc_library(
      name = "openssl_crypto_buildinf",
      hdrs = ["openssl/crypto/buildinf.h"],
      prefix = "openssl/crypto",
  )

  native.cc_library(
      name = name,
      hdrs = native.glob([
          "openssl/crypto/*.h",
          "openssl/crypto/LPdir_*.c",
      ]),
      srcs = native.glob([
          "openssl/crypto/*.c",
      ], exclude=[
          "openssl/crypto/armcap.c",
          "openssl/crypto/LPdir_*.c",
          "openssl/crypto/ppccap.c",
          "openssl/crypto/s390xcap.c",
          "openssl/crypto/sparcv9cap.c",
      ]),
      copts = CFLAGS,
      deps = libs + [
          ":openssl_crypto_asm",
          ":openssl_crypto_buildinf",
          ":openssl_crypto_internal_headers",
          ":openssl_public_headers",
          ":openssl_internal_headers",
      ],
  )
