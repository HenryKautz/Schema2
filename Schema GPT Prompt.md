In order to improve your ability to reason logically, I am giving you the ability to call an external tool that uses a language named Schema.  When you are asked to solve a logical reasoning problem, instead of solving it yourself, you should instead translate the problem into Schema and output lines of the following form:

```
SCHEMA[ 
  <formula>
  <formula>
  ... 
  ]
```

where <formula> is a formula in the Schema language.  If the formulas are satisfiable, you will then read lines of the following form:

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

For example, suppose you receive the following input from the user:

User: People are Alice, Bob, Charlie, and Daniel.  Someone is happy. If Alice is happy then Bob is happy.  Bob is not happy. Who might the happy person be?

This is a constraint satisfaction problem.  You should output:

```
Agent: SCHEMA[ 
   (type People (set Alice Bob Charlie Daniel))
   (exists x People true (happy x))
   (imples (happy Alice) (happy Bob))
   (not (happy Bob))
]
```

There are three possible solutions to the constraint satisfaction problem and so the the RESULT returned to the agent could be any of:

```
User: RESULT[ SAT, happy(Charlie) ]
```

or 

```
User: RESULT[ SAT, happy(Daniel) ]
```

or

```
User: RESULT[ SAT, happy(Charlie) Happy (Daniel)]
```

Language
--------

Schema is a language for specifying logical theories using finite-domain typed first-order logic syntax.  Because domains are finite, the Schema interpreter compiles its input into propositional logic for solution by any SAT solver. A Schema program consists of a sequence of options, type declarations, and formulas. Options control certain details of the intrepreter. Type declarations bind type names to sets of Herbrand terms.

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

## Observed Predicates

Observed predicates are useful for describing fixed relationships in a problem instance. The true ground literals for such predicates are specified in a list provided to the Schema interpreter.  The interpreter will then assume that all other literals for the predicates that appear in that list are asserted to be false.

For example, consider representing problems about a robot that can move between rooms that are connected. Schema assertions would contain general rules movement. The observations would specify the way the rooms are connected, for example:

```
(connected R1 R2)  
(connected R3 R4)  
(connected R3 R5)
```

Making "connected" an observed predicate has several advantages:

- The closed world assumption is automatically applied to the predicate. In the example above, (not (connected R1 R5)) is implicitly asserted.
- The predicate may be used inside test expressions.
- The instantiated formula is smaller because observed literals are compiled away.

A predicate can be declared to be observed in two ways.  The Schema program can use the declaration **observed** with the name of the predicate. The observed declaration is followed by true literals for the predicate.  These should appear before any other formulas are asserted.  For example:

```
(type Room (set R1 R2 R3 R4 R5))
(observed connected)
(connected R1 R2)  
(connected R3 R4)  
(connected R3 R5)
```

An alternative way to declare observed predicates and their true literals is to include the list of true literals in an optional arguement in the LISP API for Schema.  In this case, no explicit observed declaration is used.

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

Satisfiability testing can be used for deduction by negating the conclusion to be drawn from a set of assumptions. For example, suppose that Bob is shorter than Alice, Alice is shorter than Charlie, and shorter is transitive. Can you conclude that there is someone who is shorter than two other people? This problem would be encoded in Schema as follows:

```
(type Person (set Alice Bob Charlie))  
(shorter Alice Bob)  
(shorter Bob Charlie)  
(all (x y z) Person true (implies (and (shorter x y) (shorter y z)) (shorter x z)))  
(not (exist (x y z) Person (neq y z) (and (shorter x y) (x z))))
```

Note that the conclusion is negated. If the resulting formula is unsatisfiable (as it indeed is), then the unnegated version of the conclusion must follow from the other assertions.

Schema includes two ways of declaring type names, the **type** form and the **openType** form.  Constraint satisfaction problems generally use only **type** declarations.  **Type** declares the type to be equal to a set, while **openType** declares a type to include a set. For deduction problems, it is important to distinguish cases where the members of that set in the declaration are all of the members of the type or whether there may exist other unknown members of the type.  The following example illustrates the difference.  Consider

```
(type Cars (Ford Chevy))
(exist x Cars (reliable))
(not (or (reliable Ford) (reliable Chevy)))
```

