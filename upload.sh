#!/bin/bash

timestamp=$(date "+%Y-%m-%d_%H-%M-%S")

git add files
git commit -m "[update] $timestamp"
git push --all -f
