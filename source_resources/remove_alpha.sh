#!/bin/bash

convert "${1}" -background white -alpha remove -alpha off "rgb_${1}"
