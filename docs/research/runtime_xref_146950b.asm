; RUNTIME MEMORY pid 51579; function metadata (21402768, 21403019, 29443516)

docs/research/runtime_xref_146950b.bin:     file format binary


Disassembly of section .data:

0000000141469490 <.data>:
   141469490:	40 53                	rex push rbx
   141469492:	48 83 ec 20          	sub    rsp,0x20
   141469496:	48 8b d9             	mov    rbx,rcx
   141469499:	48 8b 0d c0 d9 9f 00 	mov    rcx,QWORD PTR [rip+0x9fd9c0]        # 0x141e66e60
   1414694a0:	48 85 c9             	test   rcx,rcx
   1414694a3:	74 10                	je     0x1414694b5
   1414694a5:	e8 46 b7 7a ff       	call   0x140c14bf0
   1414694aa:	48 c7 05 ab d9 9f 00 	mov    QWORD PTR [rip+0x9fd9ab],0x0        # 0x141e66e60
   1414694b1:	00 00 00 00 
   1414694b5:	48 8b d3             	mov    rdx,rbx
   1414694b8:	48 8d 1d 41 d8 9f 00 	lea    rbx,[rip+0x9fd841]        # 0x141e66d00
   1414694bf:	48 8b cb             	mov    rcx,rbx
   1414694c2:	e8 c9 8f ed ff       	call   0x141342490
   1414694c7:	48 8b 05 0a f8 81 05 	mov    rax,QWORD PTR [rip+0x581f80a]        # 0x146c88cd8
   1414694ce:	48 8d 0d ab d8 9f 00 	lea    rcx,[rip+0x9fd8ab]        # 0x141e66d80
   1414694d5:	48 89 05 8c d8 9f 00 	mov    QWORD PTR [rip+0x9fd88c],rax        # 0x141e66d68
   1414694dc:	ba 02 00 00 00       	mov    edx,0x2
   1414694e1:	48 8d 05 78 d8 9f 00 	lea    rax,[rip+0x9fd878]        # 0x141e66d60
   1414694e8:	48 89 05 e9 f7 81 05 	mov    QWORD PTR [rip+0x581f7e9],rax        # 0x146c88cd8
   1414694ef:	48 8b 05 7a f6 81 05 	mov    rax,QWORD PTR [rip+0x581f67a]        # 0x146c88b70
   1414694f6:	48 89 05 7b d8 9f 00 	mov    QWORD PTR [rip+0x9fd87b],rax        # 0x141e66d78
   1414694fd:	48 8d 05 6c d8 9f 00 	lea    rax,[rip+0x9fd86c]        # 0x141e66d70
   141469504:	48 89 05 65 f6 81 05 	mov    QWORD PTR [rip+0x581f665],rax        # 0x146c88b70
   14146950b:	48 8d 05 06 00 49 00 	lea    rax,[rip+0x490006]        # 0x1418f9518
   141469512:	48 89 05 e7 d7 9f 00 	mov    QWORD PTR [rip+0x9fd7e7],rax        # 0x141e66d00
   141469519:	48 8d 05 68 ff 48 00 	lea    rax,[rip+0x48ff68]        # 0x1418f9488
   141469520:	48 89 05 39 d8 9f 00 	mov    QWORD PTR [rip+0x9fd839],rax        # 0x141e66d60
   141469527:	48 8d 05 42 ff 48 00 	lea    rax,[rip+0x48ff42]        # 0x1418f9470
   14146952e:	48 89 05 3b d8 9f 00 	mov    QWORD PTR [rip+0x9fd83b],rax        # 0x141e66d70
   141469535:	e8 3e 6c 9e ff       	call   0x140e50178
   14146953a:	ba 02 00 00 00       	mov    edx,0x2
   14146953f:	48 8d 0d 8a d8 9f 00 	lea    rcx,[rip+0x9fd88a]        # 0x141e66dd0
   141469546:	e8 2d 6c 9e ff       	call   0x140e50178
   14146954b:	0f 57 c0             	xorps  xmm0,xmm0
   14146954e:	48 c7 05 f7 d8 9f 00 	mov    QWORD PTR [rip+0x9fd8f7],0x0        # 0x141e66e50
   141469555:	00 00 00 00 
   141469559:	0f 57 c9             	xorps  xmm1,xmm1
   14146955c:	66 0f 7f 05 bc d8 9f 	movdqa XMMWORD PTR [rip+0x9fd8bc],xmm0        # 0x141e66e20
   141469563:	00 
   141469564:	66 0f 7f 0d c4 d8 9f 	movdqa XMMWORD PTR [rip+0x9fd8c4],xmm1        # 0x141e66e30
   14146956b:	00 
   14146956c:	48 8b c3             	mov    rax,rbx
   14146956f:	66 0f 7f 05 c9 d8 9f 	movdqa XMMWORD PTR [rip+0x9fd8c9],xmm0        # 0x141e66e40
   141469576:	00 
   141469577:	c6 05 da d8 9f 00 00 	mov    BYTE PTR [rip+0x9fd8da],0x0        # 0x141e66e58
   14146957e:	48 89 1d db d8 9f 00 	mov    QWORD PTR [rip+0x9fd8db],rbx        # 0x141e66e60
   141469585:	48 83 c4 20          	add    rsp,0x20
   141469589:	5b                   	pop    rbx
   14146958a:	c3                   	ret
