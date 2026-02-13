% Parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
int: n_students;
int: n_days;
int: n_classes;
int: n_groups;
int: n_time_units_in_hour;
int: exclusion = -1;

set of int: Student = 1..n_students;
set of int: Class = 1..n_classes;
set of int: Group = 1..n_groups;
set of int: Day = 1..n_days;
set of int: Time = 0..n_time_units_in_hour * 24;
set of int: WorkTime = 0..max(Time)*n_days;
set of int: Preference = exclusion..max([student_prefers[s,g] | s in Student, g in Group]);

int: max_time = n_time_units_in_hour * 24;

array[Student] of 0..5: student_break_importance;
array[Student, Group] of int: student_prefers;

array[Class] of Time: class_duration;
array[Class] of int: class_size;

array[Group] of Class: group_class;
array[Group] of Time: group_start;
array[Group] of Day: group_day;
array[Group, Group] of bool: groups_conflicts;


% variables
array[Student, Group] of var bool: enrolles;
array[Student] of var int: time_at_uni;
array[Student] of var int: learning_time;
array[Student] of var int: break_disappointment;
array[Student] of var int: preference_disappointment;
array[Student] of var int: total_disappointment;
var int: objective;


% helpers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function var int: ceil_div(var int: x, var int: y) =
  x div y + ((x mod y) > 0);

% is the student allowed to take this class? 
array[Student, Class] of bool: student_can_take_class = array2d(Student, Class, [
    exists(g in Group where group_class[g] == c)(student_prefers[s,g] != exclusion)
    | s in Student, c in Class
]);

% max preference a student could possibly get for a specific class
array[Student, Class] of int: max_pref_per_class = array2d(Student, Class, [
    if student_can_take_class[s,c] then 
       max([student_prefers[s,g] | g in Group where group_class[g] == c])
    else 0 endif
    | s in Student, c in Class
]);

% constraints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
% group conflicts constraint - if groups_conflicts[i,j] == True then student may be enrolled to max. 1 of them
constraint forall(i,j in Group where i < j /\ groups_conflicts[i,j])(
    forall(s in Student)(enrolles[s,i] + enrolles[s,j] <= 1)
);

% group size constraint - no of students attending certain group cannot exceed its max capacity
constraint forall(g in Group)(
    sum(s in Student)(bool2int(enrolles[s,g])) <= class_size[group_class[g]]
);

% students group constraint - each student should attend 1 group per class (or 0 if they are excluded)
constraint forall(s in Student, c in Class)(
    sum(g in Group where group_class[g] == c)(bool2int(enrolles[s,g])) == bool2int(student_can_take_class[s,c])
);

% students group exclusion - when preference is equal to -1 student cannot attend certain group
constraint forall(s in Student, g in Group)(
    if student_prefers[s,g] == exclusion then enrolles[s,g] == false else true endif
);

% time constraints - arrays of days' starts and ends
array[Student, Day] of var int: day_start = array2d(Student, Day, [
    min([ if enrolles[s,g] then group_start[g] else max_time endif | g in Group where group_day[g] == d])
    | s in Student, d in Day
]);

array[Student, Day] of var int: day_end = array2d(Student, Day, [
    max([ if enrolles[s,g] then group_start[g] + class_duration[group_class[g]] else 0 endif | g in Group where group_day[g] == d])
    | s in Student, d in Day
]);

% learning time constraint - sum of all the classes duration student attends
array[Student, Day] of var int: day_learning = array2d(Student, Day, [
    sum(g in Group where group_day[g] == d)(bool2int(enrolles[s,g]) * class_duration[group_class[g]])
    | s in Student, d in Day
]);

% break disappointment constraint - wasted time: difference between total and learning times for each student
constraint forall(s in Student)(
    let {
        % Sum of (Time at Uni - Learning Time) for all days
        % max(0, day_end - day_start) handles days where the student has NO classes
        var int: total_wasted = sum(d in Day)(
             max(0, day_end[s,d] - day_start[s,d]) - day_learning[s,d]
        );
    } in
    break_disappointment[s] = ceil_div(max(0, total_wasted), n_time_units_in_hour)
);

% preference disappointment constraint - difference between signed and preferred group for each student
constraint forall(s in Student)(
    preference_disappointment[s] = sum(c in Class where student_can_take_class[s,c])(
        max_pref_per_class[s,c] - sum(g in Group where group_class[g] == c)(bool2int(enrolles[s,g]) * student_prefers[s,g])
    )
);

% total disappointment constraint - weighted sum of break disappointment and preference disappointment
constraint forall(s in Student)(total_disappointment[s] = 
    ceil_div(student_break_importance[s] * break_disappointment[s] + (10 - student_break_importance[s]) *       preference_disappointment[s], 10)
);

% objective constraint
constraint objective = sum([total_disappointment[s] * total_disappointment[s] | s in Student]);

%dla warm startu
% array[Student] of set of Group: start_assignment;

% array[Student, Group] of bool: enrolles_start =
%   array2d(Student, Group,
%     [ if g in start_assignment[s] then true else false endif
%       | s in Student, g in Group ]
%   );


solve 
% :: warm_start_array([
%         warm_start(enrolles, enrolles_start)
%      ])
minimize objective;  
  
output [
    "assignment = [", 
    join(",", [ 
        "{" ++ join(",", [show(g) | g in Group where fix(enrolles[s,g])]) ++ "}" 
        | s in Student
    ]), 
    "];\n",
    "total_break_disappointment = ", show(sum(break_disappointment)), ";\n",
    "total_preference_disappointment = ", show(sum(preference_disappointment)), ";\n",
    "objective = ", show(objective), ";"
];