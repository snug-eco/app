jsr main
brk

use lib.sys.s
use lib.mem.s
use lib.string.s

var _iter
var _file


lab main
    lit 0
    stv _iter


lab loop
    ; copy iter to file
    ldv _iter
    stv _file

    ; check flag
    ldv _file
        dup ;preinc file ptr to skip flag byte
        inc
        stv _file
    jsr sys/disk/read
     
    ; end of file block stream
    dup
    not
    jcn done

    ; invalid file
    lit 176 ; present and active flag
    neq
    jcn next-file

lab print-name-loop
    ; read name char
    ldv _file
        dup
        inc
        stv _file
    jsr sys/disk/read

    ; check termi
    dup
    not
    jcn print-name-done

    ; print
    out

    ;again
    jmp print-name-loop

lab print-name-done
    pop ; char
    jsr string/newline

lab next-file
    ldv _iter
    jsr sys/file/next
    stv _iter

    jmp loop

lab done
    brk








