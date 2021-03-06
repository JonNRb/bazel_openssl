load("//:perlasm.bzl", "perlasm_sources")

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
    "-DOPENSSL_USE_NODELETE",
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

LDFLAGS = select({
    ":linux": [
        "-ldl",
        "-lpthread",
    ],
    ":macos": [],
})

PERLASM_COPTS = select({
    ":macos": ["macosx"],
    ":linux": ["elf"],
})

# exceptions are based on `build.info` files in the OpenSSL tree
def _module_hdrs_and_srcs(module):
  srcs_include, srcs_exclude, hdrs_include, hdrs_exclude = [], [], [], []

  if module == "aes":
    srcs_exclude.append("openssl/crypto/aes/aes_cbc.c")
    srcs_exclude.append("openssl/crypto/aes/aes_core.c")
    srcs_exclude.append("openssl/crypto/aes/aes_x86core.c")
  elif module == "camellia":
    srcs_exclude.append("openssl/crypto/camellia/camellia.c")
    srcs_exclude.append("openssl/crypto/camellia/cmll_cbc.c")
  elif module == "chacha":
    srcs_exclude.append("openssl/crypto/chacha/chacha_enc.c")
  elif module == "des":
    hdrs_include.append("openssl/crypto/des/ncbc_enc.c")
    srcs_exclude.append("openssl/crypto/des/ncbc_enc.c")
  elif module == "ec":
    srcs_exclude.append("openssl/crypto/ec/ecp_nistz256_table.c")
  elif module == "engine":
    srcs_exclude.append("openssl/crypto/engine/eng_devcrypto.c")
  elif module == "rc4":
    srcs_exclude.append("openssl/crypto/rc4/rc4_enc.c")
    srcs_exclude.append("openssl/crypto/rc4/rc4_skey.c")
  elif module == "poly1305":
    srcs_exclude.append("openssl/crypto/poly1305/poly1305_base2_44.c")
    srcs_exclude.append("openssl/crypto/poly1305/poly1305_ieee754.c")
  elif module == "whrlpool":
    srcs_exclude.append("openssl/crypto/whrlpool/wp_block.c")

  srcs = native.glob([
      "openssl/crypto/{}/*.c".format(module),
      "openssl/crypto/{}/arch/*_posix.c".format(module),
  ] + srcs_include, exclude=srcs_exclude)

  hdrs = native.glob(hdrs_include, exclude=hdrs_exclude)

  return hdrs, srcs

def _asm_srcs_and_deps(module):
  srcs = native.glob(["openssl/crypto/{}/asm/*x86_64*.pl".format(module)])
  deps = native.glob([
      "openssl/crypto/{}/*.c".format(module),
  ])

  if module == "bn":
    srcs.append("openssl/crypto/bn/asm/rsaz-avx2.pl")
  elif module == "sha":
    # sha uses the same asm for 256 and 512 and checks the name of the output?!
    native.genrule(
        name = "gensha256perlasm",
        srcs = ["openssl/crypto/sha/asm/sha512-x86_64.pl"],
        outs = ["openssl/crypto/sha/asm/sha256-x86_64.pl"],
        cmd = "mv $< $@",
    )
    srcs.append("openssl/crypto/sha/asm/sha256-x86_64.pl")

    native.genrule(
        name = "genrelxlate",
        srcs = ["openssl/crypto/perlasm/x86_64-xlate.pl"],
        outs = ["openssl/crypto/sha/asm/x86_64-xlate.pl"],
        cmd = "mv $< $@",
    )
    deps.append("openssl/crypto/sha/asm/x86_64-xlate.pl")

    srcs.remove("openssl/crypto/sha/asm/keccak1600-x86_64.pl")

  return srcs, deps

def openssl_crypto(name, modules=[], visibility=[]):

  native.cc_library(
      name = "{}_internal_headers".format(name),
      hdrs = native.glob(["openssl/crypto/include/internal/*.h"]) + [
          "openssl/crypto/include/internal/bn_conf.h",
          "openssl/crypto/include/internal/dso_conf.h",
      ],
      strip_include_prefix = "openssl/crypto/include",
  )

  header_libs = []

  for module in modules:
    inc_headers = native.glob([
        "openssl/crypto/{}/*.h".format(module),
        "openssl/crypto/{}/arch/*.h".format(module),
    ])
    if len(inc_headers) != 0:
      lib = "{}_{}_include_noprefix".format(name, module)
      native.cc_library(
          name = lib,
          hdrs = inc_headers,
          deps = [
              ":{}_internal_headers".format(name),
              ":openssl_public_headers",
              ":openssl_internal_headers",
          ],
          strip_include_prefix = "openssl/crypto/{}".format(module),
      )
      header_libs.append(":" + lib)
    lib = "{}_{}_include".format(name, module)
    native.cc_library(
        name = lib,
        hdrs = inc_headers,
        deps = [
            ":{}_internal_headers".format(name),
            ":openssl_public_headers",
            ":openssl_internal_headers",
        ],
    )
    header_libs.append(":" + lib)

  hdrs = []
  srcs = []
  asm_deps = []
  asm_srcs = []

  for module in modules:
    lib_hdrs, lib_srcs = _module_hdrs_and_srcs(module)
    hdrs += lib_hdrs
    srcs += lib_srcs

    # compile perlasm sources for each included module
    lib_asm_srcs, lib_asm_deps = _asm_srcs_and_deps(module)
    asm_deps += lib_asm_deps
    asm_srcs += lib_asm_srcs

  native.cc_library(
      name = "{}_buildinf".format(name),
      hdrs = ["openssl/crypto/buildinf.h"],
      strip_include_prefix = "openssl/crypto",
  )

  perlasm_sources(
      name = "{}_asm".format(name),
      srcs = ["openssl/crypto/x86_64cpuid.pl"] + asm_srcs,
      deps = native.glob(["openssl/crypto/perlasm/*.pl"]) + asm_deps,
      copts = PERLASM_COPTS,
  )
  srcs.append(":{}_asm".format(name))

  native.cc_library(
      name = name,
      hdrs = hdrs + native.glob([
          "openssl/crypto/*.h",
          "openssl/crypto/LPdir_*.c",
      ]),
      srcs = srcs + native.glob([
          "openssl/crypto/*.c",
      ], exclude=[
          "openssl/crypto/armcap.c",
          "openssl/crypto/LPdir_*.c",
          "openssl/crypto/mem_clr.c",
          "openssl/crypto/ppccap.c",
          "openssl/crypto/s390xcap.c",
          "openssl/crypto/sparcv9cap.c",
      ]),
      copts = CFLAGS,
      linkopts = LDFLAGS,
      deps = header_libs + [
          ":{}_buildinf".format(name),
          ":{}_internal_headers".format(name),
          ":openssl_public_headers",
          ":openssl_internal_headers",
      ],
      visibility = visibility,
  )
