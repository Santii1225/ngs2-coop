; DISK ONLY; do not infer live control flow from protected bytes

~/.local/share/Steam/steamapps/common/[NINJA GAIDEN Master Collection] NINJA GAIDEN Σ２/NINJA GAIDEN SIGMA2.exe:     file format pei-x86-64


Disassembly of section .text:

0000000141462a00 <.text+0x1461a00>:
   141462a00:	3b 48 c7             	cmp    ecx,DWORD PTR [rax-0x39]
   141462a03:	bb 7f 6e 9c a7       	mov    ebx,0xa79c6e7f
   141462a08:	0d 3c c1 a1 15       	or     eax,0x15a1c13c
   141462a0d:	74 7c                	je     0x141462a8b
   141462a0f:	6f                   	outs   dx,DWORD PTR [rsi]
   141462a10:	28 e0                	sub    al,ah
   141462a12:	09 95 3a a5 7c fd    	or     DWORD PTR [rbp-0x2835ac6],edx
   141462a18:	cb                   	retf
   141462a19:	1a ea                	sbb    ch,dl
   141462a1b:	9d                   	popf
   141462a1c:	b6 cd                	mov    dh,0xcd
   141462a1e:	0c 93                	or     al,0x93
   141462a20:	fb                   	sti
   141462a21:	7a dd                	jp     0x141462a00
   141462a23:	95                   	xchg   ebp,eax
   141462a24:	a1 54 9a 2d cb 57 c6 	movabs eax,ds:0x2d74c657cb2d9a54
   141462a2b:	74 2d 
   141462a2d:	c7                   	(bad)
   141462a2e:	9e                   	sahf
   141462a2f:	61                   	(bad)
   141462a30:	de b9 57 5f 66 48    	fidivr WORD PTR [rcx+0x48665f57]
   141462a36:	0e                   	(bad)
   141462a37:	f9                   	stc
   141462a38:	60                   	(bad)
   141462a39:	be 85 f6 03 ab       	mov    esi,0xab03f685
   141462a3e:	47 e6 41             	rex.RXB out 0x41,al
   141462a41:	62 c1 c8 18 34       	(bad)
   141462a46:	29 51 7f             	sub    DWORD PTR [rcx+0x7f],edx
   141462a49:	ce                   	(bad)
   141462a4a:	d5 62 37             	{rex2 0x62} (bad)
   141462a4d:	46 5f                	rex.RX pop rdi
   141462a4f:	f0 a7                	lock cmps DWORD PTR [rsi],DWORD PTR [rdi]
   141462a51:	b6 35                	mov    dh,0x35
   141462a53:	73 ac                	jae    0x141462a01
   141462a55:	e3 ce                	jrcxz  0x141462a25
   141462a57:	4b bc ef f3 59 cd 90 	rex.WXB movabs r12,0xef7b9490cd59f3ef
   141462a5e:	94 7b ef 
   141462a61:	4d 69 61 1f fa 7b b1 	imul   r12,QWORD PTR [r9+0x1f],0x21b17bfa
   141462a68:	21 
   141462a69:	14 4b                	adc    al,0x4b
   141462a6b:	5b                   	pop    rbx
   141462a6c:	2d c1 4b 66 9a       	sub    eax,0x9a664bc1
   141462a71:	54                   	push   rsp
   141462a72:	94                   	xchg   esp,eax
   141462a73:	28 ff                	sub    bh,bh
   141462a75:	42 b6 20             	rex.X mov sil,0x20
   141462a78:	c4                   	(bad)
   141462a79:	3c f1                	cmp    al,0xf1
   141462a7b:	53                   	push   rbx
   141462a7c:	b6 8c                	mov    dh,0x8c
   141462a7e:	c5 fd bf             	(bad)
   141462a81:	b9 9e 21 de 97       	mov    ecx,0x97de219e
   141462a86:	c3                   	ret
   141462a87:	32 71 09             	xor    dh,BYTE PTR [rcx+0x9]
   141462a8a:	74 32                	je     0x141462abe
   141462a8c:	5a                   	pop    rdx
   141462a8d:	f6 55 a1             	not    BYTE PTR [rbp-0x5f]
   141462a90:	b0 2f                	mov    al,0x2f
   141462a92:	d3 a3 f1 48 dd 4b    	shl    DWORD PTR [rbx+0x4bdd48f1],cl
   141462a98:	48 82                	rex.W (bad)
   141462a9a:	6f                   	outs   dx,DWORD PTR [rsi]
   141462a9b:	14 c0                	adc    al,0xc0
   141462a9d:	f6 ad 9c 6f 50 12    	imul   BYTE PTR [rbp+0x12506f9c]
   141462aa3:	e4 9b                	in     al,0x9b
   141462aa5:	f7 37                	div    DWORD PTR [rdi]
   141462aa7:	ae                   	scas   al,BYTE PTR [rdi]
   141462aa8:	4b 6e                	rex.WXB outs dx,BYTE PTR [rsi]
   141462aaa:	88 61 44             	mov    BYTE PTR [rcx+0x44],ah
   141462aad:	71 90                	jno    0x141462a3f
   141462aaf:	88 a5 2d 2a cd a9    	mov    BYTE PTR [rbp-0x5632d5d3],ah
   141462ab5:	21 ad de 5a 4d 12    	and    DWORD PTR [rbp+0x124d5ade],ebp
   141462abb:	c3                   	ret
   141462abc:	f8                   	clc
   141462abd:	17                   	(bad)
   141462abe:	81 80 85 97 3f eb 9c 	add    DWORD PTR [rax-0x14c0687b],0x7ec94c9c
   141462ac5:	4c c9 7e 
   141462ac8:	fa                   	cli
   141462ac9:	6d                   	ins    DWORD PTR [rdi],dx
   141462aca:	12 f9                	adc    bh,cl
   141462acc:	1b ad 56 40 d9 12    	sbb    ebp,DWORD PTR [rbp+0x12d94056]
   141462ad2:	df 2f                	fild   QWORD PTR [rdi]
   141462ad4:	ef                   	out    dx,eax
   141462ad5:	05 61 99 08 a0       	add    eax,0xa0089961
   141462ada:	78 e1                	js     0x141462abd
   141462adc:	d7                   	xlat   BYTE PTR [rbx]
   141462add:	03 0d a3 2a 18 c6    	add    ecx,DWORD PTR [rip+0xffffffffc6182aa3]        # 0x1075e5586
   141462ae3:	08 6a 70             	or     BYTE PTR [rdx+0x70],ch
   141462ae6:	c9                   	leave
   141462ae7:	65 13 c6             	gs adc eax,esi
   141462aea:	07                   	(bad)
   141462aeb:	d4                   	(bad)
   141462aec:	bf a3 28 d2 c3       	mov    edi,0xc3d228a3
   141462af1:	24 dc                	and    al,0xdc
   141462af3:	7d 6d                	jge    0x141462b62
   141462af5:	33 0c 94             	xor    ecx,DWORD PTR [rsp+rdx*4]
   141462af8:	ff aa 7f 4e ee 22    	jmp    FWORD PTR [rdx+0x22ee4e7f]
   141462afe:	bf 80 00 e5 a7       	mov    edi,0xa7e50080
   141462b03:	40 18 60 1e          	sbb    BYTE PTR [rax+0x1e],spl
   141462b07:	64 54                	fs push rsp
   141462b09:	ef                   	out    dx,eax
   141462b0a:	d6                   	udb
   141462b0b:	59                   	pop    rcx
   141462b0c:	20 72 4a             	and    BYTE PTR [rdx+0x4a],dh
   141462b0f:	4f e7 6e             	rex.WRXB out 0x6e,eax
   141462b12:	11 f5                	adc    ebp,esi
   141462b14:	62 ac 11 36 cd       	(bad)
   141462b19:	72 61                	jb     0x141462b7c
   141462b1b:	5e                   	pop    rsi
   141462b1c:	fe c2                	inc    dl
   141462b1e:	eb 3c                	jmp    0x141462b5c
   141462b20:	5b                   	pop    rbx
   141462b21:	78 61                	js     0x141462b84
   141462b23:	db 0f                	fisttp DWORD PTR [rdi]
   141462b25:	07                   	(bad)
   141462b26:	51                   	push   rcx
   141462b27:	3c a0                	cmp    al,0xa0
   141462b29:	b7 7e                	mov    bh,0x7e
   141462b2b:	b9 dc 61 10 80       	mov    ecx,0x801061dc
   141462b30:	61                   	(bad)
   141462b31:	ca e9 7e             	retf   0x7ee9
   141462b34:	7b 88                	jnp    0x141462abe
   141462b36:	6b 13 7b             	imul   edx,DWORD PTR [rbx],0x7b
   141462b39:	8e 37                	mov    ?,WORD PTR [rdi]
   141462b3b:	d5 22 c2 be 40       	{rex2 0x22} ret 0x40be
   141462b40:	02 8f b0 53 eb 96    	add    cl,BYTE PTR [rdi-0x6914ac50]
   141462b46:	cc                   	int3
   141462b47:	03 4a 1a             	add    ecx,DWORD PTR [rdx+0x1a]
   141462b4a:	67 71 9f             	addr32 jno 0x141462aec
   141462b4d:	85 a6 5e 0f 5a d4    	test   DWORD PTR [rsi-0x2ba5f0a2],esp
   141462b53:	92                   	xchg   edx,eax
   141462b54:	a0 6e 63 fa 01 8f c0 	movabs al,ds:0xca3fc08f01fa636e
   141462b5b:	3f ca 
   141462b5d:	1a 8c 83 0c 20 61 31 	sbb    cl,BYTE PTR [rbx+rax*4+0x3161200c]
   141462b64:	6a 76                	push   0x76
   141462b66:	bc ef 12 fd 93       	mov    esp,0x93fd12ef
   141462b6b:	7a 6b                	jp     0x141462bd8
   141462b6d:	1e                   	(bad)
   141462b6e:	19 ba a5 14 20 03    	sbb    DWORD PTR [rdx+0x32014a5],edi
   141462b74:	69 b5 3c b6 fa 3f 4d 	imul   esi,DWORD PTR [rbp+0x3ffab63c],0x6044104d
   141462b7b:	10 44 60 
   141462b7e:	34 eb                	xor    al,0xeb
   141462b80:	ef                   	out    dx,eax
   141462b81:	58                   	pop    rax
   141462b82:	03 bf 31 a1 f7 db    	add    edi,DWORD PTR [rdi-0x24085ecf]
   141462b88:	fb                   	sti
   141462b89:	f0 ae                	lock scas al,BYTE PTR [rdi]
   141462b8b:	53                   	push   rbx
   141462b8c:	b6 28                	mov    dh,0x28
   141462b8e:	b7 33                	mov    bh,0x33
   141462b90:	dc d6                	(bad)
   141462b92:	ca a0 9c             	retf   0x9ca0
   141462b95:	d3 b6 39 dd f9 7e    	shl    DWORD PTR [rsi+0x7ef9dd39],cl
   141462b9b:	0f 18 4d 61          	prefetcht0 BYTE PTR [rbp+0x61]
   141462b9f:	7d 5a                	jge    0x141462bfb
   141462ba1:	2f                   	(bad)
   141462ba2:	b8 8e 14 75 33       	mov    eax,0x3375148e
   141462ba7:	95                   	xchg   ebp,eax
   141462ba8:	67 cc                	addr32 int3
   141462baa:	ce                   	(bad)
   141462bab:	70 c8                	jo     0x141462b75
   141462bad:	a6                   	cmps   BYTE PTR [rsi],BYTE PTR [rdi]
   141462bae:	5d                   	pop    rbp
   141462baf:	16                   	(bad)
   141462bb0:	d6                   	udb
   141462bb1:	cc                   	int3
   141462bb2:	fd                   	std
   141462bb3:	7c 68                	jl     0x141462c1d
   141462bb5:	8e 08                	mov    cs,WORD PTR [rax]
   141462bb7:	59                   	pop    rcx
   141462bb8:	e9 73 d2 64 4e       	jmp    0x18faafe30
   141462bbd:	bc 1b 79 03 b4       	mov    esp,0xb403791b
   141462bc2:	0d cd 54 55 3e       	or     eax,0x3e5554cd
   141462bc7:	c2 53 23             	ret    0x2353
   141462bca:	e0 8e                	loopne 0x141462b5a
   141462bcc:	3e 98                	ds cwde
   141462bce:	36 71 2e             	ss jno 0x141462bff
   141462bd1:	1a d3                	sbb    dl,bl
   141462bd3:	b4 41                	mov    ah,0x41
   141462bd5:	1c 95                	sbb    al,0x95
   141462bd7:	9b                   	fwait
   141462bd8:	11 89 44 65 b9 b7    	adc    DWORD PTR [rcx-0x48469abc],ecx
   141462bde:	ae                   	scas   al,BYTE PTR [rdi]
   141462bdf:	01 12                	add    DWORD PTR [rdx],edx
   141462be1:	ca b0 20             	retf   0x20b0
   141462be4:	99                   	cdq
   141462be5:	a0 10 d5 67 04 74 e9 	movabs al,ds:0x23ffe9740467d510
   141462bec:	ff 23 
   141462bee:	b9 a5 85 42 da       	mov    ecx,0xda4285a5
   141462bf3:	fd                   	std
   141462bf4:	52                   	push   rdx
   141462bf5:	f0 15 c2 a7 8a 0e    	lock adc eax,0xe8aa7c2
   141462bfb:	6a 5f                	push   0x5f
   141462bfd:	69 c4 68 ad f8 90    	imul   eax,esp,0x90f8ad68
   141462c03:	bc 7f f5 53 81       	mov    esp,0x8153f57f
   141462c08:	66 f2 ad             	repnz lods ax,WORD PTR [rsi]
   141462c0b:	df c4                	ffreep st(4)
   141462c0d:	01 dd                	add    ebp,ebx
   141462c0f:	99                   	cdq
   141462c10:	b9 5b a3 6a 5e       	mov    ecx,0x5e6aa35b
   141462c15:	8c 13                	mov    WORD PTR [rbx],ss
   141462c17:	70 c3                	jo     0x141462bdc
   141462c19:	49 f5                	rex.WB cmc
   141462c1b:	d5 27 12 00          	{rex2 0x27} adc r8b,BYTE PTR [r8]
   141462c1f:	db 0c a3             	fisttp DWORD PTR [rbx+riz*4]
   141462c22:	a3 23 04 62 0f 28 57 	movabs ds:0xf42057280f620423,eax
   141462c29:	20 f4 
   141462c2b:	15 dc 00 e8 3d       	adc    eax,0x3de800dc
   141462c30:	07                   	(bad)
   141462c31:	97                   	xchg   edi,eax
   141462c32:	60                   	(bad)
   141462c33:	34 79                	xor    al,0x79
   141462c35:	70 bb                	jo     0x141462bf2
   141462c37:	9d                   	popf
   141462c38:	70 9a                	jo     0x141462bd4
   141462c3a:	6c                   	ins    BYTE PTR [rdi],dx
   141462c3b:	40 e5 16             	rex in eax,0x16
   141462c3e:	fe                   	(bad)
   141462c3f:	3f                   	(bad)
   141462c40:	2d 91 a5 29 b3       	sub    eax,0xb329a591
   141462c45:	b7 23                	mov    bh,0x23
   141462c47:	dd d0                	fst    st(0)
   141462c49:	ad                   	lods   eax,DWORD PTR [rsi]
   141462c4a:	18 36                	sbb    BYTE PTR [rsi],dh
   141462c4c:	e0 87                	loopne 0x141462bd5
   141462c4e:	d1 a3 02 7b 14 37    	shl    DWORD PTR [rbx+0x37147b02],1
   141462c54:	d9 16                	fst    DWORD PTR [rsi]
   141462c56:	29 bd 2f 73 e4 cf    	sub    DWORD PTR [rbp-0x301b8cd1],edi
   141462c5c:	1c 6b                	sbb    al,0x6b
   141462c5e:	2c d4                	sub    al,0xd4
   141462c60:	38 6a 7f             	cmp    BYTE PTR [rdx+0x7f],ch
   141462c63:	35 49 dc bb 7c       	xor    eax,0x7cbbdc49
   141462c68:	65 d3 bb 4e e7 18 79 	sar    DWORD PTR gs:[rbx+0x7918e74e],cl
   141462c6f:	37                   	(bad)
   141462c70:	2e cd b0             	cs int 0xb0
   141462c73:	ea                   	(bad)
   141462c74:	a4                   	movs   BYTE PTR [rdi],BYTE PTR [rsi]
   141462c75:	38 9a db b6 cd f2    	cmp    BYTE PTR [rdx-0xd324925],bl
   141462c7b:	a5                   	movs   DWORD PTR [rdi],DWORD PTR [rsi]
   141462c7c:	cb                   	retf
   141462c7d:	50                   	push   rax
   141462c7e:	4c c2 f7 b2          	rex.WR ret 0xb2f7
   141462c82:	79 81                	jns    0x141462c05
   141462c84:	d4                   	(bad)
   141462c85:	0e                   	(bad)
   141462c86:	55                   	push   rbp
   141462c87:	dd 57 c4             	fst    QWORD PTR [rdi-0x3c]
   141462c8a:	29 82 95 e2 a1 ce    	sub    DWORD PTR [rdx-0x315e1d6b],eax
   141462c90:	03 cc                	add    ecx,esp
   141462c92:	1e                   	(bad)
   141462c93:	ae                   	scas   al,BYTE PTR [rdi]
   141462c94:	cd e3                	int    0xe3
   141462c96:	bc a9 d5 73 92       	mov    esp,0x9273d5a9
   141462c9b:	bf 91 51 09 e2       	mov    edi,0xe2095191
   141462ca0:	9e                   	sahf
   141462ca1:	02 ad 67 c8 de 04    	add    ch,BYTE PTR [rbp+0x4dec867]
   141462ca7:	1e                   	(bad)
   141462ca8:	97                   	xchg   edi,eax
   141462ca9:	30 5e f1             	xor    BYTE PTR [rsi-0xf],bl
   141462cac:	91                   	xchg   ecx,eax
   141462cad:	9b                   	fwait
   141462cae:	97                   	xchg   edi,eax
   141462caf:	2b 8c 04 2b 68 20 81 	sub    ecx,DWORD PTR [rsp+rax*1-0x7edf97d5]
   141462cb6:	20 af 0f 69 49 04    	and    BYTE PTR [rdi+0x449690f],ch
   141462cbc:	c4                   	(bad)
   141462cbd:	b7 bd                	mov    bh,0xbd
   141462cbf:	0a 1d fa 49 e7 54    	or     bl,BYTE PTR [rip+0x54e749fa]        # 0x1962d76bf
   141462cc5:	ba 59 5d ba 21       	mov    edx,0x21ba5d59
   141462cca:	9d                   	popf
   141462ccb:	90                   	nop
   141462ccc:	1c 2c                	sbb    al,0x2c
   141462cce:	fc                   	cld
   141462ccf:	f2 b7 90             	repnz mov bh,0x90
   141462cd2:	10 d0                	adc    al,dl
   141462cd4:	b2 09                	mov    dl,0x9
   141462cd6:	9d                   	popf
   141462cd7:	25 2d 54 ef 23       	and    eax,0x23ef542d
   141462cdc:	70 c7                	jo     0x141462ca5
   141462cde:	ac                   	lods   al,BYTE PTR [rsi]
   141462cdf:	c9                   	leave
   141462ce0:	dd 50 42             	fst    QWORD PTR [rax+0x42]
   141462ce3:	d6                   	udb
   141462ce4:	a2 25 79 a7 fd 42 3b 	movabs ds:0xf7293b42fda77925,al
   141462ceb:	29 f7 
   141462ced:	ca 4f 55             	retf   0x554f
   141462cf0:	c4                   	(bad)
   141462cf1:	d7                   	xlat   BYTE PTR [rbx]
   141462cf2:	f6 75 e2             	div    BYTE PTR [rbp-0x1e]
   141462cf5:	90                   	nop
   141462cf6:	c0             	ror    BYTE PTR [rdx+0x3c],0x32
