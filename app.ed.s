jsr main
brk


use lib.sys.s
use lib.mem.s
use lib.string.s
use lib.args.s
use lib.line.s

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
var _line_no
var _file_end
var _target_end

lab main
    ; line buffer
    lit 80
    jsr sys/heap/alloc
    stv _buffer

    ; read file name argument
    jsr args/get
    stv _filename

    ; check present
    ldv _filename
    not
    jcn no-file-error

    ; check file
    ldv _filename
    jsr sys/file/check
    not
    jcn file-not-exist-error

    ; open file
    ldv _filename
    jsr sys/file/seek
    jsr sys/file/open
    stv _file

    ; cursor
    lit 0
    stv _cursor
 
lab loop
    ; clear buffer
    lit 0
    ldv _buffer
    sta

lab loop-no-buffer-clear
    ; make sure start of paramater is terminated
    lit 0 
    ldv _buffer
    lit 2
    add
    sta

    ; prompt
    lit 64
    out
    ldv _cursor
    jsr string/print-int-thou
    lit 32
    out

    ; read input
    ldv _buffer
    lit 80
    jsr line-resume

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
    dup
    lit 100 ;d
    equ
    jcn command-delete

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
    lit 1
    sub
    sta

    ; get end of file content
    ldv _line
    jsr seek-file-content-end
    stv _file_end

    ; compute target end
    ; meaning, the end address of the file after rcopy
    ldv _file_end
    ldv _content_len
    add
    stv _target_end

    ; reverse copy _file_end ptr to _target_end ptr.
    ; thus moving the file content after _line back by _content_len
lab command-insert/rcopy
    ;copy
    ldv _target_end
        ldv _file_end
        jsr sys/disk/read
    jsr sys/disk/write

    ; check bound
    ldv _file_end
    ldv _line
    equ
    jcn command-insert/rdone

    ;dec
    ldv _file_end
        lit 1
        sub
        stv _file_end
    ldv _target_end
        lit 1
        sub
        stv _target_end

    jmp command-insert/rcopy
lab command-insert/rdone
    
    ; insert content into line
lab command-insert/fcopy
    ;copy
    ldv _content
        dup
        inc
        stv _content
    lda
    ldv _line
        dup
        inc
        stv _line
    jsr sys/disk/write

    ; check
    ldv _content_len
        dup
        lit 1
        sub
        stv _content_len
    jcn command-insert/fcopy

    ; setup buffer for another insertion
    jmp loop-no-buffer-clear





lab command-delete
    ; cursor bounds check
    ldv _cursor
    lit 0
    equ
    jcn loop

    ; grab line
    ldv _cursor
    jsr seek-line
    stv _line

    ; get end of file content
    ldv _line
    jsr seek-file-content-end
    stv _file_end

    ; origin address 
    ldv _line
    stv _ptr

    ldv _ptr
    jsr next-line
    stv _ptr


lab command-delete/loop
    ; copy from _ptr to _line
    ldv _line
            dup
            inc
            stv _line
        ldv _ptr
            dup
            inc
            stv _ptr
        jsr sys/disk/read
    jsr sys/disk/write

    ; bounds.
    ; bounds check has to happen after copy,
    ; to ensure valid terminator.
    ldv _ptr
    ldv _file_end
    equ
    jcn command-delete/done

    jmp command-delete/loop
lab command-delete/done
    jmp loop
    









lab command-enum
    ldv _file
    stv _ptr

    ; line number counter
    lit 0
    stv _line_no

    lit 10
    out
lab command-enum/line-loop
    ;cr (hackyyyyy)
    lit 13
    out

    ; inc line number count
    ldv _line_no
    inc
    dup
    stv _line_no

    ;print line no
    jsr string/print-int-thou
    lit 32
    out


lab command-enum/char-loop
    ldv _ptr
        dup
        inc
        stv _ptr
    jsr sys/disk/read

        ; null
        dup
        not
        jcn command-enum/done

        ; output
        dup
        out

        ; linefeed
        lit 10
        equ
        jcn command-enum/line-loop

    jmp command-enum/char-loop

lab command-enum/done
    pop
    jsr string/newline
    jsr string/newline

    jmp loop



    



    


; --- routines ---

; ( *ptr -- *end )
; given pointer into file content,
; seek end of (null terminated) content.
; returned ptr points to null terminator!
lab seek-file-content-end
    stv _ptr

lab seek-file-content-end/loop
    ; bounds
    ldv _ptr
        dup
        inc
        stv _ptr
    jsr sys/disk/read
    jcn seek-file-content-end/loop

    ldv _ptr
    ret
    




; ( n -- *ptr )
; given the line number (zero indexed),
; returns a pointer to the base address of
; the line in the _file with that number.
lab seek-line
    stv _n

    ldv _file
    stv _ptr

lab seek-line/loop
    ; dec and check countdown
    ldv _n
    lit 1
    sub
        dup
        stv _n

    jcn seek-line/done

    ;next line
    ldv _ptr
    jsr next-line
    stv _ptr

    jmp seek-line/loop
lab seek-line/done

    ldv _ptr
    ret

    


; ( ptr -- ptr )
; advances a pointer by one line in a file,
; assuming it points to the base address of the
; preceeding line.
lab next-line
    stv _ptr

lab next-line/loop 
    ; check linefeed 
    ldv _ptr
        dup
        inc
        stv _ptr
    jsr sys/disk/read
    lit 10 ;linefeed
    equ
    jcn next-line/done

    jmp next-line/loop
lab next-line/done

    ldv _ptr
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



