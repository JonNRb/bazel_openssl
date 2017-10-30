package(default_visibility = ["//visibility:private"])

load("//:crypto.bzl", "openssl_crypto")
load("//:genfiles.bzl", "run_configure", "gen_headers")

run_configure()
gen_headers()

cc_inc_library(
    name = "openssl_public_headers",
    hdrs = glob([
        "openssl/include/openssl/*.h",
        "openssl/include/internal/*.h",
    ]) + [
        "openssl/include/openssl/opensslconf.h",
    ],
    prefix = "openssl/include",
)

cc_inc_library(
    name = "openssl_internal_headers",
    hdrs = [
        "openssl/e_os.h",
    ],
    prefix = "openssl",
)

cc_library(
    name = "ssl",
    hdrs = glob([
        "openssl/ssl/*.h",
        "openssl/ssl/*/*.h",
    ]),
    srcs = glob([
        "openssl/ssl/*.c",
        "openssl/ssl/*/*.c",
    ]),
    deps = [
        ":openssl_internal_headers",
        ":openssl_public_headers",
    ]
)

openssl_crypto(
    name = "crypto",
    modules = [
        "aes",
        #"aria",
        "asn1",
        "async",
        "bf",
        "bio",
        "blake2",
        "bn",
        "buffer",
        "camellia",
        "cast",
        "chacha",
        "cmac",
        "cms",
        "comp",
        "conf",
        "ct",
        "des",
        "dh",
        "dsa",
        "dso",
        "ec",
        "engine",
        "err",
        "evp",
        "hmac",
        "idea",
        "kdf",
        "lhash",
        #"md2",
        "md4",
        "md5",
        "mdc2",
        "modes",
        "objects",
        "ocsp",
        "pem",
        "pkcs12",
        "pkcs7",
        "poly1305",
        "rand",
        "rc2",
        "rc4",
        #"rc5",
        "ripemd",
        "rsa",
        "seed",
        "sha",
        "siphash",
        "srp",
        "stack",
        "store",
        "ts",
        "txt_db",
        "ui",
        "whrlpool",
        "x509",
        "x509v3",
    ]
)

cc_inc_library(
    name = "openssl_apps_headers",
    hdrs = glob([
        "openssl/apps/*.h",
    ]) + [
        "openssl/apps/progs.h",
    ],
    prefix = "openssl/apps",
)

cc_binary(
    name = "openssl",
    srcs = glob([
        "openssl/apps/*.c",
    ], exclude=[
        "openssl/apps/win32_init.c",
    ]),
    deps = [
        ":openssl_apps_headers",
        ":crypto",
        ":ssl",
    ],
)
