
var _file
var _name

lab init-shell
    lit 0
    stv _file
    lit 4
    stv _name

    ldv _name
    str "bin.shell"

    ldv _name
    s04 ; fs_check
    lit 0
    equ
    jcn done-shell

    ldv _file
    ldv _name
    s05 ; fs_seek

    ldv _file
    s11 ; vm_launch
lab done-shell






