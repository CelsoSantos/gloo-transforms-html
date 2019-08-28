workspace(name = "gloodemo")

# -----------------------------------------------------------------------------
# Global variables
# -----------------------------------------------------------------------------

# Requisite minimal Golang toolchain version
MINIMAL_GOLANG_VERSION = "1.12.4"

# Requisite minimal Bazel version requested to build this project
MINIMAL_BAZEL_VERSION = "0.23.0"

# Requisite minimal Gazelle version compatible with Golang Bazel rules
MINIMAL_GAZELLE_VERSION = "0.18.1"

# Requisite minimal Golang Bazel rules (must be set in accordance with minimal Gazelle version)
#
# @see https://github.com/bazelbuild/bazel-gazelle#compatibility)
MINIMAL_GOLANG_BAZEL_RULES_VERSION = "0.19.0"

MINIMAL_GOLANG_BAZEL_RULES_SHASUM = "9fb16af4d4836c8222142e54c9efa0bb5fc562ffc893ce2abeac3e25daead144"

# -----------------------------------------------------------------------------
# Basic Bazel settings
# -----------------------------------------------------------------------------

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

# Import Bazel Skylib repository into the workspace
http_archive(
    name = "bazel_skylib",
    sha256 = "eb5c57e4c12e68c0c20bc774bfbc60a568e800d025557bc4ea022c6479acc867",
    strip_prefix = "bazel-skylib-0.6.0",
    url = "https://github.com/bazelbuild/bazel-skylib/archive/0.6.0.tar.gz",
)

load("@bazel_skylib//lib:versions.bzl", "versions")

versions.check(
    minimum_bazel_version = MINIMAL_BAZEL_VERSION,
)

# -----------------------------------------------------------------------------
# Golang and gRPC tools and external dependencies
# -----------------------------------------------------------------------------

# Fetch gRPC and Protobuf dependencies (should be fetched before Go rules)
http_archive(
    name = "build_stack_rules_proto",
    sha256 = "5474d1b83e24ec1a6db371033a27ff7aff412f2b23abba86fedd902330b61ee6",
    strip_prefix = "rules_proto-91cbae9bd71a9c51406014b8b3c931652fb6e660",
    urls = ["https://github.com/stackb/rules_proto/archive/91cbae9bd71a9c51406014b8b3c931652fb6e660.tar.gz"],
)

load("@build_stack_rules_proto//go:deps.bzl", "go_grpc_library", "go_proto_library")

go_grpc_library()

# Import Golang Bazel repository into the workspace
http_archive(
    name = "io_bazel_rules_go",
    urls = [
        "https://storage.googleapis.com/bazel-mirror/github.com/bazelbuild/rules_go/releases/download/0.19.1/rules_go-0.19.1.tar.gz",
        "https://github.com/bazelbuild/rules_go/releases/download/0.19.1/rules_go-0.19.1.tar.gz",
    ],
    sha256 = "8df59f11fb697743cbb3f26cfb8750395f30471e9eabde0d174c3aebc7a1cd39",
)

# Fetch Golang dependencies.
#
# The 'go_rules_dependencies()' is a macro that registers external dependencies needed by
# the Go and proto rules in rules_go.
# You can override a dependency declared in go_rules_dependencies by declaring a repository
# rule in WORKSPACE with the same name BEFORE the call to 'go_rules_dependencies()' macro.
#
# You can find the full implementation in repositories.bzl availble at https://github.com/bazelbuild/rules_go/blob/master/go/private/repositories.bzl.
#
# @see: https://github.com/bazelbuild/rules_go/blob/master/go/workspace.rst#id5
load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")

# NOTE:
# To override dependencies declared in 'go_rules_dependencies' macro, you should
# declare your dependencies here, before invoking 'go_rules_dependencies' macro.

# Fetch external dependencies needed by the Go and proto rules in rules_go, as
# well as some basic Golang packages, such as, for instance, 'golang.org/x/text'
# i18n tool.
go_rules_dependencies()

go_register_toolchains()
#  go_version = MINIMAL_GOLANG_VERSION,
#)

# -----------------------------------------------------------------------------
# Bazel Gazelle build files generator settings
# -----------------------------------------------------------------------------

# Import Gazelle repository into the workspace
http_archive(
    name = "bazel_gazelle",
    urls = [
        "https://storage.googleapis.com/bazel-mirror/github.com/bazelbuild/bazel-gazelle/releases/download/0.18.1/bazel-gazelle-0.18.1.tar.gz",
        "https://github.com/bazelbuild/bazel-gazelle/releases/download/0.18.1/bazel-gazelle-0.18.1.tar.gz",
    ],
    sha256 = "be9296bfd64882e3c08e3283c58fcb461fa6dd3c171764fcc4cf322f60615a9b",
)

