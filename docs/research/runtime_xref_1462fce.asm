; RUNTIME MEMORY pid 51579; function metadata (21376896, 21377104, 29441692)

docs/research/runtime_xref_1462fce.bin:     file format binary


Disassembly of section .data:

0000000141462f80 <.data>:
   141462f80:	40 53                	rex push rbx
   141462f82:	48 83 ec 20          	sub    rsp,0x20
   141462f86:	48 8b d9             	mov    rbx,rcx
   141462f89:	e8 02 f5 ed ff       	call   0x141342490
   141462f8e:	48 8d 53 70          	lea    rdx,[rbx+0x70]
   141462f92:	4c 8d 43 60          	lea    r8,[rbx+0x60]
   141462f96:	48 8d 05 63 c8 48 00 	lea    rax,[rip+0x48c863]        # 0x1418ef800
   141462f9d:	49 89 00             	mov    QWORD PTR [r8],rax
   141462fa0:	48 8d 8b 80 00 00 00 	lea    rcx,[rbx+0x80]
   141462fa7:	48 8b 05 2a 5d 82 05 	mov    rax,QWORD PTR [rip+0x5825d2a]        # 0x146c88cd8
   141462fae:	49 89 40 08          	mov    QWORD PTR [r8+0x8],rax
   141462fb2:	48 8d 05 77 65 49 00 	lea    rax,[rip+0x496577]        # 0x1418f9530
   141462fb9:	4c 89 05 18 5d 82 05 	mov    QWORD PTR [rip+0x5825d18],r8        # 0x146c88cd8
   141462fc0:	48 89 02             	mov    QWORD PTR [rdx],rax
   141462fc3:	48 8b 05 a6 5b 82 05 	mov    rax,QWORD PTR [rip+0x5825ba6]        # 0x146c88b70
   141462fca:	48 89 42 08          	mov    QWORD PTR [rdx+0x8],rax
   141462fce:	48 8d 05 43 65 49 00 	lea    rax,[rip+0x496543]        # 0x1418f9518
   141462fd5:	48 89 15 94 5b 82 05 	mov    QWORD PTR [rip+0x5825b94],rdx        # 0x146c88b70
   141462fdc:	48 89 03             	mov    QWORD PTR [rbx],rax
   141462fdf:	48 8d 05 a2 64 49 00 	lea    rax,[rip+0x4964a2]        # 0x1418f9488
   141462fe6:	49 89 00             	mov    QWORD PTR [r8],rax
   141462fe9:	48 8d 05 80 64 49 00 	lea    rax,[rip+0x496480]        # 0x1418f9470
   141462ff0:	48 89 02             	mov    QWORD PTR [rdx],rax
   141462ff3:	ba 02 00 00 00       	mov    edx,0x2
   141462ff8:	e8 7b d1 9e ff       	call   0x140e50178
   141462ffd:	48 8d 8b d0 00 00 00 	lea    rcx,[rbx+0xd0]
   141463004:	ba 02 00 00 00       	mov    edx,0x2
   141463009:	e8 6a d1 9e ff       	call   0x140e50178
   14146300e:	33 c0                	xor    eax,eax
   141463010:	48 89 83 20 01 00 00 	mov    QWORD PTR [rbx+0x120],rax
   141463017:	48 89 83 28 01 00 00 	mov    QWORD PTR [rbx+0x128],rax
   14146301e:	48 89 83 30 01 00 00 	mov    QWORD PTR [rbx+0x130],rax
   141463025:	48 89 83 38 01 00 00 	mov    QWORD PTR [rbx+0x138],rax
   14146302c:	48 89 83 40 01 00 00 	mov    QWORD PTR [rbx+0x140],rax
   141463033:	48 89 83 48 01 00 00 	mov    QWORD PTR [rbx+0x148],rax
   14146303a:	48 89 83 50 01 00 00 	mov    QWORD PTR [rbx+0x150],rax
   141463041:	88 83 58 01 00 00    	mov    BYTE PTR [rbx+0x158],al
   141463047:	48 8b c3             	mov    rax,rbx
   14146304a:	48 83 c4 20          	add    rsp,0x20
   14146304e:	5b                   	pop    rbx
   14146304f:	c3                   	ret
