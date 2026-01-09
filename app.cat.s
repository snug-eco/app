jsr main
brk


use lib.sys.s
use lib.mem.s
use lib.string.s
use lib.args.s

var _iter
var _end
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
    jsr sys/file/open
    stv _iter

lab loop
    ; read char
    ldv _iter
        inc
        stv _iter
    jsr sys/disk/read

    dup
        not
        jcn done

    dup
        out

    ; scan for lf 
    lit 10
    equ
    jcn linefeed

    jmp loop

lab done
    pop
    ret

lab linefeed
    ; suppliment lf with cr
    lit 13
    out

    jmp loop


lab file-not-exist-error
    lit 100
    jsr sys/heap/alloc
    dup
    str "cat error: no such file "
    jsr string/print

    ldv _name
    jsr string/print

    jsr string/newline
    brk

lab no-file-error
    lit 100
    jsr sys/heap/alloc
    dup
    str "cat error: no file name provided"
    jsr string/print
    jsr string/newline
    brk




    



