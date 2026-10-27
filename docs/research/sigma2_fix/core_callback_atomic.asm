00000001e4f31658 <(anonymous namespace)::Sigma2_vfunction1((anonymous namespace)::Sigma2*)>:
   1e4f31658:	55                   	push   rbp
   1e4f31659:	48 89 e5             	mov    rbp,rsp
   1e4f3165c:	48 83 ec 30          	sub    rsp,0x30
   1e4f31660:	48 89 4d 10          	mov    QWORD PTR [rbp+0x10],rcx
   1e4f31664:	8b 05 a2 ca 00 00    	mov    eax,DWORD PTR [rip+0xcaa2]        # 1e4f3e10c <_tls_index>
   1e4f3166a:	65 48 8b 14 25 58 00 	mov    rdx,QWORD PTR gs:0x58
   1e4f31671:	00 00 
   1e4f31673:	48 8b 04 c2          	mov    rax,QWORD PTR [rdx+rax*8]
   1e4f31677:	0f b6 80 08 00 00 00 	movzx  eax,BYTE PTR [rax+0x8]
   1e4f3167e:	83 f0 01             	xor    eax,0x1
   1e4f31681:	84 c0                	test   al,al
   1e4f31683:	74 13                	je     1e4f31698 <(anonymous namespace)::Sigma2_vfunction1((anonymous namespace)::Sigma2*)+0x40>
   1e4f31685:	48 8d 45 ff          	lea    rax,[rbp-0x1]
   1e4f31689:	48 8d 0d 38 ca 00 00 	lea    rcx,[rip+0xca38]        # 1e4f3e0c8 <(anonymous namespace)::plugins_once>
   1e4f31690:	48 89 c2             	mov    rdx,rax
   1e4f31693:	e8 18 03 00 00       	call   1e4f319b0 <void std::call_once<(anonymous namespace)::Sigma2_vfunction1((anonymous namespace)::Sigma2*)::{lambda()#1}>(std::once_flag&, (anonymous namespace)::Sigma2_vfunction1((anonymous namespace)::Sigma2*)::{lambda()#1}&&)>
   1e4f31698:	48 8d 05 01 ca 00 00 	lea    rax,[rip+0xca01]        # 1e4f3e0a0 <(anonymous namespace)::Sigma2_vfunction1_hook>
   1e4f3169f:	48 89 c1             	mov    rcx,rax
   1e4f316a2:	e8 af 03 00 00       	call   1e4f31a56 <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::original() const>
   1e4f316a7:	48 8b 55 10          	mov    rdx,QWORD PTR [rbp+0x10]
   1e4f316ab:	48 89 d1             	mov    rcx,rdx
   1e4f316ae:	ff d0                	call   rax
   1e4f316b0:	48 83 c4 30          	add    rsp,0x30
   1e4f316b4:	5d                   	pop    rbp
   1e4f316b5:	c3                   	ret

00000001e4f31a7e <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::install(unsigned long long, bool (*)((anonymous namespace)::Sigma2*), bool (*)((anonymous namespace)::Sigma2*))>:
   1e4f31a7e:	55                   	push   rbp
   1e4f31a7f:	53                   	push   rbx
   1e4f31a80:	48 83 ec 58          	sub    rsp,0x58
   1e4f31a84:	48 8d 6c 24 50       	lea    rbp,[rsp+0x50]
   1e4f31a89:	48 89 4d 20          	mov    QWORD PTR [rbp+0x20],rcx
   1e4f31a8d:	48 89 55 28          	mov    QWORD PTR [rbp+0x28],rdx
   1e4f31a91:	4c 89 45 30          	mov    QWORD PTR [rbp+0x30],r8
   1e4f31a95:	4c 89 4d 38          	mov    QWORD PTR [rbp+0x38],r9
   1e4f31a99:	48 8b 55 20          	mov    rdx,QWORD PTR [rbp+0x20]
   1e4f31a9d:	48 8d 45 e0          	lea    rax,[rbp-0x20]
   1e4f31aa1:	48 89 c1             	mov    rcx,rax
   1e4f31aa4:	e8 0f 05 00 00       	call   1e4f31fb8 <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::Guard::Guard(std::atomic_flag&)>
   1e4f31aa9:	0f b6 45 e8          	movzx  eax,BYTE PTR [rbp-0x18]
   1e4f31aad:	83 f0 01             	xor    eax,0x1
   1e4f31ab0:	84 c0                	test   al,al
   1e4f31ab2:	74 0a                	je     1e4f31abe <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::install(unsigned long long, bool (*)((anonymous namespace)::Sigma2*), bool (*)((anonymous namespace)::Sigma2*))+0x40>
   1e4f31ab4:	bb 03 00 00 00       	mov    ebx,0x3
   1e4f31ab9:	e9 e0 01 00 00       	jmp    1e4f31c9e <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::install(unsigned long long, bool (*)((anonymous namespace)::Sigma2*), bool (*)((anonymous namespace)::Sigma2*))+0x220>
   1e4f31abe:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31ac2:	0f b6 40 24          	movzx  eax,BYTE PTR [rax+0x24]
   1e4f31ac6:	84 c0                	test   al,al
   1e4f31ac8:	74 0a                	je     1e4f31ad4 <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::install(unsigned long long, bool (*)((anonymous namespace)::Sigma2*), bool (*)((anonymous namespace)::Sigma2*))+0x56>
   1e4f31aca:	bb 04 00 00 00       	mov    ebx,0x4
   1e4f31acf:	e9 ca 01 00 00       	jmp    1e4f31c9e <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::install(unsigned long long, bool (*)((anonymous namespace)::Sigma2*), bool (*)((anonymous namespace)::Sigma2*))+0x220>
   1e4f31ad4:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31ad8:	c6 40 24 01          	mov    BYTE PTR [rax+0x24],0x1
   1e4f31adc:	48 83 7d 28 00       	cmp    QWORD PTR [rbp+0x28],0x0
   1e4f31ae1:	74 24                	je     1e4f31b07 <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::install(unsigned long long, bool (*)((anonymous namespace)::Sigma2*), bool (*)((anonymous namespace)::Sigma2*))+0x89>
   1e4f31ae3:	48 8b 45 28          	mov    rax,QWORD PTR [rbp+0x28]
   1e4f31ae7:	83 e0 07             	and    eax,0x7
   1e4f31aea:	48 85 c0             	test   rax,rax
   1e4f31aed:	75 18                	jne    1e4f31b07 <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::install(unsigned long long, bool (*)((anonymous namespace)::Sigma2*), bool (*)((anonymous namespace)::Sigma2*))+0x89>
   1e4f31aef:	48 83 7d 30 00       	cmp    QWORD PTR [rbp+0x30],0x0
   1e4f31af4:	74 11                	je     1e4f31b07 <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::install(unsigned long long, bool (*)((anonymous namespace)::Sigma2*), bool (*)((anonymous namespace)::Sigma2*))+0x89>
   1e4f31af6:	48 83 7d 38 00       	cmp    QWORD PTR [rbp+0x38],0x0
   1e4f31afb:	74 0a                	je     1e4f31b07 <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::install(unsigned long long, bool (*)((anonymous namespace)::Sigma2*), bool (*)((anonymous namespace)::Sigma2*))+0x89>
   1e4f31afd:	48 8b 45 30          	mov    rax,QWORD PTR [rbp+0x30]
   1e4f31b01:	48 3b 45 38          	cmp    rax,QWORD PTR [rbp+0x38]
   1e4f31b05:	75 0a                	jne    1e4f31b11 <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::install(unsigned long long, bool (*)((anonymous namespace)::Sigma2*), bool (*)((anonymous namespace)::Sigma2*))+0x93>
   1e4f31b07:	bb 07 00 00 00       	mov    ebx,0x7
   1e4f31b0c:	e9 8d 01 00 00       	jmp    1e4f31c9e <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::install(unsigned long long, bool (*)((anonymous namespace)::Sigma2*), bool (*)((anonymous namespace)::Sigma2*))+0x220>
   1e4f31b11:	48 8d 55 d8          	lea    rdx,[rbp-0x28]
   1e4f31b15:	48 8b 45 28          	mov    rax,QWORD PTR [rbp+0x28]
   1e4f31b19:	48 89 c1             	mov    rcx,rax
   1e4f31b1c:	e8 0f 5c 00 00       	call   1e4f37730 <nm::WindowsSlotOps::load(unsigned long long, unsigned long long&)>
   1e4f31b21:	83 f0 01             	xor    eax,0x1
   1e4f31b24:	84 c0                	test   al,al
   1e4f31b26:	74 0a                	je     1e4f31b32 <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::install(unsigned long long, bool (*)((anonymous namespace)::Sigma2*), bool (*)((anonymous namespace)::Sigma2*))+0xb4>
   1e4f31b28:	bb 06 00 00 00       	mov    ebx,0x6
   1e4f31b2d:	e9 6c 01 00 00       	jmp    1e4f31c9e <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::install(unsigned long long, bool (*)((anonymous namespace)::Sigma2*), bool (*)((anonymous namespace)::Sigma2*))+0x220>
   1e4f31b32:	48 8b 45 30          	mov    rax,QWORD PTR [rbp+0x30]
   1e4f31b36:	48 89 45 f8          	mov    QWORD PTR [rbp-0x8],rax
   1e4f31b3a:	48 8b 45 d8          	mov    rax,QWORD PTR [rbp-0x28]
   1e4f31b3e:	48 39 45 f8          	cmp    QWORD PTR [rbp-0x8],rax
   1e4f31b42:	74 0a                	je     1e4f31b4e <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::install(unsigned long long, bool (*)((anonymous namespace)::Sigma2*), bool (*)((anonymous namespace)::Sigma2*))+0xd0>
   1e4f31b44:	bb 05 00 00 00       	mov    ebx,0x5
   1e4f31b49:	e9 50 01 00 00       	jmp    1e4f31c9e <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::install(unsigned long long, bool (*)((anonymous namespace)::Sigma2*), bool (*)((anonymous namespace)::Sigma2*))+0x220>
   1e4f31b4e:	48 8b 45 38          	mov    rax,QWORD PTR [rbp+0x38]
   1e4f31b52:	48 89 c1             	mov    rcx,rax
   1e4f31b55:	e8 9b 05 00 00       	call   1e4f320f5 <bool nm::WindowsSlotOps::pin<bool (*)((anonymous namespace)::Sigma2*)>(bool (*)((anonymous namespace)::Sigma2*))>
   1e4f31b5a:	83 f0 01             	xor    eax,0x1
   1e4f31b5d:	84 c0                	test   al,al
   1e4f31b5f:	74 0a                	je     1e4f31b6b <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::install(unsigned long long, bool (*)((anonymous namespace)::Sigma2*), bool (*)((anonymous namespace)::Sigma2*))+0xed>
   1e4f31b61:	bb 08 00 00 00       	mov    ebx,0x8
   1e4f31b66:	e9 33 01 00 00       	jmp    1e4f31c9e <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::install(unsigned long long, bool (*)((anonymous namespace)::Sigma2*), bool (*)((anonymous namespace)::Sigma2*))+0x220>
   1e4f31b6b:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31b6f:	48 8b 55 28          	mov    rdx,QWORD PTR [rbp+0x28]
   1e4f31b73:	48 89 50 10          	mov    QWORD PTR [rax+0x10],rdx
   1e4f31b77:	48 8b 55 38          	mov    rdx,QWORD PTR [rbp+0x38]
   1e4f31b7b:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31b7f:	48 89 50 18          	mov    QWORD PTR [rax+0x18],rdx
   1e4f31b83:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31b87:	48 8d 48 08          	lea    rcx,[rax+0x8]
   1e4f31b8b:	48 8b 45 30          	mov    rax,QWORD PTR [rbp+0x30]
   1e4f31b8f:	41 b8 03 00 00 00    	mov    r8d,0x3
   1e4f31b95:	48 89 c2             	mov    rdx,rax
   1e4f31b98:	e8 8b 05 00 00       	call   1e4f32128 <std::atomic<bool (*)((anonymous namespace)::Sigma2*)>::store(bool (*)((anonymous namespace)::Sigma2*), std::memory_order)>
   1e4f31b9d:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31ba1:	48 8d 50 20          	lea    rdx,[rax+0x20]
   1e4f31ba5:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31ba9:	48 8b 40 10          	mov    rax,QWORD PTR [rax+0x10]
   1e4f31bad:	48 89 c1             	mov    rcx,rax
   1e4f31bb0:	e8 2b 5c 00 00       	call   1e4f377e0 <nm::WindowsSlotOps::writable(unsigned long long, unsigned long&)>
   1e4f31bb5:	83 f0 01             	xor    eax,0x1
   1e4f31bb8:	84 c0                	test   al,al
   1e4f31bba:	74 0a                	je     1e4f31bc6 <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::install(unsigned long long, bool (*)((anonymous namespace)::Sigma2*), bool (*)((anonymous namespace)::Sigma2*))+0x148>
   1e4f31bbc:	bb 09 00 00 00       	mov    ebx,0x9
   1e4f31bc1:	e9 d8 00 00 00       	jmp    1e4f31c9e <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::install(unsigned long long, bool (*)((anonymous namespace)::Sigma2*), bool (*)((anonymous namespace)::Sigma2*))+0x220>
   1e4f31bc6:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31bca:	c6 40 26 01          	mov    BYTE PTR [rax+0x26],0x1
   1e4f31bce:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31bd2:	48 8b 48 18          	mov    rcx,QWORD PTR [rax+0x18]
   1e4f31bd6:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31bda:	48 8b 40 10          	mov    rax,QWORD PTR [rax+0x10]
   1e4f31bde:	48 8b 55 f8          	mov    rdx,QWORD PTR [rbp-0x8]
   1e4f31be2:	49 89 c8             	mov    r8,rcx
   1e4f31be5:	48 89 c1             	mov    rcx,rax
   1e4f31be8:	e8 f3 5a 00 00       	call   1e4f376e0 <nm::WindowsSlotOps::exchange_if(unsigned long long, unsigned long long, unsigned long long)>
   1e4f31bed:	48 89 45 f0          	mov    QWORD PTR [rbp-0x10],rax
   1e4f31bf1:	48 8b 45 f0          	mov    rax,QWORD PTR [rbp-0x10]
   1e4f31bf5:	48 3b 45 f8          	cmp    rax,QWORD PTR [rbp-0x8]
   1e4f31bf9:	0f 94 c2             	sete   dl
   1e4f31bfc:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31c00:	88 50 25             	mov    BYTE PTR [rax+0x25],dl
   1e4f31c03:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31c07:	8b 50 20             	mov    edx,DWORD PTR [rax+0x20]
   1e4f31c0a:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31c0e:	48 8b 40 10          	mov    rax,QWORD PTR [rax+0x10]
   1e4f31c12:	48 89 c1             	mov    rcx,rax
   1e4f31c15:	e8 86 5b 00 00       	call   1e4f377a0 <nm::WindowsSlotOps::protect(unsigned long long, unsigned long)>
   1e4f31c1a:	83 f0 01             	xor    eax,0x1
   1e4f31c1d:	84 c0                	test   al,al
   1e4f31c1f:	74 5d                	je     1e4f31c7e <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::install(unsigned long long, bool (*)((anonymous namespace)::Sigma2*), bool (*)((anonymous namespace)::Sigma2*))+0x200>
   1e4f31c21:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31c25:	0f b6 40 25          	movzx  eax,BYTE PTR [rax+0x25]
   1e4f31c29:	84 c0                	test   al,al
   1e4f31c2b:	74 1f                	je     1e4f31c4c <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::install(unsigned long long, bool (*)((anonymous namespace)::Sigma2*), bool (*)((anonymous namespace)::Sigma2*))+0x1ce>
   1e4f31c2d:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31c31:	48 8b 50 18          	mov    rdx,QWORD PTR [rax+0x18]
   1e4f31c35:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31c39:	48 8b 40 10          	mov    rax,QWORD PTR [rax+0x10]
   1e4f31c3d:	48 8b 4d f8          	mov    rcx,QWORD PTR [rbp-0x8]
   1e4f31c41:	49 89 c8             	mov    r8,rcx
   1e4f31c44:	48 89 c1             	mov    rcx,rax
   1e4f31c47:	e8 94 5a 00 00       	call   1e4f376e0 <nm::WindowsSlotOps::exchange_if(unsigned long long, unsigned long long, unsigned long long)>
   1e4f31c4c:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31c50:	c6 40 25 00          	mov    BYTE PTR [rax+0x25],0x0
   1e4f31c54:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31c58:	8b 50 20             	mov    edx,DWORD PTR [rax+0x20]
   1e4f31c5b:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31c5f:	48 8b 40 10          	mov    rax,QWORD PTR [rax+0x10]
   1e4f31c63:	48 89 c1             	mov    rcx,rax
   1e4f31c66:	e8 35 5b 00 00       	call   1e4f377a0 <nm::WindowsSlotOps::protect(unsigned long long, unsigned long)>
   1e4f31c6b:	83 f0 01             	xor    eax,0x1
   1e4f31c6e:	89 c2                	mov    edx,eax
   1e4f31c70:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31c74:	88 50 26             	mov    BYTE PTR [rax+0x26],dl
   1e4f31c77:	bb 0a 00 00 00       	mov    ebx,0xa
   1e4f31c7c:	eb 20                	jmp    1e4f31c9e <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::install(unsigned long long, bool (*)((anonymous namespace)::Sigma2*), bool (*)((anonymous namespace)::Sigma2*))+0x220>
   1e4f31c7e:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31c82:	c6 40 26 00          	mov    BYTE PTR [rax+0x26],0x0
   1e4f31c86:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31c8a:	0f b6 40 25          	movzx  eax,BYTE PTR [rax+0x25]
   1e4f31c8e:	84 c0                	test   al,al
   1e4f31c90:	74 07                	je     1e4f31c99 <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::install(unsigned long long, bool (*)((anonymous namespace)::Sigma2*), bool (*)((anonymous namespace)::Sigma2*))+0x21b>
   1e4f31c92:	bb 00 00 00 00       	mov    ebx,0x0
   1e4f31c97:	eb 05                	jmp    1e4f31c9e <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::install(unsigned long long, bool (*)((anonymous namespace)::Sigma2*), bool (*)((anonymous namespace)::Sigma2*))+0x220>
   1e4f31c99:	bb 0b 00 00 00       	mov    ebx,0xb
   1e4f31c9e:	48 8d 45 e0          	lea    rax,[rbp-0x20]
   1e4f31ca2:	48 89 c1             	mov    rcx,rax
   1e4f31ca5:	e8 56 03 00 00       	call   1e4f32000 <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::Guard::~Guard()>
   1e4f31caa:	89 d8                	mov    eax,ebx
   1e4f31cac:	48 83 c4 58          	add    rsp,0x58
   1e4f31cb0:	5b                   	pop    rbx
   1e4f31cb1:	5d                   	pop    rbp
   1e4f31cb2:	c3                   	ret
   1e4f31cb3:	90                   	nop

00000001e4f31cb4 <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::restore()>:
   1e4f31cb4:	55                   	push   rbp
   1e4f31cb5:	53                   	push   rbx
   1e4f31cb6:	48 83 ec 58          	sub    rsp,0x58
   1e4f31cba:	48 8d 6c 24 50       	lea    rbp,[rsp+0x50]
   1e4f31cbf:	48 89 4d 20          	mov    QWORD PTR [rbp+0x20],rcx
   1e4f31cc3:	48 8b 55 20          	mov    rdx,QWORD PTR [rbp+0x20]
   1e4f31cc7:	48 8d 45 e0          	lea    rax,[rbp-0x20]
   1e4f31ccb:	48 89 c1             	mov    rcx,rax
   1e4f31cce:	e8 e5 02 00 00       	call   1e4f31fb8 <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::Guard::Guard(std::atomic_flag&)>
   1e4f31cd3:	0f b6 45 e8          	movzx  eax,BYTE PTR [rbp-0x18]
   1e4f31cd7:	83 f0 01             	xor    eax,0x1
   1e4f31cda:	84 c0                	test   al,al
   1e4f31cdc:	74 0a                	je     1e4f31ce8 <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::restore()+0x34>
   1e4f31cde:	bb 03 00 00 00       	mov    ebx,0x3
   1e4f31ce3:	e9 54 01 00 00       	jmp    1e4f31e3c <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::restore()+0x188>
   1e4f31ce8:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31cec:	0f b6 40 26          	movzx  eax,BYTE PTR [rax+0x26]
   1e4f31cf0:	84 c0                	test   al,al
   1e4f31cf2:	74 30                	je     1e4f31d24 <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::restore()+0x70>
   1e4f31cf4:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31cf8:	8b 50 20             	mov    edx,DWORD PTR [rax+0x20]
   1e4f31cfb:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31cff:	48 8b 40 10          	mov    rax,QWORD PTR [rax+0x10]
   1e4f31d03:	48 89 c1             	mov    rcx,rax
   1e4f31d06:	e8 95 5a 00 00       	call   1e4f377a0 <nm::WindowsSlotOps::protect(unsigned long long, unsigned long)>
   1e4f31d0b:	83 f0 01             	xor    eax,0x1
   1e4f31d0e:	84 c0                	test   al,al
   1e4f31d10:	74 0a                	je     1e4f31d1c <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::restore()+0x68>
   1e4f31d12:	bb 0a 00 00 00       	mov    ebx,0xa
   1e4f31d17:	e9 20 01 00 00       	jmp    1e4f31e3c <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::restore()+0x188>
   1e4f31d1c:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31d20:	c6 40 26 00          	mov    BYTE PTR [rax+0x26],0x0
   1e4f31d24:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31d28:	0f b6 40 25          	movzx  eax,BYTE PTR [rax+0x25]
   1e4f31d2c:	83 f0 01             	xor    eax,0x1
   1e4f31d2f:	84 c0                	test   al,al
   1e4f31d31:	74 0a                	je     1e4f31d3d <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::restore()+0x89>
   1e4f31d33:	bb 02 00 00 00       	mov    ebx,0x2
   1e4f31d38:	e9 ff 00 00 00       	jmp    1e4f31e3c <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::restore()+0x188>
   1e4f31d3d:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31d41:	48 8b 40 10          	mov    rax,QWORD PTR [rax+0x10]
   1e4f31d45:	48 8d 55 d8          	lea    rdx,[rbp-0x28]
   1e4f31d49:	48 89 c1             	mov    rcx,rax
   1e4f31d4c:	e8 df 59 00 00       	call   1e4f37730 <nm::WindowsSlotOps::load(unsigned long long, unsigned long long&)>
   1e4f31d51:	83 f0 01             	xor    eax,0x1
   1e4f31d54:	84 c0                	test   al,al
   1e4f31d56:	74 0a                	je     1e4f31d62 <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::restore()+0xae>
   1e4f31d58:	bb 06 00 00 00       	mov    ebx,0x6
   1e4f31d5d:	e9 da 00 00 00       	jmp    1e4f31e3c <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::restore()+0x188>
   1e4f31d62:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31d66:	48 8b 50 18          	mov    rdx,QWORD PTR [rax+0x18]
   1e4f31d6a:	48 8b 45 d8          	mov    rax,QWORD PTR [rbp-0x28]
   1e4f31d6e:	48 39 c2             	cmp    rdx,rax
   1e4f31d71:	74 12                	je     1e4f31d85 <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::restore()+0xd1>
   1e4f31d73:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31d77:	c6 40 25 00          	mov    BYTE PTR [rax+0x25],0x0
   1e4f31d7b:	bb 0b 00 00 00       	mov    ebx,0xb
   1e4f31d80:	e9 b7 00 00 00       	jmp    1e4f31e3c <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::restore()+0x188>
   1e4f31d85:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31d89:	48 8d 50 20          	lea    rdx,[rax+0x20]
   1e4f31d8d:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31d91:	48 8b 40 10          	mov    rax,QWORD PTR [rax+0x10]
   1e4f31d95:	48 89 c1             	mov    rcx,rax
   1e4f31d98:	e8 43 5a 00 00       	call   1e4f377e0 <nm::WindowsSlotOps::writable(unsigned long long, unsigned long&)>
   1e4f31d9d:	83 f0 01             	xor    eax,0x1
   1e4f31da0:	84 c0                	test   al,al
   1e4f31da2:	74 0a                	je     1e4f31dae <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::restore()+0xfa>
   1e4f31da4:	bb 09 00 00 00       	mov    ebx,0x9
   1e4f31da9:	e9 8e 00 00 00       	jmp    1e4f31e3c <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::restore()+0x188>
   1e4f31dae:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31db2:	c6 40 26 01          	mov    BYTE PTR [rax+0x26],0x1
   1e4f31db6:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31dba:	48 83 c0 08          	add    rax,0x8
   1e4f31dbe:	ba 02 00 00 00       	mov    edx,0x2
   1e4f31dc3:	48 89 c1             	mov    rcx,rax
   1e4f31dc6:	e8 45 01 00 00       	call   1e4f31f10 <std::atomic<bool (*)((anonymous namespace)::Sigma2*)>::load(std::memory_order) const>
   1e4f31dcb:	48 89 c1             	mov    rcx,rax
   1e4f31dce:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31dd2:	48 8b 50 18          	mov    rdx,QWORD PTR [rax+0x18]
   1e4f31dd6:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31dda:	48 8b 40 10          	mov    rax,QWORD PTR [rax+0x10]
   1e4f31dde:	49 89 c8             	mov    r8,rcx
   1e4f31de1:	48 89 c1             	mov    rcx,rax
   1e4f31de4:	e8 f7 58 00 00       	call   1e4f376e0 <nm::WindowsSlotOps::exchange_if(unsigned long long, unsigned long long, unsigned long long)>
   1e4f31de9:	48 89 45 f8          	mov    QWORD PTR [rbp-0x8],rax
   1e4f31ded:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31df1:	c6 40 25 00          	mov    BYTE PTR [rax+0x25],0x0
   1e4f31df5:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31df9:	8b 50 20             	mov    edx,DWORD PTR [rax+0x20]
   1e4f31dfc:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31e00:	48 8b 40 10          	mov    rax,QWORD PTR [rax+0x10]
   1e4f31e04:	48 89 c1             	mov    rcx,rax
   1e4f31e07:	e8 94 59 00 00       	call   1e4f377a0 <nm::WindowsSlotOps::protect(unsigned long long, unsigned long)>
   1e4f31e0c:	83 f0 01             	xor    eax,0x1
   1e4f31e0f:	84 c0                	test   al,al
   1e4f31e11:	74 07                	je     1e4f31e1a <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::restore()+0x166>
   1e4f31e13:	bb 0a 00 00 00       	mov    ebx,0xa
   1e4f31e18:	eb 22                	jmp    1e4f31e3c <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::restore()+0x188>
   1e4f31e1a:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31e1e:	c6 40 26 00          	mov    BYTE PTR [rax+0x26],0x0
   1e4f31e22:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1e4f31e26:	48 8b 40 18          	mov    rax,QWORD PTR [rax+0x18]
   1e4f31e2a:	48 39 45 f8          	cmp    QWORD PTR [rbp-0x8],rax
   1e4f31e2e:	75 07                	jne    1e4f31e37 <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::restore()+0x183>
   1e4f31e30:	bb 01 00 00 00       	mov    ebx,0x1
   1e4f31e35:	eb 05                	jmp    1e4f31e3c <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::restore()+0x188>
   1e4f31e37:	bb 0b 00 00 00       	mov    ebx,0xb
   1e4f31e3c:	48 8d 45 e0          	lea    rax,[rbp-0x20]
   1e4f31e40:	48 89 c1             	mov    rcx,rax
   1e4f31e43:	e8 b8 01 00 00       	call   1e4f32000 <nm::SlotHook<bool (*)((anonymous namespace)::Sigma2*), nm::WindowsSlotOps>::Guard::~Guard()>
   1e4f31e48:	89 d8                	mov    eax,ebx
   1e4f31e4a:	48 83 c4 58          	add    rsp,0x58
   1e4f31e4e:	5b                   	pop    rbx
   1e4f31e4f:	5d                   	pop    rbp
   1e4f31e50:	c3                   	ret

00000001e4f376e0 <nm::WindowsSlotOps::exchange_if(unsigned long long, unsigned long long, unsigned long long)>:
   1e4f376e0:	55                   	push   rbp
   1e4f376e1:	48 89 e5             	mov    rbp,rsp
   1e4f376e4:	48 83 ec 20          	sub    rsp,0x20
   1e4f376e8:	48 89 4d 10          	mov    QWORD PTR [rbp+0x10],rcx
   1e4f376ec:	48 89 55 18          	mov    QWORD PTR [rbp+0x18],rdx
   1e4f376f0:	4c 89 45 20          	mov    QWORD PTR [rbp+0x20],r8
   1e4f376f4:	48 8b 45 18          	mov    rax,QWORD PTR [rbp+0x18]
   1e4f376f8:	48 8b 55 20          	mov    rdx,QWORD PTR [rbp+0x20]
   1e4f376fc:	48 8b 4d 10          	mov    rcx,QWORD PTR [rbp+0x10]
   1e4f37700:	48 89 4d f8          	mov    QWORD PTR [rbp-0x8],rcx
   1e4f37704:	48 89 55 f0          	mov    QWORD PTR [rbp-0x10],rdx
   1e4f37708:	48 89 45 e8          	mov    QWORD PTR [rbp-0x18],rax
   1e4f3770c:	48 8b 4d f0          	mov    rcx,QWORD PTR [rbp-0x10]
   1e4f37710:	48 8b 45 e8          	mov    rax,QWORD PTR [rbp-0x18]
   1e4f37714:	48 8b 55 f8          	mov    rdx,QWORD PTR [rbp-0x8]
   1e4f37718:	f0 48 0f b1 0a       	lock cmpxchg QWORD PTR [rdx],rcx
   1e4f3771d:	48 83 c4 20          	add    rsp,0x20
   1e4f37721:	5d                   	pop    rbp
   1e4f37722:	c3                   	ret
   1e4f37723:	90                   	nop
   1e4f37724:	90                   	nop
   1e4f37725:	90                   	nop
   1e4f37726:	90                   	nop
   1e4f37727:	90                   	nop
   1e4f37728:	90                   	nop
   1e4f37729:	90                   	nop
   1e4f3772a:	90                   	nop
   1e4f3772b:	90                   	nop
   1e4f3772c:	90                   	nop
   1e4f3772d:	90                   	nop
   1e4f3772e:	90                   	nop
   1e4f3772f:	90                   	nop
