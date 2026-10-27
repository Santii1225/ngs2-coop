00000003205c16f2 <(anonymous namespace)::Sigma2_vfunction1((anonymous namespace)::Sigma2*)>:
   3205c16f2:	55                   	push   rbp
   3205c16f3:	48 89 e5             	mov    rbp,rsp
   3205c16f6:	48 83 ec 30          	sub    rsp,0x30
   3205c16fa:	48 89 4d 10          	mov    QWORD PTR [rbp+0x10],rcx
   3205c16fe:	c7 45 f8 00 00 00 00 	mov    DWORD PTR [rbp-0x8],0x0
   3205c1705:	48 8d 15 9d b9 00 00 	lea    rdx,[rip+0xb99d]        # 3205cd0a9 <(anonymous namespace)::invocation_logged>
   3205c170c:	b8 01 00 00 00       	mov    eax,0x1
   3205c1711:	86 02                	xchg   BYTE PTR [rdx],al
   3205c1713:	90                   	nop
   3205c1714:	83 f0 01             	xor    eax,0x1
   3205c1717:	88 45 ff             	mov    BYTE PTR [rbp-0x1],al
   3205c171a:	80 7d ff 00          	cmp    BYTE PTR [rbp-0x1],0x0
   3205c171e:	74 0f                	je     3205c172f <(anonymous namespace)::Sigma2_vfunction1((anonymous namespace)::Sigma2*)+0x3d>
   3205c1720:	48 8d 05 b9 79 00 00 	lea    rax,[rip+0x79b9]        # 3205c90e0 <.rdata+0x90>
   3205c1727:	48 89 c1             	mov    rcx,rax
   3205c172a:	e8 21 fd ff ff       	call   3205c1450 <(anonymous namespace)::log_message(char const*)>
   3205c172f:	48 8d 05 4a b9 00 00 	lea    rax,[rip+0xb94a]        # 3205cd080 <(anonymous namespace)::sigma2_hook>
   3205c1736:	48 89 c1             	mov    rcx,rax
   3205c1739:	e8 fa 03 00 00       	call   3205c1b38 <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::original() const>
   3205c173e:	48 8b 55 10          	mov    rdx,QWORD PTR [rbp+0x10]
   3205c1742:	48 89 d1             	mov    rcx,rdx
   3205c1745:	ff d0                	call   rax
   3205c1747:	88 45 fe             	mov    BYTE PTR [rbp-0x2],al
   3205c174a:	80 7d ff 00          	cmp    BYTE PTR [rbp-0x1],0x0
   3205c174e:	74 1e                	je     3205c176e <(anonymous namespace)::Sigma2_vfunction1((anonymous namespace)::Sigma2*)+0x7c>
   3205c1750:	80 7d fe 00          	cmp    BYTE PTR [rbp-0x2],0x0
   3205c1754:	74 09                	je     3205c175f <(anonymous namespace)::Sigma2_vfunction1((anonymous namespace)::Sigma2*)+0x6d>
   3205c1756:	48 8d 05 a3 79 00 00 	lea    rax,[rip+0x79a3]        # 3205c9100 <.rdata+0xb0>
   3205c175d:	eb 07                	jmp    3205c1766 <(anonymous namespace)::Sigma2_vfunction1((anonymous namespace)::Sigma2*)+0x74>
   3205c175f:	48 8d 05 e2 79 00 00 	lea    rax,[rip+0x79e2]        # 3205c9148 <.rdata+0xf8>
   3205c1766:	48 89 c1             	mov    rcx,rax
   3205c1769:	e8 e2 fc ff ff       	call   3205c1450 <(anonymous namespace)::log_message(char const*)>
   3205c176e:	0f b6 45 fe          	movzx  eax,BYTE PTR [rbp-0x2]
   3205c1772:	48 83 c4 30          	add    rsp,0x30
   3205c1776:	5d                   	pop    rbp
   3205c1777:	c3                   	ret

