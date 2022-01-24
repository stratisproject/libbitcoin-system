#!/bin/bash
###############################################################################
# Script to build and install libbitcoin-system.
#
# Script options:
# --build-dir=<path>       Location of downloaded and intermediate files.
# --prefix=<absolute-path> Library install location (defaults to /usr/local).
# --help                   Display usage, overriding script execution.

# Define constants.
#==============================================================================
# The default build directory.
#------------------------------------------------------------------------------
BUILD_DIR="build-libbitcoin-system"

# Boost archive.
#------------------------------------------------------------------------------
BOOST_URL="http://downloads.sourceforge.net/project/boost/boost/1.77.0/boost_1_77_0.tar.bz2"
BOOST_ARCHIVE="boost_1_77_0.tar.bz2"


configure_options()
{
    display_message "configure options:"
    for OPTION in "$@"; do
        if [[ $OPTION ]]; then
            display_message "$OPTION"
        fi
    done

    ./configure "$@"
}

create_directory()
{
    local DIRECTORY="$1"

    rm -rf "$DIRECTORY"
    mkdir -p "$DIRECTORY"
}

display_heading_message()
{
    printf "\n********************** %s **********************\n" "$@"
}

display_message()
{
    printf "%s\n" "$@"
}

display_error()
{
    >&2 printf "%s\n" "$@"
}

initialize_git()
{
    display_heading_message "Initialize git"

    # Initialize git repository at the root of the current directory.
    git init
    git config user.name anonymous
}

# make_current_directory jobs [configure_options]
make_current_directory()
{
    local JOBS=$1
    shift 1

    ./autogen.sh
    configure_options "$@"
    make_jobs "$JOBS"
    make install
}

# make_jobs jobs [make_options]
make_jobs()
{
    local JOBS=$1
    shift 1

    SEQUENTIAL=1
    # Avoid setting -j1 (causes problems on Travis).
    if [[ $JOBS > $SEQUENTIAL ]]; then
        make -j"$JOBS" "$@"
    else
        make "$@"
    fi
}

pop_directory()
{
    popd >/dev/null
}

push_directory()
{
    local DIRECTORY="$1"

    pushd "$DIRECTORY" >/dev/null
}

enable_exit_on_error()
{
    set -e
}

disable_exit_on_error()
{
    set +e
}

display_help()
{
    display_message "Usage: ./build.sh [OPTION]..."
    display_message "Manage the installation of libbitcoin-system."
    display_message "Script options:"
    display_message "  --build-dir=<path>       Location of downloaded and intermediate files."
    display_message "  --prefix=<absolute-path> Library install location (defaults to /usr/local)."
    display_message "  --help                   Display usage, overriding script execution."
    display_message ""
    display_message "All unrecognized options provided shall be passed as configuration options for "
    display_message "all dependencies."
}

# Define environment initialization functions
#==============================================================================
parse_command_line_options()
{
    for OPTION in "$@"; do
        case $OPTION in
            # Standard script options.
            (--help)                DISPLAY_HELP="yes";;

            # Standard build options.
            (--prefix=*)            PREFIX="${OPTION#*=}";;

            # Unique script options.
            (--build-dir=*)    BUILD_DIR="${OPTION#*=}";;
        esac
    done
}

handle_help_line_option()
{
    if [[ $DISPLAY_HELP ]]; then
        display_help
        exit 0
    fi
}

set_operating_system()
{
    OS=$(uname -s)
}

configure_build_parallelism()
{
    if [[ $PARALLEL ]]; then
        display_message "Using shell-defined PARALLEL value."
    elif [[ $OS == Linux ]]; then
        PARALLEL=$(nproc)
    elif [[ ($OS == Darwin) || ($OS == OpenBSD) ]]; then
        PARALLEL=$(sysctl -n hw.ncpu)
    else
        display_error "Unsupported system: $OS"
        display_error "  Explicit shell-definition of PARALLEL will avoid system detection."
        display_error ""
        display_help
        exit 1
    fi
}

setup_build_flags()
{
    ADDITIONAL_FLAGS="-Wall -fPIC"
    export CFLAGS="$ADDITIONAL_FLAGS $CFLAGS"
    export CXXFLAGS="$ADDITIONAL_FLAGS $CXXFLAGS"
}

