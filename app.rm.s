jsr main
brk


use lib.sys.s
use lib.mem.s
use lib.string.s
use lib.args.s

var _name

lab main
    ; file name
    jsr args/get
    stv _name

    ; check arg provided
    ldv _name
    not
    jcn no-file-error

    ; check file exists
    ldv _name
    jsr sys/file/check
    not
    jcn file-not-exist-error

    ; seek file
    ldv _name
    jsr sys/file/seek
    jsr sys/file/delete

    brk


lab file-not-exist-error
    lit 100
    jsr sys/heap/alloc
    dup
    str "rm error: no such file "
    jsr string/print
    ldv _name
    jsr string/print
    jsr string/newline
    brk

lab no-file-error
    lit 100
    jsr sys/heap/alloc
    dup
    str "rm error: no file name provided"
    jsr string/print
    jsr string/newline
    brk


    