00000003205c1a5f <DllMain>:
   3205c1a5f:	55                   	push   rbp
   3205c1a60:	48 89 e5             	mov    rbp,rsp
   3205c1a63:	48 83 ec 40          	sub    rsp,0x40
   3205c1a67:	48 89 4d 10          	mov    QWORD PTR [rbp+0x10],rcx
   3205c1a6b:	89 55 18             	mov    DWORD PTR [rbp+0x18],edx
   3205c1a6e:	4c 89 45 20          	mov    QWORD PTR [rbp+0x20],r8
   3205c1a72:	83 7d 18 01          	cmp    DWORD PTR [rbp+0x18],0x1
   3205c1a76:	75 67                	jne    3205c1adf <DllMain+0x80>
   3205c1a78:	48 8b 45 10          	mov    rax,QWORD PTR [rbp+0x10]
   3205c1a7c:	48 89 c1             	mov    rcx,rax
   3205c1a7f:	48 8b 05 1a d8 00 00 	mov    rax,QWORD PTR [rip+0xd81a]        # 3205cf2a0 <__imp_DisableThreadLibraryCalls>
   3205c1a86:	ff d0                	call   rax
   3205c1a88:	48 8b 45 10          	mov    rax,QWORD PTR [rbp+0x10]
   3205c1a8c:	48 8d 15 e5 fc ff ff 	lea    rdx,[rip+0xfffffffffffffce5]        # 3205c1778 <(anonymous namespace)::initialize(void*)>
   3205c1a93:	48 c7 44 24 28 00 00 	mov    QWORD PTR [rsp+0x28],0x0
   3205c1a9a:	00 00 
   3205c1a9c:	c7 44 24 20 00 00 00 	mov    DWORD PTR [rsp+0x20],0x0
   3205c1aa3:	00 
   3205c1aa4:	49 89 c1             	mov    r9,rax
   3205c1aa7:	49 89 d0             	mov    r8,rdx
   3205c1aaa:	ba 00 00 00 00       	mov    edx,0x0
   3205c1aaf:	b9 00 00 00 00       	mov    ecx,0x0
   3205c1ab4:	48 8b 05 d5 d7 00 00 	mov    rax,QWORD PTR [rip+0xd7d5]        # 3205cf290 <__imp_CreateThread>
   3205c1abb:	ff d0                	call   rax
   3205c1abd:	48 89 45 f8          	mov    QWORD PTR [rbp-0x8],rax
   3205c1ac1:	48 83 7d f8 00       	cmp    QWORD PTR [rbp-0x8],0x0
   3205c1ac6:	75 07                	jne    3205c1acf <DllMain+0x70>
   3205c1ac8:	b8 00 00 00 00       	mov    eax,0x0
   3205c1acd:	eb 15                	jmp    3205c1ae4 <DllMain+0x85>
   3205c1acf:	48 8b 45 f8          	mov    rax,QWORD PTR [rbp-0x8]
   3205c1ad3:	48 89 c1             	mov    rcx,rax
   3205c1ad6:	48 8b 05 a3 d7 00 00 	mov    rax,QWORD PTR [rip+0xd7a3]        # 3205cf280 <__imp_CloseHandle>
   3205c1add:	ff d0                	call   rax
   3205c1adf:	b8 01 00 00 00       	mov    eax,0x1
   3205c1ae4:	48 83 c4 40          	add    rsp,0x40
   3205c1ae8:	5d                   	pop    rbp
   3205c1ae9:	c3                   	ret

00000003205c75d0 <nm::WindowsSlotOps::exchange_if(unsigned long long, unsigned long long, unsigned long long)>:
   3205c75d0:	55                   	push   rbp
   3205c75d1:	48 89 e5             	mov    rbp,rsp
   3205c75d4:	48 83 ec 20          	sub    rsp,0x20
   3205c75d8:	48 89 4d 10          	mov    QWORD PTR [rbp+0x10],rcx
   3205c75dc:	48 89 55 18          	mov    QWORD PTR [rbp+0x18],rdx
   3205c75e0:	4c 89 45 20          	mov    QWORD PTR [rbp+0x20],r8
   3205c75e4:	48 8b 45 18          	mov    rax,QWORD PTR [rbp+0x18]
   3205c75e8:	48 8b 55 20          	mov    rdx,QWORD PTR [rbp+0x20]
   3205c75ec:	48 8b 4d 10          	mov    rcx,QWORD PTR [rbp+0x10]
   3205c75f0:	48 89 4d f8          	mov    QWORD PTR [rbp-0x8],rcx
   3205c75f4:	48 89 55 f0          	mov    QWORD PTR [rbp-0x10],rdx
   3205c75f8:	48 89 45 e8          	mov    QWORD PTR [rbp-0x18],rax
   3205c75fc:	48 8b 4d f0          	mov    rcx,QWORD PTR [rbp-0x10]
   3205c7600:	48 8b 45 e8          	mov    rax,QWORD PTR [rbp-0x18]
   3205c7604:	48 8b 55 f8          	mov    rdx,QWORD PTR [rbp-0x8]
   3205c7608:	f0 48 0f b1 0a       	lock cmpxchg QWORD PTR [rdx],rcx
   3205c760d:	48 83 c4 20          	add    rsp,0x20
   3205c7611:	5d                   	pop    rbp
   3205c7612:	c3                   	ret
   3205c7613:	90                   	nop
   3205c7614:	90                   	nop
   3205c7615:	90                   	nop
   3205c7616:	90                   	nop
   3205c7617:	90                   	nop
   3205c7618:	90                   	nop
   3205c7619:	90                   	nop
   3205c761a:	90                   	nop
   3205c761b:	90                   	nop
   3205c761c:	90                   	nop
   3205c761d:	90                   	nop
   3205c761e:	90                   	nop
   3205c761f:	90                   	nop