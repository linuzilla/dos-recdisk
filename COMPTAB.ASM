                .286

                INCLUDE RECDISK.MAC


                .MODEL  SMALL
                .CODE

                EXTRN   WorkingDRV  :BYTE
                EXTRN   FreeMemSegm :WORD
                EXTRN   ExecuteFile :WORD
                EXTRN   GarbageColl :NEAR
                EXTRN   MissingFile :NEAR

                EXTRN   TabPointer     :WORD
                EXTRN   DataTransArea  :DWORD
                EXTRN   ExeComSysBin   :BYTE
                EXTRN   WildName       :BYTE
                EXTRN   WildNameLen    :ABS
                EXTRN   SpecialMark    :BYTE
                EXTRN   CmpErrFileNum  :WORD
                EXTRN   RecordALL      :BYTE
                EXTRN   FileNameLEN    :ABS
                EXTRN   RecordFileA    :BYTE


                ASSUME  ds:_TEXT

                PUBLIC  TabCOMPARE

TabCOMPARE      PROC    NEAR
                pusha

                push    es
                IntDOS  2Fh     ; Get DTA (ES:BX)
                mov     WORD PTR DataTransArea, bx
                mov     WORD PTR DataTransArea[2], es
                mov     es, FreeMemSegm
                mov     di, TabPointer
                mov     bx, di
                mov     cx, 18
                lea     si, SpecialMark
                rep     movsb
                mov     TabPointer, di
                mov     es:[bx][3], di
                pop     es

                xor     bx, bx

                mov     al, WorkingDRV
                mov     ah, ':'
                sub     sp, 08
                mov     bp, sp
                mov     [bp], ax
                mov     WORD PTR [bp][2], '\' + '*' * 100h
                mov     WORD PTR [bp][4], '.' + '*' * 100h
                mov     WORD PTR [bp][6], bx
                mov     ax, 0308h
                push    ax
                push    bx
                push    bx
                call    CompFileTable
                add     sp, 14

                call    MissingFile

                xor     ax, ax
                cmp     ax, CmpErrFileNum
                popa
                ret
TabCOMPARE      ENDP


CompFileTable   PROC    NEAR

DirTansSucc     EQU     <WORD PTR [bp+4]>
ParentPTR       EQU     <WORD PTR [bp+6]>
DirectLEN       EQU     <WORD PTR [bp+8]>
DirectPTR       EQU     10
                push    bp
                mov     bp, sp
CurrentPTR      EQU     <WORD PTR [bp-2]>
CurrNumDIR      EQU     <WORD PTR [bp-4]>
FirstPTR        EQU     <WORD PTR [bp-6]>
                sub     sp, 6

                xor     ax, ax
                mov     CurrNumDIR, ax
                mov     ax, TabPointer
                mov     FirstPTR, ax

                lea     dx, [bp][DirectPTR]
                mov     cx, 27h
                push    ds
                mov     ax, ss
                mov     ds, ax
                IntDOS  4Eh             ; Find First match file
                pop     ds
NextFile2:      jnc     FindFile
                jmp     NoFile2

FindFile:       les     di, DataTransArea

                cmp     BYTE PTR RecordALL, 0
                jnz     FoundALL

                add     di, 30
                mov     dx, di
                mov     cx, 13
                mov     al, 0
        repnz   scasb
                sub     cx, 13
                neg     cx
                lea     si, ExeComSysBin
                mov     di, dx
                mov     al, '.'
        repnz   scasb
                jnz     NotFound2
                mov     dx, di

FindNext2:      mov     cx,4
        repz    cmpsb
                jz      Found2
                add     si, cx
                mov     di, dx
                cmp     BYTE PTR [si], 0
                jnz     FindNext2

NotFound2:      IntDOS  4Fh
                jmp     NextFile2

FoundALL:       mov     si, OFFSET RecordFileA
                add     di, 30
                mov     cx, FileNameLEN
        repz    cmpsb
                jz      NotFound2

