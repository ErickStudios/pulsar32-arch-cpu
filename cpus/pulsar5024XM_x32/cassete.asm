; =====================================
;       BOOTSECTOR CODE
;
; el codigo de inicio del disco
; =====================================

Assume-Org              0x4FFF          ; donde el bios guarda el codigo del bootsector

; =================== cargador de sectores ===================
LOADED_SECTOR_ADDR      Equ 0x4FFF      ; donde inicia el sector
LLBASEC_SECT_PTR        Equ 29197       ; el parametro de funcion de no se que

; =================== parametros de memcpy ===================
mcpy_src                Equ 29184       ; source
mcpy_dst                Equ 29188       ; destino
mcpy_siz                Equ 29192       ; source

; =================== variables para el stage2 ===================
SECTOR_READ_MMIO        Equ 64010       ; sector mmio
S1                      Equ 95001       ; zona segura para el stage2

; =================== tabla de particion ===================
_start:
    Jmp-Word-Clasic     _l              ; jump label
    Align               8               ; o
    Byte                'C','A','S','S','E','T','E','0',' ',' ',' ',' '
    Dword               0               ; cantidad de sectores, 0=indefinido
    Byte                'F','L','A','T','2',' ',' ',' ' ; nombre del fs

; =================== codigo fuente ===================
_l:
    ; copiar el sector
    Mov                 [Dword mcpy_src], Dword 0x4FFF ; fuente
    Mov                 [Dword mcpy_dst], Dword S1 ; destino
    Mov                 [Dword mcpy_siz], Dword 512 ; tamaño
    Int-Byte            0x13            ; el int
    jmp                 [C1 In S1] ; saltar
C1:
    ; imprimir identificador
    Ror-Byte            Ax, 1Eh         ; el servicio
    Ror-Dword           Bx, msg         ; la frase
    Int-Byte            10h             ; el int

    ; leer sector
    Ror-Byte            Ax, 02h         ; funcion
    Ror-Byte            Bx, 1           ; sector
    Ror-Byte            Cx, 00h         ; fs
    Ror-Dword           Dx, 024000h     ; memoria
    Int-Byte            12h             ; el int
    jmp                 024000h         ; sector2
    
msg:
    Assume-Byte         'm','m','f','s','0',0

; =====================================
;       STAGE2 CODE
;
; el codigo de la etapa 2 del arranque
; del disco
; =====================================

    Align               512
Stage2Sector:
    jmp                 [024000h Segment Stage2Sector:Stage2Data]
Stage2Data:
test:
    Assume-Byte 'm','m','f','s','1',0
Stage2Code:
    ; imprimir identificador
    Ror-Byte            Ax, 1Eh         ; el servicio
    Ror-Dword           Bx, [024000h segment Stage2Sector:test] ; la frase
    Int-Byte            10h             ; el int

    Ror-Byte            Ax, 02h         ; funcion
    Ror-Byte            Bx, 2           ; sector
    Ror-Byte            Cx, 00h         ; fs
    Ror-Dword           Dx, 041000h     ; memoria
    Int-Byte            12h             ; el int

    Ror-Byte            Ax, 03h         ; el servicio
    Ror-Dword           Bx, 041000h     ; direccion de la imagen
    Ror-Byte            Cx, 70h         ; X
    Ror-Byte            Dx, 70h         ; Y
    Int-Byte            10h             ; el int

LOOP:
    Hlt 
    Ror-Byte            Ax, 01h         ; funcion del teclado
    Int-Byte            16h             ; la int misceliana

    Ror-Byte            Ax, 0Eh         ; el putchar
    Ror-Byte            Bx, Ah         ; el caracter
    Int-Byte            10h             ; del display
    
    jmp                 [024000h segment Stage2Sector:LOOP] ; saltar

; =====================================
;       SRC/IMG/SPLASHLOGO.FD
;
; el logo splash de el cassete para el OS
; centro de juegos
; =====================================

    Align               512
