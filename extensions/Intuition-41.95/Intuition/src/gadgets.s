;Gadget functions

;Size of a we_Gadgets[] element
GADGETSIZE	equ gg_sizeof+ge_sizeof+si_sizeof
;Offset to SpecialInfo
SGADGETSIZE	equ gg_sizeof+ge_sizeof
;Size of struct Border instances (offset to coordinate pairs)
SBORDERSIZE	equ bd_sizeof*8
;Size of a we_GBorders[] element: max of 8 borders, 32 coordinate pairs
BORDERSIZE	equ SBORDERSIZE+(4*32)

;Current revision of gadget bank format
GBANKREV	equ 0


L_ReserveIgadget:	;Reserve Igadget n
	pstart
	bsr	L_ReserveIgadget0	;Free any old gadgets
	jtcall	GetCurIwin2
	move.l	d0,a2
	move.l	wd_UserData(a2),a2
	move.l	(a3)+,d2
	bmi	L_IllFunc
	cmp.l	#$10000,d2
	bcc	L_TooManyGads
	move.w	d2,d0
	mulu	#GADGETSIZE,d0
	move.l	d0,we_GadgetSize(a2)
	moveq	#MEMF_PUBLIC,d1
	jtcall	AllocMemClear
	move.l	d0,we_Gadgets(a2)
	beq	L_NoMem
	move.w	d2,d0
	mulu	#BORDERSIZE,d0
	move.l	d0,we_GBorderSize(a2)
	moveq	#MEMF_PUBLIC,d1
	jtcall	AllocMemClear
	move.l	d0,we_GBorders(a2)
	bne	.bd_ok
	move.l	we_Gadgets(a2),a1
	mulu	#gg_sizeof,d2
	syscall	FreeMem
	bra	L_NoMem
.bd_ok	move.w	d2,we_NGadgets(a2)
	ret

L_ReserveIgadget0:	;Reserve Igadget
	pstart
	jtcall	GetCurIwin2
	move.l	d0,a2
	move.l	wd_UserData(a2),a2
	tst.w	we_NGadgets(a2)
	beq	.exit
	move.l	we_GBorderSize(a2),d0
	move.l	we_GBorders(a2),a1
	syscall	FreeMem
	move.l	we_GadgetSize(a2),d0
	move.l	we_Gadgets(a2),a1
	syscall	FreeMem
	clr.w	we_NGadgets(a2)
.exit	ret


;;;;;;;;;;;;;;;;


L_MakeBoolGad:			;D0 = SELECTED state (zero or non-zero)
				;D1 = TOGGLESELECT or 0
	pstart
	move.w	d0,d2
	jtcall	GetCurIwin2
	move.l	d0,a1
	move.l	wd_UserData(a1),a6
	movem.l	(a3)+,d3-d7
	cmp.l	#$10000,d7		;Check gadget number
	bcc	L_GadNotRes
	cmp.w	we_NGadgets(a6),d7
	bhi	L_GadNotRes
	moveq	#0,d0			;Adjust for window border
	move.b	wd_BorderLeft(a1),d0
	add.w	d0,d6
	move.b	wd_BorderTop(a1),d0
	add.w	d0,d5
	cmp.l	#$8000,d3		;Must be < $8000: Height,
	bhi	L_IllFunc
	cmp.l	#$8000,d4		;                Width,
	bhi	L_IllFunc
	cmp.l	#$8000,d5		;                TopEdge,
	bhi	L_IllFunc
	cmp.l	#$8000,d6		;                LeftEdge
	bhi	L_IllFunc
	moveq	#0,d0			;BottomEdge must be < WinHeight
	move.b	wd_BorderBottom(a1),d0
	add.w	d3,d0
	add.w	d5,d0
	cmp.w	wd_Height(a1),d0
	bcc	L_IllFunc
	moveq	#0,d0			;RightEdge must be < WinWidth
	move.b	wd_BorderRight(a1),d0
	add.w	d4,d0
	add.w	d6,d0
	cmp.w	wd_Width(a1),d0
	bcc	L_IllFunc
	cmp.w	#4,d3			;Size must be >= 4x4
	bcs	L_IllFunc
	cmp.w	#4,d4
	bcs	L_IllFunc
	move.l	we_Gadgets(a6),a1
	move.l	we_GBorders(a6),a2
	subq.w	#1,d7
	move.w	d7,d0
	mulu	#GADGETSIZE,d0
	add.l	d0,a1
	move.w	d7,d0
	mulu	#BORDERSIZE,d0
	add.l	d0,a2
	lea	gg_sizeof(a1),a0
	move.l	a0,gg_UserData(a1)
	move.l	#GADGET_MAGIC,ge_MagicID(a0)
	clr.l	ge_Flags(a0)
	addq.w	#1,d7
	move.w	d7,gg_GadgetID(a1)
	move.w	d6,gg_LeftEdge(a1)
	move.w	d5,gg_TopEdge(a1)
	move.w	d4,gg_Width(a1)
	move.w	d3,gg_Height(a1)
	move.w	#BOOLGADGET,gg_GadgetType(a1)
	clr.l	gg_GadgetText(a1)
	clr.l	gg_MutualExclude(a1)
	clr.l	gg_SpecialInfo(a1)
	move.w	#GADGHIMAGE,gg_Flags(a1)
	tst.l	d2			;Set initial SELECTED state
	sne	d2
	ext.w	d2
	and.w	#SELECTED,d2
	or.w	d2,gg_Flags(a1)
	or.w	#GADGIMMEDIATE|RELVERIFY,d1
	move.w	d1,gg_Activation(a1)

	;Set up borders

	move.l	a2,gg_GadgetRender(a1)	;Unselected border
	clr.w	bd_LeftEdge(a2)
	clr.w	bd_TopEdge(a2)
	move.b	we_HilitePen(a6),bd_FrontPen(a2)
	move.b	#RP_JAM1,bd_DrawMode(a2)
	move.b	#3,bd_Count(a2)
	lea	SBORDERSIZE(a2),a0
	move.l	a0,bd_XY(a2)
	lea	bd_sizeof(a2),a0
	move.l	a0,bd_NextBorder(a2)
	clr.w	bd_LeftEdge+bd_sizeof(a2)
	clr.w	bd_TopEdge+bd_sizeof(a2)
	move.b	we_ShadowPen(a6),bd_FrontPen+bd_sizeof(a2)
	move.b	#RP_JAM1,bd_DrawMode+bd_sizeof(a2)
	move.b	#3,bd_Count+bd_sizeof(a2)
	lea	SBORDERSIZE+(4*3)(a2),a0
	move.l  a0,bd_XY+bd_sizeof(a2)
	clr.l	bd_NextBorder+bd_sizeof(a2)
	lea	SBORDERSIZE(a2),a0
	move.w	gg_Width(a1),d4
	move.w	gg_Height(a1),d3
	subq.w	#1,d4
	subq.w	#1,d3
	moveq	#0,d0
	moveq	#1,d1
