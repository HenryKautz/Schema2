#!/bin/bash
sbcl -e "(load \"schema.lisp\")" -e "(instantiate \"tests/$1.wff\" \"tests/$1.scnf\")" -e "(quit)"
cat "tests/$1.scnf"


