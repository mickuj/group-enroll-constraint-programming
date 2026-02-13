# 🎓 Group Enroll – Constraint Optimization Model

## Project Overview

This project presents a **constraint programming optimization model** for assigning students to university groups under real-world constraints and preferences.

The problem is inspired by the group enrollment system at AGH University and focuses on generating an optimal assignment that balances:

- schedule feasibility,
- student preferences,
- avoidance of time conflicts,
- minimization of wasted time between classes.

The model was implemented using **MiniZinc** as part of an advanced constraint optimization course.

---

## Problem Description

Each student must be assigned to **exactly one group per class** (unless they do not attend the class). The assignment must satisfy multiple constraints:

### Hard Constraints

- No student can attend two conflicting groups.
- Group capacity limits must not be exceeded.
- A student must attend exactly one group per class (unless all options are excluded).
- Transport time between buildings must allow feasible transitions.
- Preprocessed conflict matrix defines overlapping groups.

---

## Optimization Objective

The objective is to:

> Minimize the **sum of squared total disappointments** across all students

Each student's total disappointment consists of:

### Break Disappointment  
Measures how much time a student wastes between classes.

For each student:
- Compute total time spent at university per day.
- Subtract actual learning time.
- Normalize wasted time to full hours.
- Sum across the week.

### Preference Disappointment  
Measures how far assigned groups are from the student's favorite choices.

For each student and class:
- Compute difference between best available group and assigned group.
- Sum across all classes.

### Weighted Combination

Each student has a break importance weight (0–5).  
Total disappointment is calculated as:

```
ceil_div(
    break_importance × break_disappointment +
    (10 - break_importance) × preference_disappointment,
    10
)
```

This ensures equal impact of every student in the global objective.

Finally:

```
objective = sum(student_total_disappointment^2)
```

Squaring penalizes highly dissatisfied students more heavily.

---

## Model Components

The model includes:

- Sets:
  - `Students`
  - `Groups`
  - `Classes`
  - `Days`
  - `Time`

- Parameters:
  - group schedule (day, start time, duration)
  - class capacities
  - conflict matrix
  - student preferences
  - break importance weights

- Decision Variables:
  - Assignment of students to groups

- Derived Metrics:
  - Break disappointment
  - Preference disappointment
  - Total disappointment

---

## Technologies Used

- **MiniZinc** – constraint modeling language
- **Gurobi 13.0 Optimizer (MIP backend)**
- Constraint Programming (CP)
- Discrete optimization techniques
- Multi-criteria objective modeling

### Execution Command
```
minizinc --solver gurobi --gurobi-dll "C:\gurobi1300\win64\bin\gurobi130.dll" -p 20 enroll.mzn data/competition.dzn
```
or with warm start:
```
minizinc --solver gurobi --gurobi-dll "C:\gurobi1300\win64\bin\gurobi130.dll" -p 20 enroll.mzn data/competition.dzn data/warmstart.dzn
```

---

## Why This Project Matters

Group assignment problems are a real-world example of:

- combinatorial explosion,
- constraint satisfaction,
- multi-objective optimization,
- fairness modeling,
- scheduling under uncertainty.

This project demonstrates practical use of constraint programming for solving complex institutional scheduling problems.

---

## Authors

Developed collaboratively as part of coursework in constraint optimization and modeling.