;First border: (w-1,0) - (0,0) - (0,h-1)  in HilitePen
	move.w	d4,(a0)+
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	move.w	d3,(a0)+
;Second border: (w-1,0) - (w-1,h-1) - (0,h-1)  in ShadowPen
	move.w	d4,(a0)+
	move.w	d0,(a0)+
	move.w	d4,(a0)+
	move.w	d3,(a0)+
	move.w	d0,(a0)+
	move.w	d3,(a0)+

	add.l	#2*bd_sizeof,a2		;Selected border
	move.l	a2,gg_SelectRender(a1)
	clr.w	bd_LeftEdge(a2)
	clr.w	bd_TopEdge(a2)
	move.b	we_ShadowPen(a6),bd_FrontPen(a2)
	move.b	#RP_JAM1,bd_DrawMode(a2)
	move.b	#3,bd_Count(a2)
	lea	SBORDERSIZE-(2*bd_sizeof)+(4*6)(a2),a0
	move.l	a0,bd_XY(a2)
	lea	bd_sizeof(a2),a0
	move.l	a0,bd_NextBorder(a2)
	clr.w	bd_LeftEdge+bd_sizeof(a2)
	clr.w	bd_TopEdge+bd_sizeof(a2)
	move.b	we_HilitePen(a6),bd_FrontPen+bd_sizeof(a2)
	move.b	#RP_JAM1,bd_DrawMode+bd_sizeof(a2)
	move.b	#3,bd_Count+bd_sizeof(a2)
	lea	SBORDERSIZE-(2*bd_sizeof)+(4*9)(a2),a0
	move.l  a0,bd_XY+bd_sizeof(a2)
	clr.l	bd_NextBorder+bd_sizeof(a2)
	lea	SBORDERSIZE-(2*bd_sizeof)+(4*6)(a2),a0
;First border: (w-1,0) - (0,0) - (0,h-1)  in ShadowPen
	move.w	d4,(a0)+
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	move.w	d3,(a0)+
;Second border: (w-1,0) - (w-1,h-1) - (0,h-1)  in HilitePen
	move.w	d4,(a0)+
	move.w	d0,(a0)+
	move.w	d4,(a0)+
	move.w	d3,(a0)+
	move.w	d0,(a0)+
	move.w	d3,(a0)+
	ret

L_SetIgadToggle:	;Set Igadget Toggle n,x,y,w,h,state
	move.l	(a3)+,d0
	move.w	#TOGGLESELECT,d1
	bra	L_MakeBoolGad

L_SetIgadToggle0:	;Set Igadget Toggle n,x,y,w,h
	moveq	#0,d0
	move.w	#TOGGLESELECT,d1
	bra	L_MakeBoolGad

L_SetIgadHit:		;Set Igadget Hit n,x,y,w,h
	moveq	#0,d0
	moveq	#0,d1
	bra	L_MakeBoolGad

;;;;;;;;

