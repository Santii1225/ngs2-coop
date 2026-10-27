; RUNTIME MEMORY pid 51579

docs/research/runtime_function_1341a90.bin:     file format binary


Disassembly of section .data:

0000000141341a90 <.data>:
   141341a90:	40 53                	rex push rbx
   141341a92:	48 81 ec 70 04 00 00 	sub    rsp,0x470
   141341a99:	48 8b 05 b0 c2 90 00 	mov    rax,QWORD PTR [rip+0x90c2b0]        # 0x141c4dd50
   141341aa0:	48 33 c4             	xor    rax,rsp
   141341aa3:	48 89 84 24 60 04 00 	mov    QWORD PTR [rsp+0x460],rax
   141341aaa:	00 
   141341aab:	80 79 49 00          	cmp    BYTE PTR [rcx+0x49],0x0
   141341aaf:	48 8b d9             	mov    rbx,rcx
   141341ab2:	0f 84 9b 02 00 00    	je     0x141341d53
   141341ab8:	ff 15 8a cf 45 00    	call   QWORD PTR [rip+0x45cf8a]        # 0x14179ea48
   141341abe:	84 c0                	test   al,al
   141341ac0:	0f 84 8d 02 00 00    	je     0x141341d53
   141341ac6:	48 8b 4b 18          	mov    rcx,QWORD PTR [rbx+0x18]
   141341aca:	ba 01 00 00 00       	mov    edx,0x1
