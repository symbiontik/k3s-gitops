#!/bin/bash

# Refer: https://www.theserverside.com/blog/Coffee-Talk-Java-News-Stories-and-Opinions/delete-all-branches-except-master-main-local-remote
git branch | grep -v "main" | xargs git branch -D