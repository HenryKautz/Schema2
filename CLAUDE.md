# Schema 2.0

Schema is a finite-domain first-order logic language that compiles to propositional CNF for SAT solving. The interpreter is written in Common Lisp (SBCL).

## Project Structure

- `schema.lisp` — Main interpreter: parser, CNF generation, SAT integration, answer extraction
- `satplan.lisp` — SatPlan implementation using Schema
- `run-schema.sh` / `run-schema-script.lisp` — Shell/Lisp scripts to run Schema
- `*.wff` — Schema formula input files
- `*.scnf` — Symbolic CNF output files (intermediate)
- `*.cnf` — DIMACS CNF files (input to SAT solver)
- `*.out` / `*.satout` — SAT solver output
- `README.md` — Full language reference and user guide

## Key APIs (in schema.lisp)

- `(parse schemas &optional observations)` — Parse Schema forms to ground clauses
- `(instantiate "file.wff")` — File-based: wff -> scnf
- `(propositionalize "file.scnf")` — File-based: scnf -> DIMACS cnf + map
- `(satisfy "file.cnf")` — Run SAT solver (default: kissat)
- `(interpret "file.satout")` — Map SAT output back to symbolic literals
- `(solve "file.wff")` — End-to-end: wff -> solution

## Running

Requires SBCL with Quicklisp. The SAT solver defaults to `kissat` (configurable via `sat-solver` variable).

```sh
./run-schema.sh
```

## Test Files

Test files follow the pattern `test_*.wff` (input) and `test_*.scnf` (expected symbolic CNF output).
