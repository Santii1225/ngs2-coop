; RUNTIME MEMORY pid=51579 loaded base=0x140000000; read-only capture

docs/research/runtime_hook.bin:     file format binary


Disassembly of section .data:

0000000141462a00 <.data+0x80>:
   141462a00:	48 8b c4             	mov    rax,rsp
   141462a03:	57                   	push   rdi
   141462a04:	48 81 ec 20 01 00 00 	sub    rsp,0x120
   141462a0b:	48 c7 44 24 40 fe ff 	mov    QWORD PTR [rsp+0x40],0xfffffffffffffffe
   141462a12:	ff ff 
   141462a14:	48 89 58 10          	mov    QWORD PTR [rax+0x10],rbx
   141462a18:	48 89 70 18          	mov    QWORD PTR [rax+0x18],rsi
   141462a1c:	48 8b 05 2d b3 7e 00 	mov    rax,QWORD PTR [rip+0x7eb32d]        # 0x141c4dd50
   141462a23:	48 33 c4             	xor    rax,rsp
   141462a26:	48 89 84 24 10 01 00 	mov    QWORD PTR [rsp+0x110],rax
   141462a2d:	00 
   141462a2e:	48 8b f1             	mov    rsi,rcx
   141462a31:	e8 5a f0 ed ff       	call   0x141341a90
   141462a36:	84 c0                	test   al,al
   141462a38:	0f 84 94 02 00 00    	je     0x141462cd2
   141462a3e:	48 8d 05 7b f7 6d 05 	lea    rax,[rip+0x56df77b]        # 0x146b421c0
   141462a45:	48 89 05 0c 59 a8 01 	mov    QWORD PTR [rip+0x1a8590c],rax        # 0x142ee8358
   141462a4c:	48 89 05 0d 59 a8 01 	mov    QWORD PTR [rip+0x1a8590d],rax        # 0x142ee8360
   141462a53:	0f 28 1d 46 27 4b 00 	movaps xmm3,XMMWORD PTR [rip+0x4b2746]        # 0x1419151a0
   141462a5a:	0f 28 15 7f 75 4a 00 	movaps xmm2,XMMWORD PTR [rip+0x4a757f]        # 0x141909fe0
   141462a61:	0f 28 0d 78 61 4a 00 	movaps xmm1,XMMWORD PTR [rip+0x4a6178]        # 0x141908be0
   141462a68:	0f 28 05 b1 57 4a 00 	movaps xmm0,XMMWORD PTR [rip+0x4a57b1]        # 0x141908220
   141462a6f:	0f 29 05 5a e9 6d 05 	movaps XMMWORD PTR [rip+0x56de95a],xmm0        # 0x146b413d0
   141462a76:	0f 29 0d 63 e9 6d 05 	movaps XMMWORD PTR [rip+0x56de963],xmm1        # 0x146b413e0
   141462a7d:	0f 29 15 6c e9 6d 05 	movaps XMMWORD PTR [rip+0x56de96c],xmm2        # 0x146b413f0
   141462a84:	0f 29 1d 75 e9 6d 05 	movaps XMMWORD PTR [rip+0x56de975],xmm3        # 0x146b41400
   141462a8b:	0f 28 e3             	movaps xmm4,xmm3
   141462a8e:	0f 29 05 fb e8 6d 05 	movaps XMMWORD PTR [rip+0x56de8fb],xmm0        # 0x146b41390
   141462a95:	0f 29 0d 04 e9 6d 05 	movaps XMMWORD PTR [rip+0x56de904],xmm1        # 0x146b413a0
   141462a9c:	0f 29 15 0d e9 6d 05 	movaps XMMWORD PTR [rip+0x56de90d],xmm2        # 0x146b413b0
   141462aa3:	0f 29 1d 16 e9 6d 05 	movaps XMMWORD PTR [rip+0x56de916],xmm3        # 0x146b413c0
   141462aaa:	33 db                	xor    ebx,ebx
   141462aac:	8b cb                	mov    ecx,ebx
   141462aae:	48 8d 05 68 28 d3 01 	lea    rax,[rip+0x1d32868]        # 0x14319531d
   141462ab5:	66 66 66 0f 1f 84 00 	data16 data16 nop WORD PTR [rax+rax*1+0x0]
   141462abc:	00 00 00 00 
   141462ac0:	88 08                	mov    BYTE PTR [rax],cl
   141462ac2:	c7 40 fb 00 00 ff 00 	mov    DWORD PTR [rax-0x5],0xff0000
   141462ac9:	80 60 0f fd          	and    BYTE PTR [rax+0xf],0xfd
   141462acd:	c7 40 01 ff 00 00 00 	mov    DWORD PTR [rax+0x1],0xff
   141462ad4:	48 89 58 e3          	mov    QWORD PTR [rax-0x1d],rbx
   141462ad8:	80 60 0f fe          	and    BYTE PTR [rax+0xf],0xfe
   141462adc:	c7 40 05 00 00 ff ff 	mov    DWORD PTR [rax+0x5],0xffff0000
   141462ae3:	c7 40 09 00 00 ff ff 	mov    DWORD PTR [rax+0x9],0xffff0000
   141462aea:	66 89 58 0d          	mov    WORD PTR [rax+0xd],bx
   141462aee:	48 89 58 eb          	mov    QWORD PTR [rax-0x15],rbx
   141462af2:	48 89 58 f3          	mov    QWORD PTR [rax-0xd],rbx
   141462af6:	ff c1                	inc    ecx
   141462af8:	48 8d 40 30          	lea    rax,[rax+0x30]
   141462afc:	81 f9 a0 00 00 00    	cmp    ecx,0xa0
   141462b02:	7c bc                	jl     0x141462ac0
   141462b04:	48 8d 3d 15 1c b9 01 	lea    rdi,[rip+0x1b91c15]        # 0x142ff4720
   141462b0b:	0f 1f 44 00 00       	nop    DWORD PTR [rax+rax*1+0x0]
   141462b10:	80 a7 c7 a0 00 00 03 	and    BYTE PTR [rdi+0xa0c7],0x3
   141462b17:	0f b6 c3             	movzx  eax,bl
   141462b1a:	c0 e0 02             	shl    al,0x2
   141462b1d:	08 87 c7 a0 00 00    	or     BYTE PTR [rdi+0xa0c7],al
   141462b23:	48 8b cf             	mov    rcx,rdi
   141462b26:	e8 e5 22 b9 ff       	call   0x140ff4e10
   141462b2b:	ff c3                	inc    ebx
   141462b2d:	48 81 c7 d0 a0 00 00 	add    rdi,0xa0d0
   141462b34:	83 fb 04             	cmp    ebx,0x4
   141462b37:	7c d7                	jl     0x141462b10
   141462b39:	e8 ee ca 9e ff       	call   0x140e4f62c
   141462b3e:	89 05 20 87 d2 01    	mov    DWORD PTR [rip+0x1d28720],eax        # 0x14318b264
   141462b44:	e8 d7 1f 00 00       	call   0x141464b20
   141462b49:	48 89 74 24 60       	mov    QWORD PTR [rsp+0x60],rsi
   141462b4e:	ba 02 00 00 00       	mov    edx,0x2
   141462b53:	48 8d 4c 24 68       	lea    rcx,[rsp+0x68]
   141462b58:	e8 1b d6 9e ff       	call   0x140e50178
   141462b5d:	48 8d 8c 24 b8 00 00 	lea    rcx,[rsp+0xb8]
   141462b64:	00 
   141462b65:	e8 be da 9e ff       	call   0x140e50628
   141462b6a:	66 c7 84 24 00 01 00 	mov    WORD PTR [rsp+0x100],0x0
   141462b71:	00 00 00 
   141462b74:	48 8d 0d f5 3f 03 05 	lea    rcx,[rip+0x5033ff5]        # 0x146496b70
   141462b7b:	e8 28 d6 9e ff       	call   0x140e501a8
   141462b80:	85 c0                	test   eax,eax
   141462b82:	74 07                	je     0x141462b8b
   141462b84:	8b c8                	mov    ecx,eax
   141462b86:	e8 3d d0 9e ff       	call   0x140e4fbc8
   141462b8b:	c6 05 77 40 03 05 01 	mov    BYTE PTR [rip+0x5034077],0x1        # 0x146496c09
   141462b92:	48 8d 0d 27 40 03 05 	lea    rcx,[rip+0x5034027]        # 0x146496bc0
   141462b99:	e8 92 da 9e ff       	call   0x140e50630
   141462b9e:	85 c0                	test   eax,eax
   141462ba0:	74 08                	je     0x141462baa
   141462ba2:	8b c8                	mov    ecx,eax
   141462ba4:	e8 1f d0 9e ff       	call   0x140e4fbc8
   141462ba9:	90                   	nop
   141462baa:	48 8d 0d bf 3f 03 05 	lea    rcx,[rip+0x5033fbf]        # 0x146496b70
   141462bb1:	e8 6e d6 9e ff       	call   0x140e50224
   141462bb6:	85 c0                	test   eax,eax
   141462bb8:	74 08                	je     0x141462bc2
   141462bba:	8b c8                	mov    ecx,eax
   141462bbc:	e8 07 d0 9e ff       	call   0x140e4fbc8
   141462bc1:	90                   	nop
   141462bc2:	48 8d 05 ef 86 3a 00 	lea    rax,[rip+0x3a86ef]        # 0x14180b2b8
   141462bc9:	48 89 44 24 30       	mov    QWORD PTR [rsp+0x30],rax
   141462bce:	c7 44 24 20 05 00 00 	mov    DWORD PTR [rsp+0x20],0x5
   141462bd5:	00 
   141462bd6:	41 b9 00 00 02 00    	mov    r9d,0x20000
   141462bdc:	4c 8d 44 24 60       	lea    r8,[rsp+0x60]
   141462be1:	48 8d 15 a8 01 7b ff 	lea    rdx,[rip+0xffffffffff7b01a8]        # 0x140c12d90
   141462be8:	48 8b 0d 11 59 a8 01 	mov    rcx,QWORD PTR [rip+0x1a85911]        # 0x142ee8500
   141462bef:	e8 0c a3 94 ff       	call   0x140dacf00
   141462bf4:	48 8b 8e 50 01 00 00 	mov    rcx,QWORD PTR [rsi+0x150]
   141462bfb:	48 89 86 50 01 00 00 	mov    QWORD PTR [rsi+0x150],rax
   141462c02:	48 85 c9             	test   rcx,rcx
   141462c05:	74 06                	je     0x141462c0d
   141462c07:	e8 04 80 6f ff       	call   0x140b5ac10
   141462c0c:	90                   	nop
   141462c0d:	48 8b 8e 50 01 00 00 	mov    rcx,QWORD PTR [rsi+0x150]
   141462c14:	48 85 c9             	test   rcx,rcx
   141462c17:	0f 84 93 00 00 00    	je     0x141462cb0
   141462c1d:	48 8b 49 20          	mov    rcx,QWORD PTR [rcx+0x20]
   141462c21:	ff 15 71 b5 33 00    	call   QWORD PTR [rip+0x33b571]        # 0x14179e198
   141462c27:	85 c0                	test   eax,eax
   141462c29:	0f 84 81 00 00 00    	je     0x141462cb0
   141462c2f:	48 8d 44 24 68       	lea    rax,[rsp+0x68]
   141462c34:	48 89 44 24 48       	mov    QWORD PTR [rsp+0x48],rax
   141462c39:	48 8d 4c 24 68       	lea    rcx,[rsp+0x68]
   141462c3e:	e8 65 d5 9e ff       	call   0x140e501a8
   141462c43:	85 c0                	test   eax,eax
   141462c45:	74 07                	je     0x141462c4e
   141462c47:	8b c8                	mov    ecx,eax
   141462c49:	e8 7a cf 9e ff       	call   0x140e4fbc8
   141462c4e:	c6 44 24 50 01       	mov    BYTE PTR [rsp+0x50],0x1
   141462c53:	80 bc 24 01 01 00 00 	cmp    BYTE PTR [rsp+0x101],0x0
   141462c5a:	00 
   141462c5b:	75 2a                	jne    0x141462c87
   141462c5d:	0f 1f 00             	nop    DWORD PTR [rax]
   141462c60:	48 8d 54 24 68       	lea    rdx,[rsp+0x68]
   141462c65:	48 8d 8c 24 b8 00 00 	lea    rcx,[rsp+0xb8]
   141462c6c:	00 
   141462c6d:	e8 de d9 9e ff       	call   0x140e50650
   141462c72:	85 c0                	test   eax,eax
   141462c74:	74 07                	je     0x141462c7d
   141462c76:	8b c8                	mov    ecx,eax
   141462c78:	e8 4b cf 9e ff       	call   0x140e4fbc8
   141462c7d:	80 bc 24 01 01 00 00 	cmp    BYTE PTR [rsp+0x101],0x0
   141462c84:	00 
   141462c85:	74 d9                	je     0x141462c60
   141462c87:	0f b6 84 24 00 01 00 	movzx  eax,BYTE PTR [rsp+0x100]
   141462c8e:	00 
   141462c8f:	88 84 24 01 01 00 00 	mov    BYTE PTR [rsp+0x101],al
   141462c96:	48 8d 4c 24 68       	lea    rcx,[rsp+0x68]
   141462c9b:	e8 84 d5 9e ff       	call   0x140e50224
   141462ca0:	85 c0                	test   eax,eax
   141462ca2:	74 08                	je     0x141462cac
   141462ca4:	8b c8                	mov    ecx,eax
   141462ca6:	e8 1d cf 9e ff       	call   0x140e4fbc8
   141462cab:	90                   	nop
   141462cac:	b3 01                	mov    bl,0x1
   141462cae:	eb 02                	jmp    0x141462cb2
   141462cb0:	32 db                	xor    bl,bl
   141462cb2:	88 9e 58 01 00 00    	mov    BYTE PTR [rsi+0x158],bl
   141462cb8:	48 8d 8c 24 b8 00 00 	lea    rcx,[rsp+0xb8]
   141462cbf:	00 
   141462cc0:	e8 0f d9 9e ff       	call   0x140e505d4
   141462cc5:	48 8d 4c 24 68       	lea    rcx,[rsp+0x68]
   141462cca:	e8 39 d4 9e ff       	call   0x140e50108
   141462ccf:	0f b6 c3             	movzx  eax,bl
   141462cd2:	48 8b 8c 24 10 01 00 	mov    rcx,QWORD PTR [rsp+0x110]
   141462cd9:	00 
   141462cda:	48 33 cc             	xor    rcx,rsp
   141462cdd:	e8 be 84 a1 ff       	call   0x140e7b1a0
   141462ce2:	4c 8d 9c 24 20 01 00 	lea    r11,[rsp+0x120]
   141462ce9:	00 
   141462cea:	49 8b 5b 18          	mov    rbx,QWORD PTR [r11+0x18]
   141462cee:	49 8b 73 20          	mov    rsi,QWORD PTR [r11+0x20]
   141462cf2:	49 8b e3             	mov    rsp,r11
   141462cf5:	5f                   	pop    rdi
   141462cf6:	c3                   	ret
   141462cf7:	cc                   	int3
   141462cf8:	cc                   	int3
   141462cf9:	cc                   	int3
   141462cfa:	cc                   	int3
   141462cfb:	cc                   	int3
   141462cfc:	cc                   	int3
   141462cfd:	cc                   	int3
   141462cfe:	cc                   	int3
   141462cff:	cc                   	int3
