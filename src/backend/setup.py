"""
Package setup configuration for Mint Replica Lite backend service.

# HUMAN TASKS:
1. Verify Python 3.9+ is installed before package installation
2. Set up and activate a virtual environment before running pip install
3. Ensure all system-level dependencies are installed (postgresql-devel, python-devel)
4. Configure development environment variables if developing locally
"""

# setuptools>=65.0.0 - Package distribution tools
# wheel>=0.37.0 - Built package format
from setuptools import setup, find_packages
import os

def read_requirements():
    """
    Reads package requirements from requirements.txt file and returns a filtered list
    of package requirements.
    
    Returns:
        list: List of package requirements strings in format 'package_name==version'
    """
    requirements = []
    req_path = os.path.join(os.path.dirname(__file__), 'requirements.txt')
    
    with open(req_path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            # Skip empty lines and comments
            if line and not line.startswith('#'):
                requirements.append(line)
    
    return requirements

# Package metadata and configuration
# REQ: Backend Development Framework - Python 3.9+ backend development
setup_config = {
    'name': "mint-replica-lite",
    'version': "0.1.0",
    'description': "Financial management system backend service",
    'author': "Mint Replica Lite Team",
    'author_email': "team@mintreplicalite.com",
    'url': "https://github.com/mintreplicalite/backend",
    
    # Package configuration
    'packages': find_packages(where='.', exclude=['tests*']),
    'package_dir': {'': '.'},
    'include_package_data': True,
    
    # REQ: Backend Framework Stack - Flask framework with extensions
    # REQ: Data Storage & Caching - Database and caching system dependencies
    'install_requires': read_requirements(),
    
    # Python version requirement
    'python_requires': ">=3.9",
    
    # Package classifiers
    'classifiers': [
        'Development Status :: 4 - Beta',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: MIT License',
        'Operating System :: OS Independent',
        'Programming Language :: Python',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.9',
        'Programming Language :: Python :: 3.10',
        'Topic :: Software Development :: Libraries :: Python Modules',
        'Topic :: Internet :: WWW/HTTP :: Dynamic Content',
        'Topic :: Software Development :: Libraries :: Application Frameworks',
    ],
    
    # Entry points for CLI commands if needed
    'entry_points': {
        'console_scripts': [
            'mint-replica-lite=mint_replica_lite.cli:main',
        ],
    },
    
    # Additional metadata
    'license': 'MIT',
    'keywords': 'finance,management,banking,transactions,api',
    'project_urls': {
        'Documentation': 'https://docs.mintreplicalite.com',
        'Source': 'https://github.com/mintreplicalite/backend',
        'Tracker': 'https://github.com/mintreplicalite/backend/issues',
    },
    
    # Development dependencies are handled through requirements.txt
    'zip_safe': False,
}

# Execute setup with configuration
setup(**setup_config)