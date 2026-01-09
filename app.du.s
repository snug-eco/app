jsr main
brk


use lib.sys.s
use lib.mem.s
use lib.string.s
use lib.args.s

var _iter
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

    ; open file
    ldv _name
    jsr sys/file/seek
    jsr sys/file/size

    ; convert and print
    jsr string/from-int

    dup
    jsr string/print
    jsr string/newline

    jsr sys/heap/free

    brk


lab file-not-exist-error
    lit 100
    jsr sys/heap/alloc
    dup
    str "du error: no such file "
    dup
    jsr string/print
    ldv _name
    jsr string/print
    jsr string/newline
    brk

lab no-file-error
    lit 100
    jsr sys/heap/alloc
    dup
    str "du error: no file name provided"
    jsr string/print
    jsr string/newline
    brk


    
