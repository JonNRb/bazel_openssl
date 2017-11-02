package(default_visibility = ["//visibility:private"])

load("//:crypto.bzl", "openssl_crypto")
load("//:genfiles.bzl", "run_configure", "gen_headers")
load("//:tests.bzl", "gen_tests")

run_configure()

gen_headers()

gen_tests()

cc_library(
    name = "openssl_public_headers",
    hdrs = glob([
        "openssl/include/openssl/*.h",
        "openssl/include/internal/*.h",
    ]) + [
        "openssl/include/openssl/opensslconf.h",
    ],
    strip_include_prefix = "openssl/include",
)

cc_library(
    name = "openssl_internal_headers",
    hdrs = [
        "openssl/e_os.h",
    ],
    strip_include_prefix = "openssl",
)

cc_library(
    name = "ssl_impl",
    srcs = glob([
        "openssl/ssl/*.c",
        "openssl/ssl/*/*.c",
    ]),
    hdrs = glob([
        "openssl/ssl/*.h",
        "openssl/ssl/*/*.h",
    ]),
    visibility = ["//visibility:public"],
    deps = [
        ":openssl_internal_headers",
        ":openssl_public_headers",
    ],
)

cc_library(
    name = "ssl",
    hdrs = glob(["openssl/include/openssl/*.h"]),
    strip_include_prefix = "openssl/include",
    visibility = ["//visibility:public"],
    deps = [":ssl_impl"],
)

openssl_crypto(
    name = "crypto_impl",
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
    ],
)

cc_library(
    name = "crypto",
    hdrs = glob(["openssl/include/openssl/*.h"]),
    strip_include_prefix = "openssl/include",
    visibility = ["//visibility:public"],
    deps = [":crypto_impl"],
)

cc_library(
    name = "openssl_apps_headers",
    hdrs = glob([
        "openssl/apps/*.h",
    ]) + [
        "openssl/apps/progs.h",
    ],
    strip_include_prefix = "openssl/apps",
)

cc_library(
    name = "openssl_ui",
    srcs = glob(
        [
            "openssl/apps/*.c",
        ],
        exclude = [
            "openssl/apps/win32_init.c",
            "openssl/apps/openssl.c",
        ],
    ),
    deps = [
        ":crypto",
        ":openssl_apps_headers",
        ":ssl",
    ],
)

cc_binary(
    name = "openssl",
    srcs = ["openssl/apps/openssl.c"],
    deps = [
        ":openssl_ui",
    ],
)
