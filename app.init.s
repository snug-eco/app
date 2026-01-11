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

    ;prefix and write pid
    ldv _buffer
    str "pid"
    lit 46 ;fix dot
        ldv _buffer
        lit 3
        add
        sta


    ldv _buffer
    jsr sys/file/check
    not
    jcn init-skip-pid-rm
        ldv _buffer ; remove old pid file
        jsr sys/file/seek
        jsr sys/file/delete
    lab init-skip-pid-rm

    ldv _buffer
    jsr string/print
    jsr string/newline

    ldv _buffer
    lit 1
    jsr sys/file/create
    jsr sys/file/open
    swp
    jsr sys/disk/write
    jsr sys/flush-disk-cache

    ret






