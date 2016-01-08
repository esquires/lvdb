from setuptools import setup

def readme():
    with open('README.rst') as f:
        return f.read()

setup(name='lvdb',
      version='1.0rc1',
      description='python plugin for vim debugger',
      long_description=readme(),
      url='https://github.com/esquires/vim-pdb',
      author='Eric Squires',
      author_email='eric.g.squires@gmail.com',
      license='GPL',
      entry_points={
          'console_scripts': ['vim_gdb=lvdb.vim_gdb:main']
      },
      classifiers=[
          'Development Status :: 4 - Beta',
          'Intended Audience :: Developers',
          'License :: OSI Approved :: GNU General Public License v2 or later (GPLv2+)',
          'Operating System :: Unix',
          'Operating System :: POSIX :: Linux',
          'Programming Language :: C',
          'Programming Language :: C++',
          'Programming Language :: Fortran',
          'Programming Language :: Python',
          'Topic :: Software Development :: Debuggers',
          'Topic :: Text Editors'
          ],
      keywords='vim gdb pdb ipdb',
      install_requires=['ipdb'],
      packages=['lvdb'])