setup_options()
{
    CONFIGURE_OPTIONS=("$@" "--enable-static" "--disable-shared")
    CONFIGURE_OPTIONS=("${CONFIGURE_OPTIONS[@]/--build-*/}")
    
    CONFIGURE_OPTIONS=( "${CONFIGURE_OPTIONS[@]}" "$CUSTOM_CONFIGURE_OPTIONS")
    
    if [[ ! ($PREFIX) ]]; then
        PREFIX="$(dirname "$0")/result"
        PREFIX="/usr/local"
        CONFIGURE_OPTIONS=( "${CONFIGURE_OPTIONS[@]}" "--prefix=$PREFIX")
    fi
}

set_pkgconfigdir()
{
    # Set the prefix-based package config directory.
    PREFIX_PKG_CONFIG_DIR="$PREFIX/lib/pkgconfig"

    # Prioritize prefix package config in PKG_CONFIG_PATH search path.
    export PKG_CONFIG_PATH="$PREFIX_PKG_CONFIG_DIR:$PKG_CONFIG_PATH"

    # Set a package config save path that can be passed via our builds.
    with_pkgconfigdir="--with-pkgconfigdir=$PREFIX_PKG_CONFIG_DIR"
}

set_with_boost_prefix()
{
    # Boost has no pkg-config, m4 searches in the following order:
    # --with-boost=<path>, /usr, /usr/local, /opt, /opt/local, $BOOST_ROOT.
    # We use --with-boost to prioritize the --prefix path when we build it.
    # Otherwise standard paths suffice for Linux, Homebrew and MacPorts.
    # ax_boost_base.m4 appends /include and adds to BOOST_CPPFLAGS
    # ax_boost_base.m4 searches for /lib /lib64 and adds to BOOST_LDFLAGS
    with_boost="--with-boost=$PREFIX"
}

# Initialize the build environment.
#==============================================================================
enable_exit_on_error
parse_command_line_options "$@"
handle_help_line_option
set_operating_system
configure_build_parallelism
setup_build_flags
setup_options "$@"

display_configuration()
{
    display_message "libbitcoin-system installer configuration."
    display_message "--------------------------------------------------------------------"
    display_message "OS                    : $OS"
    display_message "PARALLEL              : $PARALLEL"
    display_message "CC                    : $CC"
    display_message "CXX                   : $CXX"
    display_message "CPPFLAGS              : $CPPFLAGS"
    display_message "CFLAGS                : $CFLAGS"
    display_message "CXXFLAGS              : $CXXFLAGS"
    display_message "LDFLAGS               : $LDFLAGS"
    display_message "LDLIBS                : $LDLIBS"
    display_message "BUILD_DIR             : $BUILD_DIR"
    display_message "PREFIX                : $PREFIX"
    display_message "--------------------------------------------------------------------"
}


# Define build options.
#==============================================================================
# Define icu options.
#------------------------------------------------------------------------------
ICU_OPTIONS=(
"--enable-draft" \
"--enable-tools" \
"--disable-extras" \
"--disable-icuio" \
"--disable-layout" \
"--disable-layoutex" \
"--disable-tests" \
"--disable-samples")

# Define boost options.
#------------------------------------------------------------------------------
BOOST_OPTIONS=(
"--with-atomic" \
"--with-chrono" \
"--with-date_time" \
"--with-filesystem" \
"--with-iostreams" \
"--with-locale" \
"--with-log" \
"--with-program_options" \
"--with-regex" \
"--with-system" \
"--with-thread" \
"--with-test")

# Define secp256k1 options.
#------------------------------------------------------------------------------
SECP256K1_OPTIONS=(
"--disable-tests" \
"--enable-experimental" \
"--enable-module-recovery" \
"--enable-module-schnorrsig")

# Define bitcoin-system options.
#------------------------------------------------------------------------------
update_prefix_options()
{
    set_pkgconfigdir
    set_with_boost_prefix

    BITCOIN_SYSTEM_OPTIONS=(
        "${with_boost}" \
        "${with_pkgconfigdir}")
}

# Define build functions.
#==============================================================================

# Because boost doesn't support autoconfig and doesn't like empty settings.
initialize_boost_configuration()
{
    BOOST_CXXFLAGS="cxxflags=$CXXFLAGS"
    BOOST_LINKFLAGS="linkflags=$LDFLAGS"
}

