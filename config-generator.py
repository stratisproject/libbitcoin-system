#!/usr/bin/env python3

import os
import subprocess
import sys

class Config:
    def __init__(self, 
                toolset, toolset_suffix,
                compiler, attributes):
        self.toolset = toolset
        self.toolset_suffix = toolset_suffix
        self.compiler = compiler
        self.attributes = attributes

    def _build_attributes(self) -> str:
        attributes = []

        if not isinstance(self.attributes, dict):
            return ""

        for attribute, value in self.attributes.items():
            if isinstance(value, (list, tuple)):
                for item in value:
                    attributes.append(f'<{attribute}>{item}')
            else:
                attributes.append(f'<{attribute}>{value}')

        return '\n'.join(attributes)

    def __str__(self) -> str:
        return '\n:\n'.join((
            f'using {self.toolset} : {self.toolset_suffix}',
            self.compiler,
            self._build_attributes()
        )) + '\n;\n'
        
class AndroidConfigsProvider:

    _compiler_flags = [
        'fPIC', 
        'ffunction-sections', 
        'fdata-sections',
        'funwind-tables',
        'fstack-protector-strong',
        'no-canonical-prefixes',
        'Wformat',
        'Werror=format-security',
        'frtti',
        'fexceptions',
        'DNDEBUG',
        'g',
        'Oz',
        'std=c++17'
    ]

    _arch_specific_flags = {
        'arm32': ['mthumb']
    }

    _architectures = ['arm32', 'arm64', 'x86', 'x64']

    def __init__(self, target_api: int):
        self.target_api = target_api
        self.toolset_path = os.path.join(os.getenv('NDK_PATH', ''), 'toolchains/llvm/prebuilt/darwin-x86_64/bin/')

    def _compiler_name(self, arch):
        arch_prefixes = {
            'arm32': 'armv7a',
            'arm64': 'aarch64',
            'x86': 'i686',
            'x64': 'x86_64'
        }

        arch_prefix = arch_prefixes[arch]

        android_api = 'android'

        if arch == 'arm32':
            android_api = 'androideabi'

        android_api += str(self.target_api)

        return "-".join([arch_prefix, "linux", android_api, 'clang++'])

    def _get_compile_flags(self, arch):
        return ['-' + flag for flag in self._compiler_flags + self._arch_specific_flags.get(arch, [])]

    def _make_tool_path(self, tool_name) -> str:
        return os.path.join(self.toolset_path, tool_name)

    def provide_config(self, arch) -> Config:
        return Config(
                toolset='clang',
                toolset_suffix='android' + arch,
                compiler=self._make_tool_path(self._compiler_name(arch)),
                attributes = {
                    'archiever': self._make_tool_path('llvm-ar'),
                    'ranlib': self._make_tool_path('llvm-ranlib'),
                    'compileflags': self._get_compile_flags(arch)
                }
        )

class IPhoneConfigsProvider:
    def __init__(self):
        xcode_path = subprocess.run(['xcode-select', '-print-path'], 
            capture_output=True, text=True).stdout.strip('\n')
        self.dev_sys_root = os.path.join(xcode_path, 'Platforms/iPhoneOS.platform/Developer')

    def provide_config(self) -> Config:
        iphone_sys_root = os.path.join(self.dev_sys_root, 'SDKs/iPhoneOS.sdk')
        return Config(
                toolset='darwin',
                toolset_suffix='ios',
                compiler=f'clang++ -arch arm64 -fembed-bitcode-marker -isysroot {iphone_sys_root}',
                attributes= {
                    'striper': '',
                    'root': self.dev_sys_root,
                    'compileflags': ['-std=c++17']
                }
            )

def make_config(platform, arch) -> str:
    if platform == 'macos':
        return ''
    elif platform == 'ios':
        return str(IPhoneConfigsProvider().provide_config())
    elif platform == 'android':
        return str(AndroidConfigsProvider(21).provide_config(arch))
    else:
        return ''

def main():
    config_path = sys.argv[1]
    platform = sys.argv[2]
    arch = sys.argv[3]

    config = make_config(platform, arch)

    with open(os.path.join(config_path, "user-config.jam"), "w") as config_file:
        config_file.write(config + '\n')


if __name__ == "__main__":
    main()