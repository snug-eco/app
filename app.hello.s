jsr main
brk

use lib.sys.s
use lib.string.s

lab main
    lit 100
    jsr sys/heap/alloc
    dup
    str "hello world"
    jsr string/print
    jsr string/newline
    ret