Found2:         mov     di, WORD PTR DataTransArea
                add     di, 30

                cmp     DirTansSucc, 0
                jnz     NewFileAppend

                push    di
                mov     al, 0
                mov     cx, 13
        repnz   scasb
        rep     stosb
                pop     di

                mov     ax, FreeMemSegm
                push    ds
                mov     ds, ax
                mov     si, ParentPTR
                mov     cx, ds:[si][1]
                mov     si, ds:[si][3]
FindMatch:      push    cx
                mov     cx, 13
                test    BYTE PTR [si], 10000010B
                jnz     NotMatch
                push    di
                push    si
                add     si, 5
        repz    cmpsb
                pop     si
                pop     di
                jz      NameMatch

NotMatch:       add     si, 18
                pop     cx
                loop    FindMatch
                pop     ds

NewFileAppend:  lea     dx, AppendMsg1
                IntDOS  09h
                lea     dx, AppendMsg2

FileErrHandle:  push    dx
                mov     cx, DirectLEN
                shr     cx, 8
                mov     si, DirectPTR
PrintDir:       mov     dl, [bp][si]
                IntDOS  02h
                inc     si
                loop    PrintDir

PrintName:      mov     dl, es:[di]
                cmp     dl, 0
                jz      EndPrintName
                IntDOS  02h
                inc     di
                jmp     PrintName

EndPrintName:   pop     dx
                cmp     dx, OFFSET SizeErrMsg
                jnz     Append_OR_New

                call    Disp_Difference         ; Modify DX

Append_OR_New:  IntDOS  09h
                inc     CmpErrFileNum

NotFound22:     jmp     NotFound2

NameMatch:      pop     cx
                push    si
                push    di
                inc     si
                sub     di, 4
                mov     cx, 2
        repz    cmpsw
                pop     di
                pop     si
                pushf
                or      BYTE PTR [si], 10000000B
                mov     ax, WORD PTR ds:[si][1]
                mov     dx, WORD PTR ds:[si][3]
                popf
                pop     ds
                jz      NotFound22

                sub     ax, WORD PTR es:[di][-4]
                sbb     dx, WORD PTR es:[di][-2]
                neg     ax
                not     dx
                mov     WORD PTR cs:SizeLOW, ax
                mov     WORD PTR cs:SizeHIGH, dx

                lea     dx, LineFeed
                IntDOS  09h
                lea     dx, SizeErrMsg
                jmp     FileErrHandle

NoFile2:        mov     ax, TabPointer
                mov     CurrentPTR, ax
                lea     dx, [bp][DirectPTR]
                mov     cx, 37h
                push    ds
                mov     ax, ss
                mov     ds, ax
                IntDOS  4Eh
                pop     ds
NextDir2:       jc      NoDIRect

                les     di, DataTransArea

                mov     al, es:[di][21]
                and     al, 10h
                jnz     FounDir2
NotFounDir2:    IntDOS  4Fh
                jmp     NextDir2

FounDir2:       cmp     BYTE PTR es:[di][30], '.'
                jz      NotFounDir2

                add     di, 30
                mov     al, 0
                mov     cx, 13
        repnz   scasb
        rep     stosb

                push    es
                mov     dx, FreeMemSegm
                mov     di, TabPointer
                mov     ax, es
                push    ds
                mov     ds, ax
                mov     es, dx
                mov     si, 30
                add     si, WORD PTR DataTransArea
                mov     bx, di
                mov     cx, 13
                mov     al, 00000010B
                stosb
                add     di, 4
        rep     movsb
                pop     ds
                mov     TabPointer, di
                pop     es
                inc     CurrNumDIR
                jmp     NotFounDir2

NoDIRect:       mov     es, FreeMemSegm
                mov     di, ParentPTR
                cmp     CurrNumDIR, 0
                jnz     Recursiv2
                jmp     EndCmpFile

Recursiv2:      mov     es, FreeMemSegm
                mov     di, CurrentPTR
                add     di, 5
                mov     al, 0
                mov     cx, -1
        repnz   scasb
                not     cx
                dec     cx
                mov     dx, cx
                mov     bx, DirectLEN
                add     cl, bh
                mov     ax, cx
                inc     ax
                add     cl, 5
                shr     cx, 1
                adc     cl, 0
                shl     cx, 1
                sub     sp, cx
                mov     di, sp
                mov     ch, al
                push    cx
                push    es
                mov     ax, ss
                mov     es, ax
                mov     cx, bx
                shr     cx, 8
                mov     si, DirectPTR
