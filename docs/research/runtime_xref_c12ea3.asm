; RUNTIME MEMORY pid 51579; function metadata (12660272, 12660540, 28566056)

docs/research/runtime_xref_c12ea3.bin:     file format binary


Disassembly of section .data:

0000000140c12e30 <.data>:
   140c12e30:	48 89 5c 24 08       	mov    QWORD PTR [rsp+0x8],rbx
   140c12e35:	48 89 74 24 10       	mov    QWORD PTR [rsp+0x10],rsi
   140c12e3a:	57                   	push   rdi
   140c12e3b:	48 83 ec 20          	sub    rsp,0x20
   140c12e3f:	48 8b d9             	mov    rbx,rcx
   140c12e42:	33 f6                	xor    esi,esi
   140c12e44:	48 8b 89 60 01 00 00 	mov    rcx,QWORD PTR [rcx+0x160]
   140c12e4b:	48 8b fa             	mov    rdi,rdx
   140c12e4e:	48 85 c9             	test   rcx,rcx
   140c12e51:	74 0c                	je     0x140c12e5f
   140c12e53:	e8 98 1d 00 00       	call   0x140c14bf0
   140c12e58:	48 89 b3 60 01 00 00 	mov    QWORD PTR [rbx+0x160],rsi
   140c12e5f:	48 8b d7             	mov    rdx,rdi
   140c12e62:	48 8b cb             	mov    rcx,rbx
   140c12e65:	e8 26 f6 72 00       	call   0x141342490
   140c12e6a:	48 8d 53 60          	lea    rdx,[rbx+0x60]
   140c12e6e:	48 8d 4b 70          	lea    rcx,[rbx+0x70]
   140c12e72:	48 8d 05 87 c9 cd 00 	lea    rax,[rip+0xcdc987]        # 0x1418ef800
   140c12e79:	48 89 02             	mov    QWORD PTR [rdx],rax
   140c12e7c:	48 8b 05 55 5e 07 06 	mov    rax,QWORD PTR [rip+0x6075e55]        # 0x146c88cd8
   140c12e83:	48 89 42 08          	mov    QWORD PTR [rdx+0x8],rax
   140c12e87:	48 8d 05 a2 66 ce 00 	lea    rax,[rip+0xce66a2]        # 0x1418f9530
   140c12e8e:	48 89 15 43 5e 07 06 	mov    QWORD PTR [rip+0x6075e43],rdx        # 0x146c88cd8
   140c12e95:	48 89 01             	mov    QWORD PTR [rcx],rax
   140c12e98:	48 8b 05 d1 5c 07 06 	mov    rax,QWORD PTR [rip+0x6075cd1]        # 0x146c88b70
   140c12e9f:	48 89 41 08          	mov    QWORD PTR [rcx+0x8],rax
   140c12ea3:	48 8d 05 6e 66 ce 00 	lea    rax,[rip+0xce666e]        # 0x1418f9518
   140c12eaa:	48 89 0d bf 5c 07 06 	mov    QWORD PTR [rip+0x6075cbf],rcx        # 0x146c88b70
   140c12eb1:	48 89 03             	mov    QWORD PTR [rbx],rax
   140c12eb4:	48 8d 05 cd 65 ce 00 	lea    rax,[rip+0xce65cd]        # 0x1418f9488
   140c12ebb:	48 89 02             	mov    QWORD PTR [rdx],rax
   140c12ebe:	48 8d 05 ab 65 ce 00 	lea    rax,[rip+0xce65ab]        # 0x1418f9470
   140c12ec5:	48 89 01             	mov    QWORD PTR [rcx],rax
   140c12ec8:	ba 02 00 00 00       	mov    edx,0x2
   140c12ecd:	48 8d 8b 80 00 00 00 	lea    rcx,[rbx+0x80]
   140c12ed4:	e8 9f d2 23 00       	call   0x140e50178
   140c12ed9:	48 8d 8b d0 00 00 00 	lea    rcx,[rbx+0xd0]
   140c12ee0:	ba 02 00 00 00       	mov    edx,0x2
   140c12ee5:	e8 8e d2 23 00       	call   0x140e50178
   140c12eea:	48 89 b3 20 01 00 00 	mov    QWORD PTR [rbx+0x120],rsi
   140c12ef1:	48 8b c3             	mov    rax,rbx
   140c12ef4:	48 89 b3 28 01 00 00 	mov    QWORD PTR [rbx+0x128],rsi
   140c12efb:	48 89 b3 30 01 00 00 	mov    QWORD PTR [rbx+0x130],rsi
   140c12f02:	48 89 b3 38 01 00 00 	mov    QWORD PTR [rbx+0x138],rsi
   140c12f09:	48 89 b3 40 01 00 00 	mov    QWORD PTR [rbx+0x140],rsi
   140c12f10:	48 89 b3 48 01 00 00 	mov    QWORD PTR [rbx+0x148],rsi
   140c12f17:	48 89 b3 50 01 00 00 	mov    QWORD PTR [rbx+0x150],rsi
   140c12f1e:	40 88 b3 58 01 00 00 	mov    BYTE PTR [rbx+0x158],sil
   140c12f25:	48 8b 74 24 38       	mov    rsi,QWORD PTR [rsp+0x38]
   140c12f2a:	48 89 9b 60 01 00 00 	mov    QWORD PTR [rbx+0x160],rbx
   140c12f31:	48 8b 5c 24 30       	mov    rbx,QWORD PTR [rsp+0x30]
   140c12f36:	48 83 c4 20          	add    rsp,0x20
   140c12f3a:	5f                   	pop    rdi
   140c12f3b:	c3                   	ret