# Fetch Gazelle dependencies
load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies", "go_repository")

gazelle_dependencies()

# -----------------------------------------------------------------------------
# Docker Bazel rules dependencies
# -----------------------------------------------------------------------------

# Import the rules_docker repository at release v0.7.0 - be sure the Go rules
# are previously loaded - see above Go rules section in this file
http_archive(
    name = "io_bazel_rules_docker",
    sha256 = "aed1c249d4ec8f703edddf35cbe9dfaca0b5f5ea6e4cd9e83e99f3b0d1136c3d",
    strip_prefix = "rules_docker-0.7.0",
    urls = ["https://github.com/bazelbuild/rules_docker/archive/v0.7.0.tar.gz"],
)

# Load the macro that allows you to customize the docker toolchain configuration.
load(
    "@io_bazel_rules_docker//toolchains/docker:toolchain.bzl",
    docker_toolchain_configure = "toolchain_configure",
)

docker_toolchain_configure(
    name = "docker_config",
    # Replace this with a path to a directory which has a custom docker client
    # config.json. Docker allows you to specify custom authentication credentials
    # in the client configuration JSON file.
    # See https://docs.docker.com/engine/reference/commandline/cli/#configuration-files
    # for more details.
    #
    # IMPORTANT: This path is relative to the sandbox workspace directory
    client_config = "/workspace/tooling/docker",
)

load(
    "@io_bazel_rules_docker//go:image.bzl",
    _go_image_repos = "repositories",
)

_go_image_repos()

# -----------------------------------------------------------------------------
# External dependencies
# -----------------------------------------------------------------------------

load("//tooling/bazel:dependencies.bzl", "ext_dependencies")

ext_dependencies()

go_repository(
    name = "co_honnef_go_tools",
    importpath = "honnef.co/go/tools",
    sum = "h1:TEgegKbBqByGUb1Coo1pc2qIdf2xw6v0mYyLSYtyopE=",
    version = "v0.0.1-2019.2.2",
)

go_repository(
    name = "com_github_burntsushi_toml",
    importpath = "github.com/BurntSushi/toml",
    sum = "h1:WXkYYl6Yr3qBf1K79EBnL4mak0OimBfB0XUf9Vl28OQ=",
    version = "v0.3.1",
)

go_repository(
    name = "com_github_burntsushi_xgb",
    importpath = "github.com/BurntSushi/xgb",
    sum = "h1:1BDTz0u9nC3//pOCMdNH+CiXJVYJh5UQNCOBG7jbELc=",
    version = "v0.0.0-20160522181843-27f122750802",
)

go_repository(
    name = "com_github_client9_misspell",
    importpath = "github.com/client9/misspell",
    sum = "h1:ta993UF76GwbvJcIo3Y68y/M3WxlpEHPWIGDkJYwzJI=",
    version = "v0.3.4",
)

go_repository(
    name = "com_github_creack_pty",
    importpath = "github.com/creack/pty",
    sum = "h1:6pwm8kMQKCmgUg0ZHTm5+/YvRK0s3THD/28+T6/kk4A=",
    version = "v1.1.7",
)

go_repository(
    name = "com_github_golang_glog",
    importpath = "github.com/golang/glog",
    sum = "h1:VKtxabqXZkF25pY9ekfRL6a582T4P37/31XEstQ5p58=",
    version = "v0.0.0-20160126235308-23def4e6c14b",
)

go_repository(
    name = "com_github_golang_mock",
    importpath = "github.com/golang/mock",
    sum = "h1:qGJ6qTW+x6xX/my+8YUVl4WNpX9B7+/l2tRsHGZ7f2s=",
    version = "v1.3.1",
)

go_repository(
    name = "com_github_golang_protobuf",
    importpath = "github.com/golang/protobuf",
    sum = "h1:6nsPYzhq5kReh6QImI3k5qWzO4PEbvbIW2cwSfR/6xs=",
    version = "v1.3.2",
)

go_repository(
    name = "com_github_google_btree",
    importpath = "github.com/google/btree",
    sum = "h1:0udJVsspx3VBr5FwtLhQQtuAsVc79tTq0ocGIPAU6qo=",
    version = "v1.0.0",
)

go_repository(
    name = "com_github_google_go_cmp",
    importpath = "github.com/google/go-cmp",
    sum = "h1:Xye71clBPdm5HgqGwUkwhbynsUJZhDbS20FvLhQ2izg=",
    version = "v0.3.1",
)

go_repository(
    name = "com_github_google_martian",
    importpath = "github.com/google/martian",
    sum = "h1:/CP5g8u/VJHijgedC/Legn3BAbAaWPgecwXBIDzw5no=",
    version = "v2.1.0+incompatible",
)