StoreHISTORY:   mov     al, [bp][si]
                inc     si
                stosb
                loop    StoreHISTORY
                pop     ax
                push    ax
                mov     si, CurrentPTR
                add     si, 5
                push    ds
                mov     ds, ax
                mov     cx, dx
        rep     movsb
                pop     ds
                mov     cx, WildNameLen
                lea     si, WildName
        rep     movsb
                pop     es

                mov     ax, 1
                cmp     DirTansSucc, 0
                jnz     NewDirAppend

                mov     ax, FreeMemSegm

                push    ds
                push    es
                mov     ds, ax
                mov     es, ax

                mov     si, ParentPTR
                mov     cx, ds:[si][1]
                mov     si, ds:[si][3]
                mov     di, CurrentPTR
DirMatch:       push    cx
                mov     cx, 13
                test    BYTE PTR [si], 10000001B
                jnz     NotMatchD
                push    di
                push    si
                add     si, 5
                add     di, 5
        repz    cmpsb
                pop     si
                pop     di
                jz      DirNameMatch

NotMatchD:      add     si, 18
                pop     cx
                loop    DirMatch
                mov     ax, 1
                jmp     SHORT noMatchDir

DirNameMatch:   xor     ax, ax
                pop     cx

noMatchDir:     pop     es
                pop     ds

NewDirAppend:   push    si

                push    ax

                call    CompFileTable

                pop     bx
                pop     bx
                pop     bx
                xor     bh, bh
                add     sp, bx

                mov     di, CurrentPTR
                mov     es, FreeMemSegm
                mov     es:[di][3], ax
                add     di, 18
                mov     CurrentPTR, di

                dec     CurrNumDIR
                jz      EndCmpFile
                jmp     Recursiv2

EndCmpFile:     mov     ax, FirstPTR
                mov     sp, bp
                pop     bp
                ret
CompFileTable   ENDP

                PUBLIC  Disp_Difference

Disp_Difference PROC    NEAR
                push    ds
                push    es
                push    si
                push    di
                push    bx

                push    dx

                mov     ax, cs
                mov     ds, ax
                mov     es, ax

                mov     bx, 10
                lea     di, Diff_Buffer

                lea     si, SizeDifference
                xor     ax, ax
                cmp     [si], ax
                jge     Positive
                not     WORD PTR ds:[si]
                neg     WORD PTR ds:[si][2]
                inc     ax
Positive:       mov     Diff_Sign, al


Div_Again:      lea     si, SizeDifference
                mov     cx, 2
                xor     dx, dx

div_10:         mov     ax, [si]
                div     bx
                mov     [si], ax
                inc     si
                inc     si
                loop    div_10

                dec     di
                add     dl, '0'
                mov     [di], dl

                lea     si, SizeDifference
                mov     cx, 2
Test_0:         lodsw
                cmp     ax, 0
                jnz     Div_Again
                loop    Test_0

                pop     dx
                cmp     BYTE PTR Diff_Sign, 0
                jz      Postive_print
                lea     dx, Decrease_Msg
Postive_print:  IntDOS  09h

                mov     dx, di  ;  Modify DX --> Print by Caller

                pop     bx
                pop     di
                pop     si
                pop     es
                pop     ds
                ret
Disp_Difference ENDP

SizeDifference  LABEL   DWORD
SizeHIGH        DW      ?
SizeLOW         DW      ?

SizeErrMsg      LABEL   BYTE
Increase_Msg    DB      '  < Increase $'
Decrease_Msg    DB      '  < Decrease $'
Diff_Sign       DB      ?
                DB      12 DUP(0)
Diff_Buffer     DB      ' byte(s) >', 7, '$'

AppendMsg2      DB      ' Appended !', '$'
AppendMsg1      DB      13, 10, 'New File : $'
LineFeed        DB      13, 10, '$'

                END
