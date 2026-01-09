jmp main

var _buffer

use lib.sys.s
use lib.mem.s
use lib.string.s

lab main
    ; message
    lit 100
    jsr sys/heap/alloc
    stv _buffer

    ldv _buffer
    str "[INIT] Initializing root processes... "
    ldv _buffer
    jsr string/print
    jsr string/newline

lab register
    ldv _buffer
    str "bin.shell"
    jsr init

    brk





lab init
    ldv _buffer
    jsr string/print
    jsr string/newline

    ldv _buffer
    jsr sys/file/check
    jcn init-good
    ret

lab init-good
    ldv _buffer
    jsr sys/file/seek

    jsr sys/proc/launch
    ret






