; RUNTIME MEMORY pid 51579

docs/research/runtime_function_b5c890.bin:     file format binary


Disassembly of section .data:

0000000140b5c890 <.data>:
   140b5c890:	40 53                	rex push rbx
   140b5c892:	48 83 ec 20          	sub    rsp,0x20
   140b5c896:	48 8b da             	mov    rbx,rdx
   140b5c899:	e8 8e 2d 2f 00       	call   0x140e4f62c
   140b5c89e:	89 05 08 6d 08 06    	mov    DWORD PTR [rip+0x6086d08],eax        # 0x146be35ac
   140b5c8a4:	48 8b cb             	mov    rcx,rbx
   140b5c8a7:	48 8b 03             	mov    rax,QWORD PTR [rbx]
   140b5c8aa:	ff 10                	call   QWORD PTR [rax]
   140b5c8ac:	84 c0                	test   al,al
   140b5c8ae:	74 09                	je     0x140b5c8b9
   140b5c8b0:	48 8b 03             	mov    rax,QWORD PTR [rbx]
   140b5c8b3:	48 8b cb             	mov    rcx,rbx
   140b5c8b6:	ff 50 08             	call   QWORD PTR [rax+0x8]
   140b5c8b9:	48 8b 4b 18          	mov    rcx,QWORD PTR [rbx+0x18]
   140b5c8bd:	45 33 c9             	xor    r9d,r9d
   140b5c8c0:	45 33 c0             	xor    r8d,r8d
   140b5c8c3:	41 8d 51 02          	lea    edx,[r9+0x2]
   140b5c8c7:	ff 15 c3 1f c4 00    	call   QWORD PTR [rip+0xc41fc3]        # 0x14179e890
   140b5c8cd:	33 c0                	xor    eax,eax
   140b5c8cf:	48 83 c4 20          	add    rsp,0x20
   140b5c8d3:	5b                   	pop    rbx
   140b5c8d4:	c3                   	ret
