I would like you to build a ruby gem.  
The gem can be called rralph.
The idea is to have a loop in ruby doing something similar to:

```
echo "Orignal plan: @plan.md , Learnings: @learnings.md , todo list: @todo.md . Continue to process the remaining tasks that are in the todo list. For each task, write a unit test. If the test fails after implementation, return FAILURE, if the test passes, update the todo list to mark the current task as done. If you learn something new during your work, add it to learnings.md" | qwen-code -y
```

Every time this runs, we want to check if the text returned is FAILURE or not, if it's failure, we want to increment a max-failure counter by one. The max-failure counter should be reset to zero if the response is not FAILURE. The user should be able to have a --max-failures option to set the max number of failures per loop.  
If we get to the max failure count, we stop the whole program.

During that whole process, I want to add a git commit of all changes in the repo at each sucessful iteration.