LaSebollaLogo:
    Byte            008h,000h,001h,0B5h,020h,000h,0FFh,005h,000h,001h,0B5h,001h,000h,001h,0B5h,014h
    Byte            000h,001h,0B5h,00Ch,000h,0FFh,006h,000h,001h,0B5h,00Ch,000h,007h,0FDh,001h,000h
    Byte            004h,0B5h,005h,000h,004h,0FDh,001h,000h,0FFh,014h,000h,006h,0FDh,001h,000h,004h
    Byte            0B5h,005h,000h,004h,0FDh,001h,000h,0FFh,005h,000h,004h,0B5h,00Bh,000h,005h,0FDh
    Byte            002h,000h,004h,0B5h,005h,000h,004h,0FDh,001h,000h,0FFh,005h,000h,004h,0B5h,004h
    Byte            000h,003h,0FDh,00Bh,000h,004h,0B5h,007h,000h,001h,0FDh,002h,000h,0FFh,005h,000h
    Byte            004h,0B5h,004h,000h,004h,0FDh,018h,000h,0FFh,001h,0B5h,00Ch,000h,003h,0FDh,005h
    Byte            000h,002h,0B5h,007h,000h,002h,0B5h,002h,000h,002h,0FDh,005h,000h,0FFh,001h,0B5h
    Byte            014h,000h,002h,0B5h,007h,000h,002h,0B5h,002h,000h,002h,0FDh,004h,000h,001h,0B5h
    Byte            0FFh,001h,0B5h,014h,000h,003h,0B5h,007h,000h,001h,0B5h,002h,000h,002h,0FDh,004h
    Byte            000h,001h,0B5h,0FFh,001h,0B5h,004h,000h,001h,0BDh,001h,0FDh,003h,000h,005h,0B5h
    Byte            001h,000h,004h,0FDh,001h,0BDh,005h,0B5h,003h,0FDh,001h,000h,002h,0B5h,002h,000h
    Byte            002h,0FDh,002h,000h,003h,0B5h,0FFh,001h,0B5h,004h,000h,002h,0FDh,003h,000h,001h
    Byte            0B5h,003h,000h,001h,0B5h,001h,000h,001h,0FDh,002h,000h,002h,0FDh,001h,0B5h,003h
    Byte            000h,001h,0B5h,003h,0FDh,001h,000h,002h,0B5h,002h,000h,002h,0FDh,001h,000h,003h
    Byte            0B5h,001h,000h,0FFh,001h,0B5h,003h,000h,001h,0BDh,002h,0FDh,003h,000h,003h,0B5h
    Byte            002h,000h,001h,0BDh,001h,0FDh,002h,000h,001h,0FDh,001h,0BDh,001h,0B5h,003h,000h
    Byte            001h,0B5h,001h,0FDh,001h,000h,002h,0FDh,002h,0B5h,002h,000h,001h,0FDh,001h,0BDh
    Byte            001h,000h,001h,0B5h,001h,000h,001h,0B5h,001h,000h,0FFh,001h,0B5h,003h,000h,002h
    Byte            0FDh,001h,000h,001h,0FDh,005h,000h,002h,0B5h,001h,0BDh,003h,0FDh,001h,000h,001h
    Byte            0BDh,001h,0B5h,003h,000h,001h,0B5h,001h,0FDh,001h,000h,002h,0FDh,002h,0B5h,002h
    Byte            000h,002h,0FDh,001h,000h,001h,0B5h,001h,000h,001h,0B5h,001h,000h,0FFh,004h,0B5h
    Byte            004h,0FDh,002h,000h,001h,0B5h,003h,000h,001h,0B5h,002h,0FDh,003h,000h,001h,0FDh
    Byte            001h,0B5h,002h,000h,002h,0B5h,004h,0FDh,002h,0B5h,002h,000h,002h,0FDh,001h,000h
    Byte            001h,0B5h,001h,000h,001h,0B5h,001h,000h,0FFh,001h,000h,002h,0B5h,001h,000h,001h
    Byte            0BDh,003h,0FDh,002h,000h,005h,0B5h,001h,000h,004h,0FDh,001h,0BDh,005h,0B5h,003h
    Byte            0FDh,002h,000h,003h,0B5h,003h,0FDh,004h,0B5h,0FFh,029h,000h,0FFh,009h,000h,001h
    Byte            0FDh,010h,000h,001h,0FDh,006h,000h,005h,0B5h,003h,000h,0FFh,001h,000h,004h,0FDh
    Byte            003h,000h,003h,0FDh,00Eh,000h,003h,0FDh,005h,000h,005h,0B5h,003h,000h,0FFh,001h
    Byte            000h,004h,0FDh,002h,000h,005h,0FDh,00Dh,000h,003h,0FDh,005h,000h,005h,0B5h,003h
    Byte            000h,0FFh,001h,000h,004h,0FDh,003h,000h,003h,0FDh,00Eh,000h,003h,0FDh,005h,000h
    Byte            005h,0B5h,003h,000h,0FFh,009h,000h,001h,0FDh,005h,000h,003h,0B5h,010h,000h,002h
    Byte            0B5h,005h,000h,0FFh,00Fh,000h,003h,0B5h,017h,000h,0FFh,000h