jsr main
brk

use lib.sys.s
use lib.string.s

var _pid_name

lab main
    lit 10
    jsr sys/heap/alloc
    stv _pid_name

    ldv _pid_name
    str "pid.shell"

    ldv _pid_name
    jsr sys/file/check
    not
    jcn file-not-found-error

    ldv _pid_name
    jsr sys/file/seek
    jsr sys/file/open
    jsr sys/disk/read
        dup
        jsr string/print-int-thou
        jsr string/newline
    jsr sys/proc/kill
    brk


lab file-not-found-error
    lit 100
    jsr sys/heap/alloc
    dup
    str "exit error: pid.shell not found. shell doesn't seem to be running. (how are you running this??? did you delete the pid.shell file??? don't do that!)"
    jsr string/print
    jsr string/newline
    brk
    



