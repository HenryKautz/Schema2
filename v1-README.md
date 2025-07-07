# SCHEMA USERS GUIDE

henry.kautz@gmail.com
---------------------

[Gitlab Repository](https://gitlab.com/HenryKautz/Schema)

Schema is a language for specifying logical theories using finite-domain typed first-order logic syntax. Because domains are finite, the language is a compact representation for propositional logic. The Schema interpreter produces propositional CNF (conjunctive normal form) which can be input to any satisfiability testing program.

The Schema interpreter is written in Common Lisp, but it is not necessary to know how to program in Lisp in order to use Schema.

As of December 1, 2024, the following language features are not fully implemented:

- Observed quantified formulas
- The **observations** form
- The **prove** formula
- The lisp **SchemaParser** object type

## Examples of Schema

```
;; Define set types boy, girl, and child
(type boy (set jon alex max sam))
(type girl (set mary sue ann june))
(type child (union boy girl))
;; Three different children all love the same the same girl
(exists g girl true
		(exists (c1 c2 c3) (alldiff g c1 c2 c3)
				(and 
						(loves c1 g)
						(loves c2 g)
						(loves c3 g))))

;; STRIPS planning
;; Define range type time
(type time (range 1 100))
;; Define set type block
(type block (A B C))
;; Preconditions and effects of move
(all t time true
    (all (x y z) block (alldiff x y z)
         (implies (move x y z t)
                  (and
                      ;; Preconditions hold at time t
                      (clear x t)
                      (on x y t)
                      (clear z t)
                      ;; Effects hold at time t+1
                      (on y z (+ t 1))
                      (clear y (+ t 1))
                      ((not (clear z (+ t 1))))))))
```

Common Lisp API
------------

Invoke any implementation of Common Lisp, and load the file "schema.el". The following Lisp functions are available:

**(instantiate '(SCHEMA+) &optional '(OBSERVATION+)) returns ((OR LITERAL+)\*)**  
Parse a list of schemas (see BNF syntax below) and return a list of symbolic ground clauses. Each OBSERVATION is a ground atom that is asserted to be true. When the schemas are expanded, they are simplified by replacing observed atoms by true and all non-observed atoms that employ the same predicates by false.

**(instantiate "test.wff" "test.scnf" &optional "test.obs")**  
Reads the Schema file "test.wff", instantiates it, and saves the result in symbolic conjunctive normal form in the file "test.scnf". The optional file "test.obs" contains a sequence of observed ground atoms.

**(propositionalize '((OR LITERAL+)\*) returns ((INTEGER+)\*), NUM_VARS, NUM_CLAUSES, ((INTEGER LITERAL)\*)**   
Converts a list of symbolic ground clauses to a list of list of integers.  Other returned values are the number of variables, the number of clauses, and a list that maps integers back to positive literals.

**(propositionalize "test.scnf" "test.cnf" "test.map")**  
Reads the symbolic conjunctive normal form file "test.scnf" and creates a DIMACS format CNF file3 "test.cnf". In DIMACS format (the standard input language for all modern SAT solvers), propositions are represented by positive and negative integers. The mapping from symbolic ground atoms to integers is written to the file "test.map". The file "test.cnf" may then be sent to a SAT solver.

**(satisfy "test.cnf" "test.out")**
The solver named by the variable **sat-solver-program** (default "kissat") is called on "test.cnf" and the output of the solver is captured in the file "test.out".  Satisfy returns 'SAT, 'UNSAT, or nil if the solver fails or its output contains neither the strings SAT nor UNSAT.

**(interpret "test.out" "test.map" "test.lits" &optional sort-by-time)**  
Reads in the output of a SAT solver "test.out" and a mapping file "test.map", and creates a file "test.lits" containing the positive literals in the satisfying assignment in symbolic form. The file "test.out" specifies a solution by a sequence of positive and negative integers. The format of the file can be flexible; it can simply be a sequence of integers; or be in official DIMACS solution format where lines containing the integers begin with the letter "v"; or free-form text where lines containing only integers are assumed to be the solution. If for some integer, neither the integer nor its complement appears, then it is assumed to be false (negative) for the assignment. The results are sorted alphabetically unless sort-by-time is set to t, in which case the results are sorted by the last argument to each predicate, which is often used to specify a time index.

**(make-instance SchemaParser '(SCHEMA ...) '(OBSERVATION ...)))**
See the section below on Answer Extraction for Refutation Proofs.

**(find '(SCHEMA ...)' &optional  '(OBSERVATION ...))**
The schemas must include a find form.  The function returns a list of `(<variable> <value>)` pairs or the atom FAILED.

**(solve "test.wff" "test.solution" &optional "test.obs")**
Reads in the Schema file "test.wff" and an optional "test.obs" observation file, solves it using the **sat-solver-program** and writes the results in symbolic form to "test.solution".  If "test.wff" contains no **find** formula, the sat solver will be called a single time.  If it does contain **find**, then the sat solver may be invoked several times as described in the section below on Answer Extraction for Refutation Proofs.  If "test.wff" contains a **find** formula, then the solution will be FOUND or FAILED; otherwise it will be SAT or UNSAT.  The format of "test.solution" will be one of:

- SAT followed by the positive ground literals in a satisying model, one per line
- UNSAT followed by nothing
- FIND followed by a sequence of variable bindings, one per line.  Each variable binding is of the form `(<variable> <value>)`
- FAILED followed by the positive ground literals in a counterexample to the formula to be proved

Language
--------

Schema is a language for specifying logical theories using finite-domain typed first-order logic syntax.  Because domains are finite, the Schema interpreter compiles its input into propositional logic for solution by any SAT solver. A Schema program consists of a sequence of options, type declarations, and formulas. Options control certain details of the intrepreter. Type declarations bind type names to sets of Herbrand terms.  Types may share elements.  No type declarations are associated with predicates; every predicate may accept terms of any type as arguments.  It is also permissible for different instances of predicates to take different number of arguments.

Formulas are composed, as in first-order logic, of predicates, variables, constants, function symbols, logical connections, and quantifiers. The basic function of the Schema interpreter is to instantiate the variables in each formula and convert the result to CNF.

Formulas and terms are specified in prefix (LISP) notation. The quantifiers, all and exists, iterate over sets of Herbrand terms. Terms are integers, constants, or complex terms built using uninterpreted function symbols. A quantified formula is represented by a list containing the quantifier, a variable, a set of terms, a test (integer valued) expression, and the subformula to which the quantification is applied. The subformula is instantiated only for bindings of the variable for which the test is true. For example,

```
(all x (range 1 10) (= 0 (mod x 2)) (p x))
```

can be read, "for all x in the range 1 through 10, such that x is even, assert (p x)".

Propositions are expressed in Schema as either atomic symbols or complex propositions specified by a list beginning with a predicate followed by zero or more terms.  The special proposition "true" and "false" have the expected meaning.  Terms can be built from interpreted functions such as + and uninterpreted function symbols. For example, the literal expression (winner john (round (\* 3 8))) is instantiated as

```
(winner john (round 24))
```

where "winner" is a predicate, "john" is a simple term, "round" is an uninterpreted function symbol, and "(round 24)" is a complex term.

The integer values 1 and 0 are used to represent true and false respectively in intger expressions. The special constants "true" and "false" are equivalent to 1 and 0 respectively when they appear in integer expressions. Integer expressions may include arithmetic functions (+, -, \*, div, rem, mod), comparison functions (<, <=, =, >=, >, member, eq, neq, alldiff), set composition functions (enumerated sets, ranges of integers, union, intersection, setdiff), logical functions (and, or, not), and observed predicates. Non-observed predicates may not appear in an integer expression. Note that logical functions in integer expressions are evaluated by the Schema interpreter and do not appear in the final CNF, unlike the logical operators that have the same names.

Comments can appear in the input.  They begin with ;; (double semicolon) and extend to the end of the line.

## Functions and Equality

Schema includes both interpreted an uninterpreted functions.  Interpreted functions include mathematical operations and set operations.  A term that does begin with an interpreted function is taken to be an uninterpreted function.  Thus, the formula using the interpreted function + and the uninterpreted function symbol node

```
(all i (range 1 3) true (edge (vertex x) (vertex (+ x 1))))
```

is expanded to

```
(edge (vertex 1) (vertex 2))
(edge (vertex 2) (vertex 3))
(edge (vertex 3) (vertex 4))
```

The for operator can be used in a set expression (such as a type declaration) to generate a set of ground uninterpreted functions.  For example,

```
(type Vertices (for i (range 1 3) true (set (vertex i)))
```

is expanded to

```
(type Vertices (set (vertex 1) (vertex 2) (vertex 3))
```

As in logic programming, ground terms refer to themselves, or in other words, formulas are interpreted over a Herbrand universe.  The predicates **eq** and **neq** check for syntactic equality at the time that formulas are instantiated.  The mathematical comparison predicates cited above check for numeric equality at instantiation time.  There is no semantic equality operator that would allow one to assert that two different Herbrand terms refer to the same entity.

## Observed Predicates

Observed predicates are useful for describing fixed relationships in a problem instance. The true ground literals for such predicates are specified in a list provided to the Schema interpreter.  The interpreter will then assume that all other literals for the predicates that appear in that list are asserted to be false.

For example, consider representing problems about a graph. The observations would specify edges in the graph, for example:

```
(edge N1 N2)  
(edge N3 N4)  
(edge N3 N5)
```

Making "connected" an observed predicate has several advantages:

- The closed world assumption is automatically applied to the predicate. In the example above, (not (connected R1 R5)) is implicitly asserted.
- The predicate may be used inside test expressions.
- The instantiated formula is smaller because observed literals are compiled away.

A predicate can be declared to be observed in two ways. The **observations** form can be used to specify it's observed positive literals.  These should appear before any other formulas are asserted.  For example:

```
(type Node (set N1 N2 N3 N4 N5))
(observations 
	(edge N1 N2)  
	(edge N3 N4)  
	(edge N3 N5))
```

An alternative way to declare observed predicates and their true literals is to include the list of observed literals as an optional argument for the LISP API.  In this case, no explicit observations declaration is used.

## Observed Quantified Formulas

Quantified formulas can appear as observations with the restriction that only the forms **all**, **and**, **if**, and positive literals may appear in the body of a quantified formula.  For example, the following defines a sequence of 10 cells with the "next" relation from a cell to its neighbor.

```
(observations
	(all i (range 1 9) true
		(next (cell i) (cell (+ 1 i))))
)
```

The following asserts that "greater" is the transitive closure of "next".

```
(observations
	(all i (range 1 10) true
		(all j (range 1 10) (next (cell i) (cell j))
			(greater (cell i) (cell j))))
	
	(all i (range 1 10) true
		(all j (range 1 10) true
			(all k (range 1 10) (and 
														(next (cell i) (cell j))
														(next (cell j) (cell k)))
					(next (cell i) (cell k)))))
)
```

Note that the expression `(and (next (cell i) (cell j)) (next (cell j) (cell k)))` appears as a *test* in the innermost **all**.  Recall that this is valid because observed literals can appear in a test.  Evaluating the form can add additional pairs to the observed predicate "next".  The Schema program therefore re-evaluates *every* observed quantified formula if *any* such formula adds a *new* observed literal.  

## Types

A  **type** declaration defines a type name as a set of of ground terms.  Terms can appear in more than one type.  Types are used to expand quantified **all** and **exists** forms, but predicates themselves do not have type constraints on their arguments.  Examples of type declarations:

```
(type fruit (set apple orange banana))
(type berry (set carrot cabbage))
(type plant (union fruit vegetable))
```

The for operator is used to compactly create a set of non-atomic ground terms.  Consider a problem where we wish to define a type Node that contains 100 terms.  Instead of listing the names of the terms individually as in the previous section, we can write:

```
(type Node (for i (range 1 100) true (set (n i))))
```

This defines Node as a set containing the terms (n 1), (n 2), and so on up to (n 100).

Care needs to be taken in translating problems stated in English.  Consider the problem:

> Some cars are Fords.
> Some cars are reliable.
> Are Fords reliable?

Translating this as

```
(type Cars (set Ford))
(exists x Cars true (reliable x))
;; Negated conclusion
(not (reliable Ford))
```

This formula is unsatisfiable, and so one concludes that Fords are reliable.  The second line in the input expands to `(reliable Ford)` because Ford is the only known member of the type Cars.  A better translation of the problem would include some other anonymous member of type Car which might be the reliable brand; for example,

```
(type Cars (set Ford CarBrand02))
(exists x Cars true (reliable x))
;; Negated conclusion
(not (reliable Ford))
```

This formula is satisfiable, so the unwanted conclusion does not hold.

## Constraint Satisfaction

Discrete constraint satisfaction problems (CSPs) can easily be represented in Schema.  The answer can be read off from the symbolic form of the SAT solution generated by the interpret function.

Multi-valued variables in CSPs can be encoded as follows.  Suppose the CSP has a variable named Color whose values can be Red, Blue, or Green.  In Schema, we create a proposition named Color, a type ColorValues containing the constants Red, Blue, and Green, and assert that Color holds for exactly one ColorValue.

```
(type ColorValue (set Red Blue Green))
(exists c ColorValue (Color c))
(not (exists (c1 c2) ColorValue (neq c1 c2) (and (Color c1) (Color c2))))
```

Deduction 
---------------------------------------

Satisfiability testing can be used for deduction by negating the conclusion to be drawn from a set of assumptions. For example, suppose that Bob is shorter than Alice, Alice is shorter than Charlie, and shorter is transitive. Can you conclude that there is someone who is shorter than two other people? This problem could be encoded in Schema as follows for proof by refutation.  The (unnegated) conclusion holds if the formula is unsatisfiable.

```
(type Person (set Alice Bob Charlie))  
(shorter Alice Bob)  
(shorter Bob Charlie)  
(all (x y z) Person true (implies (and (shorter x y) (shorter y z)) (shorter x z)))  
(not (exist (x y z) Person (neq y z) (and (shorter x y) (x z))))
```

Schema provides an alternative way of encoding a deduction problem by using the **prove** construct.  In this case, the last line above would be replaced by:

```
(prove () (exists (x y z) Person (neq y z) (and (shorter x y) (x z))))
```

Note that the formula to be deduced is not negated.  Use of prove makes makes the goal of the Schema problem clearer to a user.  

## Answer Extraction for Deduction

 Suppose we want to also *derive* the constant for person who is shorter than two other people. Schema provides the operator "prove" to support answer extraction from proofs of unsatisfiability. A single find operation may appear as the last schema in the list of input schemas. The last schema in previous example would be changed to:

```
(find ((x Person)) true (exists (y z) Person (neq y z) (and (shorter x y) (x z))))
```

Note that the conclusion inside the prove is unnegated. Prove can also be used to extract the bindings for several variables by specifying a series of variables and types in the operator. For example, suppose the problem involves people and jobs, states that all mechanics are also drivers and Alice is a mechanic. We wish to find a person with two jobs and the names of those jobs.

```
(type Person (set Alice Bob))  
(type Job (set Mechanic Driver Programmer))  
(all x Person true (and (work x Mechanic) (work x Driver)))
(works Alice Mechanic)  
(works Bob Programmer)  
(find ((p Person) ((j1 j2) Job)) (neq j1 j2) (and (works p j1) (works p j2)))
```

## Common Lisp API for Answer Extraction

Instead of calling the parse function directly, answer extraction begins by creating a SchemaParser object. Its initialization takes a list of schemas and a list of observations. Its method GetCNF takes a LastResult argument and returns three arguments:

*   A symbolic CNF formula
*   A status symbol
*   A list of answer bindings (possibly partial)

LastResult is one of SAT or UNSAT. Status is one of:

*   TEST: the user should test the returned CNF for satisfaibility and return the result in its next call to GetCNF.
*   FAIL: no answer can be found
*   DONE: the final answer is the list of returned answer bindings. The returned CNF formula can be ignored.

The algorithm for answer extraction using SchemaParser follows:

```
(setq parser (make-instance SchemaParser my-schemas my-observations))
(setq status 'TEST)
(setq last-result 'SAT)
(setq bindings nil)
(while (eq status 'TEST)
	(multiple-value-bind (scnf status bindings) (GetCNF parser last-result))
	;; Test scnf using a sat solver and set last-result to SAT or UNSAT
	)
(if (eq status 'DONE)
	bindings
	'FAIL)
```

Note that answer extraction can fail even if the assumptions together with the negation of the conclusion is unsatisfiable. Consider, for example:

```
(type Person (set Alice Bob))  
(or (happy Alice) (happy Bob))  
(Prove x Person t (happy x))
```

Answer extraction will end in FAIL because it cannot prove that Alice is happy and it cannot prove that Bob is happy.

A SchemaParser performs binary search on each answer variable to find the answer bindings.  Suppose the first variable is $t_1$. The parser makes $t_1$ existentially quantified over half of its domain and variables $t_2, t_3, ...$ existentially quantified over their full domains.  If this formula is satisfable, it repeats the process but making $t_1$ existentially quantified over a quarter of its domain.  If the formula is unsatisfiable, then the process is repeated with $t_1$ existentially quantified over the other half of its domain.  Eventually the process will fail or result in an answer binding for $t_1$.  The parser then continues on to search for a binding for $t_1, t_2$, etc. The maximum number of wffs returned by GetCNF before it returns FAIL or DONE, and thus the maximum number of calls to a SAT solver, is $\sum{\log|T_i|}$ where $T_i$ is the type of answer variable $i$.  Note that is this is an improvement over a naive implementation of answer extraction which would be $\prod |T_i|$.

## Common Binary Relationship Patterns

Suppose R is a binary relation.  Properties of R can be asserted as follows.

### R is a strict order

Suppose R is a relation over pairs of type E

```
;; R is a strict order
(all (x y z)  E true (implies (and (r x y) (r y z)) (r x z))))
(all x E (not (R x x)))
```

### R is a strict total order

```
;; R is a strict total order
(all (x y z) E true (implies (and (r x y) (r y z)) (r x z))))
(all x E true  (not (R x x)))
(all (x y) E (neq x y) (or (R x y) (R y x)))
```

### R is functional

We say that a relationship over types E and V is functional if for every E there is exactly one V such that R holds.  Functional relations are often used when E is a set of entities and V is a set of possible values of some property of the entities.

```
;; R is functional
(all x E true (exists y V true (R x y)))
(all x E true (not (exists (y z) V (neq y z) (and (R x y) (R x z)))))
```

### R is a bijection

We say that a relationship over types E and V is a mapping if (1) R is functional (2) R is onto, meaning for every V there is some E related to it by R, and (3) R is one-to-one, meaning no two E are related to the same V.  Bijections are often used in representing matching problems where a set of entities must be matched to a set of unique values.

```
;; R is a bijection
;; (1) R is functional
(all x E true (exists y V true (R x y)))
(all x E true (not (exists (y z) V (neq y z) (and (R x y) (R x z)))))
;; (2) R is onto
(all y V true (exists x E true (R x y)))
;; (3) R is one to one
(not (exists (x1 x2) E (neq x1 x2) (exists y V true (and (R x1 y) (R x2 y)))))
```

Schema BNF
----------

    <schema> = <option> | <type declaration> | <formula> | <observations>
    
    <option> = (option <option name> <integer expression>)
    
    <option name> = compact | shadow
    
    <type declaration> = (type <type name> <set expression>) |
    		(opentype <type name> <set expression) |
    		(observed <type name>)
    
    <formula> = <proposition> | (not <formula>) | 
    		(and <formula>*) | (or <formula>*) |  
        (implies <formula> <formula>) | (equiv <formula> <formula>) |  
        (all <variable> <set expression> <test> <formula>) |  
        (all (<variable>+) <set expression> <test> <formula>) |  
        (exists <variable> <set expression> <test> <formula>) |  
        (exists (<variable>+) <set expression> <test> <formula>) |  
        (if <test> <formula>) |  
        (prove ((<variable> <set expression>)*) <test> <formula>)
    
    <proposition> = <predicate symbol> | true | false | 
    		(<predicate symbol> <term>*) |
    
    <set expression> = <type name> | (set <term>+) | 
    		(range <integer expression> <integer expression>) |  
        (union <set expression> <set expression>) | 
        (intersection <set expression> <set expression>) |  
        (setdiff <set expression> <set expression>) | 
        (for <variable> <set expression> <test> <set expression>) |
        (for (<variable>+) <set expression> <test> <set expression>) |
        (lisp <lisp list valued expression>)
    
    <test> = <integer expression>
    
    <term> = <constant symbol> | <integer expression> | 
    		<variable> |  
        (<uninterpreted function symbol> <term>*)
    
    <integer expression> = <integer> | 
    		true | false |
    		<variable ranging over an integer type> | 
    		(<observed predicate symbol> <term>*) |  
        (member <term> <set expression>) | 
        (alldiff <term> <term>+) |  
        (not <integer expression>) | 
        (and <integer expression>\*) | 
        (or <integer expression>\*) |  
        (<operator> <integer expression> <integer expression>) |  
        (lisp <lisp integer valued expression>)
    
    <operator> = + | - | \* | div | rem | mod | < | <= | > | >= | = | eq | neq | \*\* | bit
    
    <observations> = (observations <observed-formula>+)
    
    <observed-formula> = <proposition> |
    		(and <observed-formula>*) | 
        (all <variable> <set expression> <test> <observed-formula>) |  
        (all (<variable>+) <set expression> <test> <observed-formula>) |  
        (if <test> <observed-formula>) 


## Prompting a Large Language Model to Use Schema

A large language model can be prompted to use Schema as follows:

1. Make a copy of this user guide.
2. Eliminate the sections:
   1. Common Lisp API
   3. Common Lisp API for Answer Extraction
   4. Compact Encodings
   5. Options
3. Eliminate everything in this section that comes before the following paragraph:

In order to improve your ability to reason logically, I am giving you the ability to call an external tool that uses a language named Schema.  When you are asked to solve a logical reasoning problem, instead of solving it yourself, you should instead translate the problem into Schema and output lines of the following form:

```
SCHEMA[ 
  <formula>
  <formula>
  ... 
  ]
```

where <formula> is a formula in the Schema language.  If the formulas do not include a **prove** statement, then Schema will consider it to be a constraint satisfaction problem and test the formula for satisfiability.  If the formulas are satisfiable, you will then read lines of the following form:

```
RESULT[
   SAT
   <literal>
   <literal>
   ... 
]
```

where <literal> is a positive ground literal in a satisfying assignment for the formulas.  If the formulas are unsatisfiable, then you will read

```
RESULT[ UNSAT ]
```

If the formulas contain a **prove** statement, then Schema will consider it to be a deduction problem.  If the formula in the prove statement deductively follows from the other formulas, then you will read lines of the following form:

```
RESULT[
   PROVEN
   (<variable> <term>)
   (<variable> <term>)
   ... 
]
```

If the formula in the prove form does not deductively follow, then you will read

```
RESULT[ 
		UNPROVEN 
		<literal>
		<literal>
		...
]
```

where the literals describe a model that is a counterexample to the theorem.

For example, suppose you output

```
SCHEMA[
	(type Person (set Alice Bob))  
	(type Job (set Mechanic Driver Programmer))  
	(all x Person true (work x Mechanic) (work x Driver))  
	(works Alice Mechanic)  
	(works Bob Programmer)  
	(prove (p j1 j2) (Person Job Job) (neq j1 j2) (and (works p j1) (works p j2)))
]
```

then you will next read

```
RESULT[ 
	PROVEN 
	(p  Alice)
	(j1 Mechanic)
	(j2 Driver)
]
```

Compact Encodings
-----------------

The input formulas need not be in conjunctive normal form. Converting a formula to CNF using only the user-defined propositions can cause its size to increase exponentially. By creating new propositions, the Schema interpreter can guarantee the size of the output CNF formula is only exponential in the nesting of quantifiers. Specifically, where

> M = number of input formulas  
> L = length of the longest input formula  
> D = size of the largest set appearing in a quantification statement  
> N = deepest nesting of quantifiers in a formula

the size of the output CNF is $O(M*L*D^N)$.

When new propositions are introduced in this manner, the relationship between the input and output formulas is that the output formula entails the input formula and any model of the input formula can be extended to a model of the output formula.

## Options

The input to Schema may include the following options, which should appear before any formulas.

```
; Allow new propositions to be created to reduce the size of the instantiated formula (default).
(option compact-encoding 1) 
; Do not create new propositions 
(option compact-encoding 0) 
; Allow an inner quantified variable to shadow an outer variable of the same name.
(option shadow 1) 
; Do not allow the same variable name to be used in nested subformulas (default).
(option shadow 0) 
```

