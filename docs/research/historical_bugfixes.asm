
~/.local/share/Steam/steamapps/common/[NINJA GAIDEN Master Collection] NINJA GAIDEN Σ２/plugin/nmsteam-bugfixes.dll:     file format pei-x86-64


Disassembly of section .text:

0000000180001000 <.text>:
   180001000:	48 83 ec 28          	sub    rsp,0x28
   180001004:	33 c9                	xor    ecx,ecx
   180001006:	ff 15 04 20 00 00    	call   QWORD PTR [rip+0x2004]        # 0x180003010
   18000100c:	48 89 05 55 41 00 00 	mov    QWORD PTR [rip+0x4155],rax        # 0x180005168
   180001013:	48 83 c4 28          	add    rsp,0x28
   180001017:	c3                   	ret
   180001018:	cc                   	int3
   180001019:	cc                   	int3
   18000101a:	cc                   	int3
   18000101b:	cc                   	int3
   18000101c:	cc                   	int3
   18000101d:	cc                   	int3
   18000101e:	cc                   	int3
   18000101f:	cc                   	int3
   180001020:	48 83 ec 28          	sub    rsp,0x28
   180001024:	33 c9                	xor    ecx,ecx
   180001026:	ff 15 e4 1f 00 00    	call   QWORD PTR [rip+0x1fe4]        # 0x180003010
   18000102c:	8b 48 3c             	mov    ecx,DWORD PTR [rax+0x3c]
   18000102f:	8b 44 01 1c          	mov    eax,DWORD PTR [rcx+rax*1+0x1c]
   180001033:	89 05 27 41 00 00    	mov    DWORD PTR [rip+0x4127],eax        # 0x180005160
   180001039:	48 83 c4 28          	add    rsp,0x28
   18000103d:	c3                   	ret
   18000103e:	cc                   	int3
   18000103f:	cc                   	int3
   180001040:	48 83 ec 28          	sub    rsp,0x28
   180001044:	83 fa 01             	cmp    edx,0x1
   180001047:	0f 85 61 01 00 00    	jne    0x1800011ae
   18000104d:	48 89 5c 24 20       	mov    QWORD PTR [rsp+0x20],rbx
   180001052:	ff 15 b0 1f 00 00    	call   QWORD PTR [rip+0x1fb0]        # 0x180003008
   180001058:	8b 05 02 41 00 00    	mov    eax,DWORD PTR [rip+0x4102]        # 0x180005160
   18000105e:	3d 00 c0 79 01       	cmp    eax,0x179c000
   180001063:	0f 84 81 00 00 00    	je     0x1800010ea
   180001069:	3d 00 c4 79 01       	cmp    eax,0x179c400
   18000106e:	0f 85 2b 01 00 00    	jne    0x18000119f
   180001074:	b9 18 00 00 00       	mov    ecx,0x18
   180001079:	e8 3a 01 00 00       	call   0x1800011b8
   18000107e:	48 8b d8             	mov    rbx,rax
   180001081:	48 85 c0             	test   rax,rax
   180001084:	74 35                	je     0x1800010bb
   180001086:	48 8b 0d db 40 00 00 	mov    rcx,QWORD PTR [rip+0x40db]        # 0x180005168
   18000108d:	4c 8b cb             	mov    r9,rbx
   180001090:	48 81 c1 a9 df 3d 01 	add    rcx,0x13ddfa9
   180001097:	ba 01 00 00 00       	mov    edx,0x1
   18000109c:	48 89 48 08          	mov    QWORD PTR [rax+0x8],rcx
   1800010a0:	41 b8 40 00 00 00    	mov    r8d,0x40
   1800010a6:	0f b6 01             	movzx  eax,BYTE PTR [rcx]
   1800010a9:	88 43 10             	mov    BYTE PTR [rbx+0x10],al
   1800010ac:	ff 15 4e 1f 00 00    	call   QWORD PTR [rip+0x1f4e]        # 0x180003000
   1800010b2:	48 8b 43 08          	mov    rax,QWORD PTR [rbx+0x8]
   1800010b6:	c6 00 07             	mov    BYTE PTR [rax],0x7
   1800010b9:	eb 02                	jmp    0x1800010bd
   1800010bb:	33 db                	xor    ebx,ebx
   1800010bd:	b9 18 00 00 00       	mov    ecx,0x18
   1800010c2:	48 89 1d a7 40 00 00 	mov    QWORD PTR [rip+0x40a7],rbx        # 0x180005170
   1800010c9:	e8 ea 00 00 00       	call   0x1800011b8
   1800010ce:	48 8b d8             	mov    rbx,rax
   1800010d1:	48 85 c0             	test   rax,rax
   1800010d4:	0f 84 bc 00 00 00    	je     0x180001196
   1800010da:	48 8b 0d 87 40 00 00 	mov    rcx,QWORD PTR [rip+0x4087]        # 0x180005168
   1800010e1:	48 81 c1 60 30 c4 00 	add    rcx,0xc43060
   1800010e8:	eb 70                	jmp    0x18000115a
   1800010ea:	b9 18 00 00 00       	mov    ecx,0x18
   1800010ef:	e8 c4 00 00 00       	call   0x1800011b8
   1800010f4:	48 8b d8             	mov    rbx,rax
   1800010f7:	48 85 c0             	test   rax,rax
   1800010fa:	74 35                	je     0x180001131
   1800010fc:	48 8b 0d 65 40 00 00 	mov    rcx,QWORD PTR [rip+0x4065]        # 0x180005168
   180001103:	4c 8b c8             	mov    r9,rax
   180001106:	48 81 c1 79 dd 3d 01 	add    rcx,0x13ddd79
   18000110d:	41 b8 40 00 00 00    	mov    r8d,0x40
   180001113:	48 89 48 08          	mov    QWORD PTR [rax+0x8],rcx
   180001117:	0f b6 11             	movzx  edx,BYTE PTR [rcx]
   18000111a:	88 50 10             	mov    BYTE PTR [rax+0x10],dl
   18000111d:	ba 01 00 00 00       	mov    edx,0x1
   180001122:	ff 15 d8 1e 00 00    	call   QWORD PTR [rip+0x1ed8]        # 0x180003000
   180001128:	48 8b 43 08          	mov    rax,QWORD PTR [rbx+0x8]
   18000112c:	c6 00 07             	mov    BYTE PTR [rax],0x7
   18000112f:	eb 02                	jmp    0x180001133
   180001131:	33 db                	xor    ebx,ebx
   180001133:	b9 18 00 00 00       	mov    ecx,0x18
   180001138:	48 89 1d 31 40 00 00 	mov    QWORD PTR [rip+0x4031],rbx        # 0x180005170
   18000113f:	e8 74 00 00 00       	call   0x1800011b8
   180001144:	48 8b d8             	mov    rbx,rax
   180001147:	48 85 c0             	test   rax,rax
   18000114a:	74 4a                	je     0x180001196
   18000114c:	48 8b 0d 15 40 00 00 	mov    rcx,QWORD PTR [rip+0x4015]        # 0x180005168
   180001153:	48 81 c1 60 2e c4 00 	add    rcx,0xc42e60
   18000115a:	48 89 48 08          	mov    QWORD PTR [rax+0x8],rcx
   18000115e:	4c 8b cb             	mov    r9,rbx
   180001161:	8b 01                	mov    eax,DWORD PTR [rcx]
   180001163:	ba 05 00 00 00       	mov    edx,0x5
   180001168:	89 43 10             	mov    DWORD PTR [rbx+0x10],eax
   18000116b:	41 b8 40 00 00 00    	mov    r8d,0x40
   180001171:	0f b6 41 04          	movzx  eax,BYTE PTR [rcx+0x4]
   180001175:	88 43 14             	mov    BYTE PTR [rbx+0x14],al
   180001178:	c7 44 24 48 e9 de 00 	mov    DWORD PTR [rsp+0x48],0xdee9
   18000117f:	00 
   180001180:	ff 15 7a 1e 00 00    	call   QWORD PTR [rip+0x1e7a]        # 0x180003000
   180001186:	48 8b 4b 08          	mov    rcx,QWORD PTR [rbx+0x8]
   18000118a:	8b 44 24 48          	mov    eax,DWORD PTR [rsp+0x48]
   18000118e:	89 01                	mov    DWORD PTR [rcx],eax
   180001190:	c6 41 04 00          	mov    BYTE PTR [rcx+0x4],0x0
   180001194:	eb 02                	jmp    0x180001198
   180001196:	33 db                	xor    ebx,ebx
   180001198:	48 89 1d d9 3f 00 00 	mov    QWORD PTR [rip+0x3fd9],rbx        # 0x180005178
   18000119f:	48 8b 5c 24 20       	mov    rbx,QWORD PTR [rsp+0x20]
   1800011a4:	b8 01 00 00 00       	mov    eax,0x1
   1800011a9:	48 83 c4 28          	add    rsp,0x28
   1800011ad:	c3                   	ret
   1800011ae:	b8 01 00 00 00       	mov    eax,0x1
   1800011b3:	48 83 c4 28          	add    rsp,0x28
   1800011b7:	c3                   	ret
   1800011b8:	40 53                	rex push rbx
   1800011ba:	48 83 ec 20          	sub    rsp,0x20
   1800011be:	48 8b d9             	mov    rbx,rcx
   1800011c1:	eb 0f                	jmp    0x1800011d2
   1800011c3:	48 8b cb             	mov    rcx,rbx
   1800011c6:	e8 3e 0e 00 00       	call   0x180002009
   1800011cb:	85 c0                	test   eax,eax
   1800011cd:	74 13                	je     0x1800011e2
   1800011cf:	48 8b cb             	mov    rcx,rbx
   1800011d2:	e8 38 0e 00 00       	call   0x18000200f
   1800011d7:	48 85 c0             	test   rax,rax
   1800011da:	74 e7                	je     0x1800011c3
   1800011dc:	48 83 c4 20          	add    rsp,0x20
   1800011e0:	5b                   	pop    rbx
   1800011e1:	c3                   	ret
   1800011e2:	48 83 fb ff          	cmp    rbx,0xffffffffffffffff
   1800011e6:	74 06                	je     0x1800011ee
   1800011e8:	e8 9b 04 00 00       	call   0x180001688
   1800011ed:	cc                   	int3
   1800011ee:	e8 b5 04 00 00       	call   0x1800016a8
   1800011f3:	cc                   	int3
   1800011f4:	48 83 ec 28          	sub    rsp,0x28
   1800011f8:	85 d2                	test   edx,edx
   1800011fa:	74 39                	je     0x180001235
   1800011fc:	83 ea 01             	sub    edx,0x1
   1800011ff:	74 28                	je     0x180001229
   180001201:	83 ea 01             	sub    edx,0x1
   180001204:	74 16                	je     0x18000121c
   180001206:	83 fa 01             	cmp    edx,0x1
   180001209:	74 0a                	je     0x180001215
   18000120b:	b8 01 00 00 00       	mov    eax,0x1
   180001210:	48 83 c4 28          	add    rsp,0x28
   180001214:	c3                   	ret
   180001215:	e8 66 06 00 00       	call   0x180001880
   18000121a:	eb 05                	jmp    0x180001221
   18000121c:	e8 37 06 00 00       	call   0x180001858
   180001221:	0f b6 c0             	movzx  eax,al
   180001224:	48 83 c4 28          	add    rsp,0x28
   180001228:	c3                   	ret
   180001229:	49 8b d0             	mov    rdx,r8
   18000122c:	48 83 c4 28          	add    rsp,0x28
   180001230:	e9 0f 00 00 00       	jmp    0x180001244
   180001235:	4d 85 c0             	test   r8,r8
   180001238:	0f 95 c1             	setne  cl
   18000123b:	48 83 c4 28          	add    rsp,0x28
   18000123f:	e9 18 01 00 00       	jmp    0x18000135c
   180001244:	48 89 5c 24 08       	mov    QWORD PTR [rsp+0x8],rbx
   180001249:	48 89 74 24 10       	mov    QWORD PTR [rsp+0x10],rsi
   18000124e:	48 89 7c 24 20       	mov    QWORD PTR [rsp+0x20],rdi
   180001253:	41 56                	push   r14
   180001255:	48 83 ec 20          	sub    rsp,0x20
   180001259:	48 8b f2             	mov    rsi,rdx
   18000125c:	4c 8b f1             	mov    r14,rcx
   18000125f:	33 c9                	xor    ecx,ecx
   180001261:	e8 d6 06 00 00       	call   0x18000193c
   180001266:	84 c0                	test   al,al
   180001268:	0f 84 c8 00 00 00    	je     0x180001336
   18000126e:	e8 5d 05 00 00       	call   0x1800017d0
   180001273:	8a d8                	mov    bl,al
   180001275:	88 44 24 40          	mov    BYTE PTR [rsp+0x40],al
   180001279:	40 b7 01             	mov    dil,0x1
   18000127c:	83 3d 2d 3f 00 00 00 	cmp    DWORD PTR [rip+0x3f2d],0x0        # 0x1800051b0
   180001283:	0f 85 c5 00 00 00    	jne    0x18000134e
   180001289:	c7 05 1d 3f 00 00 01 	mov    DWORD PTR [rip+0x3f1d],0x1        # 0x1800051b0
   180001290:	00 00 00 
   180001293:	e8 a8 05 00 00       	call   0x180001840
   180001298:	84 c0                	test   al,al
   18000129a:	74 4f                	je     0x1800012eb
   18000129c:	e8 a3 09 00 00       	call   0x180001c44
   1800012a1:	e8 e2 04 00 00       	call   0x180001788
   1800012a6:	e8 09 05 00 00       	call   0x1800017b4
   1800012ab:	48 8d 15 d6 1e 00 00 	lea    rdx,[rip+0x1ed6]        # 0x180003188
   1800012b2:	48 8d 0d c7 1e 00 00 	lea    rcx,[rip+0x1ec7]        # 0x180003180
   1800012b9:	e8 5d 0d 00 00       	call   0x18000201b
   1800012be:	85 c0                	test   eax,eax
   1800012c0:	75 29                	jne    0x1800012eb
   1800012c2:	e8 45 05 00 00       	call   0x18000180c
   1800012c7:	84 c0                	test   al,al
   1800012c9:	74 20                	je     0x1800012eb
   1800012cb:	48 8d 15 a6 1e 00 00 	lea    rdx,[rip+0x1ea6]        # 0x180003178
   1800012d2:	48 8d 0d 87 1e 00 00 	lea    rcx,[rip+0x1e87]        # 0x180003160
   1800012d9:	e8 37 0d 00 00       	call   0x180002015
   1800012de:	c7 05 c8 3e 00 00 02 	mov    DWORD PTR [rip+0x3ec8],0x2        # 0x1800051b0
   1800012e5:	00 00 00 
   1800012e8:	40 32 ff             	xor    dil,dil
   1800012eb:	8a cb                	mov    cl,bl
   1800012ed:	e8 aa 07 00 00       	call   0x180001a9c
   1800012f2:	40 84 ff             	test   dil,dil
   1800012f5:	75 3f                	jne    0x180001336
   1800012f7:	e8 f0 07 00 00       	call   0x180001aec
   1800012fc:	48 8b d8             	mov    rbx,rax
   1800012ff:	48 83 38 00          	cmp    QWORD PTR [rax],0x0
   180001303:	74 24                	je     0x180001329
   180001305:	48 8b c8             	mov    rcx,rax
   180001308:	e8 f7 06 00 00       	call   0x180001a04
   18000130d:	84 c0                	test   al,al
   18000130f:	74 18                	je     0x180001329
   180001311:	4c 8b c6             	mov    r8,rsi
   180001314:	ba 02 00 00 00       	mov    edx,0x2
   180001319:	49 8b ce             	mov    rcx,r14
   18000131c:	48 8b 03             	mov    rax,QWORD PTR [rbx]
   18000131f:	4c 8b 0d 12 1e 00 00 	mov    r9,QWORD PTR [rip+0x1e12]        # 0x180003138
   180001326:	41 ff d1             	call   r9
   180001329:	ff 05 51 3e 00 00    	inc    DWORD PTR [rip+0x3e51]        # 0x180005180
   18000132f:	b8 01 00 00 00       	mov    eax,0x1
   180001334:	eb 02                	jmp    0x180001338
   180001336:	33 c0                	xor    eax,eax
   180001338:	48 8b 5c 24 30       	mov    rbx,QWORD PTR [rsp+0x30]
   18000133d:	48 8b 74 24 38       	mov    rsi,QWORD PTR [rsp+0x38]
   180001342:	48 8b 7c 24 48       	mov    rdi,QWORD PTR [rsp+0x48]
   180001347:	48 83 c4 20          	add    rsp,0x20
   18000134b:	41 5e                	pop    r14
   18000134d:	c3                   	ret
   18000134e:	b9 07 00 00 00       	mov    ecx,0x7
   180001353:	e8 a4 07 00 00       	call   0x180001afc
   180001358:	90                   	nop
   180001359:	cc                   	int3
   18000135a:	cc                   	int3
   18000135b:	cc                   	int3
   18000135c:	48 89 5c 24 08       	mov    QWORD PTR [rsp+0x8],rbx
   180001361:	57                   	push   rdi
   180001362:	48 83 ec 30          	sub    rsp,0x30
   180001366:	40 8a f9             	mov    dil,cl
   180001369:	8b 05 11 3e 00 00    	mov    eax,DWORD PTR [rip+0x3e11]        # 0x180005180
   18000136f:	85 c0                	test   eax,eax
   180001371:	7f 0d                	jg     0x180001380
   180001373:	33 c0                	xor    eax,eax
   180001375:	48 8b 5c 24 40       	mov    rbx,QWORD PTR [rsp+0x40]
   18000137a:	48 83 c4 30          	add    rsp,0x30
   18000137e:	5f                   	pop    rdi
   18000137f:	c3                   	ret
   180001380:	ff c8                	dec    eax
   180001382:	89 05 f8 3d 00 00    	mov    DWORD PTR [rip+0x3df8],eax        # 0x180005180
   180001388:	e8 43 04 00 00       	call   0x1800017d0
   18000138d:	8a d8                	mov    bl,al
   18000138f:	88 44 24 20          	mov    BYTE PTR [rsp+0x20],al
   180001393:	83 3d 16 3e 00 00 02 	cmp    DWORD PTR [rip+0x3e16],0x2        # 0x1800051b0
   18000139a:	75 33                	jne    0x1800013cf
   18000139c:	e8 57 05 00 00       	call   0x1800018f8
   1800013a1:	e8 f2 03 00 00       	call   0x180001798
   1800013a6:	e8 d5 08 00 00       	call   0x180001c80
   1800013ab:	83 25 fe 3d 00 00 00 	and    DWORD PTR [rip+0x3dfe],0x0        # 0x1800051b0
   1800013b2:	8a cb                	mov    cl,bl
   1800013b4:	e8 e3 06 00 00       	call   0x180001a9c
   1800013b9:	33 d2                	xor    edx,edx
   1800013bb:	40 8a cf             	mov    cl,dil
   1800013be:	e8 fd 06 00 00       	call   0x180001ac0
   1800013c3:	0f b6 d8             	movzx  ebx,al
   1800013c6:	e8 5d 05 00 00       	call   0x180001928
   1800013cb:	8b c3                	mov    eax,ebx
   1800013cd:	eb a6                	jmp    0x180001375
   1800013cf:	b9 07 00 00 00       	mov    ecx,0x7
   1800013d4:	e8 23 07 00 00       	call   0x180001afc
   1800013d9:	90                   	nop
   1800013da:	90                   	nop
   1800013db:	cc                   	int3
   1800013dc:	48 8b c4             	mov    rax,rsp
   1800013df:	48 89 58 20          	mov    QWORD PTR [rax+0x20],rbx
   1800013e3:	4c 89 40 18          	mov    QWORD PTR [rax+0x18],r8
   1800013e7:	89 50 10             	mov    DWORD PTR [rax+0x10],edx
   1800013ea:	48 89 48 08          	mov    QWORD PTR [rax+0x8],rcx
   1800013ee:	56                   	push   rsi
   1800013ef:	57                   	push   rdi
   1800013f0:	41 56                	push   r14
   1800013f2:	48 83 ec 40          	sub    rsp,0x40
   1800013f6:	49 8b f0             	mov    rsi,r8
   1800013f9:	8b fa                	mov    edi,edx
   1800013fb:	4c 8b f1             	mov    r14,rcx
   1800013fe:	85 d2                	test   edx,edx
   180001400:	75 0f                	jne    0x180001411
   180001402:	39 15 78 3d 00 00    	cmp    DWORD PTR [rip+0x3d78],edx        # 0x180005180
   180001408:	7f 07                	jg     0x180001411
   18000140a:	33 c0                	xor    eax,eax
   18000140c:	e9 e5 00 00 00       	jmp    0x1800014f6
   180001411:	8d 42 ff             	lea    eax,[rdx-0x1]
   180001414:	83 f8 01             	cmp    eax,0x1
   180001417:	77 40                	ja     0x180001459
   180001419:	48 8b 05 90 1d 00 00 	mov    rax,QWORD PTR [rip+0x1d90]        # 0x1800031b0
   180001420:	48 85 c0             	test   rax,rax
   180001423:	75 05                	jne    0x18000142a
   180001425:	8d 58 01             	lea    ebx,[rax+0x1]
   180001428:	eb 08                	jmp    0x180001432
   18000142a:	ff 15 08 1d 00 00    	call   QWORD PTR [rip+0x1d08]        # 0x180003138
   180001430:	8b d8                	mov    ebx,eax
   180001432:	89 5c 24 30          	mov    DWORD PTR [rsp+0x30],ebx
   180001436:	85 db                	test   ebx,ebx
   180001438:	0f 84 ae 00 00 00    	je     0x1800014ec
   18000143e:	4c 8b c6             	mov    r8,rsi
   180001441:	8b d7                	mov    edx,edi
   180001443:	49 8b ce             	mov    rcx,r14
   180001446:	e8 a9 fd ff ff       	call   0x1800011f4
   18000144b:	8b d8                	mov    ebx,eax
   18000144d:	89 44 24 30          	mov    DWORD PTR [rsp+0x30],eax
   180001451:	85 c0                	test   eax,eax
   180001453:	0f 84 93 00 00 00    	je     0x1800014ec
   180001459:	4c 8b c6             	mov    r8,rsi
   18000145c:	8b d7                	mov    edx,edi
   18000145e:	49 8b ce             	mov    rcx,r14
   180001461:	e8 da fb ff ff       	call   0x180001040
   180001466:	8b d8                	mov    ebx,eax
   180001468:	89 44 24 30          	mov    DWORD PTR [rsp+0x30],eax
   18000146c:	83 ff 01             	cmp    edi,0x1
   18000146f:	75 36                	jne    0x1800014a7
   180001471:	85 c0                	test   eax,eax
   180001473:	75 32                	jne    0x1800014a7
   180001475:	4c 8b c6             	mov    r8,rsi
   180001478:	33 d2                	xor    edx,edx
   18000147a:	49 8b ce             	mov    rcx,r14
   18000147d:	e8 be fb ff ff       	call   0x180001040
   180001482:	48 85 f6             	test   rsi,rsi
   180001485:	0f 95 c1             	setne  cl
   180001488:	e8 cf fe ff ff       	call   0x18000135c
   18000148d:	48 8b 05 1c 1d 00 00 	mov    rax,QWORD PTR [rip+0x1d1c]        # 0x1800031b0
   180001494:	48 85 c0             	test   rax,rax
   180001497:	74 0e                	je     0x1800014a7
   180001499:	4c 8b c6             	mov    r8,rsi
   18000149c:	33 d2                	xor    edx,edx
   18000149e:	49 8b ce             	mov    rcx,r14
   1800014a1:	ff 15 91 1c 00 00    	call   QWORD PTR [rip+0x1c91]        # 0x180003138
   1800014a7:	85 ff                	test   edi,edi
   1800014a9:	74 05                	je     0x1800014b0
   1800014ab:	83 ff 03             	cmp    edi,0x3
   1800014ae:	75 3c                	jne    0x1800014ec
   1800014b0:	4c 8b c6             	mov    r8,rsi
   1800014b3:	8b d7                	mov    edx,edi
   1800014b5:	49 8b ce             	mov    rcx,r14
   1800014b8:	e8 37 fd ff ff       	call   0x1800011f4
   1800014bd:	8b d8                	mov    ebx,eax
   1800014bf:	89 44 24 30          	mov    DWORD PTR [rsp+0x30],eax
   1800014c3:	85 c0                	test   eax,eax
   1800014c5:	74 25                	je     0x1800014ec
   1800014c7:	48 8b 05 e2 1c 00 00 	mov    rax,QWORD PTR [rip+0x1ce2]        # 0x1800031b0
   1800014ce:	48 85 c0             	test   rax,rax
   1800014d1:	75 05                	jne    0x1800014d8
   1800014d3:	8d 58 01             	lea    ebx,[rax+0x1]
   1800014d6:	eb 10                	jmp    0x1800014e8
   1800014d8:	4c 8b c6             	mov    r8,rsi
   1800014db:	8b d7                	mov    edx,edi
   1800014dd:	49 8b ce             	mov    rcx,r14
   1800014e0:	ff 15 52 1c 00 00    	call   QWORD PTR [rip+0x1c52]        # 0x180003138
   1800014e6:	8b d8                	mov    ebx,eax
   1800014e8:	89 5c 24 30          	mov    DWORD PTR [rsp+0x30],ebx
   1800014ec:	eb 06                	jmp    0x1800014f4
   1800014ee:	33 db                	xor    ebx,ebx
   1800014f0:	89 5c 24 30          	mov    DWORD PTR [rsp+0x30],ebx
   1800014f4:	8b c3                	mov    eax,ebx
   1800014f6:	48 8b 5c 24 78       	mov    rbx,QWORD PTR [rsp+0x78]
   1800014fb:	48 83 c4 40          	add    rsp,0x40
   1800014ff:	41 5e                	pop    r14
   180001501:	5f                   	pop    rdi
   180001502:	5e                   	pop    rsi
   180001503:	c3                   	ret
   180001504:	48 89 5c 24 08       	mov    QWORD PTR [rsp+0x8],rbx
   180001509:	48 89 74 24 10       	mov    QWORD PTR [rsp+0x10],rsi
   18000150e:	57                   	push   rdi
   18000150f:	48 83 ec 20          	sub    rsp,0x20
   180001513:	49 8b f8             	mov    rdi,r8
   180001516:	8b da                	mov    ebx,edx
   180001518:	48 8b f1             	mov    rsi,rcx
   18000151b:	83 fa 01             	cmp    edx,0x1
   18000151e:	75 05                	jne    0x180001525
   180001520:	e8 b7 01 00 00       	call   0x1800016dc
   180001525:	4c 8b c7             	mov    r8,rdi
   180001528:	8b d3                	mov    edx,ebx
   18000152a:	48 8b ce             	mov    rcx,rsi
   18000152d:	48 8b 5c 24 30       	mov    rbx,QWORD PTR [rsp+0x30]
   180001532:	48 8b 74 24 38       	mov    rsi,QWORD PTR [rsp+0x38]
   180001537:	48 83 c4 20          	add    rsp,0x20
   18000153b:	5f                   	pop    rdi
   18000153c:	e9 9b fe ff ff       	jmp    0x1800013dc
   180001541:	cc                   	int3
   180001542:	cc                   	int3
   180001543:	cc                   	int3
   180001544:	40 53                	rex push rbx
   180001546:	48 83 ec 20          	sub    rsp,0x20
   18000154a:	48 8b d9             	mov    rbx,rcx
   18000154d:	48 8b c2             	mov    rax,rdx
   180001550:	48 8d 0d 69 1c 00 00 	lea    rcx,[rip+0x1c69]        # 0x1800031c0
   180001557:	0f 57 c0             	xorps  xmm0,xmm0
   18000155a:	48 89 0b             	mov    QWORD PTR [rbx],rcx
   18000155d:	48 8d 53 08          	lea    rdx,[rbx+0x8]
   180001561:	48 8d 48 08          	lea    rcx,[rax+0x8]
   180001565:	0f 11 02             	movups XMMWORD PTR [rdx],xmm0
   180001568:	e8 7e 0a 00 00       	call   0x180001feb
   18000156d:	48 8d 05 7c 1c 00 00 	lea    rax,[rip+0x1c7c]        # 0x1800031f0
   180001574:	48 89 03             	mov    QWORD PTR [rbx],rax
   180001577:	48 8b c3             	mov    rax,rbx
   18000157a:	48 83 c4 20          	add    rsp,0x20
   18000157e:	5b                   	pop    rbx
   18000157f:	c3                   	ret
   180001580:	48 83 61 10 00       	and    QWORD PTR [rcx+0x10],0x0
   180001585:	48 8d 05 74 1c 00 00 	lea    rax,[rip+0x1c74]        # 0x180003200
   18000158c:	48 89 41 08          	mov    QWORD PTR [rcx+0x8],rax
   180001590:	48 8d 05 59 1c 00 00 	lea    rax,[rip+0x1c59]        # 0x1800031f0
   180001597:	48 89 01             	mov    QWORD PTR [rcx],rax
   18000159a:	48 8b c1             	mov    rax,rcx
   18000159d:	c3                   	ret
   18000159e:	cc                   	int3
   18000159f:	cc                   	int3
   1800015a0:	40 53                	rex push rbx
   1800015a2:	48 83 ec 20          	sub    rsp,0x20
   1800015a6:	48 8b d9             	mov    rbx,rcx
   1800015a9:	48 8b c2             	mov    rax,rdx
   1800015ac:	48 8d 0d 0d 1c 00 00 	lea    rcx,[rip+0x1c0d]        # 0x1800031c0
   1800015b3:	0f 57 c0             	xorps  xmm0,xmm0
   1800015b6:	48 89 0b             	mov    QWORD PTR [rbx],rcx
   1800015b9:	48 8d 53 08          	lea    rdx,[rbx+0x8]
   1800015bd:	48 8d 48 08          	lea    rcx,[rax+0x8]
   1800015c1:	0f 11 02             	movups XMMWORD PTR [rdx],xmm0
   1800015c4:	e8 22 0a 00 00       	call   0x180001feb
   1800015c9:	48 8d 05 48 1c 00 00 	lea    rax,[rip+0x1c48]        # 0x180003218
   1800015d0:	48 89 03             	mov    QWORD PTR [rbx],rax
   1800015d3:	48 8b c3             	mov    rax,rbx
   1800015d6:	48 83 c4 20          	add    rsp,0x20
   1800015da:	5b                   	pop    rbx
   1800015db:	c3                   	ret
   1800015dc:	48 83 61 10 00       	and    QWORD PTR [rcx+0x10],0x0
   1800015e1:	48 8d 05 40 1c 00 00 	lea    rax,[rip+0x1c40]        # 0x180003228
   1800015e8:	48 89 41 08          	mov    QWORD PTR [rcx+0x8],rax
   1800015ec:	48 8d 05 25 1c 00 00 	lea    rax,[rip+0x1c25]        # 0x180003218
   1800015f3:	48 89 01             	mov    QWORD PTR [rcx],rax
   1800015f6:	48 8b c1             	mov    rax,rcx
   1800015f9:	c3                   	ret
   1800015fa:	cc                   	int3
   1800015fb:	cc                   	int3
   1800015fc:	40 53                	rex push rbx
   1800015fe:	48 83 ec 20          	sub    rsp,0x20
   180001602:	48 8b d9             	mov    rbx,rcx
   180001605:	48 8b c2             	mov    rax,rdx
   180001608:	48 8d 0d b1 1b 00 00 	lea    rcx,[rip+0x1bb1]        # 0x1800031c0
   18000160f:	0f 57 c0             	xorps  xmm0,xmm0
   180001612:	48 89 0b             	mov    QWORD PTR [rbx],rcx
   180001615:	48 8d 53 08          	lea    rdx,[rbx+0x8]
   180001619:	48 8d 48 08          	lea    rcx,[rax+0x8]
   18000161d:	0f 11 02             	movups XMMWORD PTR [rdx],xmm0
   180001620:	e8 c6 09 00 00       	call   0x180001feb
   180001625:	48 8b c3             	mov    rax,rbx
   180001628:	48 83 c4 20          	add    rsp,0x20
   18000162c:	5b                   	pop    rbx
   18000162d:	c3                   	ret
   18000162e:	cc                   	int3
   18000162f:	cc                   	int3
   180001630:	48 8d 05 89 1b 00 00 	lea    rax,[rip+0x1b89]        # 0x1800031c0
   180001637:	48 89 01             	mov    QWORD PTR [rcx],rax
   18000163a:	48 83 c1 08          	add    rcx,0x8
   18000163e:	e9 ae 09 00 00       	jmp    0x180001ff1
   180001643:	cc                   	int3
   180001644:	48 89 5c 24 08       	mov    QWORD PTR [rsp+0x8],rbx
   180001649:	57                   	push   rdi
   18000164a:	48 83 ec 20          	sub    rsp,0x20
   18000164e:	48 8d 05 6b 1b 00 00 	lea    rax,[rip+0x1b6b]        # 0x1800031c0
   180001655:	48 8b f9             	mov    rdi,rcx
   180001658:	48 89 01             	mov    QWORD PTR [rcx],rax
   18000165b:	8b da                	mov    ebx,edx
   18000165d:	48 83 c1 08          	add    rcx,0x8
   180001661:	e8 8b 09 00 00       	call   0x180001ff1
   180001666:	f6 c3 01             	test   bl,0x1
   180001669:	74 0d                	je     0x180001678
   18000166b:	ba 18 00 00 00       	mov    edx,0x18
   180001670:	48 8b cf             	mov    rcx,rdi
   180001673:	e8 48 06 00 00       	call   0x180001cc0
   180001678:	48 8b 5c 24 30       	mov    rbx,QWORD PTR [rsp+0x30]
   18000167d:	48 8b c7             	mov    rax,rdi
   180001680:	48 83 c4 20          	add    rsp,0x20
   180001684:	5f                   	pop    rdi
   180001685:	c3                   	ret
   180001686:	cc                   	int3
   180001687:	cc                   	int3
   180001688:	48 83 ec 48          	sub    rsp,0x48
   18000168c:	48 8d 4c 24 20       	lea    rcx,[rsp+0x20]
   180001691:	e8 ea fe ff ff       	call   0x180001580
   180001696:	48 8d 15 3b 24 00 00 	lea    rdx,[rip+0x243b]        # 0x180003ad8
   18000169d:	48 8d 4c 24 20       	lea    rcx,[rsp+0x20]
   1800016a2:	e8 50 09 00 00       	call   0x180001ff7
   1800016a7:	cc                   	int3
   1800016a8:	48 83 ec 48          	sub    rsp,0x48
   1800016ac:	48 8d 4c 24 20       	lea    rcx,[rsp+0x20]
   1800016b1:	e8 26 ff ff ff       	call   0x1800015dc
   1800016b6:	48 8d 15 a3 24 00 00 	lea    rdx,[rip+0x24a3]        # 0x180003b60
   1800016bd:	48 8d 4c 24 20       	lea    rcx,[rsp+0x20]
   1800016c2:	e8 30 09 00 00       	call   0x180001ff7
   1800016c7:	cc                   	int3
   1800016c8:	48 83 79 08 00       	cmp    QWORD PTR [rcx+0x8],0x0
   1800016cd:	48 8d 05 fc 1a 00 00 	lea    rax,[rip+0x1afc]        # 0x1800031d0
   1800016d4:	48 0f 45 41 08       	cmovne rax,QWORD PTR [rcx+0x8]
   1800016d9:	c3                   	ret
   1800016da:	cc                   	int3
   1800016db:	cc                   	int3
   1800016dc:	48 89 5c 24 18       	mov    QWORD PTR [rsp+0x18],rbx
   1800016e1:	55                   	push   rbp
   1800016e2:	48 8b ec             	mov    rbp,rsp
   1800016e5:	48 83 ec 30          	sub    rsp,0x30
   1800016e9:	48 8b 05 50 39 00 00 	mov    rax,QWORD PTR [rip+0x3950]        # 0x180005040
   1800016f0:	48 bb 32 a2 df 2d 99 	movabs rbx,0x2b992ddfa232
   1800016f7:	2b 00 00 
   1800016fa:	48 3b c3             	cmp    rax,rbx
   1800016fd:	75 74                	jne    0x180001773
   1800016ff:	48 83 65 10 00       	and    QWORD PTR [rbp+0x10],0x0
   180001704:	48 8d 4d 10          	lea    rcx,[rbp+0x10]
   180001708:	ff 15 1a 19 00 00    	call   QWORD PTR [rip+0x191a]        # 0x180003028
   18000170e:	48 8b 45 10          	mov    rax,QWORD PTR [rbp+0x10]
   180001712:	48 89 45 f0          	mov    QWORD PTR [rbp-0x10],rax
   180001716:	ff 15 04 19 00 00    	call   QWORD PTR [rip+0x1904]        # 0x180003020
   18000171c:	8b c0                	mov    eax,eax
   18000171e:	48 31 45 f0          	xor    QWORD PTR [rbp-0x10],rax
   180001722:	ff 15 f0 18 00 00    	call   QWORD PTR [rip+0x18f0]        # 0x180003018
   180001728:	8b c0                	mov    eax,eax
   18000172a:	48 8d 4d 18          	lea    rcx,[rbp+0x18]
   18000172e:	48 31 45 f0          	xor    QWORD PTR [rbp-0x10],rax
   180001732:	ff 15 38 19 00 00    	call   QWORD PTR [rip+0x1938]        # 0x180003070
   180001738:	8b 45 18             	mov    eax,DWORD PTR [rbp+0x18]
   18000173b:	48 8d 4d f0          	lea    rcx,[rbp-0x10]
   18000173f:	48 c1 e0 20          	shl    rax,0x20
   180001743:	48 33 45 18          	xor    rax,QWORD PTR [rbp+0x18]
   180001747:	48 33 45 f0          	xor    rax,QWORD PTR [rbp-0x10]
   18000174b:	48 33 c1             	xor    rax,rcx
   18000174e:	48 b9 ff ff ff ff ff 	movabs rcx,0xffffffffffff
   180001755:	ff 00 00 
   180001758:	48 23 c1             	and    rax,rcx
   18000175b:	48 b9 33 a2 df 2d 99 	movabs rcx,0x2b992ddfa233
   180001762:	2b 00 00 
   180001765:	48 3b c3             	cmp    rax,rbx
   180001768:	48 0f 44 c1          	cmove  rax,rcx
   18000176c:	48 89 05 cd 38 00 00 	mov    QWORD PTR [rip+0x38cd],rax        # 0x180005040
   180001773:	48 8b 5c 24 50       	mov    rbx,QWORD PTR [rsp+0x50]
   180001778:	48 f7 d0             	not    rax
   18000177b:	48 89 05 fe 38 00 00 	mov    QWORD PTR [rip+0x38fe],rax        # 0x180005080
   180001782:	48 83 c4 30          	add    rsp,0x30
   180001786:	5d                   	pop    rbp
   180001787:	c3                   	ret
   180001788:	48 8d 0d 01 3a 00 00 	lea    rcx,[rip+0x3a01]        # 0x180005190
   18000178f:	48 ff 25 9a 18 00 00 	rex.W jmp QWORD PTR [rip+0x189a]        # 0x180003030
   180001796:	cc                   	int3
   180001797:	cc                   	int3
   180001798:	48 8d 0d f1 39 00 00 	lea    rcx,[rip+0x39f1]        # 0x180005190
   18000179f:	e9 59 08 00 00       	jmp    0x180001ffd
   1800017a4:	48 8d 05 f5 39 00 00 	lea    rax,[rip+0x39f5]        # 0x1800051a0
   1800017ab:	c3                   	ret
   1800017ac:	48 8d 05 f5 39 00 00 	lea    rax,[rip+0x39f5]        # 0x1800051a8
   1800017b3:	c3                   	ret
   1800017b4:	48 83 ec 28          	sub    rsp,0x28
   1800017b8:	e8 e7 ff ff ff       	call   0x1800017a4
   1800017bd:	48 83 08 24          	or     QWORD PTR [rax],0x24
   1800017c1:	e8 e6 ff ff ff       	call   0x1800017ac
   1800017c6:	48 83 08 02          	or     QWORD PTR [rax],0x2
   1800017ca:	48 83 c4 28          	add    rsp,0x28
   1800017ce:	c3                   	ret
   1800017cf:	cc                   	int3
   1800017d0:	48 83 ec 28          	sub    rsp,0x28
   1800017d4:	e8 ef 07 00 00       	call   0x180001fc8
   1800017d9:	85 c0                	test   eax,eax
   1800017db:	74 21                	je     0x1800017fe
   1800017dd:	65 48 8b 04 25 30 00 	mov    rax,QWORD PTR gs:0x30
   1800017e4:	00 00 
   1800017e6:	48 8b 48 08          	mov    rcx,QWORD PTR [rax+0x8]
   1800017ea:	eb 05                	jmp    0x1800017f1
   1800017ec:	48 3b c8             	cmp    rcx,rax
   1800017ef:	74 14                	je     0x180001805
   1800017f1:	33 c0                	xor    eax,eax
   1800017f3:	f0 48 0f b1 0d bc 39 	lock cmpxchg QWORD PTR [rip+0x39bc],rcx        # 0x1800051b8
   1800017fa:	00 00 
   1800017fc:	75 ee                	jne    0x1800017ec
   1800017fe:	32 c0                	xor    al,al
   180001800:	48 83 c4 28          	add    rsp,0x28
   180001804:	c3                   	ret
   180001805:	b0 01                	mov    al,0x1
   180001807:	eb f7                	jmp    0x180001800
   180001809:	cc                   	int3
   18000180a:	cc                   	int3
   18000180b:	cc                   	int3
   18000180c:	48 83 ec 28          	sub    rsp,0x28
   180001810:	e8 b3 07 00 00       	call   0x180001fc8
   180001815:	85 c0                	test   eax,eax
   180001817:	74 07                	je     0x180001820
   180001819:	e8 d6 04 00 00       	call   0x180001cf4
   18000181e:	eb 19                	jmp    0x180001839
   180001820:	e8 9b 07 00 00       	call   0x180001fc0
   180001825:	8b c8                	mov    ecx,eax
   180001827:	e8 fb 07 00 00       	call   0x180002027
   18000182c:	85 c0                	test   eax,eax
   18000182e:	74 04                	je     0x180001834
   180001830:	32 c0                	xor    al,al
   180001832:	eb 07                	jmp    0x18000183b
   180001834:	e8 f4 07 00 00       	call   0x18000202d
   180001839:	b0 01                	mov    al,0x1
   18000183b:	48 83 c4 28          	add    rsp,0x28
   18000183f:	c3                   	ret
   180001840:	48 83 ec 28          	sub    rsp,0x28
   180001844:	33 c9                	xor    ecx,ecx
   180001846:	e8 2d 01 00 00       	call   0x180001978
   18000184b:	84 c0                	test   al,al
   18000184d:	0f 95 c0             	setne  al
   180001850:	48 83 c4 28          	add    rsp,0x28
   180001854:	c3                   	ret
   180001855:	cc                   	int3
   180001856:	cc                   	int3
   180001857:	cc                   	int3
   180001858:	48 83 ec 28          	sub    rsp,0x28
   18000185c:	e8 eb 07 00 00       	call   0x18000204c
   180001861:	84 c0                	test   al,al
   180001863:	75 04                	jne    0x180001869
   180001865:	32 c0                	xor    al,al
   180001867:	eb 12                	jmp    0x18000187b
   180001869:	e8 de 07 00 00       	call   0x18000204c
   18000186e:	84 c0                	test   al,al
   180001870:	75 07                	jne    0x180001879
   180001872:	e8 d5 07 00 00       	call   0x18000204c
   180001877:	eb ec                	jmp    0x180001865
   180001879:	b0 01                	mov    al,0x1
   18000187b:	48 83 c4 28          	add    rsp,0x28
   18000187f:	c3                   	ret
   180001880:	48 83 ec 28          	sub    rsp,0x28
   180001884:	e8 c3 07 00 00       	call   0x18000204c
   180001889:	e8 be 07 00 00       	call   0x18000204c
   18000188e:	b0 01                	mov    al,0x1
   180001890:	48 83 c4 28          	add    rsp,0x28
   180001894:	c3                   	ret
   180001895:	cc                   	int3
   180001896:	cc                   	int3
   180001897:	cc                   	int3
   180001898:	48 89 5c 24 08       	mov    QWORD PTR [rsp+0x8],rbx
   18000189d:	48 89 6c 24 10       	mov    QWORD PTR [rsp+0x10],rbp
   1800018a2:	48 89 74 24 18       	mov    QWORD PTR [rsp+0x18],rsi
   1800018a7:	57                   	push   rdi
   1800018a8:	48 83 ec 20          	sub    rsp,0x20
   1800018ac:	49 8b f9             	mov    rdi,r9
   1800018af:	49 8b f0             	mov    rsi,r8
   1800018b2:	8b da                	mov    ebx,edx
   1800018b4:	48 8b e9             	mov    rbp,rcx
   1800018b7:	e8 0c 07 00 00       	call   0x180001fc8
   1800018bc:	85 c0                	test   eax,eax
   1800018be:	75 16                	jne    0x1800018d6
   1800018c0:	83 fb 01             	cmp    ebx,0x1
   1800018c3:	75 11                	jne    0x1800018d6
   1800018c5:	4c 8b c6             	mov    r8,rsi
   1800018c8:	33 d2                	xor    edx,edx
   1800018ca:	48 8b cd             	mov    rcx,rbp
   1800018cd:	48 8b c7             	mov    rax,rdi
   1800018d0:	ff 15 62 18 00 00    	call   QWORD PTR [rip+0x1862]        # 0x180003138
   1800018d6:	48 8b 54 24 58       	mov    rdx,QWORD PTR [rsp+0x58]
   1800018db:	8b 4c 24 50          	mov    ecx,DWORD PTR [rsp+0x50]
   1800018df:	48 8b 5c 24 30       	mov    rbx,QWORD PTR [rsp+0x30]
   1800018e4:	48 8b 6c 24 38       	mov    rbp,QWORD PTR [rsp+0x38]
   1800018e9:	48 8b 74 24 40       	mov    rsi,QWORD PTR [rsp+0x40]
   1800018ee:	48 83 c4 20          	add    rsp,0x20
   1800018f2:	5f                   	pop    rdi
   1800018f3:	e9 29 07 00 00       	jmp    0x180002021
   1800018f8:	48 83 ec 28          	sub    rsp,0x28
   1800018fc:	e8 c7 06 00 00       	call   0x180001fc8
   180001901:	85 c0                	test   eax,eax
   180001903:	74 10                	je     0x180001915
   180001905:	48 8d 0d bc 38 00 00 	lea    rcx,[rip+0x38bc]        # 0x1800051c8
   18000190c:	48 83 c4 28          	add    rsp,0x28
   180001910:	e9 24 07 00 00       	jmp    0x180002039
   180001915:	e8 36 07 00 00       	call   0x180002050
   18000191a:	85 c0                	test   eax,eax
   18000191c:	75 05                	jne    0x180001923
   18000191e:	e8 1c 07 00 00       	call   0x18000203f
   180001923:	48 83 c4 28          	add    rsp,0x28
   180001927:	c3                   	ret
   180001928:	48 83 ec 28          	sub    rsp,0x28
   18000192c:	33 c9                	xor    ecx,ecx
   18000192e:	e8 19 07 00 00       	call   0x18000204c
   180001933:	48 83 c4 28          	add    rsp,0x28
   180001937:	e9 10 07 00 00       	jmp    0x18000204c
   18000193c:	48 83 ec 28          	sub    rsp,0x28
   180001940:	85 c9                	test   ecx,ecx
   180001942:	75 07                	jne    0x18000194b
   180001944:	c6 05 75 38 00 00 01 	mov    BYTE PTR [rip+0x3875],0x1        # 0x1800051c0
   18000194b:	e8 a4 03 00 00       	call   0x180001cf4
   180001950:	e8 f7 06 00 00       	call   0x18000204c
   180001955:	84 c0                	test   al,al
   180001957:	75 04                	jne    0x18000195d
   180001959:	32 c0                	xor    al,al
   18000195b:	eb 14                	jmp    0x180001971
   18000195d:	e8 ea 06 00 00       	call   0x18000204c
   180001962:	84 c0                	test   al,al
   180001964:	75 09                	jne    0x18000196f
   180001966:	33 c9                	xor    ecx,ecx
   180001968:	e8 df 06 00 00       	call   0x18000204c
   18000196d:	eb ea                	jmp    0x180001959
   18000196f:	b0 01                	mov    al,0x1
   180001971:	48 83 c4 28          	add    rsp,0x28
   180001975:	c3                   	ret
   180001976:	cc                   	int3
   180001977:	cc                   	int3
   180001978:	40 53                	rex push rbx
   18000197a:	48 83 ec 20          	sub    rsp,0x20
   18000197e:	80 3d 3c 38 00 00 00 	cmp    BYTE PTR [rip+0x383c],0x0        # 0x1800051c1
   180001985:	8b d9                	mov    ebx,ecx
   180001987:	75 67                	jne    0x1800019f0
   180001989:	83 f9 01             	cmp    ecx,0x1
   18000198c:	77 6a                	ja     0x1800019f8
   18000198e:	e8 35 06 00 00       	call   0x180001fc8
   180001993:	85 c0                	test   eax,eax
   180001995:	74 28                	je     0x1800019bf
   180001997:	85 db                	test   ebx,ebx
   180001999:	75 24                	jne    0x1800019bf
   18000199b:	48 8d 0d 26 38 00 00 	lea    rcx,[rip+0x3826]        # 0x1800051c8
   1800019a2:	e8 8c 06 00 00       	call   0x180002033
   1800019a7:	85 c0                	test   eax,eax
   1800019a9:	75 10                	jne    0x1800019bb
   1800019ab:	48 8d 0d 2e 38 00 00 	lea    rcx,[rip+0x382e]        # 0x1800051e0
   1800019b2:	e8 7c 06 00 00       	call   0x180002033
   1800019b7:	85 c0                	test   eax,eax
   1800019b9:	74 2e                	je     0x1800019e9
   1800019bb:	32 c0                	xor    al,al
   1800019bd:	eb 33                	jmp    0x1800019f2
   1800019bf:	66 0f 6f 05 79 18 00 	movdqa xmm0,XMMWORD PTR [rip+0x1879]        # 0x180003240
   1800019c6:	00 
   1800019c7:	48 83 c8 ff          	or     rax,0xffffffffffffffff
   1800019cb:	f3 0f 7f 05 f5 37 00 	movdqu XMMWORD PTR [rip+0x37f5],xmm0        # 0x1800051c8
   1800019d2:	00 
   1800019d3:	48 89 05 fe 37 00 00 	mov    QWORD PTR [rip+0x37fe],rax        # 0x1800051d8
   1800019da:	f3 0f 7f 05 fe 37 00 	movdqu XMMWORD PTR [rip+0x37fe],xmm0        # 0x1800051e0
   1800019e1:	00 
   1800019e2:	48 89 05 07 38 00 00 	mov    QWORD PTR [rip+0x3807],rax        # 0x1800051f0
   1800019e9:	c6 05 d1 37 00 00 01 	mov    BYTE PTR [rip+0x37d1],0x1        # 0x1800051c1
   1800019f0:	b0 01                	mov    al,0x1
   1800019f2:	48 83 c4 20          	add    rsp,0x20
   1800019f6:	5b                   	pop    rbx
   1800019f7:	c3                   	ret
   1800019f8:	b9 05 00 00 00       	mov    ecx,0x5
   1800019fd:	e8 fa 00 00 00       	call   0x180001afc
   180001a02:	cc                   	int3
   180001a03:	cc                   	int3
   180001a04:	48 83 ec 18          	sub    rsp,0x18
   180001a08:	4c 8b c1             	mov    r8,rcx
   180001a0b:	b8 4d 5a 00 00       	mov    eax,0x5a4d
   180001a10:	66 39 05 e9 e5 ff ff 	cmp    WORD PTR [rip+0xffffffffffffe5e9],ax        # 0x180000000
   180001a17:	75 78                	jne    0x180001a91
   180001a19:	48 63 0d 1c e6 ff ff 	movsxd rcx,DWORD PTR [rip+0xffffffffffffe61c]        # 0x18000003c
   180001a20:	48 8d 15 d9 e5 ff ff 	lea    rdx,[rip+0xffffffffffffe5d9]        # 0x180000000
   180001a27:	48 03 ca             	add    rcx,rdx
   180001a2a:	81 39 50 45 00 00    	cmp    DWORD PTR [rcx],0x4550
   180001a30:	75 5f                	jne    0x180001a91
   180001a32:	b8 0b 02 00 00       	mov    eax,0x20b
   180001a37:	66 39 41 18          	cmp    WORD PTR [rcx+0x18],ax
   180001a3b:	75 54                	jne    0x180001a91
   180001a3d:	4c 2b c2             	sub    r8,rdx
   180001a40:	0f b7 51 14          	movzx  edx,WORD PTR [rcx+0x14]
   180001a44:	48 83 c2 18          	add    rdx,0x18
   180001a48:	48 03 d1             	add    rdx,rcx
   180001a4b:	0f b7 41 06          	movzx  eax,WORD PTR [rcx+0x6]
   180001a4f:	48 8d 0c 80          	lea    rcx,[rax+rax*4]
   180001a53:	4c 8d 0c ca          	lea    r9,[rdx+rcx*8]
   180001a57:	48 89 14 24          	mov    QWORD PTR [rsp],rdx
   180001a5b:	49 3b d1             	cmp    rdx,r9
   180001a5e:	74 18                	je     0x180001a78
   180001a60:	8b 4a 0c             	mov    ecx,DWORD PTR [rdx+0xc]
   180001a63:	4c 3b c1             	cmp    r8,rcx
   180001a66:	72 0a                	jb     0x180001a72
   180001a68:	8b 42 08             	mov    eax,DWORD PTR [rdx+0x8]
   180001a6b:	03 c1                	add    eax,ecx
   180001a6d:	4c 3b c0             	cmp    r8,rax
   180001a70:	72 08                	jb     0x180001a7a
   180001a72:	48 83 c2 28          	add    rdx,0x28
   180001a76:	eb df                	jmp    0x180001a57
   180001a78:	33 d2                	xor    edx,edx
   180001a7a:	48 85 d2             	test   rdx,rdx
   180001a7d:	75 04                	jne    0x180001a83
   180001a7f:	32 c0                	xor    al,al
   180001a81:	eb 14                	jmp    0x180001a97
   180001a83:	83 7a 24 00          	cmp    DWORD PTR [rdx+0x24],0x0
   180001a87:	7d 04                	jge    0x180001a8d
   180001a89:	32 c0                	xor    al,al
   180001a8b:	eb 0a                	jmp    0x180001a97
   180001a8d:	b0 01                	mov    al,0x1
   180001a8f:	eb 06                	jmp    0x180001a97
   180001a91:	32 c0                	xor    al,al
   180001a93:	eb 02                	jmp    0x180001a97
   180001a95:	32 c0                	xor    al,al
   180001a97:	48 83 c4 18          	add    rsp,0x18
   180001a9b:	c3                   	ret
   180001a9c:	40 53                	rex push rbx
   180001a9e:	48 83 ec 20          	sub    rsp,0x20
   180001aa2:	8a d9                	mov    bl,cl
   180001aa4:	e8 1f 05 00 00       	call   0x180001fc8
   180001aa9:	33 d2                	xor    edx,edx
   180001aab:	85 c0                	test   eax,eax
   180001aad:	74 0b                	je     0x180001aba
   180001aaf:	84 db                	test   bl,bl
   180001ab1:	75 07                	jne    0x180001aba
   180001ab3:	48 87 15 fe 36 00 00 	xchg   QWORD PTR [rip+0x36fe],rdx        # 0x1800051b8
   180001aba:	48 83 c4 20          	add    rsp,0x20
   180001abe:	5b                   	pop    rbx
   180001abf:	c3                   	ret
   180001ac0:	40 53                	rex push rbx
   180001ac2:	48 83 ec 20          	sub    rsp,0x20
   180001ac6:	80 3d f3 36 00 00 00 	cmp    BYTE PTR [rip+0x36f3],0x0        # 0x1800051c0
   180001acd:	8a d9                	mov    bl,cl
   180001acf:	74 04                	je     0x180001ad5
   180001ad1:	84 d2                	test   dl,dl
   180001ad3:	75 0c                	jne    0x180001ae1
   180001ad5:	e8 72 05 00 00       	call   0x18000204c
   180001ada:	8a cb                	mov    cl,bl
   180001adc:	e8 6b 05 00 00       	call   0x18000204c
   180001ae1:	b0 01                	mov    al,0x1
   180001ae3:	48 83 c4 20          	add    rsp,0x20
   180001ae7:	5b                   	pop    rbx
   180001ae8:	c3                   	ret
   180001ae9:	cc                   	int3
   180001aea:	cc                   	int3
   180001aeb:	cc                   	int3
   180001aec:	48 8d 05 15 37 00 00 	lea    rax,[rip+0x3715]        # 0x180005208
   180001af3:	c3                   	ret
   180001af4:	83 25 fd 36 00 00 00 	and    DWORD PTR [rip+0x36fd],0x0        # 0x1800051f8
   180001afb:	c3                   	ret
   180001afc:	48 89 5c 24 08       	mov    QWORD PTR [rsp+0x8],rbx
   180001b01:	55                   	push   rbp
   180001b02:	48 8d ac 24 40 fb ff 	lea    rbp,[rsp-0x4c0]
   180001b09:	ff 
   180001b0a:	48 81 ec c0 05 00 00 	sub    rsp,0x5c0
   180001b11:	8b d9                	mov    ebx,ecx
   180001b13:	b9 17 00 00 00       	mov    ecx,0x17
   180001b18:	ff 15 42 15 00 00    	call   QWORD PTR [rip+0x1542]        # 0x180003060
   180001b1e:	85 c0                	test   eax,eax
   180001b20:	74 04                	je     0x180001b26
   180001b22:	8b cb                	mov    ecx,ebx
   180001b24:	cd 29                	int    0x29
   180001b26:	b9 03 00 00 00       	mov    ecx,0x3
   180001b2b:	e8 c4 ff ff ff       	call   0x180001af4
   180001b30:	33 d2                	xor    edx,edx
   180001b32:	48 8d 4d f0          	lea    rcx,[rbp-0x10]
   180001b36:	41 b8 d0 04 00 00    	mov    r8d,0x4d0
   180001b3c:	e8 c2 04 00 00       	call   0x180002003
   180001b41:	48 8d 4d f0          	lea    rcx,[rbp-0x10]
   180001b45:	ff 15 ed 14 00 00    	call   QWORD PTR [rip+0x14ed]        # 0x180003038
   180001b4b:	48 8b 9d e8 00 00 00 	mov    rbx,QWORD PTR [rbp+0xe8]
   180001b52:	48 8d 95 d8 04 00 00 	lea    rdx,[rbp+0x4d8]
   180001b59:	48 8b cb             	mov    rcx,rbx
   180001b5c:	45 33 c0             	xor    r8d,r8d
   180001b5f:	ff 15 db 14 00 00    	call   QWORD PTR [rip+0x14db]        # 0x180003040
   180001b65:	48 85 c0             	test   rax,rax
   180001b68:	74 3c                	je     0x180001ba6
   180001b6a:	48 83 64 24 38 00    	and    QWORD PTR [rsp+0x38],0x0
   180001b70:	48 8d 8d e0 04 00 00 	lea    rcx,[rbp+0x4e0]
   180001b77:	48 8b 95 d8 04 00 00 	mov    rdx,QWORD PTR [rbp+0x4d8]
   180001b7e:	4c 8b c8             	mov    r9,rax
   180001b81:	48 89 4c 24 30       	mov    QWORD PTR [rsp+0x30],rcx
   180001b86:	4c 8b c3             	mov    r8,rbx
   180001b89:	48 8d 8d e8 04 00 00 	lea    rcx,[rbp+0x4e8]
   180001b90:	48 89 4c 24 28       	mov    QWORD PTR [rsp+0x28],rcx
   180001b95:	48 8d 4d f0          	lea    rcx,[rbp-0x10]
   180001b99:	48 89 4c 24 20       	mov    QWORD PTR [rsp+0x20],rcx
   180001b9e:	33 c9                	xor    ecx,ecx
   180001ba0:	ff 15 a2 14 00 00    	call   QWORD PTR [rip+0x14a2]        # 0x180003048
   180001ba6:	48 8b 85 c8 04 00 00 	mov    rax,QWORD PTR [rbp+0x4c8]
   180001bad:	48 8d 4c 24 50       	lea    rcx,[rsp+0x50]
   180001bb2:	48 89 85 e8 00 00 00 	mov    QWORD PTR [rbp+0xe8],rax
   180001bb9:	33 d2                	xor    edx,edx
   180001bbb:	48 8d 85 c8 04 00 00 	lea    rax,[rbp+0x4c8]
   180001bc2:	41 b8 98 00 00 00    	mov    r8d,0x98
   180001bc8:	48 83 c0 08          	add    rax,0x8
   180001bcc:	48 89 85 88 00 00 00 	mov    QWORD PTR [rbp+0x88],rax
   180001bd3:	e8 2b 04 00 00       	call   0x180002003
   180001bd8:	48 8b 85 c8 04 00 00 	mov    rax,QWORD PTR [rbp+0x4c8]
   180001bdf:	48 89 44 24 60       	mov    QWORD PTR [rsp+0x60],rax
   180001be4:	c7 44 24 50 15 00 00 	mov    DWORD PTR [rsp+0x50],0x40000015
   180001beb:	40 
   180001bec:	c7 44 24 54 01 00 00 	mov    DWORD PTR [rsp+0x54],0x1
   180001bf3:	00 
   180001bf4:	ff 15 56 14 00 00    	call   QWORD PTR [rip+0x1456]        # 0x180003050
   180001bfa:	8b d8                	mov    ebx,eax
   180001bfc:	33 c9                	xor    ecx,ecx
   180001bfe:	48 8d 44 24 50       	lea    rax,[rsp+0x50]
   180001c03:	48 89 44 24 40       	mov    QWORD PTR [rsp+0x40],rax
   180001c08:	48 8d 45 f0          	lea    rax,[rbp-0x10]
   180001c0c:	48 89 44 24 48       	mov    QWORD PTR [rsp+0x48],rax
   180001c11:	ff 15 51 14 00 00    	call   QWORD PTR [rip+0x1451]        # 0x180003068
   180001c17:	48 8d 4c 24 40       	lea    rcx,[rsp+0x40]
   180001c1c:	ff 15 36 14 00 00    	call   QWORD PTR [rip+0x1436]        # 0x180003058
   180001c22:	85 c0                	test   eax,eax
   180001c24:	75 0d                	jne    0x180001c33
   180001c26:	83 fb 01             	cmp    ebx,0x1
   180001c29:	74 08                	je     0x180001c33
   180001c2b:	8d 48 03             	lea    ecx,[rax+0x3]
   180001c2e:	e8 c1 fe ff ff       	call   0x180001af4
   180001c33:	48 8b 9c 24 d0 05 00 	mov    rbx,QWORD PTR [rsp+0x5d0]
   180001c3a:	00 
   180001c3b:	48 81 c4 c0 05 00 00 	add    rsp,0x5c0
   180001c42:	5d                   	pop    rbp
   180001c43:	c3                   	ret
   180001c44:	48 89 5c 24 08       	mov    QWORD PTR [rsp+0x8],rbx
   180001c49:	57                   	push   rdi
   180001c4a:	48 83 ec 20          	sub    rsp,0x20
   180001c4e:	48 8d 1d cb 1c 00 00 	lea    rbx,[rip+0x1ccb]        # 0x180003920
   180001c55:	48 8d 3d c4 1c 00 00 	lea    rdi,[rip+0x1cc4]        # 0x180003920
   180001c5c:	eb 12                	jmp    0x180001c70
   180001c5e:	48 8b 03             	mov    rax,QWORD PTR [rbx]
   180001c61:	48 85 c0             	test   rax,rax
   180001c64:	74 06                	je     0x180001c6c
   180001c66:	ff 15 cc 14 00 00    	call   QWORD PTR [rip+0x14cc]        # 0x180003138
   180001c6c:	48 83 c3 08          	add    rbx,0x8
   180001c70:	48 3b df             	cmp    rbx,rdi
   180001c73:	72 e9                	jb     0x180001c5e
   180001c75:	48 8b 5c 24 30       	mov    rbx,QWORD PTR [rsp+0x30]
   180001c7a:	48 83 c4 20          	add    rsp,0x20
   180001c7e:	5f                   	pop    rdi
   180001c7f:	c3                   	ret
   180001c80:	48 89 5c 24 08       	mov    QWORD PTR [rsp+0x8],rbx
   180001c85:	57                   	push   rdi
   180001c86:	48 83 ec 20          	sub    rsp,0x20
   180001c8a:	48 8d 1d 9f 1c 00 00 	lea    rbx,[rip+0x1c9f]        # 0x180003930
   180001c91:	48 8d 3d 98 1c 00 00 	lea    rdi,[rip+0x1c98]        # 0x180003930
   180001c98:	eb 12                	jmp    0x180001cac
   180001c9a:	48 8b 03             	mov    rax,QWORD PTR [rbx]
   180001c9d:	48 85 c0             	test   rax,rax
   180001ca0:	74 06                	je     0x180001ca8
   180001ca2:	ff 15 90 14 00 00    	call   QWORD PTR [rip+0x1490]        # 0x180003138
   180001ca8:	48 83 c3 08          	add    rbx,0x8
   180001cac:	48 3b df             	cmp    rbx,rdi
   180001caf:	72 e9                	jb     0x180001c9a
   180001cb1:	48 8b 5c 24 30       	mov    rbx,QWORD PTR [rsp+0x30]
   180001cb6:	48 83 c4 20          	add    rsp,0x20
   180001cba:	5f                   	pop    rdi
   180001cbb:	c3                   	ret
   180001cbc:	c2 00 00             	ret    0x0
   180001cbf:	cc                   	int3
   180001cc0:	e9 1b 03 00 00       	jmp    0x180001fe0
   180001cc5:	cc                   	int3
   180001cc6:	cc                   	int3
   180001cc7:	cc                   	int3
   180001cc8:	40 53                	rex push rbx
   180001cca:	48 83 ec 20          	sub    rsp,0x20
   180001cce:	48 8d 05 83 15 00 00 	lea    rax,[rip+0x1583]        # 0x180003258
   180001cd5:	48 8b d9             	mov    rbx,rcx
   180001cd8:	48 89 01             	mov    QWORD PTR [rcx],rax
   180001cdb:	f6 c2 01             	test   dl,0x1
   180001cde:	74 0a                	je     0x180001cea
   180001ce0:	ba 18 00 00 00       	mov    edx,0x18
   180001ce5:	e8 d6 ff ff ff       	call   0x180001cc0
   180001cea:	48 8b c3             	mov    rax,rbx
   180001ced:	48 83 c4 20          	add    rsp,0x20
   180001cf1:	5b                   	pop    rbx
   180001cf2:	c3                   	ret
   180001cf3:	cc                   	int3
   180001cf4:	48 89 5c 24 10       	mov    QWORD PTR [rsp+0x10],rbx
   180001cf9:	48 89 74 24 18       	mov    QWORD PTR [rsp+0x18],rsi
   180001cfe:	55                   	push   rbp
   180001cff:	57                   	push   rdi
   180001d00:	41 56                	push   r14
   180001d02:	48 8b ec             	mov    rbp,rsp
   180001d05:	48 83 ec 10          	sub    rsp,0x10
   180001d09:	33 c0                	xor    eax,eax
   180001d0b:	33 c9                	xor    ecx,ecx
   180001d0d:	0f a2                	cpuid
   180001d0f:	44 8b c1             	mov    r8d,ecx
   180001d12:	44 8b d2             	mov    r10d,edx
   180001d15:	41 81 f2 69 6e 65 49 	xor    r10d,0x49656e69
   180001d1c:	41 81 f0 6e 74 65 6c 	xor    r8d,0x6c65746e
   180001d23:	44 8b cb             	mov    r9d,ebx
   180001d26:	44 8b f0             	mov    r14d,eax
   180001d29:	33 c9                	xor    ecx,ecx
   180001d2b:	b8 01 00 00 00       	mov    eax,0x1
   180001d30:	0f a2                	cpuid
   180001d32:	45 0b d0             	or     r10d,r8d
   180001d35:	89 45 f0             	mov    DWORD PTR [rbp-0x10],eax
   180001d38:	41 81 f1 47 65 6e 75 	xor    r9d,0x756e6547
   180001d3f:	89 5d f4             	mov    DWORD PTR [rbp-0xc],ebx
   180001d42:	45 0b d1             	or     r10d,r9d
   180001d45:	89 4d f8             	mov    DWORD PTR [rbp-0x8],ecx
   180001d48:	8b f9                	mov    edi,ecx
   180001d4a:	89 55 fc             	mov    DWORD PTR [rbp-0x4],edx
   180001d4d:	75 5b                	jne    0x180001daa
   180001d4f:	48 83 0d 49 33 00 00 	or     QWORD PTR [rip+0x3349],0xffffffffffffffff        # 0x1800050a0
   180001d56:	ff 
   180001d57:	25 f0 3f ff 0f       	and    eax,0xfff3ff0
   180001d5c:	48 c7 05 31 33 00 00 	mov    QWORD PTR [rip+0x3331],0x8000        # 0x180005098
   180001d63:	00 80 00 00 
   180001d67:	3d c0 06 01 00       	cmp    eax,0x106c0
   180001d6c:	74 28                	je     0x180001d96
   180001d6e:	3d 60 06 02 00       	cmp    eax,0x20660
   180001d73:	74 21                	je     0x180001d96
   180001d75:	3d 70 06 02 00       	cmp    eax,0x20670
   180001d7a:	74 1a                	je     0x180001d96
   180001d7c:	05 b0 f9 fc ff       	add    eax,0xfffcf9b0
   180001d81:	83 f8 20             	cmp    eax,0x20
   180001d84:	77 24                	ja     0x180001daa
   180001d86:	48 b9 01 00 01 00 01 	movabs rcx,0x100010001
   180001d8d:	00 00 00 
   180001d90:	48 0f a3 c1          	bt     rcx,rax
   180001d94:	73 14                	jae    0x180001daa
   180001d96:	44 8b 05 63 34 00 00 	mov    r8d,DWORD PTR [rip+0x3463]        # 0x180005200
   180001d9d:	41 83 c8 01          	or     r8d,0x1
   180001da1:	44 89 05 58 34 00 00 	mov    DWORD PTR [rip+0x3458],r8d        # 0x180005200
   180001da8:	eb 07                	jmp    0x180001db1
   180001daa:	44 8b 05 4f 34 00 00 	mov    r8d,DWORD PTR [rip+0x344f]        # 0x180005200
   180001db1:	45 33 c9             	xor    r9d,r9d
   180001db4:	41 8b f1             	mov    esi,r9d
   180001db7:	45 8b d1             	mov    r10d,r9d
   180001dba:	45 8b d9             	mov    r11d,r9d
   180001dbd:	41 83 fe 07          	cmp    r14d,0x7
   180001dc1:	7c 65                	jl     0x180001e28
   180001dc3:	41 8d 41 07          	lea    eax,[r9+0x7]
   180001dc7:	33 c9                	xor    ecx,ecx
   180001dc9:	0f a2                	cpuid
   180001dcb:	89 45 f0             	mov    DWORD PTR [rbp-0x10],eax
   180001dce:	8b f2                	mov    esi,edx
   180001dd0:	89 5d f4             	mov    DWORD PTR [rbp-0xc],ebx
   180001dd3:	44 8b cb             	mov    r9d,ebx
   180001dd6:	89 4d f8             	mov    DWORD PTR [rbp-0x8],ecx
   180001dd9:	89 55 fc             	mov    DWORD PTR [rbp-0x4],edx
   180001ddc:	0f ba e3 09          	bt     ebx,0x9
   180001de0:	73 0b                	jae    0x180001ded
   180001de2:	41 83 c8 02          	or     r8d,0x2
   180001de6:	44 89 05 13 34 00 00 	mov    DWORD PTR [rip+0x3413],r8d        # 0x180005200
   180001ded:	83 f8 01             	cmp    eax,0x1
   180001df0:	7c 19                	jl     0x180001e0b
   180001df2:	b8 07 00 00 00       	mov    eax,0x7
   180001df7:	8d 48 fa             	lea    ecx,[rax-0x6]
   180001dfa:	0f a2                	cpuid
   180001dfc:	44 8b d2             	mov    r10d,edx
   180001dff:	89 45 f0             	mov    DWORD PTR [rbp-0x10],eax
   180001e02:	89 5d f4             	mov    DWORD PTR [rbp-0xc],ebx
   180001e05:	89 4d f8             	mov    DWORD PTR [rbp-0x8],ecx
   180001e08:	89 55 fc             	mov    DWORD PTR [rbp-0x4],edx
   180001e0b:	b8 24 00 00 00       	mov    eax,0x24
   180001e10:	44 3b f0             	cmp    r14d,eax
   180001e13:	7c 13                	jl     0x180001e28
   180001e15:	33 c9                	xor    ecx,ecx
   180001e17:	0f a2                	cpuid
   180001e19:	44 8b db             	mov    r11d,ebx
   180001e1c:	89 45 f0             	mov    DWORD PTR [rbp-0x10],eax
   180001e1f:	89 5d f4             	mov    DWORD PTR [rbp-0xc],ebx
   180001e22:	89 4d f8             	mov    DWORD PTR [rbp-0x8],ecx
   180001e25:	89 55 fc             	mov    DWORD PTR [rbp-0x4],edx
   180001e28:	48 8b 05 59 32 00 00 	mov    rax,QWORD PTR [rip+0x3259]        # 0x180005088
   180001e2f:	bb 06 00 00 00       	mov    ebx,0x6
   180001e34:	48 83 e0 fe          	and    rax,0xfffffffffffffffe
   180001e38:	c7 05 4e 32 00 00 01 	mov    DWORD PTR [rip+0x324e],0x1        # 0x180005090
   180001e3f:	00 00 00 
   180001e42:	c7 05 48 32 00 00 02 	mov    DWORD PTR [rip+0x3248],0x2        # 0x180005094
   180001e49:	00 00 00 
   180001e4c:	48 89 05 35 32 00 00 	mov    QWORD PTR [rip+0x3235],rax        # 0x180005088
   180001e53:	0f ba e7 14          	bt     edi,0x14
   180001e57:	73 1b                	jae    0x180001e74
   180001e59:	48 83 e0 ef          	and    rax,0xffffffffffffffef
   180001e5d:	c7 05 29 32 00 00 02 	mov    DWORD PTR [rip+0x3229],0x2        # 0x180005090
   180001e64:	00 00 00 
   180001e67:	48 89 05 1a 32 00 00 	mov    QWORD PTR [rip+0x321a],rax        # 0x180005088
   180001e6e:	89 1d 20 32 00 00    	mov    DWORD PTR [rip+0x3220],ebx        # 0x180005094
   180001e74:	0f ba e7 1b          	bt     edi,0x1b
   180001e78:	0f 83 2b 01 00 00    	jae    0x180001fa9
   180001e7e:	33 c9                	xor    ecx,ecx
   180001e80:	0f 01 d0             	xgetbv
   180001e83:	48 c1 e2 20          	shl    rdx,0x20
   180001e87:	48 0b d0             	or     rdx,rax
   180001e8a:	48 89 55 20          	mov    QWORD PTR [rbp+0x20],rdx
   180001e8e:	0f ba e7 1c          	bt     edi,0x1c
   180001e92:	0f 83 f6 00 00 00    	jae    0x180001f8e
   180001e98:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   180001e9c:	22 c3                	and    al,bl
   180001e9e:	3a c3                	cmp    al,bl
   180001ea0:	0f 85 e8 00 00 00    	jne    0x180001f8e
   180001ea6:	8b 05 e8 31 00 00    	mov    eax,DWORD PTR [rip+0x31e8]        # 0x180005094
   180001eac:	b2 e0                	mov    dl,0xe0
   180001eae:	83 c8 08             	or     eax,0x8
   180001eb1:	c7 05 d5 31 00 00 03 	mov    DWORD PTR [rip+0x31d5],0x3        # 0x180005090
   180001eb8:	00 00 00 
   180001ebb:	89 05 d3 31 00 00    	mov    DWORD PTR [rip+0x31d3],eax        # 0x180005094
   180001ec1:	41 f6 c1 20          	test   r9b,0x20
   180001ec5:	74 5d                	je     0x180001f24
   180001ec7:	83 c8 20             	or     eax,0x20
   180001eca:	c7 05 bc 31 00 00 05 	mov    DWORD PTR [rip+0x31bc],0x5        # 0x180005090
   180001ed1:	00 00 00 
   180001ed4:	89 05 ba 31 00 00    	mov    DWORD PTR [rip+0x31ba],eax        # 0x180005094
   180001eda:	b9 00 00 03 d0       	mov    ecx,0xd0030000
   180001edf:	48 8b 05 a2 31 00 00 	mov    rax,QWORD PTR [rip+0x31a2]        # 0x180005088
   180001ee6:	44 23 c9             	and    r9d,ecx
   180001ee9:	48 83 e0 fd          	and    rax,0xfffffffffffffffd
   180001eed:	48 89 05 94 31 00 00 	mov    QWORD PTR [rip+0x3194],rax        # 0x180005088
   180001ef4:	44 3b c9             	cmp    r9d,ecx
   180001ef7:	75 32                	jne    0x180001f2b
   180001ef9:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   180001efd:	22 c2                	and    al,dl
   180001eff:	3a c2                	cmp    al,dl
   180001f01:	75 21                	jne    0x180001f24
   180001f03:	48 8b 05 7e 31 00 00 	mov    rax,QWORD PTR [rip+0x317e]        # 0x180005088
   180001f0a:	83 0d 83 31 00 00 40 	or     DWORD PTR [rip+0x3183],0x40        # 0x180005094
   180001f11:	48 83 e0 db          	and    rax,0xffffffffffffffdb
   180001f15:	89 1d 75 31 00 00    	mov    DWORD PTR [rip+0x3175],ebx        # 0x180005090
   180001f1b:	48 89 05 66 31 00 00 	mov    QWORD PTR [rip+0x3166],rax        # 0x180005088
   180001f22:	eb 07                	jmp    0x180001f2b
   180001f24:	48 8b 05 5d 31 00 00 	mov    rax,QWORD PTR [rip+0x315d]        # 0x180005088
   180001f2b:	0f ba e6 17          	bt     esi,0x17
   180001f2f:	73 0c                	jae    0x180001f3d
   180001f31:	48 0f ba f0 18       	btr    rax,0x18
   180001f36:	48 89 05 4b 31 00 00 	mov    QWORD PTR [rip+0x314b],rax        # 0x180005088
   180001f3d:	41 0f ba e2 13       	bt     r10d,0x13
   180001f42:	73 4a                	jae    0x180001f8e
   180001f44:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   180001f48:	22 c2                	and    al,dl
   180001f4a:	3a c2                	cmp    al,dl
   180001f4c:	75 40                	jne    0x180001f8e
   180001f4e:	41 8b cb             	mov    ecx,r11d
   180001f51:	41 8b c3             	mov    eax,r11d
   180001f54:	48 c1 e9 10          	shr    rcx,0x10
   180001f58:	25 ff 00 04 00       	and    eax,0x400ff
   180001f5d:	83 e1 07             	and    ecx,0x7
   180001f60:	89 05 96 32 00 00    	mov    DWORD PTR [rip+0x3296],eax        # 0x1800051fc
   180001f66:	48 81 c9 28 00 00 01 	or     rcx,0x1000028
   180001f6d:	48 f7 d1             	not    rcx
   180001f70:	48 23 0d 11 31 00 00 	and    rcx,QWORD PTR [rip+0x3111]        # 0x180005088
   180001f77:	48 89 0d 0a 31 00 00 	mov    QWORD PTR [rip+0x310a],rcx        # 0x180005088
   180001f7e:	83 f8 01             	cmp    eax,0x1
   180001f81:	76 0b                	jbe    0x180001f8e
   180001f83:	48 83 e1 bf          	and    rcx,0xffffffffffffffbf
   180001f87:	48 89 0d fa 30 00 00 	mov    QWORD PTR [rip+0x30fa],rcx        # 0x180005088
   180001f8e:	41 0f ba e2 15       	bt     r10d,0x15
   180001f93:	73 14                	jae    0x180001fa9
   180001f95:	48 8b 45 20          	mov    rax,QWORD PTR [rbp+0x20]
   180001f99:	48 0f ba e0 13       	bt     rax,0x13
   180001f9e:	73 09                	jae    0x180001fa9
   180001fa0:	48 0f ba 35 df 30 00 	btr    QWORD PTR [rip+0x30df],0x7        # 0x180005088
   180001fa7:	00 07 
   180001fa9:	48 8b 5c 24 38       	mov    rbx,QWORD PTR [rsp+0x38]
   180001fae:	33 c0                	xor    eax,eax
   180001fb0:	48 8b 74 24 40       	mov    rsi,QWORD PTR [rsp+0x40]
   180001fb5:	48 83 c4 10          	add    rsp,0x10
   180001fb9:	41 5e                	pop    r14
   180001fbb:	5f                   	pop    rdi
   180001fbc:	5d                   	pop    rbp
   180001fbd:	c3                   	ret
   180001fbe:	cc                   	int3
   180001fbf:	cc                   	int3
   180001fc0:	b8 01 00 00 00       	mov    eax,0x1
   180001fc5:	c3                   	ret
   180001fc6:	cc                   	int3
   180001fc7:	cc                   	int3
   180001fc8:	33 c0                	xor    eax,eax
   180001fca:	39 05 e0 30 00 00    	cmp    DWORD PTR [rip+0x30e0],eax        # 0x1800050b0
   180001fd0:	0f 95 c0             	setne  al
   180001fd3:	c3                   	ret
   180001fd4:	cc                   	int3
   180001fd5:	cc                   	int3
   180001fd6:	cc                   	int3
   180001fd7:	cc                   	int3
   180001fd8:	cc                   	int3
   180001fd9:	cc                   	int3
   180001fda:	cc                   	int3
   180001fdb:	cc                   	int3
   180001fdc:	cc                   	int3
   180001fdd:	cc                   	int3
   180001fde:	cc                   	int3
   180001fdf:	cc                   	int3
   180001fe0:	e9 60 00 00 00       	jmp    0x180002045
   180001fe5:	ff 25 b5 10 00 00    	jmp    QWORD PTR [rip+0x10b5]        # 0x1800030a0
   180001feb:	ff 25 a7 10 00 00    	jmp    QWORD PTR [rip+0x10a7]        # 0x180003098
   180001ff1:	ff 25 b1 10 00 00    	jmp    QWORD PTR [rip+0x10b1]        # 0x1800030a8
   180001ff7:	ff 25 8b 10 00 00    	jmp    QWORD PTR [rip+0x108b]        # 0x180003088
   180001ffd:	ff 25 7d 10 00 00    	jmp    QWORD PTR [rip+0x107d]        # 0x180003080
   180002003:	ff 25 a7 10 00 00    	jmp    QWORD PTR [rip+0x10a7]        # 0x1800030b0
   180002009:	ff 25 c1 10 00 00    	jmp    QWORD PTR [rip+0x10c1]        # 0x1800030d0
   18000200f:	ff 25 ab 10 00 00    	jmp    QWORD PTR [rip+0x10ab]        # 0x1800030c0
   180002015:	ff 25 e5 10 00 00    	jmp    QWORD PTR [rip+0x10e5]        # 0x180003100
   18000201b:	ff 25 d7 10 00 00    	jmp    QWORD PTR [rip+0x10d7]        # 0x1800030f8
   180002021:	ff 25 c9 10 00 00    	jmp    QWORD PTR [rip+0x10c9]        # 0x1800030f0
   180002027:	ff 25 bb 10 00 00    	jmp    QWORD PTR [rip+0x10bb]        # 0x1800030e8
   18000202d:	ff 25 ad 10 00 00    	jmp    QWORD PTR [rip+0x10ad]        # 0x1800030e0
   180002033:	ff 25 d7 10 00 00    	jmp    QWORD PTR [rip+0x10d7]        # 0x180003110
   180002039:	ff 25 d9 10 00 00    	jmp    QWORD PTR [rip+0x10d9]        # 0x180003118
   18000203f:	ff 25 c3 10 00 00    	jmp    QWORD PTR [rip+0x10c3]        # 0x180003108
   180002045:	ff 25 7d 10 00 00    	jmp    QWORD PTR [rip+0x107d]        # 0x1800030c8
   18000204b:	cc                   	int3
   18000204c:	b0 01                	mov    al,0x1
   18000204e:	c3                   	ret
   18000204f:	cc                   	int3
   180002050:	33 c0                	xor    eax,eax
   180002052:	c3                   	ret
   180002053:	ff 25 37 10 00 00    	jmp    QWORD PTR [rip+0x1037]        # 0x180003090
   180002059:	cc                   	int3
   18000205a:	cc                   	int3
   18000205b:	cc                   	int3
   18000205c:	cc                   	int3
   18000205d:	cc                   	int3
   18000205e:	cc                   	int3
   18000205f:	cc                   	int3
   180002060:	cc                   	int3
   180002061:	cc                   	int3
   180002062:	cc                   	int3
   180002063:	cc                   	int3
   180002064:	cc                   	int3
   180002065:	cc                   	int3
   180002066:	66 66 0f 1f 84 00 00 	data16 nop WORD PTR [rax+rax*1+0x0]
   18000206d:	00 00 00 
   180002070:	ff e0                	jmp    rax
   180002072:	cc                   	int3
   180002073:	cc                   	int3
   180002074:	cc                   	int3
   180002075:	cc                   	int3
   180002076:	cc                   	int3
   180002077:	cc                   	int3
   180002078:	cc                   	int3
   180002079:	cc                   	int3
   18000207a:	cc                   	int3
   18000207b:	cc                   	int3
   18000207c:	cc                   	int3
   18000207d:	cc                   	int3
   18000207e:	cc                   	int3
   18000207f:	cc                   	int3
   180002080:	cc                   	int3
   180002081:	cc                   	int3
   180002082:	cc                   	int3
   180002083:	cc                   	int3
   180002084:	cc                   	int3
   180002085:	cc                   	int3
   180002086:	66 66 0f 1f 84 00 00 	data16 nop WORD PTR [rax+rax*1+0x0]
   18000208d:	00 00 00 
   180002090:	ff 25 a2 10 00 00    	jmp    QWORD PTR [rip+0x10a2]        # 0x180003138
   180002096:	40 55                	rex push rbp
   180002098:	48 83 ec 20          	sub    rsp,0x20
   18000209c:	48 8b ea             	mov    rbp,rdx
   18000209f:	8a 4d 40             	mov    cl,BYTE PTR [rbp+0x40]
   1800020a2:	48 83 c4 20          	add    rsp,0x20
   1800020a6:	5d                   	pop    rbp
   1800020a7:	e9 f0 f9 ff ff       	jmp    0x180001a9c
   1800020ac:	cc                   	int3
   1800020ad:	40 55                	rex push rbp
   1800020af:	48 83 ec 20          	sub    rsp,0x20
   1800020b3:	48 8b ea             	mov    rbp,rdx
   1800020b6:	8a 4d 20             	mov    cl,BYTE PTR [rbp+0x20]
   1800020b9:	e8 de f9 ff ff       	call   0x180001a9c
   1800020be:	90                   	nop
   1800020bf:	48 83 c4 20          	add    rsp,0x20
   1800020c3:	5d                   	pop    rbp
   1800020c4:	c3                   	ret
   1800020c5:	cc                   	int3
   1800020c6:	40 55                	rex push rbp
   1800020c8:	48 83 ec 20          	sub    rsp,0x20
   1800020cc:	48 8b ea             	mov    rbp,rdx
   1800020cf:	48 83 c4 20          	add    rsp,0x20
   1800020d3:	5d                   	pop    rbp
   1800020d4:	e9 4f f8 ff ff       	jmp    0x180001928
   1800020d9:	cc                   	int3
   1800020da:	40 55                	rex push rbp
   1800020dc:	48 83 ec 30          	sub    rsp,0x30
   1800020e0:	48 8b ea             	mov    rbp,rdx
   1800020e3:	48 8b 01             	mov    rax,QWORD PTR [rcx]
   1800020e6:	8b 10                	mov    edx,DWORD PTR [rax]
   1800020e8:	48 89 4c 24 28       	mov    QWORD PTR [rsp+0x28],rcx
   1800020ed:	89 54 24 20          	mov    DWORD PTR [rsp+0x20],edx
   1800020f1:	4c 8d 0d fc f0 ff ff 	lea    r9,[rip+0xfffffffffffff0fc]        # 0x1800011f4
   1800020f8:	4c 8b 45 70          	mov    r8,QWORD PTR [rbp+0x70]
   1800020fc:	8b 55 68             	mov    edx,DWORD PTR [rbp+0x68]
   1800020ff:	48 8b 4d 60          	mov    rcx,QWORD PTR [rbp+0x60]
   180002103:	e8 90 f7 ff ff       	call   0x180001898
   180002108:	90                   	nop
   180002109:	48 83 c4 30          	add    rsp,0x30
   18000210d:	5d                   	pop    rbp
   18000210e:	c3                   	ret
   18000210f:	cc                   	int3
   180002110:	40 55                	rex push rbp
   180002112:	48 8b ea             	mov    rbp,rdx
   180002115:	48 8b 01             	mov    rax,QWORD PTR [rcx]
   180002118:	33 c9                	xor    ecx,ecx
   18000211a:	81 38 05 00 00 c0    	cmp    DWORD PTR [rax],0xc0000005
   180002120:	0f 94 c1             	sete   cl
   180002123:	8b c1                	mov    eax,ecx
   180002125:	5d                   	pop    rbp
   180002126:	c3                   	ret
   180002127:	cc                   	int3
