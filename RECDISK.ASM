                .286

                INCLUDE RECDISK.MAC

                .MODEL  SMALL
                .CODE

                EXTRN   RecFILE     :NEAR
                EXTRN   CmpFILE     :NEAR
                EXTRN   RecordALL   :BYTE

                ASSUME  ds:_TEXT

                ORG     2Ch
EnvironSegment  LABEL   WORD            ; Segment of Environment
                ORG     80h
ParmLength      LABEL   BYTE            ; Length of Parameter
                ORG     81h
ParmString      LABEL   BYTE            ; String of Parameter

                ORG     100h


; ========  M A I N    P R O G R A M  =========================

main            PROC    FAR             ; Main Program

                cld

                mov     ax, cs
                mov     ds, ax

                PRINT   Copyright

                mov     bx, 1000h
                IntDOS  4Ah             ; Change Memory Size => 64k
                jc      AllocFAIL
                mov     bx, 1000h
                IntDOS  48h             ; Allocate 64k memory
                mov     FreeMemSegm, ax
                jnc     AllocOK

AllocFAIL:      PRINT   AllocERR
                IntDOS  4C01h           ; Out of memory, Abnormal Terminate !

AllocOK:

;
; ======  Get RECDisk file path name  ==================
;

                push    es

                mov     ax, es:[EnvironSegment]
                mov     es, ax
                xor     ax, ax
                mov     di, ax
                mov     cx, 0FFFFh
Find_Two_Zero:  repnz   scasb
                scasb
                jnz     Find_Two_Zero
                repnz   scasb

                mov     bx, es
                mov     ax, ds
                mov     si, di
                mov     di, OFFSET RecordFile

                push    ds

                mov     ds, bx
                mov     es, ax

Get_File_Name:  lodsb
                cmp     al, '.'
                stosb
                jnz     Get_File_Name

                pop     ds

                mov     al, '('
                stosb

                IntDOS  19h             ; Get Current Disk Driver number
                mov     DrvNUMBER, al

                pop     es

                push    di

;
; ======================================================
;
                mov     dl, DrvNUMBER
                mov     ah, 0Eh
                int     21h
                mov     dl, al

                xor     ch, ch
                mov     cl, BYTE PTR es:[ParmLength]
                mov     si, cx
;
                lea     di, ParmString
                add     si, di
                mov     BYTE PTR es:[si], 0

Analy_Parm:     mov     al, ' '
                repz    scasb
                jz      No_More_Char
                dec     di
                cmp     BYTE PTR es:[di], '-'
                jz      Options

                cmp     WORD PTR es:[di], '?'
                jnz     NotHelp
                mov     BYTE PTR RECDiskType, 2
                jmp     SHORT No_More_Char
NotHelp:

                cmp     BYTE PTR es:[di][1], ':'
                jnz     No_More_Char
                cmp     BYTE PTR es:[di][2], ' '
                jz      DriverTesting
                cmp     BYTE PTR es:[di][2], 0
                jnz     No_More_Char
DriverTesting:  mov     al, es:[di]
                and     al, 0DFh
                sub     al, 'A'
                cmp     al, dl
                jnc     No_More_Char

                mov     DrvNUMBER, al
                cmp     BYTE PTR es:[di][2], 0
                jz      No_More_Char
                inc     di
                inc     di
                dec     cx
                dec     cx
                jmp     Analy_Parm

Options:        inc     di
                push    di

                lea     si, RecArgu
                mov     cx, RecArguLEN
                rep     cmpsb
                pop     di
                jnz     CmpNextArgu

                mov     BYTE PTR RECDiskType, 1

CmpNextArgu:    lea     si, RecArgu2
                mov     cx, RecArguLEN2
                rep     cmpsb
                jnz     No_More_Char

                mov     BYTE PTR RECDiskType, 1
                mov     BYTE PTR RecordALL, 1

No_More_Char:   mov     al, DrvNUMBER
                add     al, 'A'
                mov     WorkingDRV, al
                mov     SpecialMark[5], al
                mov     RecordFileA[9], al

                pop     di

                push    es

                mov     bx, ds
                mov     es, bx
                stosb
                mov     al, ')'
                stosb
                xor     al, al
                stosb
                pop     es

                mov     al, RECDiskType
                dec     al
                jz      RecFileOpt

                dec     al
                jnz     CmpFileOpt

                lea     dx, HelpMenu
                IntDOS  09h
                jmp     SHORT Exit

CmpFileOpt:     call    CmpFILE
                jmp     SHORT Exit

RecFileOpt:     call    RecFILE

Exit:           IntDOS  4C00h

main            ENDP


;  ============ Data Area  AND  Stack Area ====================

                PUBLIC  RecordFile, RecordFileA, FileNameLEN
                PUBLIC  FreeMemSegm, WorkingDRV

RECDiskType     DB      0

RecordFile      DB      80 DUP(0)
RecordFileA     DB      'RECDISK.(C)'
FileNameLEN     EQU     $ - RecordFileA


FreeMemSegm     DW      ?               ; Segment of Free Memory (128k)
WorkingDRV      DB      ?               ; Working Disk Driver
Copyright       DB      13
                DB      'RECDisk v', VERSION, '  á-release (c) 1991 by Lalena Lab.  written by  Jiann-Ching Liu.', 13, 10, 10, '$'
AllocERR        DB      'This program require 128k memory !!', 13, 10, '$'

                PUBLIC  TabPointer, SpecialMark, DataTransArea, ExeComSysBin
                PUBLIC  WildName, WildNameLen, Stream, DrvNUMBER

DataTransArea   DD      ?
TabPointer      DW      0
Stream          DW      ?
DrvNUMBER       DB      ?
ExeComSysBin    DB      'SYS',0, 'COM',0, 'EXE',0, 'BIN',0, 'OVL',0, 0
WildName        DB      '\*.*', 0
WildNameLen     EQU     $ - WildName
SpecialMark     DB      0, 0, 0, 18, 0
                DB      'C:', 11 DUP(0)

RecArgu         DB      'Record', 0
RecArguLEN      EQU     $ - RecArgu

RecArgu2        DB      'Recall', 0
RecArguLEN2     EQU     $ - RecArgu2

        IF  PRIVATE EQ 0
HelpMenu        DB      'usage : RECDISK [d:] [options]', 13, 10, 10
                DB      'options are :', 13, 10
                DB      '    -Record : Record executable files only', 13, 10
                DB      '    -Recall : Record all files', 13, 10, '$'
        ELSE
HelpMenu        DB      'usage : RECDISK [d:] [options]', 13, 10, '$'
        ENDIF
                END     main
