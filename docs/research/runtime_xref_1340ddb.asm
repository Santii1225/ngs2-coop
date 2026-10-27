; RUNTIME MEMORY pid 51579; function metadata (20187872, 20189138, 29363800)

docs/research/runtime_xref_1340ddb.bin:     file format binary


Disassembly of section .data:

0000000141340ae0 <.data>:
   141340ae0:	48 8b c4             	mov    rax,rsp
   141340ae3:	55                   	push   rbp
   141340ae4:	48 8d 68 a1          	lea    rbp,[rax-0x5f]
   141340ae8:	48 81 ec e0 00 00 00 	sub    rsp,0xe0
   141340aef:	48 c7 45 07 fe ff ff 	mov    QWORD PTR [rbp+0x7],0xfffffffffffffffe
   141340af6:	ff 
   141340af7:	48 89 58 08          	mov    QWORD PTR [rax+0x8],rbx
   141340afb:	48 89 70 10          	mov    QWORD PTR [rax+0x10],rsi
   141340aff:	48 89 78 18          	mov    QWORD PTR [rax+0x18],rdi
   141340b03:	4c 89 70 20          	mov    QWORD PTR [rax+0x20],r14
   141340b07:	0f 29 70 e8          	movaps XMMWORD PTR [rax-0x18],xmm6
   141340b0b:	48 8b 05 3e d2 90 00 	mov    rax,QWORD PTR [rip+0x90d23e]        # 0x141c4dd50
   141340b12:	48 33 c4             	xor    rax,rsp
   141340b15:	48 89 45 37          	mov    QWORD PTR [rbp+0x37],rax
   141340b19:	49 8b f8             	mov    rdi,r8
   141340b1c:	48 8b f1             	mov    rsi,rcx
   141340b1f:	45 33 f6             	xor    r14d,r14d
   141340b22:	66 44 89 75 b7       	mov    WORD PTR [rbp-0x49],r14w
   141340b27:	4c 8d 45 b7          	lea    r8,[rbp-0x49]
   141340b2b:	48 8d 4d 0f          	lea    rcx,[rbp+0xf]
   141340b2f:	e8 8c 78 82 ff       	call   0x140b683c0
   141340b34:	48 8b 45 17          	mov    rax,QWORD PTR [rbp+0x17]
   141340b38:	4c 8b d0             	mov    r10,rax
   141340b3b:	4c 8b 4d 0f          	mov    r9,QWORD PTR [rbp+0xf]
   141340b3f:	4d 2b d1             	sub    r10,r9
   141340b42:	49 d1 fa             	sar    r10,1
   141340b45:	41 8b ca             	mov    ecx,r10d
   141340b48:	49 3b ca             	cmp    rcx,r10
   141340b4b:	75 5e                	jne    0x141340bab
   141340b4d:	48 8d 45 0f          	lea    rax,[rbp+0xf]
   141340b51:	48 89 45 c7          	mov    QWORD PTR [rbp-0x39],rax
   141340b55:	48 8d 45 b7          	lea    rax,[rbp-0x49]
   141340b59:	48 89 45 cf          	mov    QWORD PTR [rbp-0x31],rax
   141340b5d:	0f 28 75 c7          	movaps xmm6,XMMWORD PTR [rbp-0x39]
   141340b61:	66 44 89 75 b7       	mov    WORD PTR [rbp-0x49],r14w
   141340b66:	66 0f 7f 75 c7       	movdqa XMMWORD PTR [rbp-0x39],xmm6
   141340b6b:	43 8d 14 12          	lea    edx,[r10+r10*1]
   141340b6f:	4c 8d 45 c7          	lea    r8,[rbp-0x39]
   141340b73:	48 8d 4d 0f          	lea    rcx,[rbp+0xf]
   141340b77:	e8 44 8a 83 ff       	call   0x140b795c0
   141340b7c:	4c 8b 45 17          	mov    r8,QWORD PTR [rbp+0x17]
   141340b80:	48 8b 55 0f          	mov    rdx,QWORD PTR [rbp+0xf]
   141340b84:	4c 2b c2             	sub    r8,rdx
   141340b87:	49 d1 f8             	sar    r8,1
   141340b8a:	33 c9                	xor    ecx,ecx
   141340b8c:	ff 15 a6 d5 45 00    	call   QWORD PTR [rip+0x45d5a6]        # 0x14179e138
   141340b92:	44 8b d0             	mov    r10d,eax
   141340b95:	48 8b 45 17          	mov    rax,QWORD PTR [rbp+0x17]
   141340b99:	48 8b d0             	mov    rdx,rax
   141340b9c:	4c 8b 4d 0f          	mov    r9,QWORD PTR [rbp+0xf]
   141340ba0:	49 2b d1             	sub    rdx,r9
   141340ba3:	48 d1 fa             	sar    rdx,1
   141340ba6:	4c 3b d2             	cmp    r10,rdx
   141340ba9:	74 b6                	je     0x141340b61
   141340bab:	49 3b c1             	cmp    rax,r9
   141340bae:	74 22                	je     0x141340bd2
   141340bb0:	48 8d 48 fe          	lea    rcx,[rax-0x2]
   141340bb4:	66 83 39 5c          	cmp    WORD PTR [rcx],0x5c
   141340bb8:	74 0a                	je     0x141340bc4
   141340bba:	48 8b c1             	mov    rax,rcx
   141340bbd:	49 3b c9             	cmp    rcx,r9
   141340bc0:	75 ee                	jne    0x141340bb0
   141340bc2:	eb 0e                	jmp    0x141340bd2
   141340bc4:	49 3b c1             	cmp    rax,r9
   141340bc7:	74 09                	je     0x141340bd2
   141340bc9:	66 44 89 70 fe       	mov    WORD PTR [rax-0x2],r14w
   141340bce:	4c 8b 4d 0f          	mov    r9,QWORD PTR [rbp+0xf]
   141340bd2:	49 8b c9             	mov    rcx,r9
   141340bd5:	ff 15 05 d6 45 00    	call   QWORD PTR [rip+0x45d605]        # 0x14179e1e0
   141340bdb:	48 8b 4d 0f          	mov    rcx,QWORD PTR [rbp+0xf]
   141340bdf:	48 8b d1             	mov    rdx,rcx
   141340be2:	48 8b 45 17          	mov    rax,QWORD PTR [rbp+0x17]
   141340be6:	48 3b c8             	cmp    rcx,rax
   141340be9:	74 14                	je     0x141340bff
   141340beb:	0f 1f 44 00 00       	nop    DWORD PTR [rax+rax*1+0x0]
   141340bf0:	66 44 39 32          	cmp    WORD PTR [rdx],r14w
   141340bf4:	74 75                	je     0x141340c6b
   141340bf6:	48 83 c2 02          	add    rdx,0x2
   141340bfa:	48 3b d0             	cmp    rdx,rax
   141340bfd:	75 f1                	jne    0x141340bf0
   141340bff:	48 85 c9             	test   rcx,rcx
   141340c02:	74 37                	je     0x141340c3b
   141340c04:	48 8b 55 1f          	mov    rdx,QWORD PTR [rbp+0x1f]
   141340c08:	48 2b d1             	sub    rdx,rcx
   141340c0b:	48 d1 fa             	sar    rdx,1
   141340c0e:	48 03 d2             	add    rdx,rdx
   141340c11:	48 8b c1             	mov    rax,rcx
   141340c14:	48 81 fa 00 10 00 00 	cmp    rdx,0x1000
   141340c1b:	72 19                	jb     0x141340c36
   141340c1d:	48 83 c2 27          	add    rdx,0x27
   141340c21:	48 8b 49 f8          	mov    rcx,QWORD PTR [rcx-0x8]
   141340c25:	48 2b c1             	sub    rax,rcx
   141340c28:	48 83 c0 f8          	add    rax,0xfffffffffffffff8
   141340c2c:	48 83 f8 1f          	cmp    rax,0x1f
   141340c30:	0f 87 96 03 00 00    	ja     0x141340fcc
   141340c36:	e8 7d b4 b3 ff       	call   0x140e7c0b8
   141340c3b:	33 c0                	xor    eax,eax
   141340c3d:	48 8b 4d 37          	mov    rcx,QWORD PTR [rbp+0x37]
   141340c41:	48 33 cc             	xor    rcx,rsp
   141340c44:	e8 57 a5 b3 ff       	call   0x140e7b1a0
   141340c49:	4c 8d 9c 24 e0 00 00 	lea    r11,[rsp+0xe0]
   141340c50:	00 
   141340c51:	49 8b 5b 10          	mov    rbx,QWORD PTR [r11+0x10]
   141340c55:	49 8b 73 18          	mov    rsi,QWORD PTR [r11+0x18]
   141340c59:	49 8b 7b 20          	mov    rdi,QWORD PTR [r11+0x20]
   141340c5d:	4d 8b 73 28          	mov    r14,QWORD PTR [r11+0x28]
   141340c61:	41 0f 28 73 f0       	movaps xmm6,XMMWORD PTR [r11-0x10]
   141340c66:	49 8b e3             	mov    rsp,r11
   141340c69:	5d                   	pop    rbp
   141340c6a:	c3                   	ret
   141340c6b:	48 3b d0             	cmp    rdx,rax
   141340c6e:	74 8f                	je     0x141340bff
   141340c70:	48 8b c2             	mov    rax,rdx
   141340c73:	48 2b c1             	sub    rax,rcx
   141340c76:	48 83 e0 fe          	and    rax,0xfffffffffffffffe
   141340c7a:	48 3d 90 01 00 00    	cmp    rax,0x190
   141340c80:	0f 8f 79 ff ff ff    	jg     0x141340bff
   141340c86:	4c 8d 0d 0d 14 4c 00 	lea    r9,[rip+0x4c140d]        # 0x14180209a
   141340c8d:	4c 8d 05 e4 13 4c 00 	lea    r8,[rip+0x4c13e4]        # 0x141802078
   141340c94:	48 8d 4d 0f          	lea    rcx,[rbp+0xf]
   141340c98:	e8 23 e3 83 ff       	call   0x140b7efc0
   141340c9d:	48 8b 4d 0f          	mov    rcx,QWORD PTR [rbp+0xf]
   141340ca1:	ff 15 11 d5 45 00    	call   QWORD PTR [rip+0x45d511]        # 0x14179e1b8
   141340ca7:	b9 f6 1e 18 00       	mov    ecx,0x181ef6
   141340cac:	ff 15 7e dd 45 00    	call   QWORD PTR [rip+0x45dd7e]        # 0x14179ea30
   141340cb2:	48 8b 4d 0f          	mov    rcx,QWORD PTR [rbp+0xf]
   141340cb6:	84 c0                	test   al,al
   141340cb8:	74 44                	je     0x141340cfe
   141340cba:	48 85 c9             	test   rcx,rcx
   141340cbd:	0f 84 78 ff ff ff    	je     0x141340c3b
   141340cc3:	48 8b 55 1f          	mov    rdx,QWORD PTR [rbp+0x1f]
   141340cc7:	48 2b d1             	sub    rdx,rcx
   141340cca:	48 d1 fa             	sar    rdx,1
   141340ccd:	48 03 d2             	add    rdx,rdx
   141340cd0:	48 8b c1             	mov    rax,rcx
   141340cd3:	48 81 fa 00 10 00 00 	cmp    rdx,0x1000
   141340cda:	0f 82 56 ff ff ff    	jb     0x141340c36
   141340ce0:	48 83 c2 27          	add    rdx,0x27
   141340ce4:	48 8b 49 f8          	mov    rcx,QWORD PTR [rcx-0x8]
   141340ce8:	48 2b c1             	sub    rax,rcx
   141340ceb:	48 83 c0 f8          	add    rax,0xfffffffffffffff8
   141340cef:	48 83 f8 1f          	cmp    rax,0x1f
   141340cf3:	0f 87 bf 02 00 00    	ja     0x141340fb8
   141340cf9:	e9 38 ff ff ff       	jmp    0x141340c36
   141340cfe:	48 85 c9             	test   rcx,rcx
   141340d01:	74 38                	je     0x141340d3b
   141340d03:	48 8b 45 1f          	mov    rax,QWORD PTR [rbp+0x1f]
   141340d07:	48 2b c1             	sub    rax,rcx
   141340d0a:	48 d1 f8             	sar    rax,1
   141340d0d:	48 8d 14 00          	lea    rdx,[rax+rax*1]
   141340d11:	48 8b c1             	mov    rax,rcx
   141340d14:	48 81 fa 00 10 00 00 	cmp    rdx,0x1000
   141340d1b:	72 19                	jb     0x141340d36
   141340d1d:	48 83 c2 27          	add    rdx,0x27
   141340d21:	48 8b 49 f8          	mov    rcx,QWORD PTR [rcx-0x8]
   141340d25:	48 2b c1             	sub    rax,rcx
   141340d28:	48 83 c0 f8          	add    rax,0xfffffffffffffff8
   141340d2c:	48 83 f8 1f          	cmp    rax,0x1f
   141340d30:	0f 87 7c 02 00 00    	ja     0x141340fb2
   141340d36:	e8 7d b3 b3 ff       	call   0x140e7c0b8
   141340d3b:	4d 31 c0             	xor    r8,r8
   141340d3e:	0f 1f 40 00          	nop    DWORD PTR [rax+0x0]
   141340d42:	ba 01 00 00 00       	mov    edx,0x1
   141340d47:	33 c9                	xor    ecx,ecx
   141340d49:	ff 15 19 d4 45 00    	call   QWORD PTR [rip+0x45d419]        # 0x14179e168
   141340d4f:	48 8b d8             	mov    rbx,rax
   141340d52:	48 85 c0             	test   rax,rax
   141340d55:	0f 84 e0 fe ff ff    	je     0x141340c3b
   141340d5b:	ff 15 2f d4 45 00    	call   QWORD PTR [rip+0x45d42f]        # 0x14179e190
   141340d61:	3d b7 00 00 00       	cmp    eax,0xb7
   141340d66:	0f 84 38 02 00 00    	je     0x141340fa4
   141340d6c:	4c 89 75 17          	mov    QWORD PTR [rbp+0x17],r14
   141340d70:	48 89 75 0f          	mov    QWORD PTR [rbp+0xf],rsi
   141340d74:	48 89 7d 1f          	mov    QWORD PTR [rbp+0x1f],rdi
   141340d78:	48 8b 0d e1 60 b2 00 	mov    rcx,QWORD PTR [rip+0xb260e1]        # 0x141e66e60
   141340d7f:	48 85 c9             	test   rcx,rcx
   141340d82:	74 0c                	je     0x141340d90
   141340d84:	e8 67 3e 8d ff       	call   0x140c14bf0
   141340d89:	4c 89 35 d0 60 b2 00 	mov    QWORD PTR [rip+0xb260d0],r14        # 0x141e66e60
   141340d90:	48 8d 55 0f          	lea    rdx,[rbp+0xf]
   141340d94:	48 8d 1d 65 5f b2 00 	lea    rbx,[rip+0xb25f65]        # 0x141e66d00
   141340d9b:	48 8b cb             	mov    rcx,rbx
   141340d9e:	e8 ed 16 00 00       	call   0x141342490
   141340da3:	48 8b 05 2e 7f 94 05 	mov    rax,QWORD PTR [rip+0x5947f2e]        # 0x146c88cd8
   141340daa:	48 89 05 b7 5f b2 00 	mov    QWORD PTR [rip+0xb25fb7],rax        # 0x141e66d68
   141340db1:	48 8d 05 a8 5f b2 00 	lea    rax,[rip+0xb25fa8]        # 0x141e66d60
   141340db8:	48 89 05 19 7f 94 05 	mov    QWORD PTR [rip+0x5947f19],rax        # 0x146c88cd8
   141340dbf:	48 8b 05 aa 7d 94 05 	mov    rax,QWORD PTR [rip+0x5947daa]        # 0x146c88b70
   141340dc6:	48 89 05 ab 5f b2 00 	mov    QWORD PTR [rip+0xb25fab],rax        # 0x141e66d78
   141340dcd:	48 8d 05 9c 5f b2 00 	lea    rax,[rip+0xb25f9c]        # 0x141e66d70
   141340dd4:	48 89 05 95 7d 94 05 	mov    QWORD PTR [rip+0x5947d95],rax        # 0x146c88b70
   141340ddb:	48 8d 05 36 87 5b 00 	lea    rax,[rip+0x5b8736]        # 0x1418f9518
   141340de2:	48 89 05 17 5f b2 00 	mov    QWORD PTR [rip+0xb25f17],rax        # 0x141e66d00
   141340de9:	48 8d 05 98 86 5b 00 	lea    rax,[rip+0x5b8698]        # 0x1418f9488
   141340df0:	48 89 05 69 5f b2 00 	mov    QWORD PTR [rip+0xb25f69],rax        # 0x141e66d60
   141340df7:	48 8d 05 72 86 5b 00 	lea    rax,[rip+0x5b8672]        # 0x1418f9470
   141340dfe:	48 89 05 6b 5f b2 00 	mov    QWORD PTR [rip+0xb25f6b],rax        # 0x141e66d70
   141340e05:	ba 02 00 00 00       	mov    edx,0x2
   141340e0a:	48 8d 0d 6f 5f b2 00 	lea    rcx,[rip+0xb25f6f]        # 0x141e66d80
   141340e11:	e8 62 f3 b0 ff       	call   0x140e50178
   141340e16:	ba 02 00 00 00       	mov    edx,0x2
   141340e1b:	48 8d 0d ae 5f b2 00 	lea    rcx,[rip+0xb25fae]        # 0x141e66dd0
   141340e22:	e8 51 f3 b0 ff       	call   0x140e50178
   141340e27:	0f 57 c0             	xorps  xmm0,xmm0
   141340e2a:	66 0f 7f 05 ee 5f b2 	movdqa XMMWORD PTR [rip+0xb25fee],xmm0        # 0x141e66e20
   141340e31:	00 
   141340e32:	0f 57 c9             	xorps  xmm1,xmm1
   141340e35:	66 0f 7f 0d f3 5f b2 	movdqa XMMWORD PTR [rip+0xb25ff3],xmm1        # 0x141e66e30
   141340e3c:	00 
   141340e3d:	66 0f 7f 05 fb 5f b2 	movdqa XMMWORD PTR [rip+0xb25ffb],xmm0        # 0x141e66e40
   141340e44:	00 
   141340e45:	4c 89 35 04 60 b2 00 	mov    QWORD PTR [rip+0xb26004],r14        # 0x141e66e50
   141340e4c:	44 88 35 05 60 b2 00 	mov    BYTE PTR [rip+0xb26005],r14b        # 0x141e66e58
   141340e53:	48 89 1d 06 60 b2 00 	mov    QWORD PTR [rip+0xb26006],rbx        # 0x141e66e60
   141340e5a:	ff 15 40 d3 45 00    	call   QWORD PTR [rip+0x45d340]        # 0x14179e1a0
   141340e60:	ba 02 00 00 00       	mov    edx,0x2
   141340e65:	48 8b c8             	mov    rcx,rax
   141340e68:	ff 15 e2 d2 45 00    	call   QWORD PTR [rip+0x45d2e2]        # 0x14179e150
   141340e6e:	44 38 35 d4 5e b2 00 	cmp    BYTE PTR [rip+0xb25ed4],r14b        # 0x141e66d49
   141340e75:	74 09                	je     0x141340e80
   141340e77:	e8 e4 b5 81 ff       	call   0x140b5c460
   141340e7c:	84 c0                	test   al,al
   141340e7e:	75 65                	jne    0x141340ee5
   141340e80:	44 88 75 b7          	mov    BYTE PTR [rbp-0x49],r14b
   141340e84:	48 8d 4d b7          	lea    rcx,[rbp-0x49]
   141340e88:	e8 33 82 d3 fe       	call   0x1400790c0
   141340e8d:	84 c0                	test   al,al
   141340e8f:	75 11                	jne    0x141340ea2
   141340e91:	48 8d 05 b8 e5 5a 00 	lea    rax,[rip+0x5ae5b8]        # 0x1418ef450
   141340e98:	48 83 c8 01          	or     rax,0x1
   141340e9c:	48 89 45 0f          	mov    QWORD PTR [rbp+0xf],rax
   141340ea0:	eb 04                	jmp    0x141340ea6
   141340ea2:	4c 89 75 0f          	mov    QWORD PTR [rbp+0xf],r14
   141340ea6:	48 8d 55 0f          	lea    rdx,[rbp+0xf]
   141340eaa:	48 8b 0d af 5f b2 00 	mov    rcx,QWORD PTR [rip+0xb25faf]        # 0x141e66e60
   141340eb1:	e8 1a 1a 8d ff       	call   0x140c128d0
   141340eb6:	90                   	nop
   141340eb7:	48 8b 45 0f          	mov    rax,QWORD PTR [rbp+0xf]
   141340ebb:	48 85 c0             	test   rax,rax
   141340ebe:	74 25                	je     0x141340ee5
   141340ec0:	a8 01                	test   al,0x1
   141340ec2:	75 1d                	jne    0x141340ee1
   141340ec4:	48 83 e0 fe          	and    rax,0xfffffffffffffffe
   141340ec8:	4c 8b 08             	mov    r9,QWORD PTR [rax]
   141340ecb:	4d 85 c9             	test   r9,r9
   141340ece:	74 11                	je     0x141340ee1
   141340ed0:	41 b8 02 00 00 00    	mov    r8d,0x2
   141340ed6:	48 8d 55 17          	lea    rdx,[rbp+0x17]
   141340eda:	48 8d 4d 17          	lea    rcx,[rbp+0x17]
   141340ede:	41 ff d1             	call   r9
   141340ee1:	4c 89 75 0f          	mov    QWORD PTR [rbp+0xf],r14
   141340ee5:	48 8d 05 84 17 4c 00 	lea    rax,[rip+0x4c1784]        # 0x141802670
   141340eec:	48 89 44 24 30       	mov    QWORD PTR [rsp+0x30],rax
   141340ef1:	c7 44 24 20 05 00 00 	mov    DWORD PTR [rsp+0x20],0x5
   141340ef8:	00 
   141340ef9:	41 b9 00 00 02 00    	mov    r9d,0x20000
   141340eff:	4c 8b c3             	mov    r8,rbx
   141340f02:	48 8d 15 87 b9 81 ff 	lea    rdx,[rip+0xffffffffff81b987]        # 0x140b5c890
   141340f09:	48 8b 0d f0 75 ba 01 	mov    rcx,QWORD PTR [rip+0x1ba75f0]        # 0x142ee8500
   141340f10:	e8 eb bf a6 ff       	call   0x140dacf00
   141340f15:	48 8b 0d 3c 5e b2 00 	mov    rcx,QWORD PTR [rip+0xb25e3c]        # 0x141e66d58
   141340f1c:	48 89 05 35 5e b2 00 	mov    QWORD PTR [rip+0xb25e35],rax        # 0x141e66d58
   141340f23:	48 85 c9             	test   rcx,rcx
   141340f26:	74 0c                	je     0x141340f34
   141340f28:	e8 e3 9c 81 ff       	call   0x140b5ac10
   141340f2d:	48 8b 05 24 5e b2 00 	mov    rax,QWORD PTR [rip+0xb25e24]        # 0x141e66d58
   141340f34:	48 85 c0             	test   rax,rax
   141340f37:	74 0a                	je     0x141340f43
   141340f39:	48 8b 48 20          	mov    rcx,QWORD PTR [rax+0x20]
   141340f3d:	ff 15 55 d2 45 00    	call   QWORD PTR [rip+0x45d255]        # 0x14179e198
   141340f43:	33 c0                	xor    eax,eax
   141340f45:	48 89 45 d7          	mov    QWORD PTR [rbp-0x29],rax
   141340f49:	48 89 45 df          	mov    QWORD PTR [rbp-0x21],rax
   141340f4d:	48 89 45 e7          	mov    QWORD PTR [rbp-0x19],rax
   141340f51:	48 89 45 ef          	mov    QWORD PTR [rbp-0x11],rax
   141340f55:	48 89 45 f7          	mov    QWORD PTR [rbp-0x9],rax
   141340f59:	48 89 45 ff          	mov    QWORD PTR [rbp-0x1],rax
   141340f5d:	45 33 c9             	xor    r9d,r9d
   141340f60:	45 33 c0             	xor    r8d,r8d
   141340f63:	33 d2                	xor    edx,edx
   141340f65:	48 8d 4d d7          	lea    rcx,[rbp-0x29]
   141340f69:	ff 15 e9 d8 45 00    	call   QWORD PTR [rip+0x45d8e9]        # 0x14179e858
   141340f6f:	85 c0                	test   eax,eax
   141340f71:	74 4b                	je     0x141340fbe
   141340f73:	83 f8 ff             	cmp    eax,0xffffffff
   141340f76:	74 46                	je     0x141340fbe
   141340f78:	48 8d 4d d7          	lea    rcx,[rbp-0x29]
   141340f7c:	ff 15 8e d8 45 00    	call   QWORD PTR [rip+0x45d88e]        # 0x14179e810
   141340f82:	48 8d 4d d7          	lea    rcx,[rbp-0x29]
   141340f86:	ff 15 74 d8 45 00    	call   QWORD PTR [rip+0x45d874]        # 0x14179e800
   141340f8c:	45 33 c9             	xor    r9d,r9d
   141340f8f:	45 33 c0             	xor    r8d,r8d
   141340f92:	33 d2                	xor    edx,edx
   141340f94:	48 8d 4d d7          	lea    rcx,[rbp-0x29]
   141340f98:	ff 15 ba d8 45 00    	call   QWORD PTR [rip+0x45d8ba]        # 0x14179e858
   141340f9e:	85 c0                	test   eax,eax
   141340fa0:	74 1c                	je     0x141340fbe
   141340fa2:	eb cf                	jmp    0x141340f73
   141340fa4:	48 8b cb             	mov    rcx,rbx
   141340fa7:	ff 15 13 d2 45 00    	call   QWORD PTR [rip+0x45d213]        # 0x14179e1c0
   141340fad:	e9 89 fc ff ff       	jmp    0x141340c3b
   141340fb2:	e8 21 55 ba ff       	call   0x140ee64d8
   141340fb7:	cc                   	int3
   141340fb8:	e8 1b 55 ba ff       	call   0x140ee64d8
   141340fbd:	cc                   	int3
   141340fbe:	e8 dd 85 12 00       	call   0x1414695a0
   141340fc3:	8b 4d e7             	mov    ecx,DWORD PTR [rbp-0x19]
   141340fc6:	e8 65 5e ba ff       	call   0x140ee6e30
   141340fcb:	cc                   	int3
   141340fcc:	e8 07 55 ba ff       	call   0x140ee64d8
   141340fd1:	cc                   	int3
