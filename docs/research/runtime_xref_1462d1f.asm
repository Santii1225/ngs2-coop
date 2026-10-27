; RUNTIME MEMORY pid 51579; function metadata (21376256, 21376879, 29441600)

docs/research/runtime_xref_1462d1f.bin:     file format binary


Disassembly of section .data:

0000000141462d00 <.data>:
   141462d00:	40 56                	rex push rsi
   141462d02:	57                   	push   rdi
   141462d03:	41 56                	push   r14
   141462d05:	48 83 ec 40          	sub    rsp,0x40
   141462d09:	48 c7 44 24 20 fe ff 	mov    QWORD PTR [rsp+0x20],0xfffffffffffffffe
   141462d10:	ff ff 
   141462d12:	48 89 5c 24 68       	mov    QWORD PTR [rsp+0x68],rbx
   141462d17:	48 89 6c 24 70       	mov    QWORD PTR [rsp+0x70],rbp
   141462d1c:	48 8b f9             	mov    rdi,rcx
   141462d1f:	48 8d 05 f2 67 49 00 	lea    rax,[rip+0x4967f2]        # 0x1418f9518
   141462d26:	48 89 01             	mov    QWORD PTR [rcx],rax
   141462d29:	48 8d 71 60          	lea    rsi,[rcx+0x60]
   141462d2d:	48 8d 05 54 67 49 00 	lea    rax,[rip+0x496754]        # 0x1418f9488
   141462d34:	48 89 06             	mov    QWORD PTR [rsi],rax
   141462d37:	4c 8d 71 70          	lea    r14,[rcx+0x70]
   141462d3b:	48 8d 05 2e 67 49 00 	lea    rax,[rip+0x49672e]        # 0x1418f9470
   141462d42:	49 89 06             	mov    QWORD PTR [r14],rax
   141462d45:	83 79 40 02          	cmp    DWORD PTR [rcx+0x40],0x2
   141462d49:	0f 94 05 78 b2 bb 00 	sete   BYTE PTR [rip+0xbbb278]        # 0x14201dfc8
   141462d50:	48 8d 4c 24 28       	lea    rcx,[rsp+0x28]
   141462d55:	e8 46 05 b3 ff       	call   0x140f932a0
   141462d5a:	90                   	nop
   141462d5b:	48 8b 5c 24 28       	mov    rbx,QWORD PTR [rsp+0x28]
   141462d60:	80 7b 0c 00          	cmp    BYTE PTR [rbx+0xc],0x0
   141462d64:	75 0e                	jne    0x141462d74
   141462d66:	83 7b 08 ff          	cmp    DWORD PTR [rbx+0x8],0xffffffff
   141462d6a:	74 08                	je     0x141462d74
   141462d6c:	e8 db c9 9e ff       	call   0x140e4f74c
   141462d71:	90                   	nop
   141462d72:	eb ec                	jmp    0x141462d60
   141462d74:	48 8b 4c 24 30       	mov    rcx,QWORD PTR [rsp+0x30]
   141462d79:	48 85 c9             	test   rcx,rcx
   141462d7c:	74 35                	je     0x141462db3
   141462d7e:	bd ff ff ff ff       	mov    ebp,0xffffffff
   141462d83:	8b c5                	mov    eax,ebp
   141462d85:	f0 0f c1 41 08       	lock xadd DWORD PTR [rcx+0x8],eax
   141462d8a:	83 f8 01             	cmp    eax,0x1
   141462d8d:	75 24                	jne    0x141462db3
   141462d8f:	48 8b 5c 24 30       	mov    rbx,QWORD PTR [rsp+0x30]
   141462d94:	48 8b 03             	mov    rax,QWORD PTR [rbx]
   141462d97:	48 8b cb             	mov    rcx,rbx
   141462d9a:	ff 10                	call   QWORD PTR [rax]
   141462d9c:	90                   	nop
   141462d9d:	f0 0f c1 6b 0c       	lock xadd DWORD PTR [rbx+0xc],ebp
   141462da2:	83 fd 01             	cmp    ebp,0x1
   141462da5:	75 0c                	jne    0x141462db3
   141462da7:	48 8b 4c 24 30       	mov    rcx,QWORD PTR [rsp+0x30]
   141462dac:	48 8b 01             	mov    rax,QWORD PTR [rcx]
   141462daf:	ff 50 08             	call   QWORD PTR [rax+0x8]
   141462db2:	90                   	nop
   141462db3:	48 8b 8f 50 01 00 00 	mov    rcx,QWORD PTR [rdi+0x150]
   141462dba:	33 ed                	xor    ebp,ebp
   141462dbc:	48 89 af 50 01 00 00 	mov    QWORD PTR [rdi+0x150],rbp
   141462dc3:	48 85 c9             	test   rcx,rcx
   141462dc6:	74 06                	je     0x141462dce
   141462dc8:	e8 43 7e 6f ff       	call   0x140b5ac10
   141462dcd:	90                   	nop
   141462dce:	48 8b 1d 3b 08 a0 00 	mov    rbx,QWORD PTR [rip+0xa0083b]        # 0x141e63610
   141462dd5:	e8 52 c8 9e ff       	call   0x140e4f62c
   141462dda:	90                   	nop
   141462ddb:	89 43 08             	mov    DWORD PTR [rbx+0x8],eax
   141462dde:	48 8b 1d 83 5d 82 05 	mov    rbx,QWORD PTR [rip+0x5825d83]        # 0x146c88b68
   141462de5:	48 85 db             	test   rbx,rbx
   141462de8:	74 1e                	je     0x141462e08
   141462dea:	66 0f 1f 44 00 00    	nop    WORD PTR [rax+rax*1+0x0]
   141462df0:	48 8b 03             	mov    rax,QWORD PTR [rbx]
   141462df3:	48 8d 54 24 60       	lea    rdx,[rsp+0x60]
   141462df8:	48 8b cb             	mov    rcx,rbx
   141462dfb:	ff 50 08             	call   QWORD PTR [rax+0x8]
   141462dfe:	90                   	nop
   141462dff:	48 8b 5b 08          	mov    rbx,QWORD PTR [rbx+0x8]
   141462e03:	48 85 db             	test   rbx,rbx
   141462e06:	75 e8                	jne    0x141462df0
   141462e08:	48 8b 8f 50 01 00 00 	mov    rcx,QWORD PTR [rdi+0x150]
   141462e0f:	48 85 c9             	test   rcx,rcx
   141462e12:	74 06                	je     0x141462e1a
   141462e14:	e8 f7 7d 6f ff       	call   0x140b5ac10
   141462e19:	90                   	nop
   141462e1a:	48 8b 8f 38 01 00 00 	mov    rcx,QWORD PTR [rdi+0x138]
   141462e21:	48 85 c9             	test   rcx,rcx
   141462e24:	74 3e                	je     0x141462e64
   141462e26:	48 8b 97 40 01 00 00 	mov    rdx,QWORD PTR [rdi+0x140]
   141462e2d:	e8 7e 1f 7b ff       	call   0x140c14db0
   141462e32:	90                   	nop
   141462e33:	48 8b 05 d6 07 a0 00 	mov    rax,QWORD PTR [rip+0xa007d6]        # 0x141e63610
   141462e3a:	48 8b 88 b8 02 00 00 	mov    rcx,QWORD PTR [rax+0x2b8]
   141462e41:	48 8b 01             	mov    rax,QWORD PTR [rcx]
   141462e44:	48 8b 97 38 01 00 00 	mov    rdx,QWORD PTR [rdi+0x138]
   141462e4b:	ff 50 58             	call   QWORD PTR [rax+0x58]
   141462e4e:	90                   	nop
   141462e4f:	48 89 af 38 01 00 00 	mov    QWORD PTR [rdi+0x138],rbp
   141462e56:	48 89 af 40 01 00 00 	mov    QWORD PTR [rdi+0x140],rbp
   141462e5d:	48 89 af 48 01 00 00 	mov    QWORD PTR [rdi+0x148],rbp
   141462e64:	48 8b 8f 20 01 00 00 	mov    rcx,QWORD PTR [rdi+0x120]
   141462e6b:	48 85 c9             	test   rcx,rcx
   141462e6e:	74 3e                	je     0x141462eae
   141462e70:	48 8b 97 28 01 00 00 	mov    rdx,QWORD PTR [rdi+0x128]
   141462e77:	e8 a4 1f 7b ff       	call   0x140c14e20
   141462e7c:	90                   	nop
   141462e7d:	48 8b 05 8c 07 a0 00 	mov    rax,QWORD PTR [rip+0xa0078c]        # 0x141e63610
   141462e84:	48 8b 88 b8 02 00 00 	mov    rcx,QWORD PTR [rax+0x2b8]
   141462e8b:	48 8b 01             	mov    rax,QWORD PTR [rcx]
   141462e8e:	48 8b 97 20 01 00 00 	mov    rdx,QWORD PTR [rdi+0x120]
   141462e95:	ff 50 58             	call   QWORD PTR [rax+0x58]
   141462e98:	90                   	nop
   141462e99:	48 89 af 20 01 00 00 	mov    QWORD PTR [rdi+0x120],rbp
   141462ea0:	48 89 af 28 01 00 00 	mov    QWORD PTR [rdi+0x128],rbp
   141462ea7:	48 89 af 30 01 00 00 	mov    QWORD PTR [rdi+0x130],rbp
   141462eae:	48 8d 8f d0 00 00 00 	lea    rcx,[rdi+0xd0]
   141462eb5:	e8 4e d2 9e ff       	call   0x140e50108
   141462eba:	90                   	nop
   141462ebb:	48 8d 8f 80 00 00 00 	lea    rcx,[rdi+0x80]
   141462ec2:	e8 41 d2 9e ff       	call   0x140e50108
   141462ec7:	90                   	nop
   141462ec8:	48 8d 05 61 66 49 00 	lea    rax,[rip+0x496661]        # 0x1418f9530
   141462ecf:	49 89 06             	mov    QWORD PTR [r14],rax
   141462ed2:	4d 39 76 08          	cmp    QWORD PTR [r14+0x8],r14
   141462ed6:	74 39                	je     0x141462f11
   141462ed8:	48 8b 05 91 5c 82 05 	mov    rax,QWORD PTR [rip+0x5825c91]        # 0x146c88b70
   141462edf:	48 8d 15 8a 5c 82 05 	lea    rdx,[rip+0x5825c8a]        # 0x146c88b70
   141462ee6:	48 85 c0             	test   rax,rax
   141462ee9:	74 22                	je     0x141462f0d
   141462eeb:	0f 1f 44 00 00       	nop    DWORD PTR [rax+rax*1+0x0]
   141462ef0:	49 3b c6             	cmp    rax,r14
   141462ef3:	74 0e                	je     0x141462f03
   141462ef5:	48 8d 50 08          	lea    rdx,[rax+0x8]
   141462ef9:	48 8b 02             	mov    rax,QWORD PTR [rdx]
   141462efc:	48 85 c0             	test   rax,rax
   141462eff:	75 ef                	jne    0x141462ef0
   141462f01:	eb 0a                	jmp    0x141462f0d
   141462f03:	48 8b 02             	mov    rax,QWORD PTR [rdx]
   141462f06:	48 8b 48 08          	mov    rcx,QWORD PTR [rax+0x8]
   141462f0a:	48 89 0a             	mov    QWORD PTR [rdx],rcx
   141462f0d:	4d 89 76 08          	mov    QWORD PTR [r14+0x8],r14
   141462f11:	48 8d 05 e8 c8 48 00 	lea    rax,[rip+0x48c8e8]        # 0x1418ef800
   141462f18:	48 89 06             	mov    QWORD PTR [rsi],rax
   141462f1b:	48 39 76 08          	cmp    QWORD PTR [rsi+0x8],rsi
   141462f1f:	74 34                	je     0x141462f55
   141462f21:	48 8b 05 b0 5d 82 05 	mov    rax,QWORD PTR [rip+0x5825db0]        # 0x146c88cd8
   141462f28:	48 8d 15 a9 5d 82 05 	lea    rdx,[rip+0x5825da9]        # 0x146c88cd8
   141462f2f:	48 85 c0             	test   rax,rax
   141462f32:	74 1d                	je     0x141462f51
   141462f34:	48 3b c6             	cmp    rax,rsi
   141462f37:	74 0e                	je     0x141462f47
   141462f39:	48 8d 50 08          	lea    rdx,[rax+0x8]
   141462f3d:	48 8b 02             	mov    rax,QWORD PTR [rdx]
   141462f40:	48 85 c0             	test   rax,rax
   141462f43:	75 ef                	jne    0x141462f34
   141462f45:	eb 0a                	jmp    0x141462f51
   141462f47:	48 8b 02             	mov    rax,QWORD PTR [rdx]
   141462f4a:	48 8b 48 08          	mov    rcx,QWORD PTR [rax+0x8]
   141462f4e:	48 89 0a             	mov    QWORD PTR [rdx],rcx
   141462f51:	48 89 76 08          	mov    QWORD PTR [rsi+0x8],rsi
   141462f55:	48 8b cf             	mov    rcx,rdi
   141462f58:	48 8b 5c 24 68       	mov    rbx,QWORD PTR [rsp+0x68]
   141462f5d:	48 8b 6c 24 70       	mov    rbp,QWORD PTR [rsp+0x70]
   141462f62:	48 83 c4 40          	add    rsp,0x40
   141462f66:	41 5e                	pop    r14
   141462f68:	5f                   	pop    rdi
   141462f69:	5e                   	pop    rsi
   141462f6a:	e9 f1 f3 ed ff       	jmp    0x141342360
