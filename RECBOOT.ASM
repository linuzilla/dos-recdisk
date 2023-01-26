		.286

		INCLUDE RECDISK.MAC

		.MODEL	SMALL
		.CODE

		EXTRN	DrvNUMBER   :BYTE
		EXTRN	Stream	    :WORD
		EXTRN	FreeMemSegm :WORD
		EXTRN	TabPointer  :WORD
		EXTRN	RecordBOOT  :BYTE

		ASSUME	ds:_TEXT

		PUBLIC	recBOOT, cmpBOOT

recBOOT 	PROC	NEAR

		pusha

		lea	dx, RecBootMsg
		IntDOS	09

		mov	ax, Stream
		mov	bx, TabPointer
		push	ds
		push	ax
		push	bx

		xor	ax, ax
		mov	dx, ax
		mov	cx, ax
		mov	al, DrvNUMBER
		inc	cx

		mov	ds, FreeMemSegm
		int	25h
		pop	dx	; popf

		pop	dx
		pop	bx

		mov	si, ds
		pop	ds

		jnc	RecBootOk

		mov	BYTE PTR RecordBOOT, 1

RecBootOk:
		mov	di, dx

		mov	cx, 1
		lea	dx, RecordBOOT
		IntDOS	40h

		cmp	BYTE PTR RecordBOOT, 0
		jz	RecBootCont
		lea	dx, SkipMsg
		clc
		pushf
		jmp	SHORT RecError

RecBootCont:	push	ds
		mov	ds, si
		mov	dx, di
		mov	cx, 200h
		IntDOS	40h
		pop	ds
		pushf
		lea	dx, CmpErrMsg
		jc	RecError
		lea	dx, CmpOkMsg

RecError:	IntDOS	09h

		popf
		popa
		ret
recBOOT 	ENDP


cmpBOOT 	PROC	NEAR

		pusha

		lea	dx, CmpBootMsg
		IntDOS	09h

		cmp	BYTE PTR RecordBOOT, 0
		jz	CmpContinue
		lea	dx, SkipMsg
		jmp	SHORT Break

CmpContinue:	mov	ax, Stream
		push	ds
		push	ax

		xor	ax, ax
		mov	bx, ax
		mov	dx, ax
		mov	cx, ax
		mov	al, DrvNUMBER
		inc	cx

		mov	ds, FreeMemSegm
		int	25h
		popf
		pop	bx
		mov	cx, 200h
		mov	dx, cx
		IntDOS	3Fh
		mov	ax, ds
		pop	ds
		jc	ExitRecBoot

		push	ds
		push	es
		mov	ds, ax
		mov	es, ax
		mov	cx, 200h
		xor	di, di
		mov	si, cx
	repz	cmpsb
		pop	es
		pop	ds
		lea	dx, CmpErrMsg
		jnz	Break
		lea	dx, CmpOkMsg
Break:
		IntDOS	09h
		clc

ExitRecBoot:	popa
		ret

cmpBOOT 	ENDP

CmpBootMsg	DB	'Comparing BOOT sector ... $'
CmpErrMsg	DB	'Error !', 7, 13, 10, '$'
CmpOkMsg	DB	'ok.', 13, 10, '$'
RecBootMsg	DB	'Recording BOOT sector ... $'
SkipMsg 	DB	'skip.', 13, 10, '$'

		END
