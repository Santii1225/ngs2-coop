; RUNTIME MEMORY pid 51579; function metadata (12667648, 12667873, 28566912)

docs/research/runtime_xref_c14b50.bin:     file format binary


Disassembly of section .data:

0000000140c14b00 <.data>:
   140c14b00:	40 53                	rex push rbx
   140c14b02:	48 83 ec 20          	sub    rsp,0x20
   140c14b06:	48 8b d9             	mov    rbx,rcx
   140c14b09:	48 85 c9             	test   rcx,rcx
   140c14b0c:	0f 84 c7 00 00 00    	je     0x140c14bd9
   140c14b12:	e8 79 d9 72 00       	call   0x141342490
   140c14b17:	48 8d 53 60          	lea    rdx,[rbx+0x60]
   140c14b1b:	48 8d 4b 70          	lea    rcx,[rbx+0x70]
   140c14b1f:	48 8d 05 da ac cd 00 	lea    rax,[rip+0xcdacda]        # 0x1418ef800
   140c14b26:	48 89 02             	mov    QWORD PTR [rdx],rax
   140c14b29:	48 8b 05 a8 41 07 06 	mov    rax,QWORD PTR [rip+0x60741a8]        # 0x146c88cd8
   140c14b30:	48 89 42 08          	mov    QWORD PTR [rdx+0x8],rax
   140c14b34:	48 8d 05 f5 49 ce 00 	lea    rax,[rip+0xce49f5]        # 0x1418f9530
   140c14b3b:	48 89 15 96 41 07 06 	mov    QWORD PTR [rip+0x6074196],rdx        # 0x146c88cd8
   140c14b42:	48 89 01             	mov    QWORD PTR [rcx],rax
   140c14b45:	48 8b 05 24 40 07 06 	mov    rax,QWORD PTR [rip+0x6074024]        # 0x146c88b70
   140c14b4c:	48 89 41 08          	mov    QWORD PTR [rcx+0x8],rax
   140c14b50:	48 8d 05 c1 49 ce 00 	lea    rax,[rip+0xce49c1]        # 0x1418f9518
   140c14b57:	48 89 0d 12 40 07 06 	mov    QWORD PTR [rip+0x6074012],rcx        # 0x146c88b70
   140c14b5e:	48 89 03             	mov    QWORD PTR [rbx],rax
   140c14b61:	48 8d 05 20 49 ce 00 	lea    rax,[rip+0xce4920]        # 0x1418f9488
   140c14b68:	48 89 02             	mov    QWORD PTR [rdx],rax
   140c14b6b:	48 8d 05 fe 48 ce 00 	lea    rax,[rip+0xce48fe]        # 0x1418f9470
   140c14b72:	48 89 01             	mov    QWORD PTR [rcx],rax
   140c14b75:	ba 02 00 00 00       	mov    edx,0x2
   140c14b7a:	48 8d 8b 80 00 00 00 	lea    rcx,[rbx+0x80]
   140c14b81:	e8 f2 b5 23 00       	call   0x140e50178
   140c14b86:	48 8d 8b d0 00 00 00 	lea    rcx,[rbx+0xd0]
   140c14b8d:	ba 02 00 00 00       	mov    edx,0x2
   140c14b92:	e8 e1 b5 23 00       	call   0x140e50178
   140c14b97:	33 c0                	xor    eax,eax
   140c14b99:	48 89 83 20 01 00 00 	mov    QWORD PTR [rbx+0x120],rax
   140c14ba0:	48 89 83 28 01 00 00 	mov    QWORD PTR [rbx+0x128],rax
   140c14ba7:	48 89 83 30 01 00 00 	mov    QWORD PTR [rbx+0x130],rax
   140c14bae:	48 89 83 38 01 00 00 	mov    QWORD PTR [rbx+0x138],rax
   140c14bb5:	48 89 83 40 01 00 00 	mov    QWORD PTR [rbx+0x140],rax
   140c14bbc:	48 89 83 48 01 00 00 	mov    QWORD PTR [rbx+0x148],rax
   140c14bc3:	48 89 83 50 01 00 00 	mov    QWORD PTR [rbx+0x150],rax
   140c14bca:	88 83 58 01 00 00    	mov    BYTE PTR [rbx+0x158],al
   140c14bd0:	48 8b c3             	mov    rax,rbx
   140c14bd3:	48 83 c4 20          	add    rsp,0x20
   140c14bd7:	5b                   	pop    rbx
   140c14bd8:	c3                   	ret
   140c14bd9:	33 c0                	xor    eax,eax
   140c14bdb:	48 83 c4 20          	add    rsp,0x20
   140c14bdf:	5b                   	pop    rbx
   140c14be0:	c3                   	ret
