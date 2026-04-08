import argparse
import os
import sys
import hashlib

def main():
    parser = argparse.ArgumentParser(description='Find duplicate files')
    parser.add_argument(
        'folders', metavar='dir', type=str, nargs='+',
        help='A directory to parse for duplicates',
        )
    args = parser.parse_args()

    find_duplicates(args.folders)


if __name__ == '__main__':
sys.exit(main())