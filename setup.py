from setuptools import setup, Extension, find_packages
try:
    from Cython.Build import cythonize
except ImportError:
    cythonize = None  # If Cython is missing, pre-existing c files will be used

import sys

RELEASE_ARG = '--release'
DEBUG_ARG = '--debug'
CYTHONIZE_ARG = '--no-cythonize'

build_options_d = {
    RELEASE_ARG: ('-O2', '-g3', '-Wall', '-Wextra', '-std=c99'),
    DEBUG_ARG: ('-g3', '-Wall', '-Wextra', '-std=c99'),
}


def main():

    release_mode = get_release_mode()
    cythonization_option = get_cythonization_option()
    build_options = build_options_d[release_mode]

    def apply_cythonization_option(extensions):
        if cythonization_option and cythonize:
            return cythonize(extensions)
        else:
            for ext in extensions:
                ext.sources = [
                    src[:-4] + '.c' if src.endswith('.pyx') else src
                    for src in ext.sources]
            return extensions

    setup(
        name='pystargenplus',
        version='0.0.2',
        description='Stargen, simplified and wrapped in python',
        install_requires=[
            'setuptools>=38',
        ],
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
        ext_modules=apply_cythonization_option([
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
        ])
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


def get_cythonization_option():
    option = True
    if CYTHONIZE_ARG in sys.argv:
        option = False
        sys.argv.remove(CYTHONIZE_ARG)
    return option


if __name__ == '__main__':
    main()
