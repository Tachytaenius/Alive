# Threads

Threads use constants for their channel names which are passed as arguments to the threads and used from `consts.lua` in the main thread, as well as the quit channel's name (which comes first).
For per-sub-world threads (and so per-sub-world channels) these are concatenated with the sub-world's ID, except for the quit channel which is universal.
All threads must be killable by peeking (but not popping) `"quit"` from the quit channel, which is pushed in `boilerplate.killThreads`.
Every time a thread is added, it must be added to `util/iterateOverAllThreads.lua` to make sure that it can be killed and checked for errors.

There is one chunk loading/generating thread per sub-world.