L_MakeSlider:		;Takes parameters on A3 from Set Igadget [HV]slider,
			;  plus: D0 = 0 for horizontal, 1 for vertical
	pstart
	move.w	d0,-(a7)
	jtcall	GetCurIwin2
	move.l	d0,a1
	move.l	wd_UserData(a1),a6
	move.l	(a3)+,-(a7)
	move.l	(a3)+,-(a7)
	movem.l	(a3)+,d1-d7
	cmp.l	#$10000,d7
	bcc	L_GadNotRes
	cmp.w	we_NGadgets(a6),d7
	bhi	L_GadNotRes
	moveq	#0,d0
	move.b	wd_BorderLeft(a1),d0
	add.w	d0,d6
	move.b	wd_BorderTop(a1),d0
	add.w	d0,d5
	cmp.l	#$8000,d3
	bhi	L_IllFunc
	cmp.l	#$8000,d4
	bhi	L_IllFunc
	cmp.l	#$8000,d5
	bhi	L_IllFunc
	cmp.l	#$8000,d6
	bhi	L_IllFunc
	moveq	#0,d0
	move.b	wd_BorderBottom(a1),d0
	add.w	d3,d0
	add.w	d5,d0
	cmp.w	wd_Height(a1),d0
	bcc	L_IllFunc
	moveq	#0,d0
	move.b	wd_BorderRight(a1),d0
	add.w	d4,d0
	add.w	d6,d0
	cmp.w	wd_Width(a1),d0
	bcc	L_IllFunc
	move.l	we_Gadgets(a6),a1
	move.l	we_GBorders(a6),a2
	subq.w	#1,d7
	move.w	d7,d0
	mulu	#GADGETSIZE,d0
	add.l	d0,a1
	move.w	d7,d0
	mulu	#BORDERSIZE,d0
	add.l	d0,a2
	lea	gg_sizeof(a1),a0
	move.l	a0,gg_UserData(a1)
	move.l	#GADGET_MAGIC,ge_MagicID(a0)
	clr.l	ge_Flags(a0)
	move.l	d2,ge_NUnits(a0)
	move.l	(a7),ge_KnobSize(a0)
	addq.w	#1,d7
	move.w	d7,gg_GadgetID(a1)
	move.w	d6,gg_LeftEdge(a1)
	move.w	d5,gg_TopEdge(a1)
	move.w	d4,gg_Width(a1)
	move.w	d3,gg_Height(a1)
	move.w	#PROPGADGET,gg_GadgetType(a1)
	lea	SGADGETSIZE(a1),a0
	move.l	a0,gg_SpecialInfo(a1)
	move.w	#GADGHNONE,gg_Flags(a1)
	move.w	#GADGIMMEDIATE|RELVERIFY,gg_Activation(a1)
	clr.l	gg_GadgetText(a1)
	clr.l	gg_MutualExclude(a1)
	move.l	(a7)+,d4		;Slider size
	move.l	(a7)+,d6		;Overlap
	move.l	d2,d0
	sub.w	d4,d0			;   hidden = MAX(total - visible, 0)
	ble	.hid0			;   if (hidden > 0) {
	move.w	d0,-(a7)		;
	move.l	d4,d0			;	Body = ((visible - overlap)
	sub.l	d6,d0			;
	mulu	#MAXBODY,d0		;	        * MAXBODY)
	move.l	d2,d7			;		/ (total - overlap);
	sub.l	d6,d7			;
	divu	d7,d0			;
	tst.w	2(a7)			;
	bne	.vert1			;
	move.w	d0,pi_HorizBody(a0)	;
	bra	.pot			;
.vert1	move.w	d0,pi_VertBody(a0)	;
.pot	mulu	#MAXPOT,d1		;	Pot = (position * MAXPOT)
	divu	(a7)+,d1		;	      / hidden;
	tst.w	(a7)+			;
	bne	.vert2			;
	move.w	d1,pi_HorizPot(a0)	;
	bra	.piflag			;
.vert2	move.w	d1,pi_VertPot(a0)	;
	bra	.piflag			;   } else {
.hid0	tst.w	(a7)			;
	bne	.vert3			;
	move.w	#MAXBODY,pi_HorizBody(a0);	Body = MAXBODY;
	clr.w	pi_HorizPot(a0)		;	Pot = 0;
	bra	.piflag			;
.vert3	move.w	#MAXBODY,pi_HorizBody(a0)
	clr.w	pi_HorizPot(a0)		;
					;   }
.piflag	move.w	#AUTOKNOB,pi_Flags(a0)
	tst.w	(a7)+
	bne	.vert4
	or.w	#FREEHORIZ,pi_Flags(a0)
	bra	.border
.vert4	or.w	#FREEVERT,pi_Flags(a0)

.border	move.l	a2,gg_GadgetRender(a1)	;Set up border
	move.w	gg_Width(a1),d4		;D4 = w-1
	move.w	gg_Height(a1),d3	;D3 = h-1
	subq.w	#1,d4
	subq.w	#1,d3
	moveq	#1,d5			;D5 = 1
	move.w	d4,d6			;D6 = w-2
	subq.w	#1,d6
	move.w	d3,d7			;D7 = h-2
	subq.w	#1,d7
	lea	SBORDERSIZE(a2),a1
	clr.w	bd_LeftEdge(a2)
	clr.w	bd_TopEdge(a2)
	move.b	we_HilitePen(a6),bd_FrontPen(a2)
	move.b	#RP_JAM1,bd_DrawMode(a2)
	move.b	#2,bd_Count(a2)
	move.l	a1,bd_XY(a2)
;(1,1) - (1,h-2)  in HilitePen
	move.w	d5,(a1)+
	move.w	d5,(a1)+
	move.w	d5,(a1)+
	move.w	d7,(a1)+
	lea	bd_sizeof(a2),a0
	move.l	a0,bd_NextBorder(a2)
	move.l	a0,a2

	clr.w	bd_LeftEdge(a2)
	clr.w	bd_TopEdge(a2)
	move.b	we_HilitePen(a6),bd_FrontPen(a2)
	move.b	#RP_JAM1,bd_DrawMode(a2)
	move.b	#3,bd_Count(a2)
	move.l	a1,bd_XY(a2)
;(0,h-1) - (0,0) - (w-2,0)  in HilitePen
	clr.w	(a1)+
	move.w	d3,(a1)+
	clr.w	(a1)+
	clr.w	(a1)+
	move.w	d6,(a1)+
	clr.w	(a1)+
	lea	bd_sizeof(a2),a0
	move.l	a0,bd_NextBorder(a2)
	move.l	a0,a2

	clr.w	bd_LeftEdge(a2)
	clr.w	bd_TopEdge(a2)
	move.b	we_ShadowPen(a6),bd_FrontPen(a2)
	move.b	#RP_JAM1,bd_DrawMode(a2)
	move.b	#2,bd_Count(a2)
	move.l	a1,bd_XY(a2)
;(w-2,1) - (w-2,h-2)  in ShadowPen
	move.w	d6,(a1)+
	move.w	d5,(a1)+
	move.w	d6,(a1)+
	move.w	d7,(a1)+
	lea	bd_sizeof(a2),a0
	move.l	a0,bd_NextBorder(a2)
	move.l	a0,a2

	clr.w	bd_LeftEdge(a2)
	clr.w	bd_TopEdge(a2)
	move.b	we_ShadowPen(a6),bd_FrontPen(a2)
	move.b	#RP_JAM1,bd_DrawMode(a2)
	move.b	#3,bd_Count(a2)
	move.l	a1,bd_XY(a2)
;(w-1,0) - (w-1,h-1) - (1,h-1)  in ShadowPen
	move.w	d4,(a1)+
	clr.w	(a1)+
	move.w	d4,(a1)+
	move.w	d3,(a1)+
	move.w	d5,(a1)+
	move.w	d3,(a1)+
	clr.l	bd_NextBorder(a2)

	ret

L_SetIgadHslider:	;Set Igadget Hslider n,x,y,w,h,units,pos,size,overlap
	moveq	#0,d0
	bra	L_MakeSlider

L_SetIgadVslider:	;Set Igadget Vslider n,x,y,w,h,units,pos,size,overlap
	moveq	#1,d0
	bra	L_MakeSlider

;;;;;;;;

L_SetIgadString:	;Set Igadget String n,x,y,w,h,size,init$,strpos
	pstart
	jtcall	GetCurIwin2
	move.l	d0,a1
	move.l	wd_UserData(a1),a6
	move.l	(a3)+,-(a7)
	movem.l	(a3)+,d1-d7
	cmp.l	#Null,d1
	bne	.nonul0
	moveq	#0,d1
.nonul0	cmp.l	#$10000,d7
	bcc	L_GadNotRes
	cmp.w	we_NGadgets(a6),d7
	bhi	L_GadNotRes
	moveq	#0,d0
	move.b	wd_BorderLeft(a1),d0
	add.w	d0,d6
	move.b	wd_BorderTop(a1),d0
	add.w	d0,d5
	move.l	wd_RPort(a1),a2
	cmp.l	#Null,d3
	bne	.notnul
	moveq	#0,d3
	move.w	rp_TxHeight(a2),d3
	addq.w	#4,d3
.notnul	cmp.l	#$8000,d3
	bhi	L_IllFunc
	cmp.l	#$8000,d4
	bhi	L_IllFunc
	cmp.l	#$8000,d5
	bhi	L_IllFunc
	cmp.l	#$8000,d6
	bhi	L_IllFunc
	moveq	#0,d0
	move.b	wd_BorderBottom(a1),d0
	add.w	d3,d0
	add.w	d5,d0
	cmp.w	wd_Height(a1),d0
	bcc	L_IllFunc
	moveq	#0,d0
	move.b	wd_BorderRight(a1),d0
	add.w	d4,d0
	add.w	d6,d0
	cmp.w	wd_Width(a1),d0
	bcc	L_IllFunc
	move.w	rp_TxHeight(a2),d0
	addq.w	#4,d0
	cmp.w	d0,d3
	bcs	L_IllFunc
	cmp.w	#32,d4
	bcs	L_IllFunc
	cmp.l	#65534,d2
	bhi	L_IllFunc
	move.l	we_Gadgets(a6),a1
	move.l	we_GBorders(a6),a2
	subq.w	#1,d7
	move.w	d7,d0
	mulu	#GADGETSIZE,d0
	add.l	d0,a1
	move.w	d7,d0
	mulu	#BORDERSIZE,d0
	add.l	d0,a2
	lea	gg_sizeof(a1),a0
	move.l	a0,gg_UserData(a1)
	move.l	#GADGET_MAGIC,ge_MagicID(a0)
	clr.l	ge_Flags(a0)
	addq.w	#1,d7
	move.w	d7,gg_GadgetID(a1)
	addq.w	#4,d6
	addq.w	#2,d5
	subq.w	#8,d4
	subq.w	#4,d3
	move.w	d6,gg_LeftEdge(a1)
	move.w	d5,gg_TopEdge(a1)
	move.w	d4,gg_Width(a1)
	move.w	d3,gg_Height(a1)
	move.w	#STRGADGET,gg_GadgetType(a1)
	lea	SGADGETSIZE(a1),a0
	move.l	a0,gg_SpecialInfo(a1)
	move.w	#GADGHNONE,gg_Flags(a1)
	clr.l	gg_GadgetText(a1)
	clr.l	gg_MutualExclude(a1)
	move.l	a2,gg_GadgetRender(a1)
	move.l	(a7)+,d0
	beq	.left
	cmp.l	#1,d0
	beq	.centre
	cmp.l	#2,d0
	bne	L_IllFunc
	move.w	#STRINGRIGHT,gg_Activation(a1)
	bra	.si
.centre	move.w	#STRINGCENTER,gg_Activation(a1)
	bra	.si
.left	clr.w	gg_Activation(a1)
.si	or.w	#GADGIMMEDIATE|RELVERIFY,gg_Activation(a1)
	move.l	d1,d7
	move.l	a2,d4
	move.l	a1,d6
	move.l	a0,a2
	addq.w	#1,d2
	bne	.oklen
	move.l	#$53475347,d1
	bra	L_InternalErr
.oklen	move.l	d2,d0
	jtcall	StrAlloc
	move.l	d0,si_Buffer(a2)
	beq	L_NoMem
	dcmp.l	GadgetUndoLen,d2
	bls	.okundo
	dmove.l	GadgetUndo,a0
	jtcall	StrFree
	move.l	d2,d0
	jtcall	StrAlloc
	tmove.l	d0,GadgetUndo
	bne	.setlen
	mvoe.l	si_Buffer(a2),a0
	jtcall	StrFree
	bra	L_NoMem
.setlen	tmove.l	d0,GadgetUndoLen
.okundo	dmove.l	GadgetUndo,si_UndoBuffer(a2)
	move.w	d2,si_MaxChars(a2)
	clr.w	si_BufferPos(a2)
	clr.w	si_DispPos(a2)
	move.l	si_Buffer(a2),a0
	move.l	d7,d1			;If there was an initial string,
	beq	.nostr			;  set it up in the buffer
	move.l	d1,a1
	move.w	(a1)+,d1
	beq	.nostr
	cmp.w	d2,d1
	bcs	.okilen
	move.w	d2,d1
	subq.w	#1,d1
.okilen	subq.w	#1,d1
.loop	move.b	(a1)+,(a0)+
	dbra	d1,.loop
.nostr	clr.b	(a0)

	bra	L_gStringBorder

L_SetIgadString1:	;Set Igadget String n,x,y,w,h,size,init$
	clr.l	-(a3)
	bra	L_SetIgadString

L_SetIgadString0:	;Set Igadget String n,x,y,w,h,size
	clr.l	-(a3)
	bra	L_SetIgadString1

;;;;;;;;

L_SetIgadInt:		;Set Igadget Int n,x,y,w,h,init,strpos
	pstart
	jtcall	GetCurIwin2
	move.l	d0,a1
	move.l	wd_UserData(a1),a6
	movem.l	(a3)+,d1-d7
	cmp.l	#$10000,d7
	bcc	L_GadNotRes
	cmp.w	we_NGadgets(a6),d7
	bhi	L_GadNotRes
	moveq	#0,d0
	move.b	wd_BorderLeft(a1),d0
	add.w	d0,d6
	move.b	wd_BorderTop(a1),d0
	add.w	d0,d5
	move.l	wd_RPort(a1),a2
	cmp.l	#Null,d3
	bne	.notnul
	moveq	#0,d3
	move.w	rp_TxHeight(a2),d3
	addq.w	#4,d3
.notnul	cmp.l	#$8000,d3
	bhi	L_IllFunc
	cmp.l	#$8000,d4
	bhi	L_IllFunc
	cmp.l	#$8000,d5
	bhi	L_IllFunc
	cmp.l	#$8000,d6
	bhi	L_IllFunc
	moveq	#0,d0
	move.b	wd_BorderBottom(a1),d0
	add.w	d3,d0
	add.w	d5,d0
	cmp.w	wd_Height(a1),d0
	bcc	L_IllFunc
	moveq	#0,d0
	move.b	wd_BorderRight(a1),d0
	add.w	d4,d0
	add.w	d6,d0
	cmp.w	wd_Width(a1),d0
	bcc	L_IllFunc
	move.w	rp_TxHeight(a2),d0
	addq.w	#4,d0
	cmp.w	d0,d3
	bcs	L_IllFunc
	cmp.w	#32,d4
	bcs	L_IllFunc
	move.l	we_Gadgets(a6),a1
	move.l	we_GBorders(a6),a2
	subq.w	#1,d7
	move.w	d7,d0
	mulu	#GADGETSIZE,d0
	add.l	d0,a1
	move.w	d7,d0
	mulu	#BORDERSIZE,d0
	add.l	d0,a2
	lea	gg_sizeof(a1),a0
	move.l	a0,gg_UserData(a1)
	move.l	#GADGET_MAGIC,ge_MagicID(a0)
	clr.l	ge_Flags(a0)
	addq.w	#1,d7
	move.w	d7,gg_GadgetID(a1)
	addq.w	#4,d6
	addq.w	#2,d5
	subq.w	#8,d4
	subq.w	#4,d3
	move.w	d6,gg_LeftEdge(a1)
	move.w	d5,gg_TopEdge(a1)
	move.w	d4,gg_Width(a1)
	move.w	d3,gg_Height(a1)
	move.w	#STRGADGET,gg_GadgetType(a1)
	lea	SGADGETSIZE(a1),a0
	move.l	a0,gg_SpecialInfo(a1)
	move.w	#GADGHNONE,gg_Flags(a1)
	clr.l	gg_GadgetText(a1)
	clr.l	gg_MutualExclude(a1)
	move.l	a2,gg_GadgetRender(a1)
	tst.l	d1
	beq	.left
	cmp.l	#1,d1
	beq	.centre
	cmp.l	#2,d1
	bne	L_IllFunc
	move.w	#STRINGRIGHT,gg_Activation(a1)
	bra	.si
.centre	move.w	#STRINGCENTER,gg_Activation(a1)
	bra	.si
.left	clr.w	gg_Activation(a1)
.si	or.w	#GADGIMMEDIATE|RELVERIFY|LONGINT,gg_Activation(a1)
	move.l	a2,d5
	move.l	a1,d6
	move.l	a0,a2
	moveq	#12,d0			;"-1234567890" plus trailing null
	jtcall	StrAlloc		;It'll get freed when we quit...
	move.l	d0,si_Buffer(a2)
	beq	L_NoMem
	moveq	#12,d0
	dcmp.l	GadgetUndoLen,d0
	bls	.okundo
	dmove.l	GadgetUndo,a0
	jtcall	StrFree
	moveq	#12,d0
	jtcall	StrAlloc
	tmove.l	d0,GadgetUndo
	bne	.setlen
	mvoe.l	si_Buffer(a2),a0
	jtcall	StrFree
	bra	L_NoMem
.setlen	tmove.l	#12,GadgetUndoLen
.okundo	dmove.l	GadgetUndo,si_UndoBuffer(a2)
	move.w	#12,si_MaxChars(a2)
	clr.w	si_BufferPos(a2)
	clr.w	si_DispPos(a2)
	move.l	si_Buffer(a2),a0
	move.l	d2,si_LongInt(a2)
	bpl	.log
	cmp.l	#$80000000,d2
	bne	.neg
	move.l	#'-214',(a0)+
	move.l	#'7483',(a0)+
	move.l	#'648 ',(a0)+
	clr.b	-1(a0)
	bra	L_gStringBorder
.neg	move.b	#'-',(a0)+
	neg.l	d2
.log	move.l	d2,d0
.loglp	addq.l	#1,a0
	moveq	#10,d1
	jtcall	LongDiv
	bne	.loglp
	clr.b	(a0)
	move.l	d2,d0
.asclp	moveq	#10,d1
	jtcall	LongDiv
	add.b	#'0',d1
	move.b	d1,-(a0)
	tst.l	d0
	bne	.asclp
	bra	L_gStringBorder


L_gStringBorder:			;Set up a string/integer gadget border
	move.l	d6,a1			;Restore gadget address
	move.l	gg_GadgetRender(a1),a2
	move.w	gg_Width(a1),d4		;D4 = w-1 (=gg_Width+3)
	addq.w	#3,d4
	move.w	gg_Height(a1),d3	;D3 = h-1 (=gg_Height+1)
	addq.w	#1,d3
	move.w	d4,d6			;D6 = w-2
	subq.w	#1,d6
	move.w	d3,d7			;D7 = h-2
	subq.w	#1,d7
	lea	SBORDERSIZE(a2),a1
	clr.w	bd_LeftEdge(a2)
	clr.w	bd_TopEdge(a2)
	move.b	we_HilitePen(a6),bd_FrontPen(a2)
	move.b	#RP_JAM1,bd_DrawMode(a2)
	move.b	#2,bd_Count(a2)
	move.l	a1,bd_XY(a2)
;(1,1) - (1,h-2)  in HilitePen
	move.w	#-3,(a1)+
	move.w	#-1,(a1)+
	move.w	#-3,(a1)+
	move.w	d7,(a1)+
	lea	bd_sizeof(a2),a0
	move.l	a0,bd_NextBorder(a2)
	move.l	a0,a2

	clr.w	bd_LeftEdge(a2)
	clr.w	bd_TopEdge(a2)
	move.b	we_HilitePen(a6),bd_FrontPen(a2)
	move.b	#RP_JAM1,bd_DrawMode(a2)
	move.b	#3,bd_Count(a2)
	move.l	a1,bd_XY(a2)
;(0,h-1) - (0,0) - (w-2,0)  in HilitePen
	move.w	#-4,(a1)+
	move.w	d3,(a1)+
	move.w	#-4,(a1)+
	move.w	#-2,(a1)+
	move.w	d6,(a1)+
	move.w	#-2,(a1)+
	lea	bd_sizeof(a2),a0
	move.l	a0,bd_NextBorder(a2)
	move.l	a0,a2

	clr.w	bd_LeftEdge(a2)
	clr.w	bd_TopEdge(a2)
	move.b	we_HilitePen(a6),bd_FrontPen(a2)
	move.b	#RP_JAM1,bd_DrawMode(a2)
	move.b	#3,bd_Count(a2)
	move.l	a1,bd_XY(a2)
;(w-3,1) - (w-3,h-2) - (2,h-2)  in HilitePen
	move.w	d6,(a1)
	subq.w	#1,(a1)+
	move.w	#-1,(a1)+
	move.w	-4(a1),(a1)+
	move.w	d7,(a1)+
	move.w	#-2,(a1)+
	move.w	d7,(a1)+
	lea	bd_sizeof(a2),a0
	move.l	a0,bd_NextBorder(a2)
	move.l	a0,a2

	clr.w	bd_LeftEdge(a2)
	clr.w	bd_TopEdge(a2)
	move.b	we_HilitePen(a6),bd_FrontPen(a2)
	move.b	#RP_JAM1,bd_DrawMode(a2)
	move.b	#2,bd_Count(a2)
	move.l	a1,bd_XY(a2)
;(w-4,2) - (w-4,h-3)  in HilitePen
	move.w	d6,(a1)
	subq.w	#2,(a1)+
	move.w	#0,(a1)+
	move.w	d6,(a1)
	subq.w	#2,(a1)+
	move.w	d7,(a1)
	subq.w	#1,(a1)+
	lea	bd_sizeof(a2),a0
	move.l	a0,bd_NextBorder(a2)
	move.l	a0,a2

	clr.w	bd_LeftEdge(a2)
	clr.w	bd_TopEdge(a2)
	move.b	we_ShadowPen(a6),bd_FrontPen(a2)
	move.b	#RP_JAM1,bd_DrawMode(a2)
	move.b	#3,bd_Count(a2)
	move.l	a1,bd_XY(a2)
;(w-4,1) - (2,1) - (2,h-2)  in ShadowPen
	move.w	d6,(a1)
	subq.w	#2,(a1)+
	move.w	#-1,(a1)+
	move.w	#-2,(a1)+
	move.w	#-1,(a1)+
	move.w	#-2,(a1)+
	move.w	d7,(a1)+
	lea	bd_sizeof(a2),a0
	move.l	a0,bd_NextBorder(a2)
	move.l	a0,a2

	clr.w	bd_LeftEdge(a2)
	clr.w	bd_TopEdge(a2)
	move.b	we_ShadowPen(a6),bd_FrontPen(a2)
	move.b	#RP_JAM1,bd_DrawMode(a2)
	move.b	#2,bd_Count(a2)
	move.l	a1,bd_XY(a2)
;(3,2) - (3,h-3)  in ShadowPen
	move.w	#-1,(a1)+
	move.w	#0,(a1)+
	move.w	#-1,(a1)+
	move.w	d7,(a1)
	subq.w	#1,(a1)+
	lea	bd_sizeof(a2),a0
	move.l	a0,bd_NextBorder(a2)
	move.l	a0,a2

	clr.w	bd_LeftEdge(a2)
	clr.w	bd_TopEdge(a2)
	move.b	we_ShadowPen(a6),bd_FrontPen(a2)
	move.b	#RP_JAM1,bd_DrawMode(a2)
	move.b	#3,bd_Count(a2)
	move.l	a1,bd_XY(a2)
;(1,h-1) - (w-1,h-1) - (w-1,0)  in ShadowPen
	move.w	#-3,(a1)+
	move.w	d3,(a1)+
	move.w	d4,(a1)+
	move.w	d3,(a1)+
	move.w	d4,(a1)+
	move.w	#-2,(a1)+
	lea	bd_sizeof(a2),a0
	move.l	a0,bd_NextBorder(a2)
	move.l	a0,a2

	clr.w	bd_LeftEdge(a2)
	clr.w	bd_TopEdge(a2)
	move.b	we_ShadowPen(a6),bd_FrontPen(a2)
	move.b	#RP_JAM1,bd_DrawMode(a2)
	move.b	#2,bd_Count(a2)
	move.l	a1,bd_XY(a2)
;(w-2,1) - (w-2,h-2)  in ShadowPen
	move.w	d6,(a1)+
	move.w	#-1,(a1)+
	move.w	d6,(a1)+
	move.w	d7,(a1)+
	clr.l	bd_NextBorder(a2)

	ret

L_SetIgadInt1:		;Set Igadget Int n,x,y,w,h,init
	clr.l	-(a3)
	bra	L_SetIgadInt

L_SetIgadInt0:		;Set Igadget Int n,x,y,w,h
	clr.l	-(a3)
	bra	L_SetIgadInt1


;;;;;;;;;;;;;;;;


L_IgadgetOn:		;Igadget On n
	pstart
	jtcall	GetCurIwin2
	move.l	d0,a0
	move.l	wd_UserData(a0),a1
	move.l	(a3)+,d7
	cmp.l	#$10000,d7
	bcc	L_GadNotRes
	cmp.w	we_NGadgets(a1),d7
	bhi	L_GadNotRes
	subq.w	#1,d7
	bmi	L_IllFunc
	mulu	#GADGETSIZE,d7
	move.l	we_Gadgets(a1),a1
	add.l	d7,a1
	tst.w	gg_GadgetType(a1)
	beq	L_GadNotDef
	move.w	gg_GadgetID(a1),d0
	subq.w	#1,d0
	move.l	gg_UserData(a1),a2
	move.l	#GEF_DISPLAYED,d7
	and.l	ge_Flags(a2),d7
	bne	.done
	or.l	#GEF_DISPLAYED,ge_Flags(a2)
	move.l	a0,d4
	move.l	a1,d5
	intcall	AddGadget
	move.l	d4,a1
	move.l	d5,a0
	sub.l	a2,a2
	moveq	#1,d0
	intcall	RefreshGList
.done	ret

L_IgadgetOnAll:		;Igadget On
	pstart
	move.l	a5,-(a7)
	jtcall	GetCurIwin2
	move.l	d0,a0
	move.l	wd_UserData(a0),a1
	move.w	we_NGadgets(a1),d0
	beq	L_GadNotRes
	move.l	we_Gadgets(a1),a1
	subq.w	#1,d0
	sub.l	a2,a2
	moveq	#0,d2
	moveq	#0,d3
.loop	tst.w	gg_GadgetType(a1)
	beq	.next
	move.l	gg_UserData(a1),a5
	move.l	ge_Flags(a5),d7
	btst	#GEB_DISPLAYED,d7
	bne	.xfound
	move.l	a2,d1
	bne	.setnxt
	move.l	a1,d2
	bra	.found
.setnxt	move.l	a1,gg_NextGadget(a2)
.found	move.l	a1,a2
	clr.l	gg_NextGadget(a1)
	or.l	#GEF_DISPLAYED,ge_Flags(a5)
.xfound	moveq	#1,d3
.next	add.l	#GADGETSIZE,a1
	dbra	d0,.loop
	tst.l	d3
	beq	L_GadNotDef
	tst.l	d2
	beq	.exit
	move.l	d2,a1
	move.w	gg_GadgetID(a1),d0
	subq.w	#1,d0
	moveq	#-1,d1
	sub.l	a2,a2
	move.l	a0,d4
	move.l	a1,d5
	intcall	AddGList
	move.l	d4,a1
	move.l	d5,a0
	intcall	RefreshGadgets
.exit	move.l	(a7)+,a5
	ret

L_IgadgetOff:		;Igadget Off n
	pstart
	jtcall	GetCurIwin2
	move.l	d0,a0
	move.l	wd_UserData(a0),a1
	move.l	(a3)+,d7
	cmp.l	#$10000,d7
	bcc	L_GadNotRes
	cmp.w	we_NGadgets(a1),d7
	bhi	L_GadNotRes
	subq.w	#1,d7
	bmi	L_IllFunc
	mulu	#GADGETSIZE,d7
	move.l	we_Gadgets(a1),a1
	add.l	d7,a1
	move.l	gg_UserData(a1),a2
	move.l	#GEF_DISPLAYED,d0
	and.l	ge_Flags(a2),d0
	beq	.done
	and.l	#~GEF_DISPLAYED,ge_Flags(a2)
	move.l	a0,d7
	move.l	a1,d6
	intcall	RemoveGadget
	move.l	d6,a0
	move.l	d7,a1
	jtcall	ClearGadget
.done	ret

L_IgadgetOffAll:	;Igadget Off
	pstart
	jtcall	GetCurIwin2
	move.l	d0,a0
	move.l	wd_UserData(a0),a1
	move.w	we_NGadgets(a1),d2
	beq	L_GadNotRes
	move.l	a0,d7
	move.l	wd_FirstGadget(a0),a1
.findlp	move.l	gg_UserData(a1),a0
	cmp.l	#GADGET_MAGIC,ge_MagicID(a0)
	beq	.found
	move.l	gg_NextGadget(a1),d0
	beq	.exit				;No gadgets displayed
	move.l	d0,a1
	bra	.findlp
.found	moveq	#-1,d0
	move.l	d7,a0
	intcall	RemoveGList
	move.l	d7,a0
	subq.w	#1,d2
	move.l	wd_UserData(a0),a0
	move.l	we_Gadgets(a0),a0
.loop	tst.w	gg_GadgetType(a0)
	beq	.nogad
	move.l	gg_UserData(a0),a1
	and.l	#~GEF_DISPLAYED,ge_Flags(a1)
	move.l	a0,d6
	move.l	d7,a1
	jtcall	ClearGadget
	move.l	d6,a0
.nogad	add.l	#GADGETSIZE,a0
	dbra	d2,.loop
.exit	ret

L_IgadgetActive:	;Igadget Active n
	pstart
	jtcall	GetCurIwin2
	move.l	d0,a1
	move.l	wd_UserData(a1),a0
	move.l	(a3)+,d7
	cmp.l	#$10000,d7
	bcc	L_GadNotRes
	cmp.w	we_NGadgets(a0),d7
	bhi	L_GadNotRes
	subq.w	#1,d7
	bmi	L_IllFunc
	mulu	#GADGETSIZE,d7
	move.l	we_Gadgets(a0),a0
	add.l	d7,a0
	tst.w	gg_GadgetType(a0)
	beq	L_GadNotDef
	and.w	#~GADGDISABLED,gg_Flags(a0)
	move.l	gg_UserData(a0),a2
	moveq	#GEF_DISPLAYED,d0
	and.l	ge_Flags(a2),d0
	beq	.exit
	sub.l	a2,a2
	moveq	#1,d0
	intcall	RefreshGList
.exit	ret

L_IgadgetActiveAll:	;Igadget Active
	pstart
	jtcall	GetCurIwin2
	move.l	d0,a1
	move.l	wd_UserData(a1),a0
	tst.w	we_NGadgets(a0)
	beq	L_GadNotRes
	move.l	a5,-(a7)
	move.l	a1,d4
	sub.l	a2,a2
	move.l	we_Gadgets(a0),a5
.loop	move.l	gg_UserData(a5),a0
	moveq	#GEF_DISPLAYED,d0
	and.l	ge_Flags(a0),d0
	beq	.next
	and.w	#~GADGDISABLED,gg_Flags(a5)
	move.l	a5,a0
	move.l	d4,a1
	moveq	#1,d0
	intcall	RefreshGList
.next	add.l	#GADGETSIZE,a5
	dbra	d7,.loop
	move.l	(a7)+,a5
	ret

L_IgadgetInactive:	;Igadget Inactive n
	pstart
	jtcall	GetCurIwin2
	move.l	d0,a1
	move.l	wd_UserData(a1),a0
	move.l	(a3)+,d7
	cmp.l	#$10000,d7
	bcc	L_GadNotRes
	cmp.w	we_NGadgets(a0),d7
	bhi	L_GadNotRes
	subq.w	#1,d7
	bmi	L_IllFunc
	mulu	#GADGETSIZE,d7
	move.l	we_Gadgets(a0),a0
	add.l	d7,a0
	tst.w	gg_GadgetType(a0)
	beq	L_GadNotDef
	or.w	#GADGDISABLED,gg_Flags(a0)
	move.l	gg_UserData(a0),a2
	moveq	#GEF_DISPLAYED,d0
	and.l	ge_Flags(a2),d0
	beq	.exit
	sub.l	a2,a2
	moveq	#1,d0
	intcall	RefreshGList
.exit	ret

L_IgadgetInactiveAll:	;Igadget Inactive
	pstart
	jtcall	GetCurIwin2
	move.l	d0,a1
	move.l	wd_UserData(a1),a0
	move.w	we_NGadgets(a0),d7
	beq	L_GadNotRes
	move.l	a5,-(a7)
	sub.l	a2,a2
	move.l	a1,d4
	move.l	we_Gadgets(a0),a5
.loop	move.l	gg_UserData(a5),a0
	moveq	#GEF_DISPLAYED,d0
	and.l	ge_Flags(a0),d0
	beq	.next
	or.w	#GADGDISABLED,gg_Flags(a5)
	move.l	a5,a0
	move.l	d4,a1
	moveq	#1,d0
	intcall	RefreshGList
.next	add.l	#GADGETSIZE,a5
	dbra	d7,.loop
	move.l	(a7)+,a5
	ret

L_IgadgetRead:		;=Igadget Read(n)
	pstart
	jtcall	GetCurIwin2
	move.l	d0,a1
	move.l	wd_UserData(a1),a0
	move.l	(a3)+,d7
	cmp.l	#$10000,d7
	bcc	L_GadNotRes
	cmp.w	we_NGadgets(a0),d7
	bhi	L_GadNotRes
	subq.w	#1,d7
	bmi	L_IllFunc
	mulu	#GADGETSIZE,d7
	move.l	we_Gadgets(a0),a0
	add.l	d7,a0
	tst.w	gg_GadgetType(a0)
	beq	L_GadNotDef
	cmp.w	#STRGADGET,gg_GadgetType(a0)
	bne	.oktype
	move.w	gg_Activation(a0),d0
	and.w	#LONGINT,d0
	beq	L_WrongGadType
	move.l	gg_SpecialInfo(a0),a0
	move.l	si_LongInt(a0),d3
	bra	.exit
.oktype	cmp.w	#PROPGADGET,gg_GadgetType(a0)
	beq	.prop
	move.w	#TOGGLESELECT,d0	;Must be boolean - check TOGGLESELECT
	and.w	gg_Activation(a0),d0
	bne	.toggle
	move.l	#GADGETUP,d0		;Not TOGGLESELECT - must be HITSELECT
	move.l	a0,a2
	move.l	wd_UserPort(a1),a0
	jtcall	DoEvent
	move.l	gg_UserData(a2),a0
	moveq	#0,d3
	tst.w	ge_HitCount(a0)
	beq	.exit
	moveq	#-1,d3
	subq.w	#1,ge_HitCount(a0)
	bra	.exit
.toggle	move.w	gg_Flags(a0),d0
	and.w	#SELECTED,d0
	sne	d3
	ext.w	d3
	ext.l	d3
	bra	.exit
.prop	move.l	gg_SpecialInfo(a0),a1
	move.l	gg_UserData(a0),a2
	move.l	ge_NUnits(a2),d3
	sub.l	ge_KnobSize(a2),d3
	bpl	.chkdir
	moveq	#0,d3
.chkdir	move.l	ge_Flags(a2),d1
	btst	#GEB_VSLIDER,d1
	bne	.vprop
	move.w	pi_HorizPot(a1),d1
	bra	.calc
.vprop	move.w	pi_VertPot(a1),d1
.calc	mulu	d1,d3
	add.l	#MAXPOT/2,d3
	divu	#MAXPOT,d3
	swap	d3
	clr.w	d3
	swap	d3
.exit	moveq	#0,d2
	ret

L_IgadgetReadStr:	;=Igadget Read$(n)
	pstart
	jtcall	GetCurIwin2
	move.l	d0,a1
	move.l	wd_UserData(a1),a0
	move.l	(a3)+,d7
	cmp.l	#$10000,d7
	bcc	L_GadNotRes
	cmp.w	we_NGadgets(a0),d7
	bhi	L_GadNotRes
	subq.w	#1,d7
	bmi	L_IllFunc
	mulu	#GADGETSIZE,d7
	move.l	we_Gadgets(a0),a0
	add.l	d7,a0
	tst.w	gg_GadgetType(a0)
	beq	L_GadNotDef
	cmp.w	#STRGADGET,gg_GadgetType(a0)
	bne	L_WrongGadType
	move.w	gg_Activation(a0),d0
	and.w	#LONGINT,d0
	bne	L_WrongGadType
	move.l	gg_SpecialInfo(a0),a0
	move.l	si_Buffer(a0),a0
	lea	.rsc(pc),a1
	jtcall	ReturnString
	ret
.rsc	ds.b	rsc_sizeof


L_SetIpens:		;Set Ipens highlight,shadow
	pstart
	jtcall	GetCurIwin2
	move.l	d0,a1
	move.l	wd_UserData(a1),a0
	movem.l	(a3)+,d6-d7
	cmp.l	#Null,d7
	beq	.shadow
	cmp.l	#255,d7
	bhi	L_IllFunc
	move.b	d7,we_HilitePen(a0)
.shadow	cmp.l	#Null,d6
	beq	.exit
	cmp.l	#255,d6
	bhi	L_IllFunc
	move.b	d6,we_ShadowPen(a0)
.exit	ret

L_IgadgetDown:		;=Igadget Down(n)
	pstart
	jtcall	GetCurIwin2
	move.l	d0,a1
	move.l	wd_UserData(a1),a0
	move.l	(a3)+,d7
	cmp.l	#$10000,d7
	bcc	L_GadNotRes
	cmp.w	we_NGadgets(a0),d7
	bhi	L_GadNotRes
	subq.w	#1,d7
	bmi	L_IllFunc
	mulu	#GADGETSIZE,d7
	move.l	we_Gadgets(a0),a0
	add.l	d7,a0
	tst.w	gg_GadgetType(a0)
	beq	L_GadNotDef
	move.l	gg_UserData(a0),a0
	move.l	#GEF_GADGETDOWN,d0
	and.l	ge_Flags(a0),d0
	sne	d3
	ext.w	d3
	ext.l	d3
	moveq	#0,d2
	ret

L_SetIgadValue:		;Set Igadget Value n,v
	pstart
	jtcall	GetCurIwin2
	move.l	d0,a1
	move.l	wd_UserData(a1),a0
	move.l	(a3)+,d6
	move.l	(a3)+,d7
	cmp.l	#$10000,d7
	bcc	L_GadNotRes
	cmp.w	we_NGadgets(a0),d7
	bhi	L_GadNotRes
	subq.w	#1,d7
	bmi	L_IllFunc
	mulu	#GADGETSIZE,d7
	move.l	we_Gadgets(a0),a0
	add.l	d7,a0
	tst.w	gg_GadgetType(a0)
	beq	L_GadNotDef
	cmp.w	#STRGADGET,gg_GadgetType(a0)
	bne	.oktype
	move.w	gg_Activation(a0),d0
	and.w	#LONGINT,d0
	beq	L_WrongGadType
	movem.l	a0-a1,-(a7)
	exg	a0,a1
	intcall	RemoveGadget
	movem.l	(a7),a0-a1
	move.l	gg_SpecialInfo(a0),a2
	move.l	si_Buffer(a2),a0
	move.l	d6,si_LongInt(a2)
	bpl	.log
	cmp.l	#$80000000,d6
	bne	.neg
	move.l	#'-214',(a0)+
	move.l	#'7483',(a0)+
	move.l	#'648 ',(a0)+
	clr.b	-1(a0)
	bra	.intdon
.neg	move.b	#'-',(a0)+
	neg.l	d6
.log	move.l	d6,d0
.loglp	addq.l	#1,a0
	moveq	#10,d1
	jtcall	LongDiv
	bne	.loglp
	clr.b	(a0)
	move.l	d6,d0
.asclp	moveq	#10,d1
	jtcall	LongDiv
	add.b	#'0',d1
	move.b	d1,-(a0)
	tst.l	d0
	bne	.asclp
.intdon	movem.l	(a7),a0-a1
	move.w	gg_GadgetID(a0),d0
	exg	a0,a1
	intcall	AddGadget
	movem.l	(a7)+,a0-a1
	moveq	#1,d0
	sub.l	a2,a2
	intcall	RefreshGList
	bra	.exit
.oktype	cmp.w	#PROPGADGET,gg_GadgetType(a0)
	beq	.prop
	move.w	#TOGGLESELECT,d0
	and.w	gg_Activation(a0),d0
	beq	L_IllFunc		;Can't set value of a hit-select!
	tst.l	d6
	sne	d6
	ext.w	d6
	and.w	#SELECTED,d6
	move.w	gg_Flags(a0),d0
	and.w	#SELECTED,d0
	cmp.w	d6,d0			;If unchanged, skip the rest
	beq	.exit
	movem.l	a0-a1,-(a7)
	exg	a0,a1
	intcall	RemoveGadget
	movem.l	(a7),a0-a1
	and.w	#~SELECTED,gg_Flags(a0)
	or.w	d6,gg_Flags(a0)
	move.w	gg_GadgetID(a0),d0
	exg	a0,a1
	intcall	AddGadget
	movem.l	(a7)+,a0-a1
	moveq	#1,d0
	sub.l	a2,a2
	intcall	RefreshGList
	bra	.exit
.prop	move.l	gg_SpecialInfo(a0),a2
	move.l	gg_UserData(a0),a6
	move.w	pi_Flags(a2),d0
	move.w	pi_HorizBody(a0),d3
	move.w	pi_VertBody(a0),d4
	moveq	#1,d5
	move.l	ge_NUnits(a6),d7
	sub.l	ge_KnobSize(a6),d7
	ble	.exit
	cmp.l	d7,d6
	bls	.okpos
	move.l	d7,d6
.okpos	move.w	d6,d1
	mulu	#MAXPOT,d1
	divu	d7,d1
	moveq	#-1,d2
	moveq	#FREEVERT,d7
	and.w	d0,d7
	beq	.doprop
	exg	d1,d2
.doprop	sub.l	a2,a2
	intcall	NewModifyProp
.exit	ret

L_SetIgadValueStr:	;Set Igadget Value$ n,v$
	pstart
	jtcall	GetCurIwin2
	move.l	d0,a1
	move.l	wd_UserData(a1),a0
	move.l	(a3)+,d6
	move.l	(a3)+,d7
	cmp.l	#$10000,d7
	bcc	L_GadNotRes
	cmp.w	we_NGadgets(a0),d7
	bhi	L_GadNotRes
	subq.w	#1,d7
	bmi	L_IllFunc
	mulu	#GADGETSIZE,d7
	move.l	we_Gadgets(a0),a0
	add.l	d7,a0
	tst.w	gg_GadgetType(a0)
	beq	L_GadNotDef
	cmp.w	#STRGADGET,gg_GadgetType(a0)
	bne	L_WrongGadType
	move.w	gg_Activation(a0),d0
	and.w	#LONGINT,d0
	bne	L_WrongGadType
	movem.l	a0-a1,-(a7)
	exg	a0,a1
	intcall	RemoveGadget
	move.l	(a7),a0
	move.l	gg_SpecialInfo(a0),a0
	mvoe.l	si_Buffer(a0),a2
	move.l	a2,a1
	move.l	d6,a6
	moveq	#0,d0
	move.w	(a6)+,d0
	cmp.w	si_MaxChars(a0),d0
	bcs	.oksize
	move.w	si_MaxChars(a0),d0
.oksize	move.l	a6,a0
	move.l	d0,d2
	syscall	CopyMem
	clr.b	0(a2,d2.l)
	movem.l	(a7),a0-a1
	move.w	gg_GadgetID(a0),d0
	exg	a0,a1
	intcall	AddGadget
	movem.l	(a7)+,a0-a1
	sub.l	a2,a2
	moveq	#1,d0
	intcall	RefreshGList
	ret

L_IgadToBank:		;Igadget to Bank n
      ifd FOR_LATER
	pstart
	move.l	(a3)+,d0
	beq	L_IllFunc
	cmp.l	#65535,d0
	bhi	L_IllFunc
	move.l	d0,d2
	jtcall	GetCurIwin2
	move.l	d0,a0
	move.l	d2,d0
	move.l	wd_UserData(a0),a6
	moveq	#12,d1
	add.l	we_GadgetSize(a6),d1
	add.l	we_GBorderSize(a6),d1
	move.l	#1<<Bnk_BitData,d2
	jtcall	CreateBank
	tst.l	d0
	beq	L_NoMem
	move.l	d0,a2
	move.l	#'IGad',-8(a2)
	move.l	#'gets',-4(a2)
	move.w	#GBANKREV,(a2)+
	move.w	we_NGadgets(a6),(a2)+
	move.l	we_GadgetSize(a6),(a2)+
	move.l	we_GBorderSize(a6),(a2)+
	move.l	we_Gadgets(a6),a0
	move.l	a2,a1
	move.l	we_GadgetSize(a6),d0
	syscall	CopyMem
	move.l	we_Gadgets(a6),d2
	move.l	we_GBorders(a6),d3
	move.w	we_NGadgets(a6),d1
	subq.w	#1,d1
.ptrlp1	move.l	gg_UserData(a2),a1
	and.l	#~(GEF_DISPLAYED|GEF_GADGETDOWN),ge_Flags(a1)
	clr.w	ge_HitCount(a1)
	sub.l	d2,gg_UserData(a2)
	sub.l	d3,gg_GadgetRender(a2)
	tst.l	gg_SelectRender(a3)
	beq	.nosel
	sub.l	d3,gg_SelectRender(a2)
.nosel	tst.l	gg_SpecialInfo(a3)
	beq	.nospec
	sub.l	d2,gg_SpecialInfo(a2)
.nospec	add.l	#GADGETSIZE,a2
	dbra	d1,.ptrlp1
	move.l	we_GBorders,a0
	move.l	a2,a1
	move.l	we_GBorderSize(a6),d0
	syscall	CopyMem
	move.w	we_NGadgets(a6),d1
	subq.w	#1,d2
.ptrlp2 tst.l	bd_XY(a2)
	beq	.noxy
	sub.l	d3,bd_XY(a2)
	tst.l	bd_XY+bd_sizeof(a2)
	beq	.noxy
	sub.l	d3,bd_XY+bd_sizeof(a2)
.noxy	dbra	d1,.ptrlp2
	ret
      else
	rts
      endc ;FOR_LATER

L_BankToIgad:		;Bank To Igadget n
      ifd FOR_LATER
	pstart
	move.l	(a3)+,d0
	beq	L_IllFunc
	cmp.l	#65535,d0
	bhi	L_IllFunc
	move.l	d0,d2
	jtcall	GetCurIwin2
	move.l	d0,a0
	move.l	d2,d0
	move.l	wd_UserData(a0),a6
	jtcall	GetBankAdr
	beq	L_BankNotDef
	btst	#Bnk_BitBob,d0
	bne	L_IllFunc
	btst	#Bnk_BitIcon,d0
	bne	L_IllFunc
	move.l	a0,a2
	cmp.l	#GADGET_MAGIC,(a2)+
	bne	L_UnknownFmt
	cmp.w	#GBANKREV,(a2)+
	bhi	L_UnknownFmt
;	blo	.oldfmt
	move.w	(a2)+,-(a3)
	bsr	L_ReserveIgadget
	move.l	(a2)+,d2
	move.l	(a2)+,d3
	cmp.l	we_GadgetSize(a6),d2
	beq	.oksize
	cmp.l	we_GBorderSize(a6),d3
	beq	.oksize
	bsr	L_ReserveIgadget0
	bra	L_Inconsistent
.oksize	move.l	a2,a0
	move.l	we_Gadgets(a6),a1
	move.l	d2,d0
	syscall	CopyMem
	add.l	d2,a2
	move.l	a2,a0
	move.l	we_GBorders(a6),a1
	move.l	d3,d0
	syscall	CopyMem
	move.l	we_Gadgets(a6),d2
	move.l	we_GBorders(a6),d3
	move.l	d2,a2
	move.w	we_NGadgets(a6),d1
	subq.w	#1,d1
	move.w	d1,d5
.reloc1	add.l	d2,gg_UserData(a2)
	add.l	d3,gg_GadgetRender(a2)
	tst.l	gg_SelectRender(a2)
	beq	.nosel
	add.l	d3,gg_SelectRender(a2)
.nosel	tst.l	gg_SpecialInfo(a2)
	beq	.nospec
	add.l	d3,gg_SpecialInfo(a2)
	move.w	gg_GadgetType(a2),d0
	and.w	#~GADGETTYPE,d0
	cmp.w	#STRGADGET,d0
	bne	.nospec
	move.l	gg_SpecialInfo(a2),a1
	move.l	a1,d7
	moveq	#0,d0
	move.w	si_MaxChars(a1),d0
	beq	.bad
	subq.w	#1,d0			;L_StrAlloc adds 1 for null byte
	move.l	d0,d6
	jtcall	StrAlloc
	move.l	d7,a1
	move.l	d0,si_Buffer(a1)
	beq	.nomem
	move.l	d0,a0
	clr.b	(a0)
	dcmp.l	GadgetUndoLen,d6
	bls	.undo
	dmove.l	GadgetUndo,a0
	jtcall	StrFree
	move.l	d6,d0
	jtcall	StrAlloc
	tmove.l	d0,GadgetUndo
	beq	.nomem
	move.l	d7,a1
.undo	dmove.l	GadgetUndo,si_UndoBuffer(a1)
.nospec	add.l	#GADGETSIZE,a2
	dbra	d1,.reloc1
	move.l	d3,a2
.reloc2	tst.l	bd_XY(a2)
	beq	.noxy
	add.l	d3,bd_XY(a2)
	tst.l	bd_sizeof+bd_XY(a2)
	beq	.noxy
	add.l	d3,bd_XY(a2)
.noxy	add.l	#BORDERSIZE,a2
	dbra	d5,.reloc2
	ret
.nomem	bsr	L_ReserveIgadget0
	bra	L_NoMem
.bad	bsr	L_ReserveIgadget0
	bra	L_Inconsistent
      else
        rts
      endc ;FOR_LATER