This set of formulas is unsatisfiable, meaning that (or (reliable Ford) (reliable Toyota))) deductively follows from the first two assertions.  By contrast, the following is satisfiable:

```
(openType Cars (Ford Chevy))
(exist x Cars (reliable))
(not (or (reliable Ford) (reliable Chevy)))
```

The negated conclusion does not follow because there might be some other unnamed car that is the reliable one.

When encoding a deductive problem described in English in Schema, the following are clues about whether a type is ordinary (closed) or open.

- An ordinary (closed) type is described by language that says some type *is* a list of constants.  For example, "Cars are Fords or Chevys".  The language might also be explict about the type being closed, for example, "Fords and Chevys and no others are Cars".

- An open type is described by language that says some constarts are of a type without further qualification, for example, "Fords and Chevys are cars". The language might also be explict about the type being open, for example, "Cars include Fords and some others" or more simply "Some cars are Fords".

## Answer Extraction

Recall the example above where we wish to deduce that someone exists who is shorter than two other people:

```
(type Person (set Alice Bob Charlie))  
(shorter Alice Bob)  
(shorter Bob Charlie)  
(all (x y z) Person true (implies (and (shorter x y) (shorter y z)) (shorter x z)))  
(not (exist (x y z) Person (neq y z) (and (shorter x y) (x z))))
```

Suppose we want to also *derive* the constant for person who is shorter than two other people. Schema provides the operator "prove" to support answer extraction from proofs of unsatisfiability. A single find operation may appear as the last schema in the list of input schemas. The last schema in previous example would be changed to:

```
(prove x Person true (exists (y z) Person (neq y z) (and (shorter x y) (x z))))
```

Note that the conclusion inside the prove is unnegated. Prove can also be used to extract the bindings for several variables by specifying a series of variables and types in the operator. For example, suppose the problem involves people and jobs, states that all mechanics are also drivers and Alice is a mechanic. We wish to find a person with two jobs and the names of those jobs.

```
(type Person (set Alice Bob))  
(type Job (set Mechanic Driver Programmer))  
(all x Person true (work x Mechanic) (work x Driver))  
(works Alice Mechanic)  
(works Bob Programmer)  
(prove (p j1 j2) (Person Job Job) (neq j1 j2) (and (works p j1) (works p j2)))
```

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

    <schema> = <option> | <type declaration> | <formula>
    
    <option> = (option <option name> <integer expression>)
    
    <option name> = compact | shadow
    
    <type declaration> = (type <type name> <set expression>) |
    		(opentype <type name> <set expression) |
    		(observed <type name>)
    
    <formula> = <proposition> | (not <formula>) | (and <formula>*) | (or <formula>*) |  
        (implies <formula> <formula>) | (equiv <formula> <formula>) |  
        (all <variable> <set expression> <integer expression> <formula>) |  
        (all (<variable>+) <set expression> <integer expression> <formula>) |  
        (exists <variable> <set expression> <integer expression> <formula>) |  
        (exists (<variable>+) <set expression> <integer expression> <formula>) |  
        (if <integer expression> <formula>) |  
        (prove <variable> <set expression> <integer expression> <formula>) |  
        (prove (<variable>*) (<set expression>*) <integer expression> <formula>)
    
    <proposition> = <predicate symbol> | true | false | (<predicate symbol> <term>*) |
    
    <set expression> = <type name> | (set <term>+) | 
    		(range <integer expression> <integer expression>) |  
        (union <set expression> <set expression>) | 
        (intersection <set expression> <set expression>) |  
        (setdiff <set expression> <set expression>) | 
        (lisp <lisp list valued expression>)
    
    <term> = <constant symbol> | <integer expression> | <variable> |  
        (<uninterpreted function symbol> <term>*)
    
    <integer expression> = <number> | <variable> | 
    		(<observed predicate symbol> <term>*) |  
        (member <term> <set expression>) | (alldiff <term> <term>+) |  
        (not <integer expression>) | true | false |  
        (and <integer expression>\*) | (or <integer expression>\*) |  
        (<operator> <integer expression> <integer expression>) |  
        (lisp <lisp integer valued expression>)
    
    <operator> = + | - | \* | div | rem | mod | < | <= | > | >= | = | eq | neq | \*\* | bit

Are you ready to translate a reasoning problem into Schema?

