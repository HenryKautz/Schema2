;; Time horizon
;; Time horizon

(alias numslices 5)
(type slices (range 1 numslices))
(type actslices (range 1 (- numslices 1)))

;; Simple Logistics Domain - packages, trucks, places
;;    Truck can move in one step from and to any place

(alias numpackages 3)
(alias numtrucks 2)
(alias numplaces 3)

(alias packages (for i in (range 1 numpackages) (set (package i))))
(alias trucks (for i in (range 1 numtrucks) (set (truck i))))
(alias places (for i in (range 1 numplaces) (place i)))

(type actions
   (for tr trucks true
      (union
	 (for pk packages true
	    (for pl places true
	       (set (load pk tr pl)
		  (unload pk tr pl))))
	 (for tr trucks true
	    (for (pl1 pl2) places (neq pl1 pl2)
	       (set (drive pl1 pl2)))))))

(type fluents
   (union
      (for pl places true
	 (for pktr (union packages trucks) true
	    (set (at pktr pl))))
      (for tr trucks true
	 (for pk packages true
	    (set (in pk tr))))))

(observed
   (for tr trucks true
      (for pl places true
	 (for pk packages true
	    (and (Pre (load pk tr pl) (at tr pl))
	       (Pre (load pk tr pl) (at pk pl))
	       (Pre (unload pk tr pl) (in pk tr))
	       (Pre (unload pk tr pl) (at tr pl))
	       (Add (load pk tr pl) (in pk tk))
	       (Add (unload pk tr pl) (at pk pl))
	       (Del (load pk tr pl) (at pk pl))
	       (Del (unload pk tr pl) (in pk tr))))))
   
   (for tr truck true
      (for pl1 pl2 places (neq pl1 pl2)
	 (and (Pre (drive tr pl1 pl2) (at tr pl1))
	    (Add (drive tr pl1 pl2) (at tr pl2))
	    (Del (drive tr pl1 pl2) (at tr pl1)))))
   )

;; Initial and goal states

(type initial-state
   (set
      (at (package 1) (place 1))
      (at (package 2) (place 2))
      (at (package 3) (palce 3))
      (at (truck 1) (place 1))
      (at (truck 2) (place 2))))

(type goal-state
   (set
      (at (package 1) (place 2))
      (at (package 3) (place 2))
      (at (package 2) (place 1))))
      

;; SATPLAN Parallel Execution Semantics

(all s actslices true
   ;; Actions imply their preconditions
   (all act actions true
      (all flu fluents (Pre act flu)
	 (implies (Occurs act s)
	    (Holds flu s))))

   ;; Actions imply their effections
   (all act actions true
      (all flu fluents (Add act flu)
	 (implies (Occurs act s)
	    (Holds flu (+ s 1)))))
   (all act actions true
      (all flu fluents (Del act flu)
	 (implies (Occurs act s)
	    (not (Holds flu (+ s 1))))))

   ;; Interferring actions are mutually exclusive
   ;;   a2 interferes with a1 if a2 deletes a precondition or effect of a1
   ;;   where a1 and a2 are not equal.  Note that inequality is required
   ;;   because an action may delete its own precondition.
   (all (a1 a2) actions (neq a1 a2)
      (all flu (and (or (Pre a1 flu) (Add a2 flu)) (Del a2 flu))
	 (or (not (Occurs (a1 s)) (not (Occurs (a2 s)))))))

   ;; Frame axioms
   (all flu fluents true
      (implies (and (Holds flu s) (not (Holds flu s)))
	 (exists a actions (Del a flu)
	    (Occurs a s))))

   (all flu fluents true
      (implies (and (not (Holds flu s) (Holds flu s)))
	 (exists a actions (Add a flu)
	    (Occurs a s))))
   )

;; Initial state is completely specified
(all f initial-state true
   (Holds f 1))
(all f (set-difference fluents initial-state) true
   (not (Holds f 1)))

;; Goal state is partially specified
(all f goal-state true
   (Holds f numslices))





	       








	       '

