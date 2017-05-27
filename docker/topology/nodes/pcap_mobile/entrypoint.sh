#!/bin/bash

# nothing special

readonly NODE_NAME="$1"

# prompt
echo export PS1="\"[${NODE_NAME}] \\W # \"" > /root/.bashrc

bash