go_repository(
    name = "com_github_google_pprof",
    importpath = "github.com/google/pprof",
    sum = "h1:XTnP8fJpa4Kvpw2qARB4KS9izqxPS0Sd92cDlY3uk+w=",
    version = "v0.0.0-20190723021845-34ac40c74b70",
)

go_repository(
    name = "com_github_google_renameio",
    importpath = "github.com/google/renameio",
    sum = "h1:GOZbcHa3HfsPKPlmyPyN2KEohoMXOhdMbHrvbpl2QaA=",
    version = "v0.1.0",
)

go_repository(
    name = "com_github_googleapis_gax_go_v2",
    importpath = "github.com/googleapis/gax-go/v2",
    sum = "h1:sjZBwGj9Jlw33ImPtvFviGYvseOtDM7hkSKB7+Tv3SM=",
    version = "v2.0.5",
)

go_repository(
    name = "com_github_hashicorp_golang_lru",
    importpath = "github.com/hashicorp/golang-lru",
    sum = "h1:YPkqC67at8FYaadspW/6uE0COsBxS2656RLEr8Bppgk=",
    version = "v0.5.3",
)

go_repository(
    name = "com_github_jstemmer_go_junit_report",
    importpath = "github.com/jstemmer/go-junit-report",
    sum = "h1:rBMNdlhTLzJjJSDIjNEXX1Pz3Hmwmz91v+zycvx9PJc=",
    version = "v0.0.0-20190106144839-af01ea7f8024",
)

go_repository(
    name = "com_github_kisielk_gotool",
    importpath = "github.com/kisielk/gotool",
    sum = "h1:AV2c/EiW3KqPNT9ZKl07ehoAGi4C5/01Cfbblndcapg=",
    version = "v1.0.0",
)

go_repository(
    name = "com_github_kr_pretty",
    importpath = "github.com/kr/pretty",
    sum = "h1:L/CwN0zerZDmRFUapSPitk6f+Q3+0za1rQkzVuMiMFI=",
    version = "v0.1.0",
)

go_repository(
    name = "com_github_kr_pty",
    importpath = "github.com/kr/pty",
    sum = "h1:AkaSdXYQOWeaO3neb8EM634ahkXXe3jYbVh/F9lq+GI=",
    version = "v1.1.8",
)

go_repository(
    name = "com_github_kr_text",
    importpath = "github.com/kr/text",
    sum = "h1:45sCR5RtlFHMR4UwH9sdQ5TC8v0qDQCHnXt+kaKSTVE=",
    version = "v0.1.0",
)

go_repository(
    name = "com_github_rogpeppe_go_internal",
    importpath = "github.com/rogpeppe/go-internal",
    sum = "h1:pgz0lCb+F99TrCwoy7d83j5kI//45fBQ34KzZ7t5as0=",
    version = "v1.3.1",
)

go_repository(
    name = "com_google_cloud_go",
    importpath = "cloud.google.com/go",
    sum = "h1:0sMegbmn/8uTwpNkB0q9cLEpZ2W5a6kl+wtBQgPWBJQ=",
    version = "v0.44.3",
)

go_repository(
    name = "com_google_cloud_go_datastore",
    importpath = "cloud.google.com/go/datastore",
    sum = "h1:Kt+gOPPp2LEPWp8CSfxhsM8ik9CcyE/gYu+0r+RnZvM=",
    version = "v1.0.0",
)

go_repository(
    name = "in_gopkg_check_v1",
    importpath = "gopkg.in/check.v1",
    sum = "h1:qIbj1fsPNlZgppZ+VLlY7N33q108Sa+fhmuc+sWQYwY=",
    version = "v1.0.0-20180628173108-788fd7840127",
)

go_repository(
    name = "in_gopkg_errgo_v2",
    importpath = "gopkg.in/errgo.v2",
    sum = "h1:0vLT13EuvQ0hNvakwLuFZ/jYrLp5F3kcWHXdRggjCE8=",
    version = "v2.1.0",
)

go_repository(
    name = "io_opencensus_go",
    importpath = "go.opencensus.io",
    sum = "h1:C9hSCOW830chIVkdja34wa6Ky+IzWllkUinR+BtRZd4=",
    version = "v0.22.0",
)

go_repository(
    name = "io_rsc_binaryregexp",
    importpath = "rsc.io/binaryregexp",
    sum = "h1:HfqmD5MEmC0zvwBuF187nq9mdnXjXsSivRiXN7SmRkE=",
    version = "v0.2.0",
)

go_repository(
    name = "org_golang_google_api",
    importpath = "google.golang.org/api",
    sum = "h1:jbyannxz0XFD3zdjgrSUsaJbgpH4eTrkdhRChkHPfO8=",
    version = "v0.9.0",
)

go_repository(
    name = "org_golang_google_appengine",
    importpath = "google.golang.org/appengine",
    sum = "h1:QzqyMA1tlu6CgqCDUtU9V+ZKhLFT2dkJuANu5QaxI3I=",
    version = "v1.6.1",
)