# Because boost doesn't use autoconfig.
build_from_tarball_boost()
{
    local SAVE_IFS="$IFS"
    IFS=' '

    local URL=$1
    local ARCHIVE=$2
    local COMPRESSION=$3
    local PUSH_DIR=$4
    local JOBS=$5
    shift 5

    mkdir -p "dependencies"
    push_directory "dependencies"

    if [[ ! -e "$ARCHIVE" ]]; then
        display_heading_message "Download $ARCHIVE"
        wget --output-document "$ARCHIVE" "$URL"
    fi

    pop_directory

    # Use the suffixed archive name as the extraction directory.
    local EXTRACT="build-$ARCHIVE"
    mkdir -p "$BUILD_DIR/$EXTRACT"
    tar --extract --file "dependencies/$ARCHIVE" "--$COMPRESSION" --strip-components=1 --directory="$BUILD_DIR/$EXTRACT"


    push_directory "$BUILD_DIR"
    push_directory "$EXTRACT"

    initialize_boost_configuration

    display_message "Libbitcoin boost configuration."
    display_message "--------------------------------------------------------------------"
    display_message "variant               : release"
    display_message "threading             : multi"
    display_message "toolset               : $BOOST_TOOLSET"
    display_message "cxxflags              : $BOOST_CXXFLAGS"
    display_message "linkflags             : $BOOST_LINKFLAGS"
    display_message "-sNO_BZIP2            : 1"
    display_message "-j                    : $JOBS"
    display_message "-d0                   : [supress informational messages]"
    display_message "-q                    : [stop at the first error]"
    display_message "--reconfigure         : [ignore cached configuration]"
    display_message "--prefix              : $PREFIX"
    display_message "BOOST_OPTIONS         : $*"
    display_message "--------------------------------------------------------------------"

    ./bootstrap.sh \
        "--prefix=$PREFIX"


    ./b2 install \
        "variant=release" \
        "threading=multi" \
        "$BOOST_TOOLSET" \
        "$BOOST_CXXFLAGS" \
        "$BOOST_LINKFLAGS" \
        "link=static" \
        "boost.locale.iconv=off" \
        "boost.locale.posix=off" \
        "boost.locale.std=on" \
        "-sNO_BZIP2=1" \
        "-j $JOBS" \
        "-d0" \
        "-q" \
        "--reconfigure" \
        "--prefix=$PREFIX" \
        "$@"

    pop_directory
    pop_directory

    IFS="$SAVE_IFS"
}

# Standard build from github.
build_from_github()
{
    push_directory "$BUILD_DIR"

    local ACCOUNT=$1
    local REPO=$2
    local BRANCH=$3
    local JOBS=$4
    local OPTIONS=$5
    shift 5

    FORK="$ACCOUNT/$REPO"
    display_heading_message "Download $FORK/$BRANCH"

    # Clone the repository locally.
    git clone --depth 1 --branch "$BRANCH" --single-branch "https://github.com/$FORK"

    # Join generated and command line options.
    local CONFIGURATION=("${OPTIONS[@]}" "$@")

    # Build the local repository clone.
    push_directory "$REPO"
    make_current_directory "$JOBS" "${CONFIGURATION[@]}"
    pop_directory
    pop_directory
}

# Standard build of current directory.
build_from_local()
{
    local MESSAGE="$1"
    local JOBS=$2
    local OPTIONS=$3
    shift 3

    display_heading_message "$MESSAGE"

    # Join generated and command line options.
    local CONFIGURATION=("${OPTIONS[@]}" "$@")

    # Clear build files
    git clean -dfX

    # Build the current directory.
    make_current_directory "$JOBS" "${CONFIGURATION[@]}"
}

# The master build function.
#==============================================================================
build_all()
{
    update_prefix_options

    build_from_tarball_boost "$BOOST_URL" "$BOOST_ARCHIVE" bzip2 . "$PARALLEL" "${BOOST_OPTIONS[@]}" "$BOOST_CUSTOM_OPTIONS"
    build_from_github libbitcoin secp256k1 version7 "$PARALLEL" "${SECP256K1_OPTIONS[@]}" "$@"
    build_from_local "Building local libbitcoin-system" "$PARALLEL" "${BITCOIN_SYSTEM_OPTIONS[@]}" "$@"
}


# Build the primary library and all dependencies.
#==============================================================================
display_configuration
create_directory "$BUILD_DIR"
push_directory "$BUILD_DIR"
initialize_git
pop_directory
time build_all "${CONFIGURE_OPTIONS[@]}"
