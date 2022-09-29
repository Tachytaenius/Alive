# Threads

Threads use constants for their channel names which are passed as arguments to the threads and used from `consts.lua` in the main thread, as well as the quit channel's name (which comes first).
For per-sub-world threads (and so per-sub-world channels) these are concatenated with the sub-world's ID, except for the quit channel which is universal.
All threads must be killable by reading (but not popping) `"quit"` from the quit channel, which is pushed in `boilerplate.killThreads`.
`boilerplate.killThreads` must wait for all threads in all systems in all sub-worlds and any above that to be completely shut down.
