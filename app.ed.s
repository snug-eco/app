jsr main
brk


use lib.mem.s
use lib.quad.s
use lib.heap.s
use lib.string.s
use lib.args.s
use lib.line.s
use lib.disk.s

var _filename
var _buffer
var _iter
var _ptr
var _cursor
var _content
var _content_len
var _n
var _file
var _line
var _tmp
var _line_no
var _file_end
var _target_end

lab main
    ; line buffer
    lit 80
    jsr heap/new
    stv _buffer

    ; read file name argument
    jsr args/get
    stv _filename

    ; check present
    ldv _filename
    lit 0
    equ
    jcn no-file-error

    ; check file
    ldv _filename
    s04
    lit 0
    equ
    jcn file-not-exist-error

    ; open file
    lit 4
    jsr heap/new
    dup
    stv _file
    ldv _filename
    s05
    ldv _file
    s06

    ; cursor
    lit 0
    stv _cursor
 
lab loop
    ; prompt
    lit 64
    out
    ldv _cursor
    jsr string/from-int
    dup
    jsr string/print
    jsr heap/void
    lit 32
    out

    ; read input
    ldv _buffer
    lit 80
    jsr line

    ; first character
    ldv _buffer
    lda

    ; quit
    dup
    lit 113 ;q
    equ
    jcn command-quit

    ; goto
    dup
    lit 103 ;g
    equ
    jcn command-goto

    ; insert after
    dup
    lit 105 ;i
    equ
    jcn command-insert

    ; delete
    ;dup
    ;lit 100 ;d
    ;equ
    ;jcn command-delete

    ; change
    ;dup
    ;lit 99 ;c
    ;equ
    ;jcn command-change

    ; enumerate
    dup
    lit 110 ;n
    equ
    jcn command-enum

    ; print line
    ;dup
    ;lit 112 ;p
    ;equ
    ;jcn command-print

    pop
    jmp loop


lab command-quit
    brk

lab command-goto
    ldv _buffer
    lit 2
    add
    jsr string/to-int
    stv _cursor
    jmp loop


lab command-insert
    ;insert after
    ; -> pre inc
    ldv _cursor
    inc
    stv _cursor

    ; grab line
    ldv _cursor
    jsr seek-line
    stv _line

    ; compute content buffer
    ldv _buffer
    lit 2
    add
    stv _content

    ;get length of line
    ldv _content
    jsr string/len
    inc ; linefeed
    stv _content_len

    ;insert newline into buffer
    lit 10
    ldv _content
    ldv _content_len
    add
    sta

    ; get end of file content
    ldv _line
    jsr seek-file-content-end
    stv _file_end

    ; compute target end
    ; meaning, the end address of the file after rcopy
        lit 4
        jsr heap/new
        stv _target_end

        ;copy
        ldv _target_end
        ldv _file_end
        lit 4
        jsr mem/cpy

        ;advance by line length
        ldv _target_end
        ldv _content_len
        s18

    ldv _file_end
    jsr quad/print
    ldv _target_end
    jsr quad/print
    brk

    ; reverse copy _file_end ptr to _target_end ptr.
    ; thus moving the file content after _line back by _content_len
lab command-insert/rcopy
    ; check bound
    ldv _file_end
    ldv _line
    s17 ;quad/compare
    jcn command-insert/rdone

    ;copy
    ldv _file_end
    s02 ;sd_read

    ldv _target_end
    swp
    s03

    ;inc
    ldv _file_end
    s19
    ldv _target_end
    s19

    jmp command-insert/rcopy
lab command-insert/rdone
    
    ;insert content
    ldv _line
    ldv _content
    ldv _content_len
    jsr disk/write

    ;clean up
    ldv _line
    jsr heap/void
    ldv _file_end
    jsr heap/void
    ldv _target_end
    jsr heap/void

    jmp loop


lab command-enum
    lit 4
    jsr heap/new
    stv _tmp

    ldv _tmp
    ldv _file
    lit 4
    jsr mem/cpy

    ; line number counter
    lit 0
    stv _line_no

lab command-enum/line-loop
    ;newline (hackyyyyy)
    jsr string/newline

    ; inc line number count
    ldv _line_no
    inc
    dup
    stv _line_no

    ;print line no
    jsr string/from-int
    dup
    jsr string/print
    jsr heap/void
    lit 32
    out


lab command-enum/char-loop
    ldv _tmp
    s02 ;sd_read

    ;inc ptr
    ldv _tmp
    s16

        ; null
        dup
        lit 0
        equ
        jcn command-enum/done

        ; linefeed
        dup
        lit 10
        equ
        jcn command-enum/line-loop

    out
    jmp command-enum/char-loop

lab command-enum/done
    jsr string/newline

    ldv _tmp
    jsr heap/void

    jmp loop



    



    


; --- routines ---

; ( *ptr -- *end )
; given pointer into file content,
; seek end of (null terminated) content.
; returned ptr points to null terminator!
lab seek-file-content-end
    lit 4
    jsr heap/new
    dup
    stv _ptr
    swp
    lit 4
    jsr mem/cpy

lab seek-file-content-end/loop
    ; bounds
    ldv _ptr
    s02
    lit 0
    equ
    jcn seek-file-content-end/done

    ;inc
    ldv _ptr
    s16

    jmp seek-file-content-end/loop
lab seek-file-content-end/done
    ldv _ptr
    ret
    




; ( n -- *ptr )
; given the line number (zero indexed),
; returns a pointer to the base address of
; the line in the _file with that number.
lab seek-line
    ; ptr
    lit 4
    jsr heap/new
    stv _ptr

    ; copy
    ldv _ptr
    ldv _file
    lit 4
    jsr mem/cpy

    stv _n

lab seek-line/loop
    ; check countdown
    ldv _n
    lit 1
    equ
    jcn seek-line/done

    ;next line
    ldv _ptr
    jsr next-line

    ; dec 
    ldv _n
    lit 1
    sub
    stv _n

    jmp seek-line/loop
lab seek-line/done
    ldv _ptr
    ret

    


; ( *ptr -- )
; advances a pointer by one line in a file,
; assuming it points to the base address of the
; preceeding line.
lab next-line
    stv _ptr

lab next-line/loop 
    ; check linefeed 
    ldv _ptr
    s02
    lit 10 ;linefeed
    equ
    jcn next-line/done
    
    ; inc ptr
    ldv _ptr
    s16

    jmp next-line/loop
lab next-line/done

    ; inc ptr
    ldv _ptr
    s16
    ret
    





; --- errors ---

lab file-not-exist-error
    lit _buffer
    str "editor error: no such file "
    lit _buffer
    jsr string/print
    ldv _filename
    jsr string/print
    jsr string/newline
    brk
    

lab no-file-error
    lit _buffer
    str "editor error: no file name provided"
    lit _buffer
    jsr string/print
    jsr string/newline
    brk












