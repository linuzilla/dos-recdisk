		.286

		INCLUDE RECDISK.MAC


		.MODEL	SMALL
		.CODE

		EXTRN	FreeMemSegm :WORD
		EXTRN	TabPointer  :WORD

		ASSUME	ds:_TEXT

		PUBLIC	GarbageColl

GarbageColl	PROC	NEAR
		push	bp
		mov	bp, sp

		push	es

		mov	cx, TabPointer
		mov	ax, FreeMemSegm
		mov	es, ax
		xor	di, di
		mov	ax, 18
		mov	TabPointer, ax

		mov	cx, es:[di][1]
		mov	ax, es:[di][3]

		call	_GarbColl

		mov	es:[di][1], cx
		mov	es:[di][3], ax

		pop	es

		mov	sp, bp
		pop	bp
		ret
GarbageColl	ENDP

_GarbColl	PROC	NEAR
		push	bp
		mov	bp, sp
Counter 	EQU	<WORD PTR [bp-2]>
DirAddrPtr	EQU	<WORD PTR [bp-4]>
		sub	sp, 4

		push	di

		mov	di, TabPointer
		mov	DirAddrPtr, di
		mov	Counter, 0
		mov	si, ax

		mov	dx, 18

		push	ds
		mov	ax, es
		mov	ds, ax

ScanNext:	cmp	BYTE PTR es:[si], -1
		jz	SkipThis

		inc	Counter

		push	si
		push	cx
		mov	cx, dx
	rep	movsb
		pop	cx
		pop	si

SkipThis:	add	si, dx
		loop	ScanNext

		pop	ds
		mov	TabPointer, di

		mov	cx, Counter
		mov	di, DirAddrPtr

RecSubDir:	push	cx

		cmp	BYTE PTR es:[di], 00000010B
		jnz	SkipFile

		mov	cx, es:[di][1]
		mov	ax, es:[di][3]

		call	_GarbColl

		mov	es:[di][1], cx
		mov	es:[di][3], ax

SkipFile:	add	di, dx
		pop	cx
		loop	RecSubDir

		mov	cx, Counter
		mov	ax, DirAddrPtr
		pop	di
		mov	sp, bp
		pop	bp
		ret
_GarbColl	ENDP

		END
