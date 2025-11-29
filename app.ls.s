jsr main
brk

use lib.mem.s
use lib.quad.s
use lib.heap.s
use lib.string.s

var _iter
var _file


lab main
    lit 4    
    jsr heap/new
    stv _iter
    lit 4    
    jsr heap/new
    stv _file


lab loop
    ; copy iter to file
    ldv _file
    ldv _iter
    lit 4
    jsr mem/cpy

    ; check flag
    ldv _file
    s02 ; disk read
     
    ; end of file block stream
    dup
    lit 0
    equ
    jcn done

    ; invalid file
    lit 176 ; present and active flag
    neq
    jcn next-file

    ; skip flag
    ldv _file
    jsr quad/inc

lab print-name-loop
    ; read name char
    ldv _file
    s02 ; disk read

    ; check termi
    dup
    lit 0
    equ 
    jcn print-name-done

    ; print
    out

    ; inc ptr
    ldv _file
    jsr quad/inc

    ;again
    jmp print-name-loop

lab print-name-done
    pop ; char
    jsr string/newline

lab next-file
    ldv _iter
    s07 ; fs_next

    jmp loop

lab done
    brk