go_repository(
    name = "org_golang_google_genproto",
    importpath = "google.golang.org/genproto",
    sum = "h1:gSJIx1SDwno+2ElGhA4+qG2zF97qiUzTM+rQ0klBOcE=",
    version = "v0.0.0-20190819201941-24fa4b261c55",
)

go_repository(
    name = "org_golang_google_grpc",
    importpath = "google.golang.org/grpc",
    sum = "h1:AzbTB6ux+okLTzP8Ru1Xs41C303zdcfEht7MQnYJt5A=",
    version = "v1.23.0",
)

go_repository(
    name = "org_golang_x_crypto",
    importpath = "golang.org/x/crypto",
    sum = "h1:7KByu05hhLed2MO29w7p1XfZvZ13m8mub3shuVftRs0=",
    version = "v0.0.0-20190820162420-60c769a6c586",
)

go_repository(
    name = "org_golang_x_exp",
    importpath = "golang.org/x/exp",
    sum = "h1:estk1glOnSVeJ9tdEZZc5mAMDZk5lNJNyJ6DvrBkTEU=",
    version = "v0.0.0-20190731235908-ec7cb31e5a56",
)

go_repository(
    name = "org_golang_x_image",
    importpath = "golang.org/x/image",
    sum = "h1:1/e6LjNi7iqpDTz8tCLSKoR5dqrX4C3ub4H31JJZM4U=",
    version = "v0.0.0-20190823064033-3a9bac650e44",
)

go_repository(
    name = "org_golang_x_lint",
    importpath = "golang.org/x/lint",
    sum = "h1:QzoH/1pFpZguR8NrRHLcO6jKqfv2zpuSqZLgdm7ZmjI=",
    version = "v0.0.0-20190409202823-959b441ac422",
)

go_repository(
    name = "org_golang_x_mobile",
    importpath = "golang.org/x/mobile",
    sum = "h1:+s13ObSh95ndknca1AaNToQDyHkgfwMC7xm5ZEYf/JU=",
    version = "v0.0.0-20190826170111-cafc553e1ac5",
)

go_repository(
    name = "org_golang_x_mod",
    importpath = "golang.org/x/mod",
    sum = "h1:sfUMP1Gu8qASkorDVjnMuvgJzwFbTZSeXFiGBYAVdl4=",
    version = "v0.1.0",
)

go_repository(
    name = "org_golang_x_net",
    importpath = "golang.org/x/net",
    sum = "h1:k7pJ2yAPLPgbskkFdhRCsA77k2fySZ1zf2zCjvQCiIM=",
    version = "v0.0.0-20190827160401-ba9fcec4b297",
)

go_repository(
    name = "org_golang_x_oauth2",
    importpath = "golang.org/x/oauth2",
    sum = "h1:SVwTIAaPC2U/AvvLNZ2a7OVsmBpC8L5BlwK1whH3hm0=",
    version = "v0.0.0-20190604053449-0f29369cfe45",
)

go_repository(
    name = "org_golang_x_sync",
    importpath = "golang.org/x/sync",
    sum = "h1:8gQV6CLnAEikrhgkHFbMAEhagSSnXWGV915qUMm9mrU=",
    version = "v0.0.0-20190423024810-112230192c58",
)

go_repository(
    name = "org_golang_x_sys",
    importpath = "golang.org/x/sys",
    sum = "h1:ng0gs1AKnRRuEMZoTLLlbOd+C17zUDepwGQBb/n+JVg=",
    version = "v0.0.0-20190826190057-c7b8b68b1456",
)

go_repository(
    name = "org_golang_x_text",
    importpath = "golang.org/x/text",
    sum = "h1:tW2bmiBqwgJj/UpqtC8EpXEZVYOwU0yG4iWbprSVAcs=",
    version = "v0.3.2",
)

go_repository(
    name = "org_golang_x_time",
    importpath = "golang.org/x/time",
    sum = "h1:SvFZT6jyqRaOeXpc5h/JSfZenJ2O330aBsf7JfSUXmQ=",
    version = "v0.0.0-20190308202827-9d24e82272b4",
)

go_repository(
    name = "org_golang_x_tools",
    importpath = "golang.org/x/tools",
    sum = "h1:WtF22n/HcPWMhvZm4KWiQ0FcC1m8kk5ILpXYtY+qN7s=",
    version = "v0.0.0-20190827152308-062dbaebb618",
)

go_repository(
    name = "org_golang_x_xerrors",
    importpath = "golang.org/x/xerrors",
    sum = "h1:9zdDQZ7Thm29KFXgAX/+yaf3eVbP7djjWp/dXAppNCc=",
    version = "v0.0.0-20190717185122-a985d3407aa7",
)
