from setuptools import setup, find_packages

setup(
    name='iPhotos-extractor',
    version='0.1',
    author='FanBB2333',
    description='A package for extracting photos from iDevices.',
    long_description=open('README.md').read(),
    long_description_content_type='text/markdown',
    url='https://github.com/FanBB2333/iPhotos-extractor',
    packages=find_packages(),
    classifiers=[
        'Programming Language :: Python :: 3',
        'License :: OSI Approved :: GNU General Public License v3 (GPLv3)',
    ],
    python_requires='>=3.6',
)
