#!/bin/bash

walk_dir () {
    shopt -s nullglob dotglob

    for pathname in "$1"/*; do
        if [ -d "$pathname" ]; then
            walk_dir "$pathname"
        else
            printf '%s\n' "$pathname"
        fi
    done
}

LIST_DIR=/home/dungnt/Games

walk_dir "$LIST_DIR"

