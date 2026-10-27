
~/.local/share/Steam/steamapps/common/[NINJA GAIDEN Master Collection] NINJA GAIDEN Σ２/dbghelp.dll:     file format pei-x86-64


Disassembly of section .text:

0000000180001000 <.text>:
   180001000:	40 57                	rex push rdi
   180001002:	48 83 ec 30          	sub    rsp,0x30
   180001006:	b9 28 00 00 00       	mov    ecx,0x28
   18000100b:	e8 c4 05 00 00       	call   0x1800015d4
   180001010:	48 89 44 24 40       	mov    QWORD PTR [rsp+0x40],rax
   180001015:	48 8b f8             	mov    rdi,rax
   180001018:	48 85 c0             	test   rax,rax
   18000101b:	0f 84 85 00 00 00    	je     0x1800010a6
   180001021:	48 8d 0d 18 03 00 00 	lea    rcx,[rip+0x318]        # 0x180001340
   180001028:	48 89 5c 24 48       	mov    QWORD PTR [rsp+0x48],rbx
   18000102d:	48 89 08             	mov    QWORD PTR [rax],rcx
   180001030:	4c 8d 4f 08          	lea    r9,[rdi+0x8]
   180001034:	b8 48 b8 00 00       	mov    eax,0xb848
   180001039:	48 89 4c 24 22       	mov    QWORD PTR [rsp+0x22],rcx
   18000103e:	48 8b 0d bb 1f 00 00 	mov    rcx,QWORD PTR [rip+0x1fbb]        # 0x180003000
   180001045:	ba 0c 00 00 00       	mov    edx,0xc
   18000104a:	66 89 44 24 20       	mov    WORD PTR [rsp+0x20],ax
   18000104f:	41 b8 40 00 00 00    	mov    r8d,0x40
   180001055:	b8 ff e0 00 00       	mov    eax,0xe0ff
   18000105a:	66 89 44 24 2a       	mov    WORD PTR [rsp+0x2a],ax
   18000105f:	48 8b 05 9a 1f 00 00 	mov    rax,QWORD PTR [rip+0x1f9a]        # 0x180003000
   180001066:	48 89 47 10          	mov    QWORD PTR [rdi+0x10],rax
   18000106a:	f2 0f 10 00          	movsd  xmm0,QWORD PTR [rax]
   18000106e:	f2 0f 11 47 18       	movsd  QWORD PTR [rdi+0x18],xmm0
   180001073:	8b 40 08             	mov    eax,DWORD PTR [rax+0x8]
   180001076:	89 47 20             	mov    DWORD PTR [rdi+0x20],eax
   180001079:	ff 15 a1 1f 00 00    	call   QWORD PTR [rip+0x1fa1]        # 0x180003020
   18000107f:	48 8b 4f 10          	mov    rcx,QWORD PTR [rdi+0x10]
   180001083:	f2 0f 10 44 24 20    	movsd  xmm0,QWORD PTR [rsp+0x20]
   180001089:	8b 44 24 28          	mov    eax,DWORD PTR [rsp+0x28]
   18000108d:	48 8b 5c 24 48       	mov    rbx,QWORD PTR [rsp+0x48]
   180001092:	f2 0f 11 01          	movsd  QWORD PTR [rcx],xmm0
   180001096:	89 41 08             	mov    DWORD PTR [rcx+0x8],eax
   180001099:	48 89 3d 90 40 00 00 	mov    QWORD PTR [rip+0x4090],rdi        # 0x180005130
   1800010a0:	48 83 c4 30          	add    rsp,0x30
   1800010a4:	5f                   	pop    rdi
   1800010a5:	c3                   	ret
   1800010a6:	48 c7 05 7f 40 00 00 	mov    QWORD PTR [rip+0x407f],0x0        # 0x180005130
   1800010ad:	00 00 00 00 
   1800010b1:	48 83 c4 30          	add    rsp,0x30
   1800010b5:	5f                   	pop    rdi
   1800010b6:	c3                   	ret
   1800010b7:	cc                   	int3
   1800010b8:	cc                   	int3
   1800010b9:	cc                   	int3
   1800010ba:	cc                   	int3
   1800010bb:	cc                   	int3
   1800010bc:	cc                   	int3
   1800010bd:	cc                   	int3
   1800010be:	cc                   	int3
   1800010bf:	cc                   	int3
   1800010c0:	48 83 ec 28          	sub    rsp,0x28
   1800010c4:	33 c9                	xor    ecx,ecx
   1800010c6:	ff 15 64 1f 00 00    	call   QWORD PTR [rip+0x1f64]        # 0x180003030
   1800010cc:	48 89 05 6d 40 00 00 	mov    QWORD PTR [rip+0x406d],rax        # 0x180005140
   1800010d3:	48 83 c4 28          	add    rsp,0x28
   1800010d7:	c3                   	ret
   1800010d8:	cc                   	int3
   1800010d9:	cc                   	int3
   1800010da:	cc                   	int3
   1800010db:	cc                   	int3
   1800010dc:	cc                   	int3
   1800010dd:	cc                   	int3
   1800010de:	cc                   	int3
   1800010df:	cc                   	int3
   1800010e0:	48 83 ec 28          	sub    rsp,0x28
   1800010e4:	33 c9                	xor    ecx,ecx
   1800010e6:	ff 15 44 1f 00 00    	call   QWORD PTR [rip+0x1f44]        # 0x180003030
   1800010ec:	8b 48 3c             	mov    ecx,DWORD PTR [rax+0x3c]
   1800010ef:	8b 44 01 1c          	mov    eax,DWORD PTR [rcx+rax*1+0x1c]
   1800010f3:	89 05 3f 40 00 00    	mov    DWORD PTR [rip+0x403f],eax        # 0x180005138
   1800010f9:	48 83 c4 28          	add    rsp,0x28
   1800010fd:	c3                   	ret
   1800010fe:	cc                   	int3
   1800010ff:	cc                   	int3
   180001100:	48 89 5c 24 10       	mov    QWORD PTR [rsp+0x10],rbx
   180001105:	57                   	push   rdi
   180001106:	48 83 ec 30          	sub    rsp,0x30
   18000110a:	48 89 4c 24 20       	mov    QWORD PTR [rsp+0x20],rcx
   18000110f:	48 8b f9             	mov    rdi,rcx
   180001112:	48 8b 0d 27 40 00 00 	mov    rcx,QWORD PTR [rip+0x4027]        # 0x180005140
   180001119:	b8 48 b8 00 00       	mov    eax,0xb848
   18000111e:	48 03 ca             	add    rcx,rdx
   180001121:	66 89 44 24 20       	mov    WORD PTR [rsp+0x20],ax
   180001126:	4c 89 44 24 22       	mov    QWORD PTR [rsp+0x22],r8
   18000112b:	b8 ff e0 00 00       	mov    eax,0xe0ff
   180001130:	4c 89 07             	mov    QWORD PTR [rdi],r8
   180001133:	4c 8d 4f 08          	lea    r9,[rdi+0x8]
   180001137:	48 89 4f 10          	mov    QWORD PTR [rdi+0x10],rcx
   18000113b:	41 b8 40 00 00 00    	mov    r8d,0x40
   180001141:	f2 0f 10 01          	movsd  xmm0,QWORD PTR [rcx]
   180001145:	f2 0f 11 47 18       	movsd  QWORD PTR [rdi+0x18],xmm0
   18000114a:	8b 51 08             	mov    edx,DWORD PTR [rcx+0x8]
   18000114d:	89 57 20             	mov    DWORD PTR [rdi+0x20],edx
   180001150:	ba 0c 00 00 00       	mov    edx,0xc
   180001155:	66 89 44 24 2a       	mov    WORD PTR [rsp+0x2a],ax
   18000115a:	ff 15 c0 1e 00 00    	call   QWORD PTR [rip+0x1ec0]        # 0x180003020
   180001160:	48 8b 57 10          	mov    rdx,QWORD PTR [rdi+0x10]
   180001164:	48 8b c7             	mov    rax,rdi
   180001167:	f2 0f 10 44 24 20    	movsd  xmm0,QWORD PTR [rsp+0x20]
   18000116d:	8b 4c 24 28          	mov    ecx,DWORD PTR [rsp+0x28]
   180001171:	48 8b 5c 24 48       	mov    rbx,QWORD PTR [rsp+0x48]
   180001176:	f2 0f 11 02          	movsd  QWORD PTR [rdx],xmm0
   18000117a:	89 4a 08             	mov    DWORD PTR [rdx+0x8],ecx
   18000117d:	48 83 c4 30          	add    rsp,0x30
   180001181:	5f                   	pop    rdi
   180001182:	c3                   	ret
   180001183:	cc                   	int3
   180001184:	cc                   	int3
   180001185:	cc                   	int3
   180001186:	cc                   	int3
   180001187:	cc                   	int3
   180001188:	cc                   	int3
   180001189:	cc                   	int3
   18000118a:	cc                   	int3
   18000118b:	cc                   	int3
   18000118c:	cc                   	int3
   18000118d:	cc                   	int3
   18000118e:	cc                   	int3
   18000118f:	cc                   	int3
   180001190:	40 53                	rex push rbx
   180001192:	48 81 ec 80 02 00 00 	sub    rsp,0x280
   180001199:	48 8b 05 60 3e 00 00 	mov    rax,QWORD PTR [rip+0x3e60]        # 0x180005000
   1800011a0:	48 33 c4             	xor    rax,rsp
   1800011a3:	48 89 84 24 70 02 00 	mov    QWORD PTR [rsp+0x270],rax
   1800011aa:	00 
   1800011ab:	bb 04 01 00 00       	mov    ebx,0x104
   1800011b0:	4c 8d 05 49 20 00 00 	lea    r8,[rip+0x2049]        # 0x180003200
   1800011b7:	48 8d 84 24 60 01 00 	lea    rax,[rsp+0x160]
   1800011be:	00 
   1800011bf:	8b d3                	mov    edx,ebx
   1800011c1:	4c 2b c0             	sub    r8,rax
   1800011c4:	48 8d 8c 24 60 01 00 	lea    rcx,[rsp+0x160]
   1800011cb:	00 
   1800011cc:	0f 1f 40 00          	nop    DWORD PTR [rax+0x0]
   1800011d0:	48 8d 82 fa fe ff 7f 	lea    rax,[rdx+0x7ffffefa]
   1800011d7:	48 85 c0             	test   rax,rax
   1800011da:	74 14                	je     0x1800011f0
   1800011dc:	41 0f b6 04 08       	movzx  eax,BYTE PTR [r8+rcx*1]
   1800011e1:	84 c0                	test   al,al
   1800011e3:	74 0b                	je     0x1800011f0
   1800011e5:	88 01                	mov    BYTE PTR [rcx],al
   1800011e7:	48 ff c1             	inc    rcx
   1800011ea:	48 83 ea 01          	sub    rdx,0x1
   1800011ee:	75 e0                	jne    0x1800011d0
   1800011f0:	48 8d 41 ff          	lea    rax,[rcx-0x1]
   1800011f4:	48 85 d2             	test   rdx,rdx
   1800011f7:	48 0f 45 c1          	cmovne rax,rcx
   1800011fb:	48 8d 8c 24 60 01 00 	lea    rcx,[rsp+0x160]
   180001202:	00 
   180001203:	c6 00 00             	mov    BYTE PTR [rax],0x0
   180001206:	ff 15 34 1e 00 00    	call   QWORD PTR [rip+0x1e34]        # 0x180003040
   18000120c:	48 8b cb             	mov    rcx,rbx
   18000120f:	48 8d 84 24 60 01 00 	lea    rax,[rsp+0x160]
   180001216:	00 
   180001217:	80 38 00             	cmp    BYTE PTR [rax],0x0
   18000121a:	74 09                	je     0x180001225
   18000121c:	48 ff c0             	inc    rax
   18000121f:	48 83 e9 01          	sub    rcx,0x1
   180001223:	75 f2                	jne    0x180001217
   180001225:	33 d2                	xor    edx,edx
   180001227:	48 8b c3             	mov    rax,rbx
   18000122a:	48 2b c1             	sub    rax,rcx
   18000122d:	48 85 c9             	test   rcx,rcx
   180001230:	48 0f 44 c2          	cmove  rax,rdx
   180001234:	74 4a                	je     0x180001280
   180001236:	48 8d 8c 24 60 01 00 	lea    rcx,[rsp+0x160]
   18000123d:	00 
   18000123e:	48 8d 0c 01          	lea    rcx,[rcx+rax*1]
   180001242:	48 2b d8             	sub    rbx,rax
   180001245:	74 2b                	je     0x180001272
   180001247:	4c 8d 05 ba 1f 00 00 	lea    r8,[rip+0x1fba]        # 0x180003208
   18000124e:	b8 fe ff ff 7f       	mov    eax,0x7ffffffe
   180001253:	4c 2b c1             	sub    r8,rcx
   180001256:	48 85 c0             	test   rax,rax
   180001259:	74 17                	je     0x180001272
   18000125b:	41 0f b6 14 08       	movzx  edx,BYTE PTR [r8+rcx*1]
   180001260:	84 d2                	test   dl,dl
   180001262:	74 0e                	je     0x180001272
   180001264:	88 11                	mov    BYTE PTR [rcx],dl
   180001266:	48 ff c8             	dec    rax
   180001269:	48 ff c1             	inc    rcx
   18000126c:	48 83 eb 01          	sub    rbx,0x1
   180001270:	75 e4                	jne    0x180001256
   180001272:	48 85 db             	test   rbx,rbx
   180001275:	48 8d 41 ff          	lea    rax,[rcx-0x1]
   180001279:	48 0f 45 c1          	cmovne rax,rcx
   18000127d:	c6 00 00             	mov    BYTE PTR [rax],0x0
   180001280:	48 8d 54 24 20       	lea    rdx,[rsp+0x20]
   180001285:	48 8d 8c 24 60 01 00 	lea    rcx,[rsp+0x160]
   18000128c:	00 
   18000128d:	ff 15 7d 1d 00 00    	call   QWORD PTR [rip+0x1d7d]        # 0x180003010
   180001293:	48 8b d8             	mov    rbx,rax
   180001296:	48 83 f8 ff          	cmp    rax,0xffffffffffffffff
   18000129a:	74 3a                	je     0x1800012d6
   18000129c:	0f 1f 40 00          	nop    DWORD PTR [rax+0x0]
   1800012a0:	48 8d 4c 24 4c       	lea    rcx,[rsp+0x4c]
   1800012a5:	ff 15 85 1d 00 00    	call   QWORD PTR [rip+0x1d85]        # 0x180003030
   1800012ab:	48 85 c0             	test   rax,rax
   1800012ae:	75 0b                	jne    0x1800012bb
   1800012b0:	48 8d 4c 24 4c       	lea    rcx,[rsp+0x4c]
   1800012b5:	ff 15 7d 1d 00 00    	call   QWORD PTR [rip+0x1d7d]        # 0x180003038
   1800012bb:	48 8d 54 24 20       	lea    rdx,[rsp+0x20]
   1800012c0:	48 8b cb             	mov    rcx,rbx
   1800012c3:	ff 15 4f 1d 00 00    	call   QWORD PTR [rip+0x1d4f]        # 0x180003018
   1800012c9:	85 c0                	test   eax,eax
   1800012cb:	75 d3                	jne    0x1800012a0
   1800012cd:	48 8b cb             	mov    rcx,rbx
   1800012d0:	ff 15 32 1d 00 00    	call   QWORD PTR [rip+0x1d32]        # 0x180003008
   1800012d6:	48 8b 1d 43 3e 00 00 	mov    rbx,QWORD PTR [rip+0x3e43]        # 0x180005120
   1800012dd:	48 85 db             	test   rbx,rbx
   1800012e0:	74 3c                	je     0x18000131e
   1800012e2:	48 8b 53 10          	mov    rdx,QWORD PTR [rbx+0x10]
   1800012e6:	48 85 d2             	test   rdx,rdx
   1800012e9:	74 26                	je     0x180001311
   1800012eb:	f2 0f 10 43 18       	movsd  xmm0,QWORD PTR [rbx+0x18]
   1800012f0:	4c 8d 4b 08          	lea    r9,[rbx+0x8]
   1800012f4:	f2 0f 11 02          	movsd  QWORD PTR [rdx],xmm0
   1800012f8:	8b 43 20             	mov    eax,DWORD PTR [rbx+0x20]
   1800012fb:	89 42 08             	mov    DWORD PTR [rdx+0x8],eax
   1800012fe:	ba 0c 00 00 00       	mov    edx,0xc
   180001303:	44 8b 43 08          	mov    r8d,DWORD PTR [rbx+0x8]
   180001307:	48 8b 4b 10          	mov    rcx,QWORD PTR [rbx+0x10]
   18000130b:	ff 15 0f 1d 00 00    	call   QWORD PTR [rip+0x1d0f]        # 0x180003020
   180001311:	ba 28 00 00 00       	mov    edx,0x28
   180001316:	48 8b cb             	mov    rcx,rbx
   180001319:	e8 f2 02 00 00       	call   0x180001610
   18000131e:	b0 01                	mov    al,0x1
   180001320:	48 8b 8c 24 70 02 00 	mov    rcx,QWORD PTR [rsp+0x270]
   180001327:	00 
   180001328:	48 33 cc             	xor    rcx,rsp
   18000132b:	e8 80 03 00 00       	call   0x1800016b0
   180001330:	48 81 c4 80 02 00 00 	add    rsp,0x280
   180001337:	5b                   	pop    rbx
   180001338:	c3                   	ret
   180001339:	cc                   	int3
   18000133a:	cc                   	int3
   18000133b:	cc                   	int3
   18000133c:	cc                   	int3
   18000133d:	cc                   	int3
   18000133e:	cc                   	int3
   18000133f:	cc                   	int3
   180001340:	48 89 5c 24 08       	mov    QWORD PTR [rsp+0x8],rbx
   180001345:	57                   	push   rdi
   180001346:	48 83 ec 20          	sub    rsp,0x20
   18000134a:	8b 05 e8 3d 00 00    	mov    eax,DWORD PTR [rip+0x3de8]        # 0x180005138
   180001350:	48 8b f9             	mov    rdi,rcx
   180001353:	3d 00 aa 91 00       	cmp    eax,0x91aa00
   180001358:	0f 84 50 01 00 00    	je     0x1800014ae
   18000135e:	3d 00 c0 79 01       	cmp    eax,0x179c000
   180001363:	0f 84 a8 00 00 00    	je     0x180001411
   180001369:	3d 00 c4 79 01       	cmp    eax,0x179c400
   18000136e:	0f 85 d9 01 00 00    	jne    0x18000154d
   180001374:	b9 28 00 00 00       	mov    ecx,0x28
   180001379:	e8 56 02 00 00       	call   0x1800015d4
   18000137e:	48 89 44 24 38       	mov    QWORD PTR [rsp+0x38],rax
   180001383:	48 85 c0             	test   rax,rax
   180001386:	74 14                	je     0x18000139c
   180001388:	4c 8d 05 01 fe ff ff 	lea    r8,[rip+0xfffffffffffffe01]        # 0x180001190
   18000138f:	ba 60 c4 b5 00       	mov    edx,0xb5c460
   180001394:	48 8b c8             	mov    rcx,rax
   180001397:	e8 64 fd ff ff       	call   0x180001100
   18000139c:	b9 18 00 00 00       	mov    ecx,0x18
   1800013a1:	48 89 05 78 3d 00 00 	mov    QWORD PTR [rip+0x3d78],rax        # 0x180005120
   1800013a8:	e8 27 02 00 00       	call   0x1800015d4
   1800013ad:	48 89 44 24 38       	mov    QWORD PTR [rsp+0x38],rax
   1800013b2:	48 8b d8             	mov    rbx,rax
   1800013b5:	48 85 c0             	test   rax,rax
   1800013b8:	0f 84 86 01 00 00    	je     0x180001544
   1800013be:	48 8b 0d 7b 3d 00 00 	mov    rcx,QWORD PTR [rip+0x3d7b]        # 0x180005140
   1800013c5:	4c 8b cb             	mov    r9,rbx
   1800013c8:	48 81 c1 3b 0d 34 01 	add    rcx,0x1340d3b
   1800013cf:	41 b8 40 00 00 00    	mov    r8d,0x40
   1800013d5:	48 89 48 08          	mov    QWORD PTR [rax+0x8],rcx
   1800013d9:	8b 11                	mov    edx,DWORD PTR [rcx]
   1800013db:	89 50 10             	mov    DWORD PTR [rax+0x10],edx
   1800013de:	0f b7 51 04          	movzx  edx,WORD PTR [rcx+0x4]
   1800013e2:	66 89 50 14          	mov    WORD PTR [rax+0x14],dx
   1800013e6:	ba 07 00 00 00       	mov    edx,0x7
   1800013eb:	0f b6 41 06          	movzx  eax,BYTE PTR [rcx+0x6]
   1800013ef:	88 43 16             	mov    BYTE PTR [rbx+0x16],al
   1800013f2:	ff 15 28 1c 00 00    	call   QWORD PTR [rip+0x1c28]        # 0x180003020
   1800013f8:	48 8b 43 08          	mov    rax,QWORD PTR [rbx+0x8]
   1800013fc:	c7 00 4d 31 c0 0f    	mov    DWORD PTR [rax],0xfc0314d
   180001402:	66 c7 40 04 1f 40    	mov    WORD PTR [rax+0x4],0x401f
   180001408:	c6 40 06 00          	mov    BYTE PTR [rax+0x6],0x0
   18000140c:	e9 35 01 00 00       	jmp    0x180001546
   180001411:	b9 28 00 00 00       	mov    ecx,0x28
   180001416:	e8 b9 01 00 00       	call   0x1800015d4
   18000141b:	48 89 44 24 38       	mov    QWORD PTR [rsp+0x38],rax
   180001420:	48 85 c0             	test   rax,rax
   180001423:	74 14                	je     0x180001439
   180001425:	4c 8d 05 64 fd ff ff 	lea    r8,[rip+0xfffffffffffffd64]        # 0x180001190
   18000142c:	ba b0 c4 b5 00       	mov    edx,0xb5c4b0
   180001431:	48 8b c8             	mov    rcx,rax
   180001434:	e8 c7 fc ff ff       	call   0x180001100
   180001439:	b9 18 00 00 00       	mov    ecx,0x18
   18000143e:	48 89 05 db 3c 00 00 	mov    QWORD PTR [rip+0x3cdb],rax        # 0x180005120
   180001445:	e8 8a 01 00 00       	call   0x1800015d4
   18000144a:	48 89 44 24 38       	mov    QWORD PTR [rsp+0x38],rax
   18000144f:	48 8b d8             	mov    rbx,rax
   180001452:	48 85 c0             	test   rax,rax
   180001455:	0f 84 e9 00 00 00    	je     0x180001544
   18000145b:	48 8b 0d de 3c 00 00 	mov    rcx,QWORD PTR [rip+0x3cde]        # 0x180005140
   180001462:	4c 8b cb             	mov    r9,rbx
   180001465:	48 81 c1 0b 0b 34 01 	add    rcx,0x1340b0b
   18000146c:	41 b8 40 00 00 00    	mov    r8d,0x40
   180001472:	48 89 48 08          	mov    QWORD PTR [rax+0x8],rcx
   180001476:	8b 11                	mov    edx,DWORD PTR [rcx]
   180001478:	89 50 10             	mov    DWORD PTR [rax+0x10],edx
   18000147b:	0f b7 51 04          	movzx  edx,WORD PTR [rcx+0x4]
   18000147f:	66 89 50 14          	mov    WORD PTR [rax+0x14],dx
   180001483:	ba 07 00 00 00       	mov    edx,0x7
   180001488:	0f b6 41 06          	movzx  eax,BYTE PTR [rcx+0x6]
   18000148c:	88 43 16             	mov    BYTE PTR [rbx+0x16],al
   18000148f:	ff 15 8b 1b 00 00    	call   QWORD PTR [rip+0x1b8b]        # 0x180003020
   180001495:	48 8b 43 08          	mov    rax,QWORD PTR [rbx+0x8]
   180001499:	c7 00 4d 31 c0 0f    	mov    DWORD PTR [rax],0xfc0314d
   18000149f:	66 c7 40 04 1f 40    	mov    WORD PTR [rax+0x4],0x401f
   1800014a5:	c6 40 06 00          	mov    BYTE PTR [rax+0x6],0x0
   1800014a9:	e9 98 00 00 00       	jmp    0x180001546
   1800014ae:	b9 28 00 00 00       	mov    ecx,0x28
   1800014b3:	e8 1c 01 00 00       	call   0x1800015d4
   1800014b8:	48 89 44 24 38       	mov    QWORD PTR [rsp+0x38],rax
   1800014bd:	48 85 c0             	test   rax,rax
   1800014c0:	74 14                	je     0x1800014d6
   1800014c2:	4c 8d 05 c7 fc ff ff 	lea    r8,[rip+0xfffffffffffffcc7]        # 0x180001190
   1800014c9:	ba d0 1f 57 00       	mov    edx,0x571fd0
   1800014ce:	48 8b c8             	mov    rcx,rax
   1800014d1:	e8 2a fc ff ff       	call   0x180001100
   1800014d6:	b9 18 00 00 00       	mov    ecx,0x18
   1800014db:	48 89 05 3e 3c 00 00 	mov    QWORD PTR [rip+0x3c3e],rax        # 0x180005120
   1800014e2:	e8 ed 00 00 00       	call   0x1800015d4
   1800014e7:	48 89 44 24 38       	mov    QWORD PTR [rsp+0x38],rax
   1800014ec:	48 8b d8             	mov    rbx,rax
   1800014ef:	48 85 c0             	test   rax,rax
   1800014f2:	74 50                	je     0x180001544
   1800014f4:	48 8b 0d 45 3c 00 00 	mov    rcx,QWORD PTR [rip+0x3c45]        # 0x180005140
   1800014fb:	4c 8b cb             	mov    r9,rbx
   1800014fe:	48 81 c1 63 c4 56 00 	add    rcx,0x56c463
   180001505:	41 b8 40 00 00 00    	mov    r8d,0x40
   18000150b:	48 89 48 08          	mov    QWORD PTR [rax+0x8],rcx
   18000150f:	8b 11                	mov    edx,DWORD PTR [rcx]
   180001511:	89 50 10             	mov    DWORD PTR [rax+0x10],edx
   180001514:	0f b7 51 04          	movzx  edx,WORD PTR [rcx+0x4]
   180001518:	66 89 50 14          	mov    WORD PTR [rax+0x14],dx
   18000151c:	ba 07 00 00 00       	mov    edx,0x7
   180001521:	0f b6 41 06          	movzx  eax,BYTE PTR [rcx+0x6]
   180001525:	88 43 16             	mov    BYTE PTR [rbx+0x16],al
   180001528:	ff 15 f2 1a 00 00    	call   QWORD PTR [rip+0x1af2]        # 0x180003020
   18000152e:	48 8b 43 08          	mov    rax,QWORD PTR [rbx+0x8]
   180001532:	c7 00 4d 31 c0 0f    	mov    DWORD PTR [rax],0xfc0314d
   180001538:	66 c7 40 04 1f 40    	mov    WORD PTR [rax+0x4],0x401f
   18000153e:	c6 40 06 00          	mov    BYTE PTR [rax+0x6],0x0
   180001542:	eb 02                	jmp    0x180001546
   180001544:	33 db                	xor    ebx,ebx
   180001546:	48 89 1d db 3b 00 00 	mov    QWORD PTR [rip+0x3bdb],rbx        # 0x180005128
   18000154d:	48 8b 1d dc 3b 00 00 	mov    rbx,QWORD PTR [rip+0x3bdc]        # 0x180005130
   180001554:	48 85 db             	test   rbx,rbx
   180001557:	74 3e                	je     0x180001597
   180001559:	4c 8b 43 10          	mov    r8,QWORD PTR [rbx+0x10]
   18000155d:	4d 85 c0             	test   r8,r8
   180001560:	74 28                	je     0x18000158a
   180001562:	f2 0f 10 43 18       	movsd  xmm0,QWORD PTR [rbx+0x18]
   180001567:	4c 8d 4b 08          	lea    r9,[rbx+0x8]
   18000156b:	f2 41 0f 11 00       	movsd  QWORD PTR [r8],xmm0
   180001570:	ba 0c 00 00 00       	mov    edx,0xc
   180001575:	8b 43 20             	mov    eax,DWORD PTR [rbx+0x20]
   180001578:	41 89 40 08          	mov    DWORD PTR [r8+0x8],eax
   18000157c:	44 8b 43 08          	mov    r8d,DWORD PTR [rbx+0x8]
   180001580:	48 8b 4b 10          	mov    rcx,QWORD PTR [rbx+0x10]
   180001584:	ff 15 96 1a 00 00    	call   QWORD PTR [rip+0x1a96]        # 0x180003020
   18000158a:	ba 28 00 00 00       	mov    edx,0x28
   18000158f:	48 8b cb             	mov    rcx,rbx
   180001592:	e8 79 00 00 00       	call   0x180001610
   180001597:	48 8b cf             	mov    rcx,rdi
   18000159a:	48 8b 5c 24 30       	mov    rbx,QWORD PTR [rsp+0x30]
   18000159f:	48 83 c4 20          	add    rsp,0x20
   1800015a3:	5f                   	pop    rdi
   1800015a4:	48 ff 25 55 1a 00 00 	rex.W jmp QWORD PTR [rip+0x1a55]        # 0x180003000
   1800015ab:	cc                   	int3
   1800015ac:	cc                   	int3
   1800015ad:	cc                   	int3
   1800015ae:	cc                   	int3
   1800015af:	cc                   	int3
   1800015b0:	48 83 ec 28          	sub    rsp,0x28
   1800015b4:	83 fa 01             	cmp    edx,0x1
   1800015b7:	75 06                	jne    0x1800015bf
   1800015b9:	ff 15 69 1a 00 00    	call   QWORD PTR [rip+0x1a69]        # 0x180003028
   1800015bf:	b8 01 00 00 00       	mov    eax,0x1
   1800015c4:	48 83 c4 28          	add    rsp,0x28
   1800015c8:	c3                   	ret
   1800015c9:	cc                   	int3
   1800015ca:	cc                   	int3
   1800015cb:	cc                   	int3
   1800015cc:	cc                   	int3
   1800015cd:	cc                   	int3
   1800015ce:	cc                   	int3
   1800015cf:	cc                   	int3
   1800015d0:	c2 00 00             	ret    0x0
   1800015d3:	cc                   	int3
   1800015d4:	40 53                	rex push rbx
   1800015d6:	48 83 ec 20          	sub    rsp,0x20
   1800015da:	48 8b d9             	mov    rbx,rcx
   1800015dd:	eb 0f                	jmp    0x1800015ee
   1800015df:	48 8b cb             	mov    rcx,rbx
   1800015e2:	e8 6d 10 00 00       	call   0x180002654
   1800015e7:	85 c0                	test   eax,eax
   1800015e9:	74 13                	je     0x1800015fe
   1800015eb:	48 8b cb             	mov    rcx,rbx
   1800015ee:	e8 67 10 00 00       	call   0x18000265a
   1800015f3:	48 85 c0             	test   rax,rax
   1800015f6:	74 e7                	je     0x1800015df
   1800015f8:	48 83 c4 20          	add    rsp,0x20
   1800015fc:	5b                   	pop    rbx
   1800015fd:	c3                   	ret
   1800015fe:	48 83 fb ff          	cmp    rbx,0xffffffffffffffff
   180001602:	74 06                	je     0x18000160a
   180001604:	e8 5b 05 00 00       	call   0x180001b64
   180001609:	cc                   	int3
   18000160a:	e8 75 05 00 00       	call   0x180001b84
   18000160f:	cc                   	int3
   180001610:	e9 a3 05 00 00       	jmp    0x180001bb8
   180001615:	cc                   	int3
   180001616:	cc                   	int3
   180001617:	cc                   	int3
   180001618:	48 83 ec 28          	sub    rsp,0x28
   18000161c:	4d 8b 41 38          	mov    r8,QWORD PTR [r9+0x38]
   180001620:	48 8b ca             	mov    rcx,rdx
   180001623:	49 8b d1             	mov    rdx,r9
   180001626:	e8 0d 00 00 00       	call   0x180001638
   18000162b:	b8 01 00 00 00       	mov    eax,0x1
   180001630:	48 83 c4 28          	add    rsp,0x28
   180001634:	c3                   	ret
   180001635:	cc                   	int3
   180001636:	cc                   	int3
   180001637:	cc                   	int3
   180001638:	40 53                	rex push rbx
   18000163a:	45 8b 18             	mov    r11d,DWORD PTR [r8]
   18000163d:	48 8b da             	mov    rbx,rdx
   180001640:	41 83 e3 f8          	and    r11d,0xfffffff8
   180001644:	4c 8b c9             	mov    r9,rcx
   180001647:	41 f6 00 04          	test   BYTE PTR [r8],0x4
   18000164b:	4c 8b d1             	mov    r10,rcx
   18000164e:	74 13                	je     0x180001663
   180001650:	41 8b 40 08          	mov    eax,DWORD PTR [r8+0x8]
   180001654:	4d 63 50 04          	movsxd r10,DWORD PTR [r8+0x4]
   180001658:	f7 d8                	neg    eax
   18000165a:	4c 03 d1             	add    r10,rcx
   18000165d:	48 63 c8             	movsxd rcx,eax
   180001660:	4c 23 d1             	and    r10,rcx
   180001663:	49 63 c3             	movsxd rax,r11d
   180001666:	4a 8b 14 10          	mov    rdx,QWORD PTR [rax+r10*1]
   18000166a:	48 8b 43 10          	mov    rax,QWORD PTR [rbx+0x10]
   18000166e:	8b 48 08             	mov    ecx,DWORD PTR [rax+0x8]
   180001671:	48 8b 43 08          	mov    rax,QWORD PTR [rbx+0x8]
   180001675:	f6 44 01 03 0f       	test   BYTE PTR [rcx+rax*1+0x3],0xf
   18000167a:	74 0b                	je     0x180001687
   18000167c:	0f b6 44 01 03       	movzx  eax,BYTE PTR [rcx+rax*1+0x3]
   180001681:	83 e0 f0             	and    eax,0xfffffff0
   180001684:	4c 03 c8             	add    r9,rax
   180001687:	4c 33 ca             	xor    r9,rdx
   18000168a:	49 8b c9             	mov    rcx,r9
   18000168d:	5b                   	pop    rbx
   18000168e:	e9 1d 00 00 00       	jmp    0x1800016b0
   180001693:	cc                   	int3
   180001694:	cc                   	int3
   180001695:	cc                   	int3
   180001696:	cc                   	int3
   180001697:	cc                   	int3
   180001698:	cc                   	int3
   180001699:	cc                   	int3
   18000169a:	cc                   	int3
   18000169b:	cc                   	int3
   18000169c:	cc                   	int3
   18000169d:	cc                   	int3
   18000169e:	cc                   	int3
   18000169f:	cc                   	int3
   1800016a0:	cc                   	int3
   1800016a1:	cc                   	int3
   1800016a2:	cc                   	int3
   1800016a3:	cc                   	int3
   1800016a4:	cc                   	int3
   1800016a5:	cc                   	int3
   1800016a6:	66 66 0f 1f 84 00 00 	data16 nop WORD PTR [rax+rax*1+0x0]
   1800016ad:	00 00 00 
   1800016b0:	48 3b 0d 49 39 00 00 	cmp    rcx,QWORD PTR [rip+0x3949]        # 0x180005000
   1800016b7:	75 10                	jne    0x1800016c9
   1800016b9:	48 c1 c1 10          	rol    rcx,0x10
   1800016bd:	66 f7 c1 ff ff       	test   cx,0xffff
   1800016c2:	75 01                	jne    0x1800016c5
   1800016c4:	c3                   	ret
   1800016c5:	48 c1 c9 10          	ror    rcx,0x10
   1800016c9:	e9 26 05 00 00       	jmp    0x180001bf4
   1800016ce:	cc                   	int3
   1800016cf:	cc                   	int3
   1800016d0:	48 83 ec 28          	sub    rsp,0x28
   1800016d4:	85 d2                	test   edx,edx
   1800016d6:	74 39                	je     0x180001711
   1800016d8:	83 ea 01             	sub    edx,0x1
   1800016db:	74 28                	je     0x180001705
   1800016dd:	83 ea 01             	sub    edx,0x1
   1800016e0:	74 16                	je     0x1800016f8
   1800016e2:	83 fa 01             	cmp    edx,0x1
   1800016e5:	74 0a                	je     0x1800016f1
   1800016e7:	b8 01 00 00 00       	mov    eax,0x1
   1800016ec:	48 83 c4 28          	add    rsp,0x28
   1800016f0:	c3                   	ret
   1800016f1:	e8 ea 07 00 00       	call   0x180001ee0
   1800016f6:	eb 05                	jmp    0x1800016fd
   1800016f8:	e8 bb 07 00 00       	call   0x180001eb8
   1800016fd:	0f b6 c0             	movzx  eax,al
   180001700:	48 83 c4 28          	add    rsp,0x28
   180001704:	c3                   	ret
   180001705:	49 8b d0             	mov    rdx,r8
   180001708:	48 83 c4 28          	add    rsp,0x28
   18000170c:	e9 0f 00 00 00       	jmp    0x180001720
   180001711:	4d 85 c0             	test   r8,r8
   180001714:	0f 95 c1             	setne  cl
   180001717:	48 83 c4 28          	add    rsp,0x28
   18000171b:	e9 18 01 00 00       	jmp    0x180001838
   180001720:	48 89 5c 24 08       	mov    QWORD PTR [rsp+0x8],rbx
   180001725:	48 89 74 24 10       	mov    QWORD PTR [rsp+0x10],rsi
   18000172a:	48 89 7c 24 20       	mov    QWORD PTR [rsp+0x20],rdi
   18000172f:	41 56                	push   r14
   180001731:	48 83 ec 20          	sub    rsp,0x20
   180001735:	48 8b f2             	mov    rsi,rdx
   180001738:	4c 8b f1             	mov    r14,rcx
   18000173b:	33 c9                	xor    ecx,ecx
   18000173d:	e8 5a 08 00 00       	call   0x180001f9c
   180001742:	84 c0                	test   al,al
   180001744:	0f 84 c8 00 00 00    	je     0x180001812
   18000174a:	e8 e1 06 00 00       	call   0x180001e30
   18000174f:	8a d8                	mov    bl,al
   180001751:	88 44 24 40          	mov    BYTE PTR [rsp+0x40],al
   180001755:	40 b7 01             	mov    dil,0x1
   180001758:	83 3d 81 3f 00 00 00 	cmp    DWORD PTR [rip+0x3f81],0x0        # 0x1800056e0
   18000175f:	0f 85 c5 00 00 00    	jne    0x18000182a
   180001765:	c7 05 71 3f 00 00 01 	mov    DWORD PTR [rip+0x3f71],0x1        # 0x1800056e0
   18000176c:	00 00 00 
   18000176f:	e8 2c 07 00 00       	call   0x180001ea0
   180001774:	84 c0                	test   al,al
   180001776:	74 4f                	je     0x1800017c7
   180001778:	e8 27 0b 00 00       	call   0x1800022a4
   18000177d:	e8 66 06 00 00       	call   0x180001de8
   180001782:	e8 8d 06 00 00       	call   0x180001e14
   180001787:	48 8d 15 42 1a 00 00 	lea    rdx,[rip+0x1a42]        # 0x1800031d0
   18000178e:	48 8d 0d 33 1a 00 00 	lea    rcx,[rip+0x1a33]        # 0x1800031c8
   180001795:	e8 cc 0e 00 00       	call   0x180002666
   18000179a:	85 c0                	test   eax,eax
   18000179c:	75 29                	jne    0x1800017c7
   18000179e:	e8 c9 06 00 00       	call   0x180001e6c
   1800017a3:	84 c0                	test   al,al
   1800017a5:	74 20                	je     0x1800017c7
   1800017a7:	48 8d 15 12 1a 00 00 	lea    rdx,[rip+0x1a12]        # 0x1800031c0
   1800017ae:	48 8d 0d eb 19 00 00 	lea    rcx,[rip+0x19eb]        # 0x1800031a0
   1800017b5:	e8 a6 0e 00 00       	call   0x180002660
   1800017ba:	c7 05 1c 3f 00 00 02 	mov    DWORD PTR [rip+0x3f1c],0x2        # 0x1800056e0
   1800017c1:	00 00 00 
   1800017c4:	40 32 ff             	xor    dil,dil
   1800017c7:	8a cb                	mov    cl,bl
   1800017c9:	e8 2e 09 00 00       	call   0x1800020fc
   1800017ce:	40 84 ff             	test   dil,dil
   1800017d1:	75 3f                	jne    0x180001812
   1800017d3:	e8 74 09 00 00       	call   0x18000214c
   1800017d8:	48 8b d8             	mov    rbx,rax
   1800017db:	48 83 38 00          	cmp    QWORD PTR [rax],0x0
   1800017df:	74 24                	je     0x180001805
   1800017e1:	48 8b c8             	mov    rcx,rax
   1800017e4:	e8 7b 08 00 00       	call   0x180002064
   1800017e9:	84 c0                	test   al,al
   1800017eb:	74 18                	je     0x180001805
   1800017ed:	4c 8b c6             	mov    r8,rsi
   1800017f0:	ba 02 00 00 00       	mov    edx,0x2
   1800017f5:	49 8b ce             	mov    rcx,r14
   1800017f8:	48 8b 03             	mov    rax,QWORD PTR [rbx]
   1800017fb:	4c 8b 0d 76 19 00 00 	mov    r9,QWORD PTR [rip+0x1976]        # 0x180003178
   180001802:	41 ff d1             	call   r9
   180001805:	ff 05 3d 39 00 00    	inc    DWORD PTR [rip+0x393d]        # 0x180005148
   18000180b:	b8 01 00 00 00       	mov    eax,0x1
   180001810:	eb 02                	jmp    0x180001814
   180001812:	33 c0                	xor    eax,eax
   180001814:	48 8b 5c 24 30       	mov    rbx,QWORD PTR [rsp+0x30]
   180001819:	48 8b 74 24 38       	mov    rsi,QWORD PTR [rsp+0x38]
   18000181e:	48 8b 7c 24 48       	mov    rdi,QWORD PTR [rsp+0x48]
   180001823:	48 83 c4 20          	add    rsp,0x20
   180001827:	41 5e                	pop    r14
   180001829:	c3                   	ret
   18000182a:	b9 07 00 00 00       	mov    ecx,0x7
   18000182f:	e8 28 09 00 00       	call   0x18000215c
   180001834:	90                   	nop
   180001835:	cc                   	int3
   180001836:	cc                   	int3
   180001837:	cc                   	int3
   180001838:	48 89 5c 24 08       	mov    QWORD PTR [rsp+0x8],rbx
   18000183d:	57                   	push   rdi
   18000183e:	48 83 ec 30          	sub    rsp,0x30
   180001842:	40 8a f9             	mov    dil,cl
   180001845:	8b 05 fd 38 00 00    	mov    eax,DWORD PTR [rip+0x38fd]        # 0x180005148
   18000184b:	85 c0                	test   eax,eax
   18000184d:	7f 0d                	jg     0x18000185c
   18000184f:	33 c0                	xor    eax,eax
   180001851:	48 8b 5c 24 40       	mov    rbx,QWORD PTR [rsp+0x40]
   180001856:	48 83 c4 30          	add    rsp,0x30
   18000185a:	5f                   	pop    rdi
   18000185b:	c3                   	ret
   18000185c:	ff c8                	dec    eax
   18000185e:	89 05 e4 38 00 00    	mov    DWORD PTR [rip+0x38e4],eax        # 0x180005148
   180001864:	e8 c7 05 00 00       	call   0x180001e30
   180001869:	8a d8                	mov    bl,al
   18000186b:	88 44 24 20          	mov    BYTE PTR [rsp+0x20],al
   18000186f:	83 3d 6a 3e 00 00 02 	cmp    DWORD PTR [rip+0x3e6a],0x2        # 0x1800056e0
   180001876:	75 33                	jne    0x1800018ab
   180001878:	e8 db 06 00 00       	call   0x180001f58
   18000187d:	e8 76 05 00 00       	call   0x180001df8
   180001882:	e8 59 0a 00 00       	call   0x1800022e0
   180001887:	83 25 52 3e 00 00 00 	and    DWORD PTR [rip+0x3e52],0x0        # 0x1800056e0
   18000188e:	8a cb                	mov    cl,bl
   180001890:	e8 67 08 00 00       	call   0x1800020fc
   180001895:	33 d2                	xor    edx,edx
   180001897:	40 8a cf             	mov    cl,dil
   18000189a:	e8 81 08 00 00       	call   0x180002120
   18000189f:	0f b6 d8             	movzx  ebx,al
   1800018a2:	e8 e1 06 00 00       	call   0x180001f88
   1800018a7:	8b c3                	mov    eax,ebx
   1800018a9:	eb a6                	jmp    0x180001851
   1800018ab:	b9 07 00 00 00       	mov    ecx,0x7
   1800018b0:	e8 a7 08 00 00       	call   0x18000215c
   1800018b5:	90                   	nop
   1800018b6:	90                   	nop
   1800018b7:	cc                   	int3
   1800018b8:	48 8b c4             	mov    rax,rsp
   1800018bb:	48 89 58 20          	mov    QWORD PTR [rax+0x20],rbx
   1800018bf:	4c 89 40 18          	mov    QWORD PTR [rax+0x18],r8
   1800018c3:	89 50 10             	mov    DWORD PTR [rax+0x10],edx
   1800018c6:	48 89 48 08          	mov    QWORD PTR [rax+0x8],rcx
   1800018ca:	56                   	push   rsi
   1800018cb:	57                   	push   rdi
   1800018cc:	41 56                	push   r14
   1800018ce:	48 83 ec 40          	sub    rsp,0x40
   1800018d2:	49 8b f0             	mov    rsi,r8
   1800018d5:	8b fa                	mov    edi,edx
   1800018d7:	4c 8b f1             	mov    r14,rcx
   1800018da:	85 d2                	test   edx,edx
   1800018dc:	75 0f                	jne    0x1800018ed
   1800018de:	39 15 64 38 00 00    	cmp    DWORD PTR [rip+0x3864],edx        # 0x180005148
   1800018e4:	7f 07                	jg     0x1800018ed
   1800018e6:	33 c0                	xor    eax,eax
   1800018e8:	e9 e5 00 00 00       	jmp    0x1800019d2
   1800018ed:	8d 42 ff             	lea    eax,[rdx-0x1]
   1800018f0:	83 f8 01             	cmp    eax,0x1
   1800018f3:	77 40                	ja     0x180001935
   1800018f5:	48 8b 05 14 19 00 00 	mov    rax,QWORD PTR [rip+0x1914]        # 0x180003210
   1800018fc:	48 85 c0             	test   rax,rax
   1800018ff:	75 05                	jne    0x180001906
   180001901:	8d 58 01             	lea    ebx,[rax+0x1]
   180001904:	eb 08                	jmp    0x18000190e
   180001906:	ff 15 6c 18 00 00    	call   QWORD PTR [rip+0x186c]        # 0x180003178
   18000190c:	8b d8                	mov    ebx,eax
   18000190e:	89 5c 24 30          	mov    DWORD PTR [rsp+0x30],ebx
   180001912:	85 db                	test   ebx,ebx
   180001914:	0f 84 ae 00 00 00    	je     0x1800019c8
   18000191a:	4c 8b c6             	mov    r8,rsi
   18000191d:	8b d7                	mov    edx,edi
   18000191f:	49 8b ce             	mov    rcx,r14
   180001922:	e8 a9 fd ff ff       	call   0x1800016d0
   180001927:	8b d8                	mov    ebx,eax
   180001929:	89 44 24 30          	mov    DWORD PTR [rsp+0x30],eax
   18000192d:	85 c0                	test   eax,eax
   18000192f:	0f 84 93 00 00 00    	je     0x1800019c8
   180001935:	4c 8b c6             	mov    r8,rsi
   180001938:	8b d7                	mov    edx,edi
   18000193a:	49 8b ce             	mov    rcx,r14
   18000193d:	e8 6e fc ff ff       	call   0x1800015b0
   180001942:	8b d8                	mov    ebx,eax
   180001944:	89 44 24 30          	mov    DWORD PTR [rsp+0x30],eax
   180001948:	83 ff 01             	cmp    edi,0x1
   18000194b:	75 36                	jne    0x180001983
   18000194d:	85 c0                	test   eax,eax
   18000194f:	75 32                	jne    0x180001983
   180001951:	4c 8b c6             	mov    r8,rsi
   180001954:	33 d2                	xor    edx,edx
   180001956:	49 8b ce             	mov    rcx,r14
   180001959:	e8 52 fc ff ff       	call   0x1800015b0
   18000195e:	48 85 f6             	test   rsi,rsi
   180001961:	0f 95 c1             	setne  cl
   180001964:	e8 cf fe ff ff       	call   0x180001838
   180001969:	48 8b 05 a0 18 00 00 	mov    rax,QWORD PTR [rip+0x18a0]        # 0x180003210
   180001970:	48 85 c0             	test   rax,rax
   180001973:	74 0e                	je     0x180001983
   180001975:	4c 8b c6             	mov    r8,rsi
   180001978:	33 d2                	xor    edx,edx
   18000197a:	49 8b ce             	mov    rcx,r14
   18000197d:	ff 15 f5 17 00 00    	call   QWORD PTR [rip+0x17f5]        # 0x180003178
   180001983:	85 ff                	test   edi,edi
   180001985:	74 05                	je     0x18000198c
   180001987:	83 ff 03             	cmp    edi,0x3
   18000198a:	75 3c                	jne    0x1800019c8
   18000198c:	4c 8b c6             	mov    r8,rsi
   18000198f:	8b d7                	mov    edx,edi
   180001991:	49 8b ce             	mov    rcx,r14
   180001994:	e8 37 fd ff ff       	call   0x1800016d0
   180001999:	8b d8                	mov    ebx,eax
   18000199b:	89 44 24 30          	mov    DWORD PTR [rsp+0x30],eax
   18000199f:	85 c0                	test   eax,eax
   1800019a1:	74 25                	je     0x1800019c8
   1800019a3:	48 8b 05 66 18 00 00 	mov    rax,QWORD PTR [rip+0x1866]        # 0x180003210
   1800019aa:	48 85 c0             	test   rax,rax
   1800019ad:	75 05                	jne    0x1800019b4
   1800019af:	8d 58 01             	lea    ebx,[rax+0x1]
   1800019b2:	eb 10                	jmp    0x1800019c4
   1800019b4:	4c 8b c6             	mov    r8,rsi
   1800019b7:	8b d7                	mov    edx,edi
   1800019b9:	49 8b ce             	mov    rcx,r14
   1800019bc:	ff 15 b6 17 00 00    	call   QWORD PTR [rip+0x17b6]        # 0x180003178
   1800019c2:	8b d8                	mov    ebx,eax
   1800019c4:	89 5c 24 30          	mov    DWORD PTR [rsp+0x30],ebx
   1800019c8:	eb 06                	jmp    0x1800019d0
   1800019ca:	33 db                	xor    ebx,ebx
   1800019cc:	89 5c 24 30          	mov    DWORD PTR [rsp+0x30],ebx
   1800019d0:	8b c3                	mov    eax,ebx
   1800019d2:	48 8b 5c 24 78       	mov    rbx,QWORD PTR [rsp+0x78]
   1800019d7:	48 83 c4 40          	add    rsp,0x40
   1800019db:	41 5e                	pop    r14
   1800019dd:	5f                   	pop    rdi
   1800019de:	5e                   	pop    rsi
   1800019df:	c3                   	ret
   1800019e0:	48 89 5c 24 08       	mov    QWORD PTR [rsp+0x8],rbx
   1800019e5:	48 89 74 24 10       	mov    QWORD PTR [rsp+0x10],rsi
   1800019ea:	57                   	push   rdi
   1800019eb:	48 83 ec 20          	sub    rsp,0x20
   1800019ef:	49 8b f8             	mov    rdi,r8
   1800019f2:	8b da                	mov    ebx,edx
   1800019f4:	48 8b f1             	mov    rsi,rcx
   1800019f7:	83 fa 01             	cmp    edx,0x1
   1800019fa:	75 05                	jne    0x180001a01
   1800019fc:	e8 3b 03 00 00       	call   0x180001d3c
   180001a01:	4c 8b c7             	mov    r8,rdi
   180001a04:	8b d3                	mov    edx,ebx
   180001a06:	48 8b ce             	mov    rcx,rsi
   180001a09:	48 8b 5c 24 30       	mov    rbx,QWORD PTR [rsp+0x30]
   180001a0e:	48 8b 74 24 38       	mov    rsi,QWORD PTR [rsp+0x38]
   180001a13:	48 83 c4 20          	add    rsp,0x20
   180001a17:	5f                   	pop    rdi
   180001a18:	e9 9b fe ff ff       	jmp    0x1800018b8
   180001a1d:	cc                   	int3
   180001a1e:	cc                   	int3
   180001a1f:	cc                   	int3
   180001a20:	40 53                	rex push rbx
   180001a22:	48 83 ec 20          	sub    rsp,0x20
   180001a26:	48 8b d9             	mov    rbx,rcx
   180001a29:	48 8b c2             	mov    rax,rdx
   180001a2c:	48 8d 0d ed 17 00 00 	lea    rcx,[rip+0x17ed]        # 0x180003220
   180001a33:	0f 57 c0             	xorps  xmm0,xmm0
   180001a36:	48 89 0b             	mov    QWORD PTR [rbx],rcx
   180001a39:	48 8d 53 08          	lea    rdx,[rbx+0x8]
   180001a3d:	48 8d 48 08          	lea    rcx,[rax+0x8]
   180001a41:	0f 11 02             	movups XMMWORD PTR [rdx],xmm0
   180001a44:	e8 ed 0b 00 00       	call   0x180002636
   180001a49:	48 8d 05 00 18 00 00 	lea    rax,[rip+0x1800]        # 0x180003250
   180001a50:	48 89 03             	mov    QWORD PTR [rbx],rax
   180001a53:	48 8b c3             	mov    rax,rbx
   180001a56:	48 83 c4 20          	add    rsp,0x20
   180001a5a:	5b                   	pop    rbx
   180001a5b:	c3                   	ret
   180001a5c:	48 83 61 10 00       	and    QWORD PTR [rcx+0x10],0x0
   180001a61:	48 8d 05 f8 17 00 00 	lea    rax,[rip+0x17f8]        # 0x180003260
   180001a68:	48 89 41 08          	mov    QWORD PTR [rcx+0x8],rax
   180001a6c:	48 8d 05 dd 17 00 00 	lea    rax,[rip+0x17dd]        # 0x180003250
   180001a73:	48 89 01             	mov    QWORD PTR [rcx],rax
   180001a76:	48 8b c1             	mov    rax,rcx
   180001a79:	c3                   	ret
   180001a7a:	cc                   	int3
   180001a7b:	cc                   	int3
   180001a7c:	40 53                	rex push rbx
   180001a7e:	48 83 ec 20          	sub    rsp,0x20
   180001a82:	48 8b d9             	mov    rbx,rcx
   180001a85:	48 8b c2             	mov    rax,rdx
   180001a88:	48 8d 0d 91 17 00 00 	lea    rcx,[rip+0x1791]        # 0x180003220
   180001a8f:	0f 57 c0             	xorps  xmm0,xmm0
   180001a92:	48 89 0b             	mov    QWORD PTR [rbx],rcx
   180001a95:	48 8d 53 08          	lea    rdx,[rbx+0x8]
   180001a99:	48 8d 48 08          	lea    rcx,[rax+0x8]
   180001a9d:	0f 11 02             	movups XMMWORD PTR [rdx],xmm0
   180001aa0:	e8 91 0b 00 00       	call   0x180002636
   180001aa5:	48 8d 05 cc 17 00 00 	lea    rax,[rip+0x17cc]        # 0x180003278
   180001aac:	48 89 03             	mov    QWORD PTR [rbx],rax
   180001aaf:	48 8b c3             	mov    rax,rbx
   180001ab2:	48 83 c4 20          	add    rsp,0x20
   180001ab6:	5b                   	pop    rbx
   180001ab7:	c3                   	ret
   180001ab8:	48 83 61 10 00       	and    QWORD PTR [rcx+0x10],0x0
   180001abd:	48 8d 05 c4 17 00 00 	lea    rax,[rip+0x17c4]        # 0x180003288
   180001ac4:	48 89 41 08          	mov    QWORD PTR [rcx+0x8],rax
   180001ac8:	48 8d 05 a9 17 00 00 	lea    rax,[rip+0x17a9]        # 0x180003278
   180001acf:	48 89 01             	mov    QWORD PTR [rcx],rax
   180001ad2:	48 8b c1             	mov    rax,rcx
   180001ad5:	c3                   	ret
   180001ad6:	cc                   	int3
   180001ad7:	cc                   	int3
   180001ad8:	40 53                	rex push rbx
   180001ada:	48 83 ec 20          	sub    rsp,0x20
   180001ade:	48 8b d9             	mov    rbx,rcx
   180001ae1:	48 8b c2             	mov    rax,rdx
   180001ae4:	48 8d 0d 35 17 00 00 	lea    rcx,[rip+0x1735]        # 0x180003220
   180001aeb:	0f 57 c0             	xorps  xmm0,xmm0
   180001aee:	48 89 0b             	mov    QWORD PTR [rbx],rcx
   180001af1:	48 8d 53 08          	lea    rdx,[rbx+0x8]
   180001af5:	48 8d 48 08          	lea    rcx,[rax+0x8]
   180001af9:	0f 11 02             	movups XMMWORD PTR [rdx],xmm0
   180001afc:	e8 35 0b 00 00       	call   0x180002636
   180001b01:	48 8b c3             	mov    rax,rbx
   180001b04:	48 83 c4 20          	add    rsp,0x20
   180001b08:	5b                   	pop    rbx
   180001b09:	c3                   	ret
   180001b0a:	cc                   	int3
   180001b0b:	cc                   	int3
   180001b0c:	48 8d 05 0d 17 00 00 	lea    rax,[rip+0x170d]        # 0x180003220
   180001b13:	48 89 01             	mov    QWORD PTR [rcx],rax
   180001b16:	48 83 c1 08          	add    rcx,0x8
   180001b1a:	e9 1d 0b 00 00       	jmp    0x18000263c
   180001b1f:	cc                   	int3
   180001b20:	48 89 5c 24 08       	mov    QWORD PTR [rsp+0x8],rbx
   180001b25:	57                   	push   rdi
   180001b26:	48 83 ec 20          	sub    rsp,0x20
   180001b2a:	48 8d 05 ef 16 00 00 	lea    rax,[rip+0x16ef]        # 0x180003220
   180001b31:	48 8b f9             	mov    rdi,rcx
   180001b34:	48 89 01             	mov    QWORD PTR [rcx],rax
   180001b37:	8b da                	mov    ebx,edx
   180001b39:	48 83 c1 08          	add    rcx,0x8
   180001b3d:	e8 fa 0a 00 00       	call   0x18000263c
   180001b42:	f6 c3 01             	test   bl,0x1
   180001b45:	74 0d                	je     0x180001b54
   180001b47:	ba 18 00 00 00       	mov    edx,0x18
   180001b4c:	48 8b cf             	mov    rcx,rdi
   180001b4f:	e8 bc fa ff ff       	call   0x180001610
   180001b54:	48 8b 5c 24 30       	mov    rbx,QWORD PTR [rsp+0x30]
   180001b59:	48 8b c7             	mov    rax,rdi
   180001b5c:	48 83 c4 20          	add    rsp,0x20
   180001b60:	5f                   	pop    rdi
   180001b61:	c3                   	ret
   180001b62:	cc                   	int3
   180001b63:	cc                   	int3
   180001b64:	48 83 ec 48          	sub    rsp,0x48
   180001b68:	48 8d 4c 24 20       	lea    rcx,[rsp+0x20]
   180001b6d:	e8 ea fe ff ff       	call   0x180001a5c
   180001b72:	48 8d 15 3f 20 00 00 	lea    rdx,[rip+0x203f]        # 0x180003bb8
   180001b79:	48 8d 4c 24 20       	lea    rcx,[rsp+0x20]
   180001b7e:	e8 bf 0a 00 00       	call   0x180002642
   180001b83:	cc                   	int3
   180001b84:	48 83 ec 48          	sub    rsp,0x48
   180001b88:	48 8d 4c 24 20       	lea    rcx,[rsp+0x20]
   180001b8d:	e8 26 ff ff ff       	call   0x180001ab8
   180001b92:	48 8d 15 a7 20 00 00 	lea    rdx,[rip+0x20a7]        # 0x180003c40
   180001b99:	48 8d 4c 24 20       	lea    rcx,[rsp+0x20]
   180001b9e:	e8 9f 0a 00 00       	call   0x180002642
   180001ba3:	cc                   	int3
   180001ba4:	48 83 79 08 00       	cmp    QWORD PTR [rcx+0x8],0x0
   180001ba9:	48 8d 05 80 16 00 00 	lea    rax,[rip+0x1680]        # 0x180003230
   180001bb0:	48 0f 45 41 08       	cmovne rax,QWORD PTR [rcx+0x8]
   180001bb5:	c3                   	ret
   180001bb6:	cc                   	int3
   180001bb7:	cc                   	int3
   180001bb8:	e9 af 0a 00 00       	jmp    0x18000266c
   180001bbd:	cc                   	int3
   180001bbe:	cc                   	int3
   180001bbf:	cc                   	int3
   180001bc0:	40 53                	rex push rbx
   180001bc2:	48 83 ec 20          	sub    rsp,0x20
   180001bc6:	48 8b d9             	mov    rbx,rcx
   180001bc9:	33 c9                	xor    ecx,ecx
   180001bcb:	ff 15 8f 14 00 00    	call   QWORD PTR [rip+0x148f]        # 0x180003060
   180001bd1:	48 8b cb             	mov    rcx,rbx
   180001bd4:	ff 15 7e 14 00 00    	call   QWORD PTR [rip+0x147e]        # 0x180003058
   180001bda:	ff 15 88 14 00 00    	call   QWORD PTR [rip+0x1488]        # 0x180003068
   180001be0:	48 8b c8             	mov    rcx,rax
   180001be3:	ba 09 04 00 c0       	mov    edx,0xc0000409
   180001be8:	48 83 c4 20          	add    rsp,0x20
   180001bec:	5b                   	pop    rbx
   180001bed:	48 ff 25 7c 14 00 00 	rex.W jmp QWORD PTR [rip+0x147c]        # 0x180003070
   180001bf4:	48 89 4c 24 08       	mov    QWORD PTR [rsp+0x8],rcx
   180001bf9:	48 83 ec 38          	sub    rsp,0x38
   180001bfd:	b9 17 00 00 00       	mov    ecx,0x17
   180001c02:	ff 15 70 14 00 00    	call   QWORD PTR [rip+0x1470]        # 0x180003078
   180001c08:	85 c0                	test   eax,eax
   180001c0a:	74 07                	je     0x180001c13
   180001c0c:	b9 02 00 00 00       	mov    ecx,0x2
   180001c11:	cd 29                	int    0x29
   180001c13:	48 8d 0d d6 35 00 00 	lea    rcx,[rip+0x35d6]        # 0x1800051f0
   180001c1a:	e8 a9 00 00 00       	call   0x180001cc8
   180001c1f:	48 8b 44 24 38       	mov    rax,QWORD PTR [rsp+0x38]
   180001c24:	48 89 05 bd 36 00 00 	mov    QWORD PTR [rip+0x36bd],rax        # 0x1800052e8
   180001c2b:	48 8d 44 24 38       	lea    rax,[rsp+0x38]
   180001c30:	48 83 c0 08          	add    rax,0x8
   180001c34:	48 89 05 4d 36 00 00 	mov    QWORD PTR [rip+0x364d],rax        # 0x180005288
   180001c3b:	48 8b 05 a6 36 00 00 	mov    rax,QWORD PTR [rip+0x36a6]        # 0x1800052e8
   180001c42:	48 89 05 17 35 00 00 	mov    QWORD PTR [rip+0x3517],rax        # 0x180005160
   180001c49:	48 8b 44 24 40       	mov    rax,QWORD PTR [rsp+0x40]
   180001c4e:	48 89 05 1b 36 00 00 	mov    QWORD PTR [rip+0x361b],rax        # 0x180005270
   180001c55:	c7 05 f1 34 00 00 09 	mov    DWORD PTR [rip+0x34f1],0xc0000409        # 0x180005150
   180001c5c:	04 00 c0 
   180001c5f:	c7 05 eb 34 00 00 01 	mov    DWORD PTR [rip+0x34eb],0x1        # 0x180005154
   180001c66:	00 00 00 
   180001c69:	c7 05 f5 34 00 00 01 	mov    DWORD PTR [rip+0x34f5],0x1        # 0x180005168
   180001c70:	00 00 00 
   180001c73:	b8 08 00 00 00       	mov    eax,0x8
   180001c78:	48 6b c0 00          	imul   rax,rax,0x0
   180001c7c:	48 8d 0d ed 34 00 00 	lea    rcx,[rip+0x34ed]        # 0x180005170
   180001c83:	48 c7 04 01 02 00 00 	mov    QWORD PTR [rcx+rax*1],0x2
   180001c8a:	00 
   180001c8b:	b8 08 00 00 00       	mov    eax,0x8
   180001c90:	48 6b c0 00          	imul   rax,rax,0x0
   180001c94:	48 8b 0d 65 33 00 00 	mov    rcx,QWORD PTR [rip+0x3365]        # 0x180005000
   180001c9b:	48 89 4c 04 20       	mov    QWORD PTR [rsp+rax*1+0x20],rcx
   180001ca0:	b8 08 00 00 00       	mov    eax,0x8
   180001ca5:	48 6b c0 01          	imul   rax,rax,0x1
   180001ca9:	48 8b 0d 90 33 00 00 	mov    rcx,QWORD PTR [rip+0x3390]        # 0x180005040
   180001cb0:	48 89 4c 04 20       	mov    QWORD PTR [rsp+rax*1+0x20],rcx
   180001cb5:	48 8d 0d e4 15 00 00 	lea    rcx,[rip+0x15e4]        # 0x1800032a0
   180001cbc:	e8 ff fe ff ff       	call   0x180001bc0
   180001cc1:	90                   	nop
   180001cc2:	48 83 c4 38          	add    rsp,0x38
   180001cc6:	c3                   	ret
   180001cc7:	cc                   	int3
   180001cc8:	40 53                	rex push rbx
   180001cca:	56                   	push   rsi
   180001ccb:	57                   	push   rdi
   180001ccc:	48 83 ec 40          	sub    rsp,0x40
   180001cd0:	48 8b d9             	mov    rbx,rcx
   180001cd3:	ff 15 b7 13 00 00    	call   QWORD PTR [rip+0x13b7]        # 0x180003090
   180001cd9:	48 8b b3 f8 00 00 00 	mov    rsi,QWORD PTR [rbx+0xf8]
   180001ce0:	33 ff                	xor    edi,edi
   180001ce2:	45 33 c0             	xor    r8d,r8d
   180001ce5:	48 8d 54 24 60       	lea    rdx,[rsp+0x60]
   180001cea:	48 8b ce             	mov    rcx,rsi
   180001ced:	ff 15 55 13 00 00    	call   QWORD PTR [rip+0x1355]        # 0x180003048
   180001cf3:	48 85 c0             	test   rax,rax
   180001cf6:	74 39                	je     0x180001d31
   180001cf8:	48 83 64 24 38 00    	and    QWORD PTR [rsp+0x38],0x0
   180001cfe:	48 8d 4c 24 68       	lea    rcx,[rsp+0x68]
   180001d03:	48 8b 54 24 60       	mov    rdx,QWORD PTR [rsp+0x60]
   180001d08:	4c 8b c8             	mov    r9,rax
   180001d0b:	48 89 4c 24 30       	mov    QWORD PTR [rsp+0x30],rcx
   180001d10:	4c 8b c6             	mov    r8,rsi
   180001d13:	48 8d 4c 24 70       	lea    rcx,[rsp+0x70]
   180001d18:	48 89 4c 24 28       	mov    QWORD PTR [rsp+0x28],rcx
   180001d1d:	33 c9                	xor    ecx,ecx
   180001d1f:	48 89 5c 24 20       	mov    QWORD PTR [rsp+0x20],rbx
   180001d24:	ff 15 26 13 00 00    	call   QWORD PTR [rip+0x1326]        # 0x180003050
   180001d2a:	ff c7                	inc    edi
   180001d2c:	83 ff 02             	cmp    edi,0x2
   180001d2f:	7c b1                	jl     0x180001ce2
   180001d31:	48 83 c4 40          	add    rsp,0x40
   180001d35:	5f                   	pop    rdi
   180001d36:	5e                   	pop    rsi
   180001d37:	5b                   	pop    rbx
   180001d38:	c3                   	ret
   180001d39:	cc                   	int3
   180001d3a:	cc                   	int3
   180001d3b:	cc                   	int3
   180001d3c:	48 89 5c 24 18       	mov    QWORD PTR [rsp+0x18],rbx
   180001d41:	55                   	push   rbp
   180001d42:	48 8b ec             	mov    rbp,rsp
   180001d45:	48 83 ec 30          	sub    rsp,0x30
   180001d49:	48 8b 05 b0 32 00 00 	mov    rax,QWORD PTR [rip+0x32b0]        # 0x180005000
   180001d50:	48 bb 32 a2 df 2d 99 	movabs rbx,0x2b992ddfa232
   180001d57:	2b 00 00 
   180001d5a:	48 3b c3             	cmp    rax,rbx
   180001d5d:	75 74                	jne    0x180001dd3
   180001d5f:	48 83 65 10 00       	and    QWORD PTR [rbp+0x10],0x0
   180001d64:	48 8d 4d 10          	lea    rcx,[rbp+0x10]
   180001d68:	ff 15 3a 13 00 00    	call   QWORD PTR [rip+0x133a]        # 0x1800030a8
   180001d6e:	48 8b 45 10          	mov    rax,QWORD PTR [rbp+0x10]
   180001d72:	48 89 45 f0          	mov    QWORD PTR [rbp-0x10],rax
   180001d76:	ff 15 34 13 00 00    	call   QWORD PTR [rip+0x1334]        # 0x1800030b0
   180001d7c:	8b c0                	mov    eax,eax
   180001d7e:	48 31 45 f0          	xor    QWORD PTR [rbp-0x10],rax
   180001d82:	ff 15 00 13 00 00    	call   QWORD PTR [rip+0x1300]        # 0x180003088
   180001d88:	8b c0                	mov    eax,eax
   180001d8a:	48 8d 4d 18          	lea    rcx,[rbp+0x18]
   180001d8e:	48 31 45 f0          	xor    QWORD PTR [rbp-0x10],rax
   180001d92:	ff 15 e8 12 00 00    	call   QWORD PTR [rip+0x12e8]        # 0x180003080
   180001d98:	8b 45 18             	mov    eax,DWORD PTR [rbp+0x18]
   180001d9b:	48 8d 4d f0          	lea    rcx,[rbp-0x10]
   180001d9f:	48 c1 e0 20          	shl    rax,0x20
   180001da3:	48 33 45 18          	xor    rax,QWORD PTR [rbp+0x18]
   180001da7:	48 33 45 f0          	xor    rax,QWORD PTR [rbp-0x10]
   180001dab:	48 33 c1             	xor    rax,rcx
   180001dae:	48 b9 ff ff ff ff ff 	movabs rcx,0xffffffffffff
   180001db5:	ff 00 00 
   180001db8:	48 23 c1             	and    rax,rcx
   180001dbb:	48 b9 33 a2 df 2d 99 	movabs rcx,0x2b992ddfa233
   180001dc2:	2b 00 00 
   180001dc5:	48 3b c3             	cmp    rax,rbx
   180001dc8:	48 0f 44 c1          	cmove  rax,rcx
   180001dcc:	48 89 05 2d 32 00 00 	mov    QWORD PTR [rip+0x322d],rax        # 0x180005000
   180001dd3:	48 8b 5c 24 50       	mov    rbx,QWORD PTR [rsp+0x50]
   180001dd8:	48 f7 d0             	not    rax
   180001ddb:	48 89 05 5e 32 00 00 	mov    QWORD PTR [rip+0x325e],rax        # 0x180005040
   180001de2:	48 83 c4 30          	add    rsp,0x30
   180001de6:	5d                   	pop    rbp
   180001de7:	c3                   	ret
   180001de8:	48 8d 0d d1 38 00 00 	lea    rcx,[rip+0x38d1]        # 0x1800056c0
   180001def:	48 ff 25 aa 12 00 00 	rex.W jmp QWORD PTR [rip+0x12aa]        # 0x1800030a0
   180001df6:	cc                   	int3
   180001df7:	cc                   	int3
   180001df8:	48 8d 0d c1 38 00 00 	lea    rcx,[rip+0x38c1]        # 0x1800056c0
   180001dff:	e9 44 08 00 00       	jmp    0x180002648
   180001e04:	48 8d 05 c5 38 00 00 	lea    rax,[rip+0x38c5]        # 0x1800056d0
   180001e0b:	c3                   	ret
   180001e0c:	48 8d 05 c5 38 00 00 	lea    rax,[rip+0x38c5]        # 0x1800056d8
   180001e13:	c3                   	ret
   180001e14:	48 83 ec 28          	sub    rsp,0x28
   180001e18:	e8 e7 ff ff ff       	call   0x180001e04
   180001e1d:	48 83 08 24          	or     QWORD PTR [rax],0x24
   180001e21:	e8 e6 ff ff ff       	call   0x180001e0c
   180001e26:	48 83 08 02          	or     QWORD PTR [rax],0x2
   180001e2a:	48 83 c4 28          	add    rsp,0x28
   180001e2e:	c3                   	ret
   180001e2f:	cc                   	int3
   180001e30:	48 83 ec 28          	sub    rsp,0x28
   180001e34:	e8 e3 07 00 00       	call   0x18000261c
   180001e39:	85 c0                	test   eax,eax
   180001e3b:	74 21                	je     0x180001e5e
   180001e3d:	65 48 8b 04 25 30 00 	mov    rax,QWORD PTR gs:0x30
   180001e44:	00 00 
   180001e46:	48 8b 48 08          	mov    rcx,QWORD PTR [rax+0x8]
   180001e4a:	eb 05                	jmp    0x180001e51
   180001e4c:	48 3b c8             	cmp    rcx,rax
   180001e4f:	74 14                	je     0x180001e65
   180001e51:	33 c0                	xor    eax,eax
   180001e53:	f0 48 0f b1 0d 8c 38 	lock cmpxchg QWORD PTR [rip+0x388c],rcx        # 0x1800056e8
   180001e5a:	00 00 
   180001e5c:	75 ee                	jne    0x180001e4c
   180001e5e:	32 c0                	xor    al,al
   180001e60:	48 83 c4 28          	add    rsp,0x28
   180001e64:	c3                   	ret
   180001e65:	b0 01                	mov    al,0x1
   180001e67:	eb f7                	jmp    0x180001e60
   180001e69:	cc                   	int3
   180001e6a:	cc                   	int3
   180001e6b:	cc                   	int3
   180001e6c:	48 83 ec 28          	sub    rsp,0x28
   180001e70:	e8 a7 07 00 00       	call   0x18000261c
   180001e75:	85 c0                	test   eax,eax
   180001e77:	74 07                	je     0x180001e80
   180001e79:	e8 ca 04 00 00       	call   0x180002348
   180001e7e:	eb 19                	jmp    0x180001e99
   180001e80:	e8 8f 07 00 00       	call   0x180002614
   180001e85:	8b c8                	mov    ecx,eax
   180001e87:	e8 ec 07 00 00       	call   0x180002678
   180001e8c:	85 c0                	test   eax,eax
   180001e8e:	74 04                	je     0x180001e94
   180001e90:	32 c0                	xor    al,al
   180001e92:	eb 07                	jmp    0x180001e9b
   180001e94:	e8 e5 07 00 00       	call   0x18000267e
   180001e99:	b0 01                	mov    al,0x1
   180001e9b:	48 83 c4 28          	add    rsp,0x28
   180001e9f:	c3                   	ret
   180001ea0:	48 83 ec 28          	sub    rsp,0x28
   180001ea4:	33 c9                	xor    ecx,ecx
   180001ea6:	e8 2d 01 00 00       	call   0x180001fd8
   180001eab:	84 c0                	test   al,al
   180001ead:	0f 95 c0             	setne  al
   180001eb0:	48 83 c4 28          	add    rsp,0x28
   180001eb4:	c3                   	ret
   180001eb5:	cc                   	int3
   180001eb6:	cc                   	int3
   180001eb7:	cc                   	int3
   180001eb8:	48 83 ec 28          	sub    rsp,0x28
   180001ebc:	e8 d7 07 00 00       	call   0x180002698
   180001ec1:	84 c0                	test   al,al
   180001ec3:	75 04                	jne    0x180001ec9
   180001ec5:	32 c0                	xor    al,al
   180001ec7:	eb 12                	jmp    0x180001edb
   180001ec9:	e8 ca 07 00 00       	call   0x180002698
   180001ece:	84 c0                	test   al,al
   180001ed0:	75 07                	jne    0x180001ed9
   180001ed2:	e8 c1 07 00 00       	call   0x180002698
   180001ed7:	eb ec                	jmp    0x180001ec5
   180001ed9:	b0 01                	mov    al,0x1
   180001edb:	48 83 c4 28          	add    rsp,0x28
   180001edf:	c3                   	ret
   180001ee0:	48 83 ec 28          	sub    rsp,0x28
   180001ee4:	e8 af 07 00 00       	call   0x180002698
   180001ee9:	e8 aa 07 00 00       	call   0x180002698
   180001eee:	b0 01                	mov    al,0x1
   180001ef0:	48 83 c4 28          	add    rsp,0x28
   180001ef4:	c3                   	ret
   180001ef5:	cc                   	int3
   180001ef6:	cc                   	int3
   180001ef7:	cc                   	int3
   180001ef8:	48 89 5c 24 08       	mov    QWORD PTR [rsp+0x8],rbx
   180001efd:	48 89 6c 24 10       	mov    QWORD PTR [rsp+0x10],rbp
   180001f02:	48 89 74 24 18       	mov    QWORD PTR [rsp+0x18],rsi
   180001f07:	57                   	push   rdi
   180001f08:	48 83 ec 20          	sub    rsp,0x20
   180001f0c:	49 8b f9             	mov    rdi,r9
   180001f0f:	49 8b f0             	mov    rsi,r8
   180001f12:	8b da                	mov    ebx,edx
   180001f14:	48 8b e9             	mov    rbp,rcx
   180001f17:	e8 00 07 00 00       	call   0x18000261c
   180001f1c:	85 c0                	test   eax,eax
   180001f1e:	75 16                	jne    0x180001f36
   180001f20:	83 fb 01             	cmp    ebx,0x1
   180001f23:	75 11                	jne    0x180001f36
   180001f25:	4c 8b c6             	mov    r8,rsi
   180001f28:	33 d2                	xor    edx,edx
   180001f2a:	48 8b cd             	mov    rcx,rbp
   180001f2d:	48 8b c7             	mov    rax,rdi
   180001f30:	ff 15 42 12 00 00    	call   QWORD PTR [rip+0x1242]        # 0x180003178
   180001f36:	48 8b 54 24 58       	mov    rdx,QWORD PTR [rsp+0x58]
   180001f3b:	8b 4c 24 50          	mov    ecx,DWORD PTR [rsp+0x50]
   180001f3f:	48 8b 5c 24 30       	mov    rbx,QWORD PTR [rsp+0x30]
   180001f44:	48 8b 6c 24 38       	mov    rbp,QWORD PTR [rsp+0x38]
   180001f49:	48 8b 74 24 40       	mov    rsi,QWORD PTR [rsp+0x40]
   180001f4e:	48 83 c4 20          	add    rsp,0x20
   180001f52:	5f                   	pop    rdi
   180001f53:	e9 1a 07 00 00       	jmp    0x180002672
   180001f58:	48 83 ec 28          	sub    rsp,0x28
   180001f5c:	e8 bb 06 00 00       	call   0x18000261c
   180001f61:	85 c0                	test   eax,eax
   180001f63:	74 10                	je     0x180001f75
   180001f65:	48 8d 0d 8c 37 00 00 	lea    rcx,[rip+0x378c]        # 0x1800056f8
   180001f6c:	48 83 c4 28          	add    rsp,0x28
   180001f70:	e9 15 07 00 00       	jmp    0x18000268a
   180001f75:	e8 22 07 00 00       	call   0x18000269c
   180001f7a:	85 c0                	test   eax,eax
   180001f7c:	75 05                	jne    0x180001f83
   180001f7e:	e8 0d 07 00 00       	call   0x180002690
   180001f83:	48 83 c4 28          	add    rsp,0x28
   180001f87:	c3                   	ret
   180001f88:	48 83 ec 28          	sub    rsp,0x28
   180001f8c:	33 c9                	xor    ecx,ecx
   180001f8e:	e8 05 07 00 00       	call   0x180002698
   180001f93:	48 83 c4 28          	add    rsp,0x28
   180001f97:	e9 fc 06 00 00       	jmp    0x180002698
   180001f9c:	48 83 ec 28          	sub    rsp,0x28
   180001fa0:	85 c9                	test   ecx,ecx
   180001fa2:	75 07                	jne    0x180001fab
   180001fa4:	c6 05 45 37 00 00 01 	mov    BYTE PTR [rip+0x3745],0x1        # 0x1800056f0
   180001fab:	e8 98 03 00 00       	call   0x180002348
   180001fb0:	e8 e3 06 00 00       	call   0x180002698
   180001fb5:	84 c0                	test   al,al
   180001fb7:	75 04                	jne    0x180001fbd
   180001fb9:	32 c0                	xor    al,al
   180001fbb:	eb 14                	jmp    0x180001fd1
   180001fbd:	e8 d6 06 00 00       	call   0x180002698
   180001fc2:	84 c0                	test   al,al
   180001fc4:	75 09                	jne    0x180001fcf
   180001fc6:	33 c9                	xor    ecx,ecx
   180001fc8:	e8 cb 06 00 00       	call   0x180002698
   180001fcd:	eb ea                	jmp    0x180001fb9
   180001fcf:	b0 01                	mov    al,0x1
   180001fd1:	48 83 c4 28          	add    rsp,0x28
   180001fd5:	c3                   	ret
   180001fd6:	cc                   	int3
   180001fd7:	cc                   	int3
   180001fd8:	40 53                	rex push rbx
   180001fda:	48 83 ec 20          	sub    rsp,0x20
   180001fde:	80 3d 0c 37 00 00 00 	cmp    BYTE PTR [rip+0x370c],0x0        # 0x1800056f1
   180001fe5:	8b d9                	mov    ebx,ecx
   180001fe7:	75 67                	jne    0x180002050
   180001fe9:	83 f9 01             	cmp    ecx,0x1
   180001fec:	77 6a                	ja     0x180002058
   180001fee:	e8 29 06 00 00       	call   0x18000261c
   180001ff3:	85 c0                	test   eax,eax
   180001ff5:	74 28                	je     0x18000201f
   180001ff7:	85 db                	test   ebx,ebx
   180001ff9:	75 24                	jne    0x18000201f
   180001ffb:	48 8d 0d f6 36 00 00 	lea    rcx,[rip+0x36f6]        # 0x1800056f8
   180002002:	e8 7d 06 00 00       	call   0x180002684
   180002007:	85 c0                	test   eax,eax
   180002009:	75 10                	jne    0x18000201b
   18000200b:	48 8d 0d fe 36 00 00 	lea    rcx,[rip+0x36fe]        # 0x180005710
   180002012:	e8 6d 06 00 00       	call   0x180002684
   180002017:	85 c0                	test   eax,eax
   180002019:	74 2e                	je     0x180002049
   18000201b:	32 c0                	xor    al,al
   18000201d:	eb 33                	jmp    0x180002052
   18000201f:	66 0f 6f 05 89 12 00 	movdqa xmm0,XMMWORD PTR [rip+0x1289]        # 0x1800032b0
   180002026:	00 
   180002027:	48 83 c8 ff          	or     rax,0xffffffffffffffff
   18000202b:	f3 0f 7f 05 c5 36 00 	movdqu XMMWORD PTR [rip+0x36c5],xmm0        # 0x1800056f8
   180002032:	00 
   180002033:	48 89 05 ce 36 00 00 	mov    QWORD PTR [rip+0x36ce],rax        # 0x180005708
   18000203a:	f3 0f 7f 05 ce 36 00 	movdqu XMMWORD PTR [rip+0x36ce],xmm0        # 0x180005710
   180002041:	00 
   180002042:	48 89 05 d7 36 00 00 	mov    QWORD PTR [rip+0x36d7],rax        # 0x180005720
   180002049:	c6 05 a1 36 00 00 01 	mov    BYTE PTR [rip+0x36a1],0x1        # 0x1800056f1
   180002050:	b0 01                	mov    al,0x1
   180002052:	48 83 c4 20          	add    rsp,0x20
   180002056:	5b                   	pop    rbx
   180002057:	c3                   	ret
   180002058:	b9 05 00 00 00       	mov    ecx,0x5
   18000205d:	e8 fa 00 00 00       	call   0x18000215c
   180002062:	cc                   	int3
   180002063:	cc                   	int3
   180002064:	48 83 ec 18          	sub    rsp,0x18
   180002068:	4c 8b c1             	mov    r8,rcx
   18000206b:	b8 4d 5a 00 00       	mov    eax,0x5a4d
   180002070:	66 39 05 89 df ff ff 	cmp    WORD PTR [rip+0xffffffffffffdf89],ax        # 0x180000000
   180002077:	75 78                	jne    0x1800020f1
   180002079:	48 63 0d bc df ff ff 	movsxd rcx,DWORD PTR [rip+0xffffffffffffdfbc]        # 0x18000003c
   180002080:	48 8d 15 79 df ff ff 	lea    rdx,[rip+0xffffffffffffdf79]        # 0x180000000
   180002087:	48 03 ca             	add    rcx,rdx
   18000208a:	81 39 50 45 00 00    	cmp    DWORD PTR [rcx],0x4550
   180002090:	75 5f                	jne    0x1800020f1
   180002092:	b8 0b 02 00 00       	mov    eax,0x20b
   180002097:	66 39 41 18          	cmp    WORD PTR [rcx+0x18],ax
   18000209b:	75 54                	jne    0x1800020f1
   18000209d:	4c 2b c2             	sub    r8,rdx
   1800020a0:	0f b7 51 14          	movzx  edx,WORD PTR [rcx+0x14]
   1800020a4:	48 83 c2 18          	add    rdx,0x18
   1800020a8:	48 03 d1             	add    rdx,rcx
   1800020ab:	0f b7 41 06          	movzx  eax,WORD PTR [rcx+0x6]
   1800020af:	48 8d 0c 80          	lea    rcx,[rax+rax*4]
   1800020b3:	4c 8d 0c ca          	lea    r9,[rdx+rcx*8]
   1800020b7:	48 89 14 24          	mov    QWORD PTR [rsp],rdx
   1800020bb:	49 3b d1             	cmp    rdx,r9
   1800020be:	74 18                	je     0x1800020d8
   1800020c0:	8b 4a 0c             	mov    ecx,DWORD PTR [rdx+0xc]
   1800020c3:	4c 3b c1             	cmp    r8,rcx
   1800020c6:	72 0a                	jb     0x1800020d2
   1800020c8:	8b 42 08             	mov    eax,DWORD PTR [rdx+0x8]
   1800020cb:	03 c1                	add    eax,ecx
   1800020cd:	4c 3b c0             	cmp    r8,rax
   1800020d0:	72 08                	jb     0x1800020da
   1800020d2:	48 83 c2 28          	add    rdx,0x28
   1800020d6:	eb df                	jmp    0x1800020b7
   1800020d8:	33 d2                	xor    edx,edx
   1800020da:	48 85 d2             	test   rdx,rdx
   1800020dd:	75 04                	jne    0x1800020e3
   1800020df:	32 c0                	xor    al,al
   1800020e1:	eb 14                	jmp    0x1800020f7
   1800020e3:	83 7a 24 00          	cmp    DWORD PTR [rdx+0x24],0x0
   1800020e7:	7d 04                	jge    0x1800020ed
   1800020e9:	32 c0                	xor    al,al
   1800020eb:	eb 0a                	jmp    0x1800020f7
   1800020ed:	b0 01                	mov    al,0x1
   1800020ef:	eb 06                	jmp    0x1800020f7
   1800020f1:	32 c0                	xor    al,al
   1800020f3:	eb 02                	jmp    0x1800020f7
   1800020f5:	32 c0                	xor    al,al
   1800020f7:	48 83 c4 18          	add    rsp,0x18
   1800020fb:	c3                   	ret
   1800020fc:	40 53                	rex push rbx
   1800020fe:	48 83 ec 20          	sub    rsp,0x20
   180002102:	8a d9                	mov    bl,cl
   180002104:	e8 13 05 00 00       	call   0x18000261c
   180002109:	33 d2                	xor    edx,edx
   18000210b:	85 c0                	test   eax,eax
   18000210d:	74 0b                	je     0x18000211a
   18000210f:	84 db                	test   bl,bl
   180002111:	75 07                	jne    0x18000211a
   180002113:	48 87 15 ce 35 00 00 	xchg   QWORD PTR [rip+0x35ce],rdx        # 0x1800056e8
   18000211a:	48 83 c4 20          	add    rsp,0x20
   18000211e:	5b                   	pop    rbx
   18000211f:	c3                   	ret
   180002120:	40 53                	rex push rbx
   180002122:	48 83 ec 20          	sub    rsp,0x20
   180002126:	80 3d c3 35 00 00 00 	cmp    BYTE PTR [rip+0x35c3],0x0        # 0x1800056f0
   18000212d:	8a d9                	mov    bl,cl
   18000212f:	74 04                	je     0x180002135
   180002131:	84 d2                	test   dl,dl
   180002133:	75 0c                	jne    0x180002141
   180002135:	e8 5e 05 00 00       	call   0x180002698
   18000213a:	8a cb                	mov    cl,bl
   18000213c:	e8 57 05 00 00       	call   0x180002698
   180002141:	b0 01                	mov    al,0x1
   180002143:	48 83 c4 20          	add    rsp,0x20
   180002147:	5b                   	pop    rbx
   180002148:	c3                   	ret
   180002149:	cc                   	int3
   18000214a:	cc                   	int3
   18000214b:	cc                   	int3
   18000214c:	48 8d 05 e5 35 00 00 	lea    rax,[rip+0x35e5]        # 0x180005738
   180002153:	c3                   	ret
   180002154:	83 25 cd 35 00 00 00 	and    DWORD PTR [rip+0x35cd],0x0        # 0x180005728
   18000215b:	c3                   	ret
   18000215c:	48 89 5c 24 08       	mov    QWORD PTR [rsp+0x8],rbx
   180002161:	55                   	push   rbp
   180002162:	48 8d ac 24 40 fb ff 	lea    rbp,[rsp-0x4c0]
   180002169:	ff 
   18000216a:	48 81 ec c0 05 00 00 	sub    rsp,0x5c0
   180002171:	8b d9                	mov    ebx,ecx
   180002173:	b9 17 00 00 00       	mov    ecx,0x17
   180002178:	ff 15 fa 0e 00 00    	call   QWORD PTR [rip+0xefa]        # 0x180003078
   18000217e:	85 c0                	test   eax,eax
   180002180:	74 04                	je     0x180002186
   180002182:	8b cb                	mov    ecx,ebx
   180002184:	cd 29                	int    0x29
   180002186:	b9 03 00 00 00       	mov    ecx,0x3
   18000218b:	e8 c4 ff ff ff       	call   0x180002154
   180002190:	33 d2                	xor    edx,edx
   180002192:	48 8d 4d f0          	lea    rcx,[rbp-0x10]
   180002196:	41 b8 d0 04 00 00    	mov    r8d,0x4d0
   18000219c:	e8 ad 04 00 00       	call   0x18000264e
   1800021a1:	48 8d 4d f0          	lea    rcx,[rbp-0x10]
   1800021a5:	ff 15 e5 0e 00 00    	call   QWORD PTR [rip+0xee5]        # 0x180003090
   1800021ab:	48 8b 9d e8 00 00 00 	mov    rbx,QWORD PTR [rbp+0xe8]
   1800021b2:	48 8d 95 d8 04 00 00 	lea    rdx,[rbp+0x4d8]
   1800021b9:	48 8b cb             	mov    rcx,rbx
   1800021bc:	45 33 c0             	xor    r8d,r8d
   1800021bf:	ff 15 83 0e 00 00    	call   QWORD PTR [rip+0xe83]        # 0x180003048
   1800021c5:	48 85 c0             	test   rax,rax
   1800021c8:	74 3c                	je     0x180002206
   1800021ca:	48 83 64 24 38 00    	and    QWORD PTR [rsp+0x38],0x0
   1800021d0:	48 8d 8d e0 04 00 00 	lea    rcx,[rbp+0x4e0]
   1800021d7:	48 8b 95 d8 04 00 00 	mov    rdx,QWORD PTR [rbp+0x4d8]
   1800021de:	4c 8b c8             	mov    r9,rax
   1800021e1:	48 89 4c 24 30       	mov    QWORD PTR [rsp+0x30],rcx
   1800021e6:	4c 8b c3             	mov    r8,rbx
   1800021e9:	48 8d 8d e8 04 00 00 	lea    rcx,[rbp+0x4e8]
   1800021f0:	48 89 4c 24 28       	mov    QWORD PTR [rsp+0x28],rcx
   1800021f5:	48 8d 4d f0          	lea    rcx,[rbp-0x10]
   1800021f9:	48 89 4c 24 20       	mov    QWORD PTR [rsp+0x20],rcx
   1800021fe:	33 c9                	xor    ecx,ecx
   180002200:	ff 15 4a 0e 00 00    	call   QWORD PTR [rip+0xe4a]        # 0x180003050
   180002206:	48 8b 85 c8 04 00 00 	mov    rax,QWORD PTR [rbp+0x4c8]
   18000220d:	48 8d 4c 24 50       	lea    rcx,[rsp+0x50]
   180002212:	48 89 85 e8 00 00 00 	mov    QWORD PTR [rbp+0xe8],rax
   180002219:	33 d2                	xor    edx,edx
   18000221b:	48 8d 85 c8 04 00 00 	lea    rax,[rbp+0x4c8]
   180002222:	41 b8 98 00 00 00    	mov    r8d,0x98
   180002228:	48 83 c0 08          	add    rax,0x8
   18000222c:	48 89 85 88 00 00 00 	mov    QWORD PTR [rbp+0x88],rax
   180002233:	e8 16 04 00 00       	call   0x18000264e
   180002238:	48 8b 85 c8 04 00 00 	mov    rax,QWORD PTR [rbp+0x4c8]
   18000223f:	48 89 44 24 60       	mov    QWORD PTR [rsp+0x60],rax
   180002244:	c7 44 24 50 15 00 00 	mov    DWORD PTR [rsp+0x50],0x40000015
   18000224b:	40 
   18000224c:	c7 44 24 54 01 00 00 	mov    DWORD PTR [rsp+0x54],0x1
   180002253:	00 
   180002254:	ff 15 3e 0e 00 00    	call   QWORD PTR [rip+0xe3e]        # 0x180003098
   18000225a:	8b d8                	mov    ebx,eax
   18000225c:	33 c9                	xor    ecx,ecx
   18000225e:	48 8d 44 24 50       	lea    rax,[rsp+0x50]
   180002263:	48 89 44 24 40       	mov    QWORD PTR [rsp+0x40],rax
   180002268:	48 8d 45 f0          	lea    rax,[rbp-0x10]
   18000226c:	48 89 44 24 48       	mov    QWORD PTR [rsp+0x48],rax
   180002271:	ff 15 e9 0d 00 00    	call   QWORD PTR [rip+0xde9]        # 0x180003060
   180002277:	48 8d 4c 24 40       	lea    rcx,[rsp+0x40]
   18000227c:	ff 15 d6 0d 00 00    	call   QWORD PTR [rip+0xdd6]        # 0x180003058
   180002282:	85 c0                	test   eax,eax
   180002284:	75 0d                	jne    0x180002293
   180002286:	83 fb 01             	cmp    ebx,0x1
   180002289:	74 08                	je     0x180002293
   18000228b:	8d 48 03             	lea    ecx,[rax+0x3]
   18000228e:	e8 c1 fe ff ff       	call   0x180002154
   180002293:	48 8b 9c 24 d0 05 00 	mov    rbx,QWORD PTR [rsp+0x5d0]
   18000229a:	00 
   18000229b:	48 81 c4 c0 05 00 00 	add    rsp,0x5c0
   1800022a2:	5d                   	pop    rbp
   1800022a3:	c3                   	ret
   1800022a4:	48 89 5c 24 08       	mov    QWORD PTR [rsp+0x8],rbx
   1800022a9:	57                   	push   rdi
   1800022aa:	48 83 ec 20          	sub    rsp,0x20
   1800022ae:	48 8d 1d 03 17 00 00 	lea    rbx,[rip+0x1703]        # 0x1800039b8
   1800022b5:	48 8d 3d fc 16 00 00 	lea    rdi,[rip+0x16fc]        # 0x1800039b8
   1800022bc:	eb 12                	jmp    0x1800022d0
   1800022be:	48 8b 03             	mov    rax,QWORD PTR [rbx]
   1800022c1:	48 85 c0             	test   rax,rax
   1800022c4:	74 06                	je     0x1800022cc
   1800022c6:	ff 15 ac 0e 00 00    	call   QWORD PTR [rip+0xeac]        # 0x180003178
   1800022cc:	48 83 c3 08          	add    rbx,0x8
   1800022d0:	48 3b df             	cmp    rbx,rdi
   1800022d3:	72 e9                	jb     0x1800022be
   1800022d5:	48 8b 5c 24 30       	mov    rbx,QWORD PTR [rsp+0x30]
   1800022da:	48 83 c4 20          	add    rsp,0x20
   1800022de:	5f                   	pop    rdi
   1800022df:	c3                   	ret
   1800022e0:	48 89 5c 24 08       	mov    QWORD PTR [rsp+0x8],rbx
   1800022e5:	57                   	push   rdi
   1800022e6:	48 83 ec 20          	sub    rsp,0x20
   1800022ea:	48 8d 1d d7 16 00 00 	lea    rbx,[rip+0x16d7]        # 0x1800039c8
   1800022f1:	48 8d 3d d0 16 00 00 	lea    rdi,[rip+0x16d0]        # 0x1800039c8
   1800022f8:	eb 12                	jmp    0x18000230c
   1800022fa:	48 8b 03             	mov    rax,QWORD PTR [rbx]
   1800022fd:	48 85 c0             	test   rax,rax
   180002300:	74 06                	je     0x180002308
   180002302:	ff 15 70 0e 00 00    	call   QWORD PTR [rip+0xe70]        # 0x180003178
   180002308:	48 83 c3 08          	add    rbx,0x8
   18000230c:	48 3b df             	cmp    rbx,rdi
   18000230f:	72 e9                	jb     0x1800022fa
   180002311:	48 8b 5c 24 30       	mov    rbx,QWORD PTR [rsp+0x30]
   180002316:	48 83 c4 20          	add    rsp,0x20
   18000231a:	5f                   	pop    rdi
   18000231b:	c3                   	ret
   18000231c:	40 53                	rex push rbx
   18000231e:	48 83 ec 20          	sub    rsp,0x20
   180002322:	48 8d 05 9f 0f 00 00 	lea    rax,[rip+0xf9f]        # 0x1800032c8
   180002329:	48 8b d9             	mov    rbx,rcx
   18000232c:	48 89 01             	mov    QWORD PTR [rcx],rax
   18000232f:	f6 c2 01             	test   dl,0x1
   180002332:	74 0a                	je     0x18000233e
   180002334:	ba 18 00 00 00       	mov    edx,0x18
   180002339:	e8 d2 f2 ff ff       	call   0x180001610
   18000233e:	48 8b c3             	mov    rax,rbx
   180002341:	48 83 c4 20          	add    rsp,0x20
   180002345:	5b                   	pop    rbx
   180002346:	c3                   	ret
   180002347:	cc                   	int3
   180002348:	48 89 5c 24 10       	mov    QWORD PTR [rsp+0x10],rbx
   18000234d:	48 89 74 24 18       	mov    QWORD PTR [rsp+0x18],rsi
   180002352:	55                   	push   rbp
   180002353:	57                   	push   rdi
   180002354:	41 56                	push   r14
   180002356:	48 8b ec             	mov    rbp,rsp
   180002359:	48 83 ec 10          	sub    rsp,0x10
   18000235d:	33 c0                	xor    eax,eax
   18000235f:	33 c9                	xor    ecx,ecx
   180002361:	0f a2                	cpuid
   180002363:	44 8b c1             	mov    r8d,ecx
   180002366:	44 8b d2             	mov    r10d,edx
   180002369:	41 81 f2 69 6e 65 49 	xor    r10d,0x49656e69
   180002370:	41 81 f0 6e 74 65 6c 	xor    r8d,0x6c65746e
   180002377:	44 8b cb             	mov    r9d,ebx
   18000237a:	44 8b f0             	mov    r14d,eax
   18000237d:	33 c9                	xor    ecx,ecx
   18000237f:	b8 01 00 00 00       	mov    eax,0x1
   180002384:	0f a2                	cpuid
   180002386:	45 0b d0             	or     r10d,r8d
   180002389:	89 45 f0             	mov    DWORD PTR [rbp-0x10],eax
   18000238c:	41 81 f1 47 65 6e 75 	xor    r9d,0x756e6547
   180002393:	89 5d f4             	mov    DWORD PTR [rbp-0xc],ebx
   180002396:	45 0b d1             	or     r10d,r9d
   180002399:	89 4d f8             	mov    DWORD PTR [rbp-0x8],ecx
   18000239c:	8b f9                	mov    edi,ecx
   18000239e:	89 55 fc             	mov    DWORD PTR [rbp-0x4],edx
   1800023a1:	75 5b                	jne    0x1800023fe
   1800023a3:	48 83 0d bd 2c 00 00 	or     QWORD PTR [rip+0x2cbd],0xffffffffffffffff        # 0x180005068
   1800023aa:	ff 
   1800023ab:	25 f0 3f ff 0f       	and    eax,0xfff3ff0
   1800023b0:	48 c7 05 a5 2c 00 00 	mov    QWORD PTR [rip+0x2ca5],0x8000        # 0x180005060
   1800023b7:	00 80 00 00 
   1800023bb:	3d c0 06 01 00       	cmp    eax,0x106c0
   1800023c0:	74 28                	je     0x1800023ea
   1800023c2:	3d 60 06 02 00       	cmp    eax,0x20660
   1800023c7:	74 21                	je     0x1800023ea
   1800023c9:	3d 70 06 02 00       	cmp    eax,0x20670
   1800023ce:	74 1a                	je     0x1800023ea
   1800023d0:	05 b0 f9 fc ff       	add    eax,0xfffcf9b0
   1800023d5:	83 f8 20             	cmp    eax,0x20
   1800023d8:	77 24                	ja     0x1800023fe
   1800023da:	48 b9 01 00 01 00 01 	movabs rcx,0x100010001
   1800023e1:	00 00 00 
   1800023e4:	48 0f a3 c1          	bt     rcx,rax
   1800023e8:	73 14                	jae    0x1800023fe
   1800023ea:	44 8b 05 3f 33 00 00 	mov    r8d,DWORD PTR [rip+0x333f]        # 0x180005730
   1800023f1:	41 83 c8 01          	or     r8d,0x1
   1800023f5:	44 89 05 34 33 00 00 	mov    DWORD PTR [rip+0x3334],r8d        # 0x180005730
   1800023fc:	eb 07                	jmp    0x180002405
   1800023fe:	44 8b 05 2b 33 00 00 	mov    r8d,DWORD PTR [rip+0x332b]        # 0x180005730
   180002405:	45 33 c9             	xor    r9d,r9d
   180002408:	41 8b f1             	mov    esi,r9d
   18000240b:	45 8b d1             	mov    r10d,r9d
   18000240e:	45 8b d9             	mov    r11d,r9d
   180002411:	41 83 fe 07          	cmp    r14d,0x7
   180002415:	7c 65                	jl     0x18000247c
   180002417:	41 8d 41 07          	lea    eax,[r9+0x7]
   18000241b:	33 c9                	xor    ecx,ecx
   18000241d:	0f a2                	cpuid
   18000241f:	89 45 f0             	mov    DWORD PTR [rbp-0x10],eax
   180002422:	8b f2                	mov    esi,edx
   180002424:	89 5d f4             	mov    DWORD PTR [rbp-0xc],ebx
   180002427:	44 8b cb             	mov    r9d,ebx
   18000242a:	89 4d f8             	mov    DWORD PTR [rbp-0x8],ecx
   18000242d:	89 55 fc             	mov    DWORD PTR [rbp-0x4],edx
   180002430:	0f ba e3 09          	bt     ebx,0x9
   180002434:	73 0b                	jae    0x180002441
   180002436:	41 83 c8 02          	or     r8d,0x2
   18000243a:	44 89 05 ef 32 00 00 	mov    DWORD PTR [rip+0x32ef],r8d        # 0x180005730
   180002441:	83 f8 01             	cmp    eax,0x1
   180002444:	7c 19                	jl     0x18000245f
   180002446:	b8 07 00 00 00       	mov    eax,0x7
   18000244b:	8d 48 fa             	lea    ecx,[rax-0x6]
   18000244e:	0f a2                	cpuid
   180002450:	44 8b d2             	mov    r10d,edx
   180002453:	89 45 f0             	mov    DWORD PTR [rbp-0x10],eax
   180002456:	89 5d f4             	mov    DWORD PTR [rbp-0xc],ebx
   180002459:	89 4d f8             	mov    DWORD PTR [rbp-0x8],ecx
   18000245c:	89 55 fc             	mov    DWORD PTR [rbp-0x4],edx
   18000245f:	b8 24 00 00 00       	mov    eax,0x24
   180002464:	44 3b f0             	cmp    r14d,eax
   180002467:	7c 13                	jl     0x18000247c
   180002469:	33 c9                	xor    ecx,ecx
   18000246b:	0f a2                	cpuid
   18000246d:	44 8b db             	mov    r11d,ebx
   180002470:	89 45 f0             	mov    DWORD PTR [rbp-0x10],eax
   180002473:	89 5d f4             	mov    DWORD PTR [rbp-0xc],ebx
   180002476:	89 4d f8             	mov    DWORD PTR [rbp-0x8],ecx
   180002479:	89 55 fc             	mov    DWORD PTR [rbp-0x4],edx
   18000247c:	48 8b 05 cd 2b 00 00 	mov    rax,QWORD PTR [rip+0x2bcd]        # 0x180005050
   180002483:	bb 06 00 00 00       	mov    ebx,0x6
   180002488:	48 83 e0 fe          	and    rax,0xfffffffffffffffe
   18000248c:	c7 05 c2 2b 00 00 01 	mov    DWORD PTR [rip+0x2bc2],0x1        # 0x180005058
   180002493:	00 00 00 
   180002496:	c7 05 bc 2b 00 00 02 	mov    DWORD PTR [rip+0x2bbc],0x2        # 0x18000505c
   18000249d:	00 00 00 
   1800024a0:	48 89 05 a9 2b 00 00 	mov    QWORD PTR [rip+0x2ba9],rax        # 0x180005050
   1800024a7:	0f ba e7 14          	bt     edi,0x14
   1800024ab:	73 1b                	jae    0x1800024c8
   1800024ad:	48 83 e0 ef          	and    rax,0xffffffffffffffef
   1800024b1:	c7 05 9d 2b 00 00 02 	mov    DWORD PTR [rip+0x2b9d],0x2        # 0x180005058
   1800024b8:	00 00 00 
   1800024bb:	48 89 05 8e 2b 00 00 	mov    QWORD PTR [rip+0x2b8e],rax        # 0x180005050
   1800024c2:	89 1d 94 2b 00 00    	mov    DWORD PTR [rip+0x2b94],ebx        # 0x18000505c
   1800024c8:	0f ba e7 1b          	bt     edi,0x1b
   1800024cc:	0f 83 2b 01 00 00    	jae    0x1800025fd
   1800024d2:	33 c9                	xor    ecx,ecx
   1800024d4:	0f 01 d0             	xgetbv
   1800024d7:	48 c1 e2 20          	shl    rdx,0x20
   1800024db:	48 0b d0             	or     rdx,rax
   1800024de:	48 89 55 20          	mov    QWORD PTR [rbp+0x20],rdx
   1800024e2:	0f ba e7 1c          	bt     edi,0x1c
   1800024e6:	0f 83 f6 00 00 00    	jae    0x1800025e2
   1800024ec:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1800024f0:	22 c3                	and    al,bl
   1800024f2:	3a c3                	cmp    al,bl
   1800024f4:	0f 85 e8 00 00 00    	jne    0x1800025e2
   1800024fa:	8b 05 5c 2b 00 00    	mov    eax,DWORD PTR [rip+0x2b5c]        # 0x18000505c
   180002500:	b2 e0                	mov    dl,0xe0
   180002502:	83 c8 08             	or     eax,0x8
   180002505:	c7 05 49 2b 00 00 03 	mov    DWORD PTR [rip+0x2b49],0x3        # 0x180005058
   18000250c:	00 00 00 
   18000250f:	89 05 47 2b 00 00    	mov    DWORD PTR [rip+0x2b47],eax        # 0x18000505c
   180002515:	41 f6 c1 20          	test   r9b,0x20
   180002519:	74 5d                	je     0x180002578
   18000251b:	83 c8 20             	or     eax,0x20
   18000251e:	c7 05 30 2b 00 00 05 	mov    DWORD PTR [rip+0x2b30],0x5        # 0x180005058
   180002525:	00 00 00 
   180002528:	89 05 2e 2b 00 00    	mov    DWORD PTR [rip+0x2b2e],eax        # 0x18000505c
   18000252e:	b9 00 00 03 d0       	mov    ecx,0xd0030000
   180002533:	48 8b 05 16 2b 00 00 	mov    rax,QWORD PTR [rip+0x2b16]        # 0x180005050
   18000253a:	44 23 c9             	and    r9d,ecx
   18000253d:	48 83 e0 fd          	and    rax,0xfffffffffffffffd
   180002541:	48 89 05 08 2b 00 00 	mov    QWORD PTR [rip+0x2b08],rax        # 0x180005050
   180002548:	44 3b c9             	cmp    r9d,ecx
   18000254b:	75 32                	jne    0x18000257f
   18000254d:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   180002551:	22 c2                	and    al,dl
   180002553:	3a c2                	cmp    al,dl
   180002555:	75 21                	jne    0x180002578
   180002557:	48 8b 05 f2 2a 00 00 	mov    rax,QWORD PTR [rip+0x2af2]        # 0x180005050
   18000255e:	83 0d f7 2a 00 00 40 	or     DWORD PTR [rip+0x2af7],0x40        # 0x18000505c
   180002565:	48 83 e0 db          	and    rax,0xffffffffffffffdb
   180002569:	89 1d e9 2a 00 00    	mov    DWORD PTR [rip+0x2ae9],ebx        # 0x180005058
   18000256f:	48 89 05 da 2a 00 00 	mov    QWORD PTR [rip+0x2ada],rax        # 0x180005050
   180002576:	eb 07                	jmp    0x18000257f
   180002578:	48 8b 05 d1 2a 00 00 	mov    rax,QWORD PTR [rip+0x2ad1]        # 0x180005050
   18000257f:	0f ba e6 17          	bt     esi,0x17
   180002583:	73 0c                	jae    0x180002591
   180002585:	48 0f ba f0 18       	btr    rax,0x18
   18000258a:	48 89 05 bf 2a 00 00 	mov    QWORD PTR [rip+0x2abf],rax        # 0x180005050
   180002591:	41 0f ba e2 13       	bt     r10d,0x13
   180002596:	73 4a                	jae    0x1800025e2
   180002598:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   18000259c:	22 c2                	and    al,dl
   18000259e:	3a c2                	cmp    al,dl
   1800025a0:	75 40                	jne    0x1800025e2
   1800025a2:	41 8b cb             	mov    ecx,r11d
   1800025a5:	41 8b c3             	mov    eax,r11d
   1800025a8:	48 c1 e9 10          	shr    rcx,0x10
   1800025ac:	25 ff 00 04 00       	and    eax,0x400ff
   1800025b1:	83 e1 07             	and    ecx,0x7
   1800025b4:	89 05 72 31 00 00    	mov    DWORD PTR [rip+0x3172],eax        # 0x18000572c
   1800025ba:	48 81 c9 28 00 00 01 	or     rcx,0x1000028
   1800025c1:	48 f7 d1             	not    rcx
   1800025c4:	48 23 0d 85 2a 00 00 	and    rcx,QWORD PTR [rip+0x2a85]        # 0x180005050
   1800025cb:	48 89 0d 7e 2a 00 00 	mov    QWORD PTR [rip+0x2a7e],rcx        # 0x180005050
   1800025d2:	83 f8 01             	cmp    eax,0x1
   1800025d5:	76 0b                	jbe    0x1800025e2
   1800025d7:	48 83 e1 bf          	and    rcx,0xffffffffffffffbf
   1800025db:	48 89 0d 6e 2a 00 00 	mov    QWORD PTR [rip+0x2a6e],rcx        # 0x180005050
   1800025e2:	41 0f ba e2 15       	bt     r10d,0x15
   1800025e7:	73 14                	jae    0x1800025fd
   1800025e9:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   1800025ed:	48 0f ba e0 13       	bt     rax,0x13
   1800025f2:	73 09                	jae    0x1800025fd
   1800025f4:	48 0f ba 35 53 2a 00 	btr    QWORD PTR [rip+0x2a53],0x7        # 0x180005050
   1800025fb:	00 07 
   1800025fd:	48 8b 5c 24 38       	mov    rbx,QWORD PTR [rsp+0x38]
   180002602:	33 c0                	xor    eax,eax
   180002604:	48 8b 74 24 40       	mov    rsi,QWORD PTR [rsp+0x40]
   180002609:	48 83 c4 10          	add    rsp,0x10
   18000260d:	41 5e                	pop    r14
   18000260f:	5f                   	pop    rdi
   180002610:	5d                   	pop    rbp
   180002611:	c3                   	ret
   180002612:	cc                   	int3
   180002613:	cc                   	int3
   180002614:	b8 01 00 00 00       	mov    eax,0x1
   180002619:	c3                   	ret
   18000261a:	cc                   	int3
   18000261b:	cc                   	int3
   18000261c:	33 c0                	xor    eax,eax
   18000261e:	39 05 4c 2a 00 00    	cmp    DWORD PTR [rip+0x2a4c],eax        # 0x180005070
   180002624:	0f 95 c0             	setne  al
   180002627:	c3                   	ret
   180002628:	cc                   	int3
   180002629:	cc                   	int3
   18000262a:	cc                   	int3
   18000262b:	cc                   	int3
   18000262c:	cc                   	int3
   18000262d:	cc                   	int3
   18000262e:	cc                   	int3
   18000262f:	cc                   	int3
   180002630:	ff 25 b2 0a 00 00    	jmp    QWORD PTR [rip+0xab2]        # 0x1800030e8
   180002636:	ff 25 a4 0a 00 00    	jmp    QWORD PTR [rip+0xaa4]        # 0x1800030e0
   18000263c:	ff 25 96 0a 00 00    	jmp    QWORD PTR [rip+0xa96]        # 0x1800030d8
   180002642:	ff 25 88 0a 00 00    	jmp    QWORD PTR [rip+0xa88]        # 0x1800030d0
   180002648:	ff 25 7a 0a 00 00    	jmp    QWORD PTR [rip+0xa7a]        # 0x1800030c8
   18000264e:	ff 25 9c 0a 00 00    	jmp    QWORD PTR [rip+0xa9c]        # 0x1800030f0
   180002654:	ff 25 b6 0a 00 00    	jmp    QWORD PTR [rip+0xab6]        # 0x180003110
   18000265a:	ff 25 a0 0a 00 00    	jmp    QWORD PTR [rip+0xaa0]        # 0x180003100
   180002660:	ff 25 e2 0a 00 00    	jmp    QWORD PTR [rip+0xae2]        # 0x180003148
   180002666:	ff 25 d4 0a 00 00    	jmp    QWORD PTR [rip+0xad4]        # 0x180003140
   18000266c:	ff 25 96 0a 00 00    	jmp    QWORD PTR [rip+0xa96]        # 0x180003108
   180002672:	ff 25 c0 0a 00 00    	jmp    QWORD PTR [rip+0xac0]        # 0x180003138
   180002678:	ff 25 da 0a 00 00    	jmp    QWORD PTR [rip+0xada]        # 0x180003158
   18000267e:	ff 25 ac 0a 00 00    	jmp    QWORD PTR [rip+0xaac]        # 0x180003130
   180002684:	ff 25 c6 0a 00 00    	jmp    QWORD PTR [rip+0xac6]        # 0x180003150
   18000268a:	ff 25 90 0a 00 00    	jmp    QWORD PTR [rip+0xa90]        # 0x180003120
   180002690:	ff 25 92 0a 00 00    	jmp    QWORD PTR [rip+0xa92]        # 0x180003128
   180002696:	cc                   	int3
   180002697:	cc                   	int3
   180002698:	b0 01                	mov    al,0x1
   18000269a:	c3                   	ret
   18000269b:	cc                   	int3
   18000269c:	33 c0                	xor    eax,eax
   18000269e:	c3                   	ret
   18000269f:	ff 25 1b 0a 00 00    	jmp    QWORD PTR [rip+0xa1b]        # 0x1800030c0
   1800026a5:	cc                   	int3
   1800026a6:	cc                   	int3
   1800026a7:	cc                   	int3
   1800026a8:	cc                   	int3
   1800026a9:	cc                   	int3
   1800026aa:	cc                   	int3
   1800026ab:	cc                   	int3
   1800026ac:	cc                   	int3
   1800026ad:	cc                   	int3
   1800026ae:	cc                   	int3
   1800026af:	cc                   	int3
   1800026b0:	cc                   	int3
   1800026b1:	cc                   	int3
   1800026b2:	cc                   	int3
   1800026b3:	cc                   	int3
   1800026b4:	cc                   	int3
   1800026b5:	cc                   	int3
   1800026b6:	66 66 0f 1f 84 00 00 	data16 nop WORD PTR [rax+rax*1+0x0]
   1800026bd:	00 00 00 
   1800026c0:	ff e0                	jmp    rax
   1800026c2:	cc                   	int3
   1800026c3:	cc                   	int3
   1800026c4:	cc                   	int3
   1800026c5:	cc                   	int3
   1800026c6:	cc                   	int3
   1800026c7:	cc                   	int3
   1800026c8:	cc                   	int3
   1800026c9:	cc                   	int3
   1800026ca:	cc                   	int3
   1800026cb:	cc                   	int3
   1800026cc:	cc                   	int3
   1800026cd:	cc                   	int3
   1800026ce:	cc                   	int3
   1800026cf:	cc                   	int3
   1800026d0:	cc                   	int3
   1800026d1:	cc                   	int3
   1800026d2:	cc                   	int3
   1800026d3:	cc                   	int3
   1800026d4:	cc                   	int3
   1800026d5:	cc                   	int3
   1800026d6:	66 66 0f 1f 84 00 00 	data16 nop WORD PTR [rax+rax*1+0x0]
   1800026dd:	00 00 00 
   1800026e0:	ff 25 92 0a 00 00    	jmp    QWORD PTR [rip+0xa92]        # 0x180003178
   1800026e6:	40 55                	rex push rbp
   1800026e8:	48 83 ec 20          	sub    rsp,0x20
   1800026ec:	48 8b ea             	mov    rbp,rdx
   1800026ef:	8a 4d 40             	mov    cl,BYTE PTR [rbp+0x40]
   1800026f2:	48 83 c4 20          	add    rsp,0x20
   1800026f6:	5d                   	pop    rbp
   1800026f7:	e9 00 fa ff ff       	jmp    0x1800020fc
   1800026fc:	cc                   	int3
   1800026fd:	40 55                	rex push rbp
   1800026ff:	48 83 ec 20          	sub    rsp,0x20
   180002703:	48 8b ea             	mov    rbp,rdx
   180002706:	8a 4d 20             	mov    cl,BYTE PTR [rbp+0x20]
   180002709:	e8 ee f9 ff ff       	call   0x1800020fc
   18000270e:	90                   	nop
   18000270f:	48 83 c4 20          	add    rsp,0x20
   180002713:	5d                   	pop    rbp
   180002714:	c3                   	ret
   180002715:	cc                   	int3
   180002716:	40 55                	rex push rbp
   180002718:	48 83 ec 20          	sub    rsp,0x20
   18000271c:	48 8b ea             	mov    rbp,rdx
   18000271f:	48 83 c4 20          	add    rsp,0x20
   180002723:	5d                   	pop    rbp
   180002724:	e9 5f f8 ff ff       	jmp    0x180001f88
   180002729:	cc                   	int3
   18000272a:	40 55                	rex push rbp
   18000272c:	48 83 ec 30          	sub    rsp,0x30
   180002730:	48 8b ea             	mov    rbp,rdx
   180002733:	48 8b 01             	mov    rax,QWORD PTR [rcx]
   180002736:	8b 10                	mov    edx,DWORD PTR [rax]
   180002738:	48 89 4c 24 28       	mov    QWORD PTR [rsp+0x28],rcx
   18000273d:	89 54 24 20          	mov    DWORD PTR [rsp+0x20],edx
   180002741:	4c 8d 0d 88 ef ff ff 	lea    r9,[rip+0xffffffffffffef88]        # 0x1800016d0
   180002748:	4c 8b 45 70          	mov    r8,QWORD PTR [rbp+0x70]
   18000274c:	8b 55 68             	mov    edx,DWORD PTR [rbp+0x68]
   18000274f:	48 8b 4d 60          	mov    rcx,QWORD PTR [rbp+0x60]
   180002753:	e8 a0 f7 ff ff       	call   0x180001ef8
   180002758:	90                   	nop
   180002759:	48 83 c4 30          	add    rsp,0x30
   18000275d:	5d                   	pop    rbp
   18000275e:	c3                   	ret
   18000275f:	cc                   	int3
   180002760:	40 55                	rex push rbp
   180002762:	48 8b ea             	mov    rbp,rdx
   180002765:	48 8b 01             	mov    rax,QWORD PTR [rcx]
   180002768:	33 c9                	xor    ecx,ecx
   18000276a:	81 38 05 00 00 c0    	cmp    DWORD PTR [rax],0xc0000005
   180002770:	0f 94 c1             	sete   cl
   180002773:	8b c1                	mov    eax,ecx
   180002775:	5d                   	pop    rbp
   180002776:	c3                   	ret
   180002777:	cc                   	int3
