; ON-DISK bytes only; potentially Steam-protected, not live instructions.

~/.local/share/Steam/steamapps/common/[NINJA GAIDEN Master Collection] NINJA GAIDEN Σ２/NINJA GAIDEN SIGMA2.exe:     file format pei-x86-64


Disassembly of section .text:

0000000141462900 <.text+0x1461900>:
   141462900:	05 5c 0a 12 65       	add    eax,0x65120a5c
   141462905:	58                   	pop    rax
   141462906:	9e                   	sahf
   141462907:	05 1d 40 51 9f       	add    eax,0x9f51401d
   14146290c:	d6                   	udb
   14146290d:	dc 6c 42 fc          	fsubr  QWORD PTR [rdx+rax*2-0x4]
   141462911:	f9                   	stc
   141462912:	a6                   	cmps   BYTE PTR [rsi],BYTE PTR [rdi]
   141462913:	39 62 ab             	cmp    DWORD PTR [rdx-0x55],esp
   141462916:	a8 88                	test   al,0x88
   141462918:	23 b2 1a cc 4d cb    	and    esi,DWORD PTR [rdx-0x34b233e6]
   14146291e:	bc c4 ce 4a 32       	mov    esp,0x324acec4
   141462923:	0a dd                	or     bl,ch
   141462925:	d3 8f c3 d1 24 5d    	ror    DWORD PTR [rdi+0x5d24d1c3],cl
   14146292b:	a1 df 0a b8 0b b8 dc 	movabs eax,ds:0x9268dcb80bb80adf
   141462932:	68 92 
   141462934:	2b 99 05 f5 73 8e    	sub    ebx,DWORD PTR [rcx-0x718c0afb]
   14146293a:	70 1b                	jo     0x141462957
   14146293c:	bf 37 3e b2 bb       	mov    edi,0xbbb23e37
   141462941:	12 5a 7d             	adc    bl,BYTE PTR [rdx+0x7d]
   141462944:	26 fb                	es sti
   141462946:	bb 61 59 4a 94       	mov    ebx,0x944a5961
   14146294b:	cf                   	iret
   14146294c:	ba ad 1a 79 19       	mov    edx,0x19791aad
   141462951:	a7                   	cmps   DWORD PTR [rsi],DWORD PTR [rdi]
   141462952:	12 03                	adc    al,BYTE PTR [rbx]
   141462954:	bd f9 1d 75 d0       	mov    ebp,0xd0751df9
   141462959:	5b                   	pop    rbx
   14146295a:	ef                   	out    dx,eax
   14146295b:	e0 eb                	loopne 0x141462948
   14146295d:	6c                   	ins    BYTE PTR [rdi],dx
   14146295e:	79 f5                	jns    0x141462955
   141462960:	8d 09                	lea    ecx,[rcx]
   141462962:	1c 3b                	sbb    al,0x3b
   141462964:	30 d9                	xor    cl,bl
   141462966:	6e                   	outs   dx,BYTE PTR [rsi]
   141462967:	32 9e 23 82 30 53    	xor    bl,BYTE PTR [rsi+0x53308223]
   14146296d:	47                   	rex.RXB
   14146296e:	64 a2 a0 fa 6f 70 f3 	movabs fs:0x668f72f3706ffaa0,al
   141462975:	72 8f 66 
   141462978:	e7 a1                	out    0xa1,eax
   14146297a:	e7 1a                	out    0x1a,eax
   14146297c:	b7 b5                	mov    bh,0xb5
   14146297e:	bf c9 1f aa 06       	mov    edi,0x6aa1fc9
   141462983:	e5 20                	in     eax,0x20
   141462985:	03 b5 fb fe 41 e3    	add    esi,DWORD PTR [rbp-0x1cbe0105]
   14146298b:	3c 1e                	cmp    al,0x1e
   14146298d:	aa                   	stos   BYTE PTR [rdi],al
   14146298e:	84 ca                	test   dl,cl
   141462990:	7c 5f                	jl     0x1414629f1
   141462992:	a4                   	movs   BYTE PTR [rdi],BYTE PTR [rsi]
   141462993:	0c 13                	or     al,0x13
   141462995:	ed                   	in     eax,dx
   141462996:	72 81                	jb     0x141462919
   141462998:	82                   	(bad)
   141462999:	bf ed b5 a3 61       	mov    edi,0x61a3b5ed
   14146299e:	8a a3 80 f1 9f ca    	mov    ah,BYTE PTR [rbx-0x35600e80]
   1414629a4:	77 02                	ja     0x1414629a8
   1414629a6:	33 a4 47 2c 70 10 39 	xor    esp,DWORD PTR [rdi+rax*2+0x3910702c]
   1414629ad:	00 4d 13             	add    BYTE PTR [rbp+0x13],cl
   1414629b0:	3c e4                	cmp    al,0xe4
   1414629b2:	69 e5 23 77 f4 57    	imul   esp,ebp,0x57f47723
   1414629b8:	b2 0d                	mov    dl,0xd
   1414629ba:	4b 06                	rex.WXB (bad)
   1414629bc:	be 8a 45 8e b4       	mov    esi,0xb48e458a
   1414629c1:	a9 88 fa 32 53       	test   eax,0x5332fa88
   1414629c6:	a5                   	movs   DWORD PTR [rdi],DWORD PTR [rsi]
   1414629c7:	1a 92 16 d7 46 09    	sbb    dl,BYTE PTR [rdx+0x946d716]
   1414629cd:	aa                   	stos   BYTE PTR [rdi],al
   1414629ce:	af                   	scas   eax,DWORD PTR [rdi]
   1414629cf:	64 8b e9             	fs mov ebp,ecx
   1414629d2:	bf 38 04 a8 9a       	mov    edi,0x9aa80438
   1414629d7:	72 b0                	jb     0x141462989
   1414629d9:	98                   	cwde
   1414629da:	8f                   	(bad)
   1414629db:	70 52                	jo     0x141462a2f
   1414629dd:	72 bf                	jb     0x14146299e
   1414629df:	32 67 b0             	xor    ah,BYTE PTR [rdi-0x50]
   1414629e2:	2f                   	(bad)
   1414629e3:	01 70 fe             	add    DWORD PTR [rax-0x2],esi
   1414629e6:	91                   	xchg   ecx,eax
   1414629e7:	fc                   	cld
   1414629e8:	ef                   	out    dx,eax
   1414629e9:	89 20                	mov    DWORD PTR [rax],esp
   1414629eb:	68 eb dc c0 0e       	push   0xec0dceb
   1414629f0:	d1 80 80 50 22 a0    	rol    DWORD PTR [rax-0x5fddaf80],1
   1414629f6:	5d                   	pop    rbp
   1414629f7:	5b                   	pop    rbx
   1414629f8:	1c 6a                	sbb    al,0x6a
   1414629fa:	6b e4 b4             	imul   esp,esp,0xffffffb4
   1414629fd:	e2 0a                	loop   0x141462a09
   1414629ff:	d7                   	xlat   BYTE PTR [rbx]
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
   141462bfd:	69 c4 68       	imul   eax,esp,0x90f8ad68
