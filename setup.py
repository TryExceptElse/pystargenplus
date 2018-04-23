from setuptools import setup, Extension, find_packages
from Cython.Build import cythonize

import sys
import os

from settings import ROOT_PATH

STARGEN_C_BUILD_DIR = os.path.join(ROOT_PATH, 'sgp', 'c', 'build')

RELEASE_ARG = '--release'
DEBUG_ARG = '--debug'

build_options_d = {
    RELEASE_ARG: ('-O3', '-std=c99'),
    DEBUG_ARG: ('-g3', '-std=c99'),
}


def main():
    release_mode = get_release_mode()
    build_options = build_options_d[release_mode]

    setup(
        name='pystargenplus',
        version='0.0.1',
        description='Stargen, simplified and wrapped in python',
        keywords='stargen',
        packages=find_packages(exclude=['contrib', 'docs']),
        libraries=[
            # Contains logic from omega's development of the
            # stargen program
            ('omega', {
                'sources': [
                    'sgp/c/third_party/omega/stargen.c',
                    'sgp/c/third_party/omega/accrete.c',
                    'sgp/c/third_party/omega/Dumas.c',
                    'sgp/c/third_party/omega/enviro.c',
                    'sgp/c/third_party/omega/display.c',
                    'sgp/c/third_party/omega/utils.c',
                ],
                'include_dirs': ['sgp/c/third_party/omega']
            }),
        ],
        ext_modules=cythonize(
            [
                Extension(
                    name='sgp.stargen',
                    sources=[
                        'sgp/c/sgp.c',
                        'sgp/stargen.pyx',
                    ],
                    libraries=['omega'],
                    include_dirs=['sgp/c', 'sgp/c/third_party/omega'],
                    extra_compile_args=[*build_options]
                ),
            ]
        )
    )


def get_release_mode():
    release_mode = RELEASE_ARG
    # find build option
    if RELEASE_ARG in sys.argv:
        sys.argv.remove(RELEASE_ARG)
    if DEBUG_ARG in sys.argv:
        sys.argv.remove(DEBUG_ARG)
        release_mode = DEBUG_ARG
    return release_mode


if __name__ == '__main__':
    main()
