#!/usr/bin/env bash

number=$1

if (( number % 2 == 0 )); then
  echo "EVEN"
else
  echo "ODD"
fi
