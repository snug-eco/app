jsr main
brk


use lib.quad.s
use lib.mem.s
use lib.heap.s
use lib.string.s
use lib.args.s

var _iter
var _name

lab main
    lit 4
    jsr heap/new
    stv _iter

    ; file name
    jsr args/get
    stv _name

    ; check arg provided
    ldv _name
    lit 0
    equ
    jcn no-file-error

    ; check file exists
    ldv _name
    s04 ; fs_check
    lit 0
    equ
    jcn file-not-exist-error

    ; seek file
    ldv _iter
    ldv _name
    s05 ; fs_seek

    ; get size
    ldv _iter
    s10 ; fs_size

    ; convert and print
    jsr string/from-int

    dup
    jsr string/print
    jsr string/newline

    jsr heap/void

    brk


lab file-not-exist-error
    lit 80
    jsr heap/new
    dup
    str "du error: no such file "
    dup
    jsr string/print
    ldv _name
    jsr string/print
    jsr string/newline
    brk

lab no-file-error
    lit 0 
    str "du error: no file name provided"
    lit 0
    jsr string/print
    jsr string/newline
    brk


    
