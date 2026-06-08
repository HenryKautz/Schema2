#!/bin/bash
sbcl --eval "(load \"schema.lisp\")" --eval "(instantiate \"tests/$1.wff\" \"tests/$1.scnf\")" --eval "(quit)"
cat "tests/$1.scnf"


