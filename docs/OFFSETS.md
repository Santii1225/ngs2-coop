# Offsets

## VERSIÓN DEL JUEGO
Steam build 6998211; EXE SHA256 a66daf011d22dd6fd6676e0b8ccc68e85448d4570bbac635e25adc1f2d06ffef; SizeOfCode 0x179c400. Base dinámica GetModuleHandle(nullptr); valores siguientes son RVA, no direcciones absolutas.

## CONFIRMADO
Ningún offset funcional confirmado en memoria en esta sesión. Solo se comprobaron cabeceras/secciones del PE y presencia de valores en fuente. La carga histórica no valida individualmente los patches.

## HIPÓTESIS / valores heredados del código
| RVA / campo | Uso declarado | Estado |
|---|---|---|
| 0xb5c460 | check_dlls inline hook | Sin verificar en runtime |
| 0x1340d3b | patch core 7 bytes | Sin verificar |
| 0x1462a00 | Sigma2_vfunction1 VFPHook | Bloqueo: cae en .text; confirmar ubicación y ABI |
| 0x18ef6f0 / 0x18ef6f8 | loader NGS2 AE | En .rdata; semántica pendiente |
| 0x18ee6f0 / 0x18ee6f8 | loader NGS2 JP | Variante distinta, no usar para AE |
| 0x0994b50 / 0x0994b58 / 0x07e5630 | loader NGS1 AE | Otra versión/juego |
| 0x3195300 | game_object table | Parcial, no player validado |
| 0x2f78b10 / +0x210 | character table / dead | Uso en cadáveres, no HP |
| 0x1e38710 | object_data_offset_table | Renderizado |
| 0x1e39b40 | afterimage params | Colores/duración, no control |
| 0x6426880 | limb_manager | location_vec de miembro, no posición jugador |
| 0x6439cc0 / 0x642a6b0 | corpse / lump manager | Cuerpos/desmembramiento |
| 0x1829080 / 0x1829110 | multiplicadores Story/Chapter Challenge | Longitud 16 conservada del código 12.7, sin validación runtime |

Catálogo orientativo, no exhaustivo de todos los literales de effect. Confirmación futura exige hash de versión, bytes esperados, observación tras carga y prueba repetida ante cambios de escenario/personaje; guardar evidencia y descartar versiones incompatibles.

## Inventario estático ampliado — fase H

Todas las ocurrencias hexadecimales están en research/source_hex_literals.json.
La tabla incluye literales >=0x50000: también incluye máscaras, tamaños y discriminadores, que NO son RVAs; el contexto distingue estos casos. Expresiones +1/+3/+6 y diferencias rel32 se conservan literalmente: la sección corresponde al literal base, no a la expresión evaluada. Constantes de campos/tamaños menores están en el JSON y no se confunden con direcciones del módulo. NGS1/JP conservan procedencia en source_offsets_hooks.txt y fuente; pertenecer a .text no valida compatibilidad.

| Offset/literal base | Archivo fuente | Uso esperado / expresión completa | Sección actual si se interpreta como RVA | Estado |
|---|---|---|---|---|
| 0x1829080 | src/combat/main.cpp:51 | `patch_story = new Patch {0x1829080, arr};` | .rdata | SIN VERIFICAR |
| 0x1829110 | src/combat/main.cpp:53 | `patch_challenge = new Patch {0x1829110, arr};` | .rdata | SIN VERIFICAR |
| 0x1e26440 | src/combat/main.cpp:57 | `//*reinterpret_cast <float *> (base_of_image + 0x1e26440 + 4) = 1;` | .data | SIN VERIFICAR |
| 0x1e26440 | src/combat/main.cpp:60 | `//*reinterpret_cast <float *> (base_of_image + 0x1e26440 + 8) = 1;` | .data | SIN VERIFICAR |
| 0x0f4bfcd | src/combat/main.cpp:64 | `patch2 = new Patch {0x0f4bfcd, uint8_t {0x77}};` | .text | SIN VERIFICAR |
| 0x0f73607 | src/combat/main.cpp:65 | `patch3 = new Patch {0x0f73607 + 1, uint8_t {0x87}};` | .text | SIN VERIFICAR |
| 0xb5c460 | src/core/main.cpp:87 | `check_dlls_hook = new SimpleInlineHook {0xb5c460, check_dlls};` | .text | SIN VERIFICAR |
| 0x1340d3b | src/core/main.cpp:88 | `patch1 = new Patch {0x1340d3b, XOR_R8_NOP4};` | .text | SIN VERIFICAR |
| 0x1462a00 | src/core/main.cpp:89 | `Sigma2_vfunction1_hook = new VFPHook {0x1462a00, Sigma2_vfunction1};` | .text | SOSPECHOSO |
| 0x0fffffff | src/effect/main.cpp:391 | `uintptr_t y = reinterpret_cast <uintptr_t> (&x) + (x & 0x0fffffff);` | fuera de secciones | SIN VERIFICAR |
| 0x219bff0 | src/effect/main.cpp:578 | `auto &x = *reinterpret_cast <float (*)[0x140]> (base_address + 0x219bff0);` | .data | SIN VERIFICAR |
| 0x219c4f0 | src/effect/main.cpp:580 | `*reinterpret_cast <uintptr_t *> (base_address + 0x219c4f0) = reinterpret_cast <uintptr_t> (game_model_data_manager);` | .data | SIN VERIFICAR |
| 0x1e38710 | src/effect/main.cpp:606 | `object_data_offset_table = reinterpret_cast <uintptr_t (*)[4]> (base_address + 0x1e38710);` | .data | SIN VERIFICAR |
| 0x3195300 | src/effect/main.cpp:607 | `game_object_ptr = reinterpret_cast <struct game_object *> (base_address + 0x3195300);` | .data | SIN VERIFICAR |
| 0x211e753 | src/effect/main.cpp:608 | `in_pause_ptr = reinterpret_cast <uint8_t *> (base_address + 0x211e753);` | .data | SIN VERIFICAR |
| 0x211e990 | src/effect/main.cpp:609 | `vanish_timer_table_ptr = reinterpret_cast <int32_t *> (base_address + 0x211e990);` | .data | SIN VERIFICAR |
| 0x1048888 | src/effect/main.cpp:617 | `patch1 = new Patch {0x1048888, make_bytes (0x83, 0xe0, 0x00)};` | .text | SIN VERIFICAR |
| 0x17f25c8 | src/effect/main.cpp:621 | `patch2 = new Patch {0x17f25c8, uint16_t {0x1002}};` | .rdata | SIN VERIFICAR |
| 0x17f0428 | src/effect/main.cpp:622 | `patch3 = new Patch {0x17f0428, uint16_t {0x1002}};` | .rdata | SIN VERIFICAR |
| 0x17f3ca8 | src/effect/main.cpp:623 | `patch4 = new Patch {0x17f3ca8, uint16_t {0x1002}};` | .rdata | SIN VERIFICAR |
| 0x1457f6d | src/effect/main.cpp:628 | `patch5 = new Patch {0x1457f6d + 6, 0};` | .text | SIN VERIFICAR |
| 0x0f29437 | src/effect/main.cpp:632 | `patch6 = new Patch {0x0f29437, make_bytes (0xe9, 0xa0, 0x00, 0x00, 0x00)};` | .text | SIN VERIFICAR |
| 0x0f294dc | src/effect/main.cpp:634 | `patch7 = new Patch {0x0f294dc, make_bytes (0x31, 0xc0)};` | .text | SIN VERIFICAR |
| 0x120a13f | src/effect/main.cpp:639 | `patch1 = new Patch {0x120a13f + 1, 0x075f720 - (0x120a13f + 5)};` | .text | SIN VERIFICAR |
| 0x075f720 | src/effect/main.cpp:639 | `patch1 = new Patch {0x120a13f + 1, 0x075f720 - (0x120a13f + 5)};` | .text | SIN VERIFICAR |
| 0x120a13f | src/effect/main.cpp:639 | `patch1 = new Patch {0x120a13f + 1, 0x075f720 - (0x120a13f + 5)};` | .text | SIN VERIFICAR |
| 0x120a0f0 | src/effect/main.cpp:640 | `patch2 = new Patch {0x120a0f0 + 1, 0x075fd20 - (0x120a0f0 + 5)};` | .text | SIN VERIFICAR |
| 0x075fd20 | src/effect/main.cpp:640 | `patch2 = new Patch {0x120a0f0 + 1, 0x075fd20 - (0x120a0f0 + 5)};` | .text | SIN VERIFICAR |
| 0x120a0f0 | src/effect/main.cpp:640 | `patch2 = new Patch {0x120a0f0 + 1, 0x075fd20 - (0x120a0f0 + 5)};` | .text | SIN VERIFICAR |
| 0x12058c9 | src/effect/main.cpp:645 | `patch3 = new Patch {0x12058c9 + 3, uint8_t {0x4u}};` | .text | SIN VERIFICAR |
| 0x1c8e218 | src/effect/main.cpp:646 | `*reinterpret_cast <uintptr_t *> (base_address + 0x1c8e218) = base_address + 0x12058b0;` | .data | SIN VERIFICAR |
| 0x12058b0 | src/effect/main.cpp:646 | `*reinterpret_cast <uintptr_t *> (base_address + 0x1c8e218) = base_address + 0x12058b0;` | .text | SIN VERIFICAR |
| 0x1205899 | src/effect/main.cpp:647 | `patch4 = new Patch {0x1205899 + 3, uint8_t {0x5u}};` | .text | SIN VERIFICAR |
| 0x1c8e1f8 | src/effect/main.cpp:648 | `*reinterpret_cast <uintptr_t *> (base_address + 0x1c8e1f8) = base_address + 0x1205880;` | .data | SIN VERIFICAR |
| 0x1205880 | src/effect/main.cpp:648 | `*reinterpret_cast <uintptr_t *> (base_address + 0x1c8e1f8) = base_address + 0x1205880;` | .text | SIN VERIFICAR |
| 0x120cc1d | src/effect/main.cpp:657 | `patch1 = new Patch {0x120cc1d + 1, 0x077b010 - (0x120cc1d + 5)};` | .text | SIN VERIFICAR |
| 0x077b010 | src/effect/main.cpp:657 | `patch1 = new Patch {0x120cc1d + 1, 0x077b010 - (0x120cc1d + 5)};` | .text | SIN VERIFICAR |
| 0x120cc1d | src/effect/main.cpp:657 | `patch1 = new Patch {0x120cc1d + 1, 0x077b010 - (0x120cc1d + 5)};` | .text | SIN VERIFICAR |
| 0x120cbe1 | src/effect/main.cpp:658 | `patch2 = new Patch {0x120cbe1 + 1, 0x077b010 - (0x120cbe1 + 5)};` | .text | SIN VERIFICAR |
| 0x077b010 | src/effect/main.cpp:658 | `patch2 = new Patch {0x120cbe1 + 1, 0x077b010 - (0x120cbe1 + 5)};` | .text | SIN VERIFICAR |
| 0x120cbe1 | src/effect/main.cpp:658 | `patch2 = new Patch {0x120cbe1 + 1, 0x077b010 - (0x120cbe1 + 5)};` | .text | SIN VERIFICAR |
| 0x120c82d | src/effect/main.cpp:660 | `patch3 = new Patch {0x120c82d + 1, 0x077b010 - (0x120c82d + 5)};` | .text | SIN VERIFICAR |
| 0x077b010 | src/effect/main.cpp:660 | `patch3 = new Patch {0x120c82d + 1, 0x077b010 - (0x120c82d + 5)};` | .text | SIN VERIFICAR |
| 0x120c82d | src/effect/main.cpp:660 | `patch3 = new Patch {0x120c82d + 1, 0x077b010 - (0x120c82d + 5)};` | .text | SIN VERIFICAR |
| 0x120c7f1 | src/effect/main.cpp:661 | `patch4 = new Patch {0x120c7f1 + 1, 0x077b010 - (0x120c7f1 + 5)};` | .text | SIN VERIFICAR |
| 0x077b010 | src/effect/main.cpp:661 | `patch4 = new Patch {0x120c7f1 + 1, 0x077b010 - (0x120c7f1 + 5)};` | .text | SIN VERIFICAR |
| 0x120c7f1 | src/effect/main.cpp:661 | `patch4 = new Patch {0x120c7f1 + 1, 0x077b010 - (0x120c7f1 + 5)};` | .text | SIN VERIFICAR |
| 0x120daa5 | src/effect/main.cpp:663 | `patch5 = new Patch {0x120daa5 + 1, 0x077ce10 - (0x120daa5 + 5)};` | .text | SIN VERIFICAR |
| 0x077ce10 | src/effect/main.cpp:663 | `patch5 = new Patch {0x120daa5 + 1, 0x077ce10 - (0x120daa5 + 5)};` | .text | SIN VERIFICAR |
| 0x120daa5 | src/effect/main.cpp:663 | `patch5 = new Patch {0x120daa5 + 1, 0x077ce10 - (0x120daa5 + 5)};` | .text | SIN VERIFICAR |
| 0x120da69 | src/effect/main.cpp:664 | `patch6 = new Patch {0x120da69 + 1, 0x077ce10 - (0x120da69 + 5)};` | .text | SIN VERIFICAR |
| 0x077ce10 | src/effect/main.cpp:664 | `patch6 = new Patch {0x120da69 + 1, 0x077ce10 - (0x120da69 + 5)};` | .text | SIN VERIFICAR |
| 0x120da69 | src/effect/main.cpp:664 | `patch6 = new Patch {0x120da69 + 1, 0x077ce10 - (0x120da69 + 5)};` | .text | SIN VERIFICAR |
| 0x120cafe | src/effect/main.cpp:667 | `patch7 = new Patch {0x120cafe, concat (NOP7, uint8_t {0xeb})};` | .text | SIN VERIFICAR |
| 0x120c70e | src/effect/main.cpp:668 | `patch8 = new Patch {0x120c70e, concat (NOP7, uint8_t {0xeb})};` | .text | SIN VERIFICAR |
| 0x188a890 | src/effect/main.cpp:670 | `BloodStampEffectManager_vfunction2_hook = new VFPHook {0x188a890, BloodStampEffectManager_vfunction2};` | .rdata | SIN VERIFICAR |
| 0x18c5578 | src/effect/main.cpp:671 | `SphericalResourceGenerator_vfunction2_hook = new VFPHook {0x18c5578, SphericalResourceGenerator_vfunction2};` | .rdata | SIN VERIFICAR |
| 0x1455880 | src/effect/main.cpp:677 | `update_SUP_NodeObj_visibility_hook = new SimpleInlineHook {0x1455880, update_SUP_NodeObj_visibility <0x1e38710>};` | .text | SIN VERIFICAR |
| 0x1e38710 | src/effect/main.cpp:677 | `update_SUP_NodeObj_visibility_hook = new SimpleInlineHook {0x1455880, update_SUP_NodeObj_visibility <0x1e38710>};` | .data | SIN VERIFICAR |
| 0x144cb00 | src/effect/main.cpp:678 | `get_OPTscat_indices_hook = new SimpleInlineHook {0x144cb00, get_OPTscat_indices};` | .text | SIN VERIFICAR |
| 0x145866a | src/effect/main.cpp:682 | `patch1 = new Patch {0x145866a + 1, 0x1220060 - (0x145866a + 5)};` | .text | SIN VERIFICAR |
| 0x1220060 | src/effect/main.cpp:682 | `patch1 = new Patch {0x145866a + 1, 0x1220060 - (0x145866a + 5)};` | .text | SIN VERIFICAR |
| 0x145866a | src/effect/main.cpp:682 | `patch1 = new Patch {0x145866a + 1, 0x1220060 - (0x145866a + 5)};` | .text | SIN VERIFICAR |
| 0x12201f6 | src/effect/main.cpp:686 | `patch2 = new Patch {0x12201f6 + 1, 0x1206ec0 - (0x12201f6 + 5)};` | .text | SIN VERIFICAR |
| 0x1206ec0 | src/effect/main.cpp:686 | `patch2 = new Patch {0x12201f6 + 1, 0x1206ec0 - (0x12201f6 + 5)};` | .text | SIN VERIFICAR |
| 0x12201f6 | src/effect/main.cpp:686 | `patch2 = new Patch {0x12201f6 + 1, 0x1206ec0 - (0x12201f6 + 5)};` | .text | SIN VERIFICAR |
| 0x1207430 | src/effect/main.cpp:688 | `patch3 = new Patch {0x1207430, *reinterpret_cast <uint32_t (*)[4]> (base_address + 0x1207430 + 4 * 0x10)};` | .text | SIN VERIFICAR |
| 0x1207430 | src/effect/main.cpp:688 | `patch3 = new Patch {0x1207430, *reinterpret_cast <uint32_t (*)[4]> (base_address + 0x1207430 + 4 * 0x10)};` | .text | SIN VERIFICAR |
| 0x1458761 | src/effect/main.cpp:692 | `patch4 = new Patch {0x1458761 + 1, 0x121fe20 - (0x1458761 + 5)};` | .text | SIN VERIFICAR |
| 0x121fe20 | src/effect/main.cpp:692 | `patch4 = new Patch {0x1458761 + 1, 0x121fe20 - (0x1458761 + 5)};` | .text | SIN VERIFICAR |
| 0x1458761 | src/effect/main.cpp:692 | `patch4 = new Patch {0x1458761 + 1, 0x121fe20 - (0x1458761 + 5)};` | .text | SIN VERIFICAR |
| 0x1460d34 | src/effect/main.cpp:696 | `patch5 = new Patch {0x1460d34, concat (NOP9, NOP9, NOP9, NOP7, uint8_t {0xeb})};` | .text | SIN VERIFICAR |
| 0x144c0d0 | src/effect/main.cpp:700 | `patch7 = new Patch {0x144c0d0, concat (NOP5, NOP5)};` | .text | SIN VERIFICAR |
| 0x145a338 | src/effect/main.cpp:706 | `patch8 = new Patch {0x145a338, concat (make_bytes (0x31, 0xc0), NOP4)};` | .text | SIN VERIFICAR |
| 0x144ae80 | src/effect/main.cpp:709 | `patch9 = new Patch {0x144ae80, concat (make_bytes (0x31, 0xc0), NOP4)};` | .text | SIN VERIFICAR |
| 0x1c74980 | src/effect/main.cpp:714 | `*reinterpret_cast <uintptr_t *> (base_address + 0x1c74980) = base_address + 0x100a990;` | .data | SIN VERIFICAR |
| 0x100a990 | src/effect/main.cpp:714 | `*reinterpret_cast <uintptr_t *> (base_address + 0x1c74980) = base_address + 0x100a990;` | .text | SIN VERIFICAR |
| 0x1c74900 | src/effect/main.cpp:718 | `*reinterpret_cast <uintptr_t *> (base_address + 0x1c74900) = base_address + 0x100a990;` | .data | SIN VERIFICAR |
| 0x100a990 | src/effect/main.cpp:718 | `*reinterpret_cast <uintptr_t *> (base_address + 0x1c74900) = base_address + 0x100a990;` | .text | SIN VERIFICAR |
| 0x1e39b40 | src/effect/main.cpp:724 | `afterimage::update_afterimage_params <0x1e39b40> ();` | .data | SIN VERIFICAR |
| 0x1053d20 | src/effect/main.cpp:726 | `patch1 = new Patch {0x1053d20 + 2, uint8_t {0}};` | .text | SIN VERIFICAR |
| 0x145e67a | src/effect/main.cpp:734 | `patch1 = new Patch {0x145e67a, make_bytes(0x0f, 0x57, 0xc0, 0x0f, 0x57, 0xc9, 0x66, 0x90)};` | .text | SIN VERIFICAR |
| 0x6439cc0 | src/effect/main.cpp:736 | `corpse_table_ptr = reinterpret_cast <struct corpse_object *> (base_address + 0x6439cc0);` | .data | SIN VERIFICAR |
| 0x13ffb50 | src/effect/main.cpp:737 | `FUN_13ffb50_hook = new SimpleInlineHook {0x13ffb50, FUN_13ffb50};` | .text | SIN VERIFICAR |
| 0x145d60a | src/effect/main.cpp:741 | `patch2_1 = new Patch {0x145d60a,` | .text | SIN VERIFICAR |
| 0x145d60a | src/effect/main.cpp:748 | `// jne 0x145d60a;` | .text | SIN VERIFICAR |
| 0x145d635 | src/effect/main.cpp:749 | `patch2_2 = new Patch {0x145d635 + 1, concat (uint8_t {0xd5})};` | .text | SIN VERIFICAR |
| 0x145d7d8 | src/effect/main.cpp:753 | `patch3 = new Patch {0x145d7d8, concat (NOP5, NOP5)};` | .text | SIN VERIFICAR |
| 0x145f584 | src/effect/main.cpp:758 | `patch4 = new Patch {0x145f584, concat (make_bytes (0x31, 0xc0), NOP3)};` | .text | SIN VERIFICAR |
| 0x145dde0 | src/effect/main.cpp:760 | `release_corpse = reinterpret_cast <decltype (release_corpse)> (base_address + 0x145dde0);` | .text | SIN VERIFICAR |
| 0x64b4850 | src/effect/main.cpp:762 | `rigidbody_id_table_ptr = reinterpret_cast <uint32_t (*)[0x80]> (base_address + 0x64b4850);` | .data | SIN VERIFICAR |
| 0x2f78b10 | src/effect/main.cpp:763 | `character_ptr = reinterpret_cast <struct character *> (base_address + 0x2f78b10);` | .data | SIN VERIFICAR |
| 0x21b3000 | src/effect/main.cpp:764 | `limb_count_ptr = reinterpret_cast <uint32_t *> (base_address + 0x21b3000);` | .data | SIN VERIFICAR |
| 0x6426880 | src/effect/main.cpp:765 | `limb_manager_ptr = reinterpret_cast <struct limb_data (*)[4]> (base_address + 0x6426880);` | .data | SIN VERIFICAR |
| 0x642a6b0 | src/effect/main.cpp:766 | `lump_manager_ptr = reinterpret_cast <lump_manager *> (base_address + 0x642a6b0);` | .data | SIN VERIFICAR |
| 0x144a330 | src/effect/main.cpp:767 | `get_lump_pose_matrix = reinterpret_cast <decltype (get_lump_pose_matrix)> (base_address + 0x144a330);` | .text | SIN VERIFICAR |
| 0xc0fdc0 | src/effect/main.cpp:768 | `get_pose_matrix_hook = new SimpleInlineHook {0xc0fdc0, get_pose_matrix};` | .text | SIN VERIFICAR |
| 0x0f87410 | src/effect/main.cpp:770 | `is_stationary_hook = new SimpleInlineHook {0x0f87410, is_stationary};` | .text | SIN VERIFICAR |
| 0xf291de | src/effect/main.cpp:773 | `patch5 = new Patch {0xf291de, concat (NOP9, NOP8, NOP3)};` | .text | SIN VERIFICAR |
| 0x1635e60 | src/effect/main.cpp:774 | `is_to_be_vanished_hook = new SimpleInlineHook {0x1635e60, is_to_be_vanished};` | .text | SIN VERIFICAR |
| 0x141b6d0 | src/effect/main.cpp:776 | `init_game_model_data_manager_hook = new SimpleInlineHook {0x141b6d0, init_game_model_data_manager};` | .text | SIN VERIFICAR |
| 0x0f896d0 | src/effect/main.cpp:781 | `patch6_1 = new Patch {0x0f896d0, NOP_CMP_CL_IMM_JB_IMM};` | .text | SIN VERIFICAR |
| 0x0f89700 | src/effect/main.cpp:782 | `patch6_2 = new Patch {0x0f89700, NOP_CMP_CL_IMM_JB_IMM};` | .text | SIN VERIFICAR |
| 0x1377bb0 | src/effect/main.cpp:783 | `patch6_3 = new Patch {0x1377bb0, NOP_CMP_CL_IMM_JB_IMM};` | .text | SIN VERIFICAR |
| 0x1381ce5 | src/effect/main.cpp:784 | `//patch6_4 = new Patch {0x1381ce5, NOP_CMP_CL_IMM_JB_IMM};` | .text | SIN VERIFICAR |
| 0x14075d0 | src/effect/main.cpp:785 | `patch6_5 = new Patch {0x14075d0, NOP_CMP_CL_IMM_JB_IMM};` | .text | SIN VERIFICAR |
| 0x140b805 | src/effect/main.cpp:786 | `//patch6_6 = new Patch {0x140b805, NOP_CMP_CL_IMM_JB_IMM};` | .text | SIN VERIFICAR |
| 0x140c8e0 | src/effect/main.cpp:787 | `patch6_7 = new Patch {0x140c8e0, NOP_CMP_CL_IMM_JB_IMM};` | .text | SIN VERIFICAR |
| 0x141a257 | src/effect/main.cpp:788 | `patch6_8 = new Patch {0x141a257, NOP_CMP_DL_IMM_JB_IMM};` | .text | SIN VERIFICAR |
| 0x141b0d6 | src/effect/main.cpp:789 | `//patch6_9 = new Patch {0x141b0d6, NOP_CMP_CL_IMM_JB_IMM};` | .text | SIN VERIFICAR |
| 0x141ba79 | src/effect/main.cpp:790 | `//patch6_10 = new Patch {0x141ba79, NOP_CMP_CL_IMM_JB_IMM};` | .text | SIN VERIFICAR |
| 0x15f1e08 | src/effect/main.cpp:791 | `patch6_11 = new Patch {0x15f1e08, NOP_CMP_CL_IMM_JB_IMM};` | .text | SIN VERIFICAR |
| 0x15f2ad2 | src/effect/main.cpp:792 | `patch6_12 = new Patch {0x15f2ad2, NOP_CMP_CL_IMM_JB_IMM};` | .text | SIN VERIFICAR |
| 0x163507a | src/effect/main.cpp:793 | `patch6_13 = new Patch {0x163507a, CMP_R8B_IMM_JB_IMM};` | .text | SIN VERIFICAR |
| 0x146794d | src/effect/main.cpp:796 | `patch7 = new Patch {0x146794d + 1, 0x800000u};` | .text | SIN VERIFICAR |
| 0x800000 | src/effect/main.cpp:796 | `patch7 = new Patch {0x146794d + 1, 0x800000u};` | .text | SIN VERIFICAR |
| 0x1444f23 | src/effect/main.cpp:799 | `patch8 = new Patch {0x1444f23 + 1, 0x145dde0 - (0x1444f23 + 5)};` | .text | SIN VERIFICAR |
| 0x145dde0 | src/effect/main.cpp:799 | `patch8 = new Patch {0x1444f23 + 1, 0x145dde0 - (0x1444f23 + 5)};` | .text | SIN VERIFICAR |
| 0x1444f23 | src/effect/main.cpp:799 | `patch8 = new Patch {0x1444f23 + 1, 0x145dde0 - (0x1444f23 + 5)};` | .text | SIN VERIFICAR |
| 0x91aa00 | src/loader/main.cpp:174 | `NGS1SteamAE = 0x91aa00,` | .text | SIN VERIFICAR |
| 0x179c400 | src/loader/main.cpp:175 | `NGS2SteamAE = 0x179c400,` | .text | SIN VERIFICAR |
| 0x179c000 | src/loader/main.cpp:176 | `NGS2SteamJP = 0x179c000,` | .text | SIN VERIFICAR |
| 0x0994b50 | src/loader/main.cpp:184 | `load_data_hook = new VFPHook {0x0994b50, load_data_ngs1};` | .text | SIN VERIFICAR |
| 0x0994b58 | src/loader/main.cpp:185 | `get_chunk_info_hook = new VFPHook {0x0994b58, get_chunk_info};` | .text | SIN VERIFICAR |
| 0x07e5630 | src/loader/main.cpp:186 | `tmcl_malloc = reinterpret_cast<decltype (tmcl_malloc)>(base_address + 0x07e5630);` | .text | SIN VERIFICAR |
| 0x18ef6f0 | src/loader/main.cpp:189 | `load_data_hook = new VFPHook {0x18ef6f0, load_data};` | .rdata | SIN VERIFICAR |
| 0x18ef6f8 | src/loader/main.cpp:190 | `get_chunk_info_hook = new VFPHook {0x18ef6f8, get_chunk_info};` | .rdata | SIN VERIFICAR |
| 0x18ee6f0 | src/loader/main.cpp:193 | `load_data_hook = new VFPHook {0x18ee6f0, load_data};` | .rdata | SIN VERIFICAR |
| 0x18ee6f8 | src/loader/main.cpp:194 | `get_chunk_info_hook = new VFPHook {0x18ee6f8, get_chunk_info};` | .rdata | SIN VERIFICAR |
| 0x13ddfa6 | src/steam-bugfixes/main.cpp:32 | `patch1 = new Patch {0x13ddfa6 + 3, uint8_t {7}};` | .text | SIN VERIFICAR |
| 0xC43060 | src/steam-bugfixes/main.cpp:36 | `patch2 = new Patch {0xC43060, make_bytes (0xe9, 0xde, 0x00, 0x00, 0x00)};` | .text | SIN VERIFICAR |

## Resultado específico del hook

| Offset | Archivo fuente/evidencia | Uso esperado | Sección actual | Estado |
|---|---|---|---|---|
| 0x1462a00 | src/core/main.cpp:89 | Slot VFPHook; metadata identifica inicio de función | .text | SOSPECHOSO |
| 0x18f9518 | research/vtable_xrefs.txt | Slot candidato de Sigma2, QWORD hacia función; RTTI+DIR64 corroboran | .rdata | SIN VERIFICAR |
| 0x19c9448 | research/vtable_xrefs.txt | RTTI COL de Sigma2, estático | .rdata | SIN VERIFICAR |
| 0x1fa27e0 | research/vtable_xrefs.txt | TypeDescriptor Sigma2, estático | .data | SIN VERIFICAR |
| 0x1c13db8 | research/hook_pe.json | UnwindInfo de función | .rdata | SIN VERIFICAR |

Estados reservan CONFIRMADO para validación funcional; los hechos estáticos particulares sí están verificados por lectura, tabla de relocaciones y LLVM. No se modificó ningún offset de producción.

## Validación dinámica — PID 51579

Las tablas anteriores permanecen como inventario STATIC ONLY de su hito. Confirmaciones siguientes basadas en memoria y código, no mera pertenencia a sección:

| Offset | Archivo/evidencia | Uso observado | Sección | Estado |
|---|---|---|---|---|
| 0x1462a00 | core:89 / runtime_hook_1462A00.asm | Función, NO slot VFPHook; uso actual como slot incompatible | .text | INCORRECTO |
| 0x18f9518 | runtime_capture.json | Slot 0 Sigma2 apunta a base+0x1462a00, RUNTIME VERIFIED | .rdata | CONFIRMADO |
| 0x18f9520 | runtime_capture.json | Slot 1 apunta a base+0x1462750, RUNTIME VERIFIED | .rdata | CONFIRMADO |
| 0x18f9510 | runtime_capture.json | QWORD hacia COL 0x19c9448, RUNTIME VERIFIED | .rdata | CONFIRMADO |
| 0x1e66d00 | runtime_instance.json / runtime_xref_1340ddb.asm | Instancia con vptr Sigma2, RUNTIME VERIFIED | .data | CONFIRMADO |
| 0x1e66e60 | runtime_instance.json | Global apunta a instancia anterior, RUNTIME VERIFIED | .data | CONFIRMADO |
| 0xb5c8aa | runtime_function_b5c890.asm | Call virtual slot 0 seguido de test AL, RUNTIME VERIFIED | .text | CONFIRMADO |

INCORRECTO califica su uso como dirección de slot, no niega que 0x1462a00 sea el RVA correcto de la función. CONFIRMADO describe el hecho específico observado para este hash/build; no valida estabilidad entre versiones ni todas las semánticas del objeto.

## Estado de implementación CASE C — BUILD/HARNESS VERIFIED

La fila histórica INCORRECTO para 0x1462a00 describe el código previo. Implementación actual:

| RVA | Fuente | Uso actual | Estado de evidencia |
|---|---|---|---|
| 0x1462a00 | src/core/sigma2_hook.hpp | Solo target esperado/original; ninguna escritura a función | RUNTIME VERIFIED para dirección histórica; nuevo hook sin prueba de juego |
| 0x18f9518 | src/core/sigma2_hook.hpp | Único destino de CAS/VirtualProtect del hook Sigma2 | RUNTIME VERIFIED para slot; BUILD/HARNESS VERIFIED para implementación |

Base dinámica. Guards de cabecera + igualdad de puntero, no hash en código. Otros offsets/patches legacy no reciben nuevas confirmaciones por esta compilación.

## Fase 6 — preparación Player/XYZ (sin validación runtime nueva)

Hito 151ea14 e INGAME_TEST_01 PASS preservados. Investigación separada en [PLAYER_RESEARCH.md](PLAYER_RESEARCH.md). Tablas legacy game_object RVA 0x3195300/stride 0x30 y character RVA 0x2f78b10/stride 0x1240, enlazadas en fuente por group +0x1f: candidatos, NO resolver Player confirmado. limb_data.location_vec pertenece a miembros separados; no es posición de Ryu demostrada. No cambios en hook/core/DLL ni nueva ejecución; esperando RYU QUIETO para snapshot A acotado. Player/XYZ solo serán RUNTIME VERIFIED tras A/B/C y reinicio. Sin commit de hipótesis.

### Player snapshot A (reposo) obtenido

PID 12404; EXE/base/core/slot activo verificados sin escrituras. PLAYER_SCAN_A_IDLE contiene dos muestras de 166760 bytes separadas por 2 s, tablas candidatas y bloques referenciados. Triples plausibles presentes en varios grupos; ningún Player/XYZ confirmado, falta movimiento B/C y reinicio. Herramienta player_snapshot.py es capturador acotado, NO resolver. Evidencia/método en PLAYER_RESEARCH.md. Sin commit de hipótesis ni cambios core.

### Player snapshot B (movimiento) obtenido

Mismo proceso, dos muestras quietas B. Candidato float3 object[0].ptr0+0x2b0 coincide con character group 0+0x310: A (65.1453,5.22,-109.8843) -> B (81.9927,6.4168,-92.9247), estable dentro de A y B. Es candidato, NO Player/XYZ RUNTIME VERIFIED; falta C y reinicio, ejes físicos sin asignar. Detalles en PLAYER_RESEARCH.md y AB_shortlist.json. Sin commit ni cambios core.

### Player snapshot C (más alto) obtenido

Triple candidato C=(109.80220032,7.99999952,-138.06065369), coincidente en object[0].ptr0+0x2b0 y character[group=0]+0x310, estable en pareja y tres lecturas pequeñas posteriores. Usuario confirma más altura: componente 1 compatible con vertical, aún sin aislamiento físico. A/B/C refuerzan candidato; resolver/Player/XYZ NO RUNTIME VERIFIED hasta nuevo arranque. Próxima interacción: cerrar normalmente y confirmar antes de pedir reinicio. Evidencia en PLAYER_RESEARCH.md, ABC_candidates.json y C_targeted_stability.json; sin commit/core changes.

### Player research — cierre para reinicio confirmado

Primera sesión A/B/C terminada normalmente según usuario; PID 12404 ausente, sin proceso NINJA activo. Resolver/XYZ siguen candidatos, pendientes de nuevo arranque. Evidencia restart_shutdown.json; sin memoria escrita, core modificado ni commit de hipótesis.

## Player resolver — RUNTIME VERIFIED tras reinicio (2026-09-06, PID 12404 → PID 16942)

Reproducido en un arranque nuevo del juego. Solo lectura. Detalle en [PLAYER_RESEARCH.md](PLAYER_RESEARCH.md) y `research/player/restart_validation.json`. Todos los valores son RVA sobre base dinámica `GetModuleHandle(nullptr)` (observada 0x140000000, delta ASLR 0 en ambas sesiones).

| RVA / campo | Uso | Sección | Estado |
|---|---|---|---|
| 0x3195300 | Root del resolver: tabla game_object, stride 0x30. `u64[root + index*0x30]` → objeto; `u8[root + index*0x30 + 0x1F]` → group. index 0 = Ryu en esta misión | .data | **RUNTIME VERIFIED** como root del resolver (reproducido tras reinicio; entrada 0 = Ryu no generalizado a otros personajes/misiones) |
| 0x3197100 | Objeto resuelto para entrada 0 en esta build = `module_base + 0x3197100` (datos estáticos del EXE, NO heap). No registrar como offset permanente del layout; es a dónde apunta la entrada 0 en esta imagen | .data (imagen EXE) | **RUNTIME VERIFIED** (misma RVA en dos procesos; cadena module-relative) |
| objeto + 0x2B0 / +0x2B4 / +0x2B8 | float3 de posición del jugador (C0 horizontal, C1 = vertical, C2 horizontal) | — | **RUNTIME VERIFIED** como float3 ligado a posición: estable en reposo, se mueve con el jugador, corroborado en dos tablas y dos procesos. Etiquetado X/Z y handedness: **CANDIDATE** |
| 0x2F78B10 + group*0x1240 + 0x310 / +0x314 / +0x318 | float3 corroborante en la tabla character; coincide bit a bit con object+0x2B0 en reposo | .data | **RUNTIME VERIFIED** como copia coincidente de posición; cuál es autoritativa: sin determinar |
| 0x18F9518 | Slot Sigma2 usado como gate de continuidad del hook (`u64[base+0x18F9518] == core_base + 0x16F2`) | .rdata | CONFIRMADO (ya RUNTIME VERIFIED en hitos previos; re-verificado vivo esta sesión) |

Valores de referencia (C0, C1/Y, C2): A (65.14528656, 5.21999979, -109.88428497) · B (81.99269867, 6.41679859, -92.92471313) · C (109.80220032, 7.99999952, -138.06065369) · RESTART_MOVED (74.63035583, 5.21999931, -135.97770691). La Y de reposo se mantiene ~5.2200 en A y en la sesión de reinicio (mismo plano de suelo).

Cadena para documentación (equivalente, solo lo demostrado):

```
module base
  + 0x3195300  ->  game_object table
      entrada[0]  ->  puntero al objeto  (= module_base + 0x3197100 en esta build)
          + 0x2B0 / +0x2B4 / +0x2B8  ->  float3 posición
corrobora: module base + 0x2F78B10 + group*0x1240 + 0x310/+0x314/+0x318
```

Herramientas solo lectura: `tools/player_resolver.py` (descubre Player, imprime PID/base/address/posición; valida hashes + slot; sin escritura/attach/inputs), `tools/player_stability_probe.py` (sonda de estabilidad acotada). Ningún offset de producción modificado; sin cambios en core/hook/instalación.

## Player transform — FASE 7: semántica XYZ + rotación (2026-09-06, PID 16942)

Solo lectura. Detalle en [PLAYER_RESEARCH.md](PLAYER_RESEARCH.md) y `research/player/transform_characterization.json`. RVA sobre base dinámica.

| Field | Offset | Representation | Evidence | Status |
|---|---|---|---|---|
| Player resolver | `module_base + 0x3195300` → entrada 0 → objeto; group en +0x1F | tabla game_object (stride 0x30) + puntero | reinicio + 2ª misión, descubrimiento automático | **RUNTIME VERIFIED** |
| Position C0 = X | object + 0x2B0 | float32, world X | correlación movimiento ↔ vector forward de la matriz (~3°); base compartida | **RUNTIME VERIFIED** (MEDIA-ALTA) |
| Position Y | object + 0x2B4 | float32, world Y (arriba) | sesión C (altura) + `row1 ≈ world +Y` + estable en suelo plano | **RUNTIME VERIFIED** |
| Position C2 = Z | object + 0x2B8 | float32, world Z | correlación movimiento ↔ vector forward (~3°) | **RUNTIME VERIFIED** (MEDIA-ALTA) |
| Position history ring | object + 0x2B0 / +0x2E0 / +0x310 / +0x340 / +0x370 | float3, stride 0x30 | +0x2B0 actual/autoritativa; +0x310 visual (retrasa); +0x340/+0x370 posiciones anteriores | CANDIDATE (estructura) |
| Rotation matrix | `module_base + 0x2F78B10 + group*0x1240 + 0x80` (filas +0x80 right / +0x90 up / +0xA0 forward, 4 floats c/u) | matriz 3×3 row-major, right-handed | `det = +1` en 6 capturas; ortonormal; ROTATION_TEST A/B/C coherentes; copias en +0x100/+0x67C/+0x1020/+0x1040/+0x10EC | **RUNTIME VERIFIED** (yaw; pitch/roll sin ejercitar) |
| Coordinate handedness | — | right-handed, Y-up | `det = +1`, `row0×row1 = row2`, `row1 ≈ +Y` | CANDIDATE→FUERTE (MEDIA-ALTA) |
| Rotation refs descartados | `char+0x76C` (quat yaw fijo -45.3°); `obj+0x60/0xB0/0x1B0/0x1D0` (quats) | float4 norma≈1 | sin cambio al girar Ryu | REJECTED como facing vivo del jugador |
| Character identity | `game_object[0].obj_id` = 0 (rec +0x18); group 0 (rec +0x1F) | uint8 | sigue al personaje controlado; Ryu-vs-otros sin id/nombre/RTTI | **CANDIDATE** |

`0x2F78B10` deja de ser solo LEGACY: la tabla character group 0 contiene la matriz de rotación viva del jugador en +0x80 y la copia de posición en +0x310. `0x3195300` entrada 0 sigue siendo el root del resolver (RUNTIME VERIFIED). Ningún offset de producción del código modificado.

## FASE 8 — clasificación de actores (metodología, sin offsets nuevos)

Sin offsets nuevos. Recordatorio de estructura usada por `tools/actor_classifier.py` (solo lectura), todo ya documentado arriba:
- `game_object` table: `module_base + 0x3195300`, stride `0x30`, ≤160 entradas. Por entrada: puntero objeto `+0`, `obj_id` `+0x18`, `group` `+0x1F`, meta `+0x18..+0x20`.
- posición por entrada: `object + 0x2B0/+0x2B4/+0x2B8` (RUNTIME VERIFIED solo para la entrada 0; candidato para el resto hasta correlacionar movimiento). Muchas entradas dan `(0,0,0)` → objetos no espaciales.
- rotación por grupo: `module_base + 0x2F78B10 + group*0x1240 + 0x80` (matriz 3×3). Varias entradas comparten `group`.

Criterio `LOCAL_PLAYER_STABLE`: 10 muestras, intervalo 0.5 s, tol. horizontal 0.05 u, tol. vertical 0.05 u. Detalle y justificación en [TEAM_MISSION_RESEARCH.md](TEAM_MISSION_RESEARCH.md).

## FASE 8 — actores Team Mission (sin offsets de módulo nuevos)

Sin RVA de módulo nuevos. Discriminadores de actor sobre estructuras ya documentadas (`game_object` en `module_base + 0x3195300`, `character` en `module_base + 0x2F78B10`):

| Campo | LOCAL_PLAYER | AI_PARTNER (STRONG CANDIDATE) | ENEMY |
|---|---|---|---|
| `game_object` index | 0 | 4 (estable entre misiones de esta sesión; falta reinicio) | recicla |
| `game_object` rec +0x1F (group) | 0 | 1 (2 misiones) | ≠ 0 |
| `char[group] + 0x00` | 0x00 | 0x04 | 0x04 |
| `char[group] + 0x04..0x06` | `0000` | `0000` / `0909` (no `9898`) | `9898` / `c2c2` / `ffff` |
| `char[group] + 0x210` (dead legacy) | 0 | 0 | 4 si derrotado |
| `object + 0x60` quaternion | unitario | unitario | ceros / (0,0,0,0) si muerto |
| `object + 0x90` header | poblado | poblado | ceros |
| `game_object` rec +0x18 (`obj_id`) | 0 | 219 / 220 — **contador de spawn, NO id de personaje** | 4 / 41 / 23 / 8 / 42 |

Objeto del compañero en RVA `0x319cdb0` en esta sesión: **dirección de ejemplo**, no offset permanente (falta reinicio). `LOCAL_PLAYER_STABLE`: 10 muestras / 0.5 s / tol. 0.05 u. Detalle en [TEAM_MISSION_RESEARCH.md](TEAM_MISSION_RESEARCH.md).

## FASE 9 — actor restart validation (discriminadores confirmados tras reinicio)

Sin RVA de módulo nuevos. Tras arranque completo nuevo (PID 29318), sobre estructuras ya documentadas:

| Señal | LOCAL_PLAYER | AI_PARTNER (RUNTIME VERIFIED, rol) | ENEMY |
|---|---|---|---|
| `game_object` index | 0 | 4 (3 Team Missions + reinicio; base determinista) | recicla |
| `game_object` rec + 0x1D (byte) | 0x00 | 0x04 | — |
| `game_object` rec + 0x1F (group) | 0 | 1 | ≠ 0 |
| `char[group] + 0x00` (byte) — `CONTROL_DISCRIMINATOR_CANDIDATE` | **0x00** | 0x04 | 0x04 |
| `char[group] + 0x04..0x06` | `0000` | `0000` / `0909` / `2828` (∉ firma enemiga) | `9898` / `c2c2` / `ffff` |
| `char[group] + 0x16` (byte) — `CHARACTER_ID_CANDIDATE` (baja confianza) | `0x4e` (Ryu) | `0xb6` (Ayane) | — |
| `char[group] + 0x210` (dead legacy) | 0 | 0 | 4 si derrotado |
| `char[group] + 0x1e8/+0x1ec` | ≈4530/4565 (Ryu) | ≈4271/4342 (Ayane) — plausiblemente HP máx | — |
| `object + 0x60` quaternion / `object + 0x90` header | vivo / poblado | vivo / poblado | ceros / (0,0,0,0) si muerto |
| `object + 0x98` (byte) | 0x02 | 0x04 | — |
| `game_object` rec + 0x18 (`obj_id`) | 0 | 219 / 220 — **contador de spawn, NO id de personaje (REJECTED)** | varía |

`0x319cdb0` = dirección de ejemplo del objeto del compañero (base determinista bajo este Proton; no offset permanente). PITCH/ROLL de `char[group]+0x80`: **NOT VERIFIED**; yaw/matriz RUNTIME VERIFIED. Detalle en [TEAM_MISSION_RESEARCH.md](TEAM_MISSION_RESEARCH.md) §4h y [MVP2_WRITE_PLAN.md](MVP2_WRITE_PLAN.md).

## FASE 10 — copias de posición del jugador (clasificadas; ninguna canónica)

Sin RVA de módulo nuevos. Sobre `object` (game_object[0] → RVA 0x3197100) y `character[group]` (RVA 0x2F78B10 + grp*0x1240):

| Offset | Estructura | Clasificación (Fase 10) |
|---|---|---|
| object +0x2B0 / +0x2E0 / +0xAF0 / +0xB20 / +0x1330 / +0x1360 / +0x1930 | object | RENDER/OBSERVABLE COPY (sigue al jugador exacto; escrito cada frame por copia de bloque; **revertido en <150 ms** tras escribir en MVP 2) |
| character[grp] +0x310 / +0xFE0 / +0x1010 / +0x10E0 / +0x1120 / +0x1160 / +0x1170 | character | RENDER/OBSERVABLE COPY |
| object +0x310 (+ transitorios +0xB50 / +0x1390) | object | INTERPOLATED POSITION (lag en movimiento) |
| object +0x340 / +0x370 | object | HISTORICAL/PREVIOUS POSITION (ring) |
| — | — | CANONICAL POSITION: **no localizada** (escrita dentro de `object` cada frame desde una fuente no aislada; hilo «Updating»; RVA de la copia 0x8C7B4 / 0x1353E41 / 0xEAD02E) |

`object+0x2B0/+0x2B4/+0x2B8` sigue RUNTIME VERIFIED **como posición observable** (Fase 7) pero **NO es escribible de forma persistente** (Fase 10). AI_PARTNER (game_object[4]) tiene la misma arquitectura de copias. Detalle en [CANONICAL_POSITION_RESEARCH.md](CANONICAL_POSITION_RESEARCH.md).

## FASE 11 — fuente autoritativa de transform (PID 14042, 2026-09-07)

Solo lectura (volcado `.text` runtime + capstone offline + `awatch` gdb). Detalle en [TRANSFORM_SYNC_RESEARCH.md](TRANSFORM_SYNC_RESEARCH.md). RVA sobre base dinámica; **específicos de esta build** `a66daf…` (no validados como firmas estables entre versiones).

### Bloque de estado de movimiento en `object` (`game_object[N] → object`)

| Offset | Estructura | Representación | Evidencia | Estado |
|---|---|---|---|---|
| `object + 0x4B80` | movement block | float3 posición mundo (X,Y,Z,0) | leída por `0xF7BB70` para producir `object+0x2B0`; se movió 14.55 u en lockstep con `+0x2B0` (xcorr r=1.0); layout equivalente en AI_PARTNER | **`CANONICAL_POSITION_STRONG_CANDIDATE`** (MEDIA-ALTA) |
| `object + 0x4BC0` | movement block | float3 velocity / vector de movimiento | `(0,0,0)` en reposo (Ryu y Momiji); `(0,0,1.985)` caminando en −Z; `addss [obj+0x4BC0], xmm` en el integrador `0xF8190E` | **VELOCITY** (RUNTIME, correlación de 1 movimiento) |
| `object + 0x4BD0` | movement block | float4 (X,Y,Z,1) centro de cápsula de colisión | X/Z ≈ posición, Y ≈ posición.Y + ~1.10; jitter ~0.03 en reposo | CANDIDATE (cápsula) |
| `object + 0x1AB0 .. 0x1AE0` | object | matriz 3×3 (+ fila 0001) — copia de la rotación de `char[grp]+0x80` | usada por `0xF7BB70` / `0xF8A8C0` al aplicar transform | RENDER/OBSERVABLE COPY (rotación) |

### Funciones (RVA de esta build; NO firmas estables)

| RVA | `.pdata` begin–end (unwind) | rol |
|---|---|---|
| `0x1353E37` | fragmento `[0x1353D92, 0x1353E84]` (`0x1C02714`) | **escribe `object+0x2B0` = xmm6** (store real; la Fase 10 apuntó a `0x1353E41`, que es la instrucción siguiente) |
| `0x1353D00` | `[0x1353D00, 0x1353D92]` (`0x1C02708`) + fragmento | sync de transform por actor `(rec, idx)` → llama `0xF7BB70`, escribe `+0x2B0/+0x2C0/+0x1930/+0x1940` |
| `0x1354390` | `0x1354390–0x13545F3` (`0x1C027C8`) | bucle per-frame sobre `game_object[0..0xA0]` (stride 0x30) |
| `0x136CBC0` | `0x136CBC0–0x136D05B` (`0x1C03964`) | driver multi-pass de update; llama `0x1354390` @ `0x136CE11` |
| `0xF7BB70` | `0xF7BB70–0xF7BC13` (`0x1B970AC`) | LOD/prioridad; **lee `object+0x4B80` y `character[grp]+0x10E0`** |
| `0xF8E420` | `0xF8E420–0xF8E85F` (`0x1B98B20`) | productor de los vectores; despacha por `char[grp]+0x04` (0xC6..0xCA), llama `0xF7B430` |
| `0xF8E280` | `0xF8E280–0xF8E379` (`0x1B98B14`) | gate: deriva `character[group]`, comprueba `char[grp]+0x0B != 0x77` |
| `0xF8190E` | fragmento (`0x1B97808`) | integrador: `addss [obj+0x4BC0]` + matriz `obj+0x1AB0` → `movdqa [obj+0x4B80]` (writer de `+0x4B80`) |
| `0xF8A8C0` | `0xF8A8C0–0xF8A943` (`0x1B986FC`) | primitiva "aplicar transform a actor(cx)": `(cx, dx, r8=&pos, r9=&mat)` → escribe `obj+0x4B80` + `obj+0x1AB0` |
| `0x1462160` | `0x1462160–0x146218F` (`0x1C13C38`) | stub de dispatch del sistema de update: `call qword [rcx+0x10]` (`rcx = [rip+0xDD3CF9]`) |

### `.text` runtime — volcado

`docs/research/runtime_text/20260907T1650Z_pid14042/` (`.bin` git-ignored; manifest tracked).
`.text` RVA `0x1000` size `0x179C2E0` SHA256 `193894e5311dd6e5452aa9e9940d28bdf1b1e007927991cd72f598f0790bfec5`.
PE `TimeDateStamp` 2021-07-08 09:16:09 UTC. 104838 `RUNTIME_FUNCTION` en `.pdata`.

## FASE 12 — writers de `object+0x4B80` (posición canónica), 2026-09-07 (PID 14042)

Hardware write-watchpoints de solo observación. Detalle en [CANONICAL_WRITER_TRACE.md](CANONICAL_WRITER_TRACE.md). RVA de esta build `a66daf…`; **NO firmas estables**. Thread "Updating".

| RVA | `.pdata` / forma | rol | actor |
|---|---|---|---|
| `0x141BB90` (`0x141BBC1` = `movss [rax],xmm1` tras `addss xmm1,[rax]`) | leaf, sin `.pdata`; call directo | **W1 — integración de locomotion**: `object+0x4B80 += delta4` (`rcx+0x10` = object; `rdx` = delta; guard NaN) | LOCAL_PLAYER + AI_PARTNER |
| `0x14249A0`–`0x1429E38` (`0x5498`, unwind `0x1C0FA14`) | sí | update per-actor ≈21 KB; construye `delta = movement_vector * scale` y llama `0x141BB90` @ `0x1429B92` | ambos |
| `0x1420F60`–`0x14215C3` (`0x663`, unwind `0x1C0F554`) | sí | dispatcher de update de movimiento: `(edx = índice)` → `&game_object[edx]` (`module_base+0x3195300`) → global `[rip+0x4FD06F5]` → `0x14249A0` @ `0x14211C5` | ambos |
| `0x1420841`–`0x142099E` (`0x15D`, unwind `0x1C0F4EC`), store `0x14208DD` (`movdqu [rax+0x4B80], xmm0`) | sí | **W2 — commit de transform**: `xmm0` = resultado de `call 0x6FDE0` (matriz), w=1; `rax` = puntero global al jugador activo (`[rip+0x4FD0DD3]`); luego `-` constante `[rip+0x4FD0DD7]` | ambos |
| `0x1353A5C` (`movdqu [rax],xmm0`), `0x1353EF9` (`movdqa [rax],xmm6`) | fragmentos de `0x135399A`–`0x1353AB9` / `0x1353EF1`–`0x1353F02` | familia transform-sync per-actor (la misma que escribe `+0x2B0`); escribe `+0x4B80` **solo visto para el AI_PARTNER** | AI_PARTNER |
| `0xF8190E` (`movss [rbx+0x4BC0],xmm0` + escribe `+0x4B80`), `0x14218C0` (`movdqa [rax+0x4BC0],xmm0`), `0x14219A0` (`movss [rax+0x4BC0],xmm0`) | fragmentos / `.pdata` | writers de `object+0x4BC0` **velocity** — mismo subsistema, mismo puntero global | ambos |
| `0x6FB20` | leaf | copiador de 16 bytes (`*rcx = *rdx`) — NO es rotación; solo mueve el delta a un buffer | — |

`object+0x4B80` = **`CANONICAL_POSITION_RUNTIME_VERIFIED`** (confianza ALTA): escrito por `pos += delta` (locomotion) + commit de transform, nunca por `memcpy`; alimenta `object+0x2B0` (Fase 11); `+0x4BC0` velocity coherente; repetido en 2 movimientos; mismos writers en AI_PARTNER. Prueba definitiva de persistencia = MVP 2B (diseñada, NO ejecutada).


## MVP 2B EJECUTADO — PASS (2026-09-07)

`object+0x4B80` escrito una vez (`+0.30` X, `tools/player_write_test_2b.py`, autorizado por el usuario). **La escritura se mantuvo ~3.5 s** (el motor NO la revirtió) y **`object+0x2B0` convergió** al valor nuevo en ≤ 1 frame; restauración `EXACT`; sin crash; Y/Z/velocity/rotación/AI_PARTNER intactos. Usuario: `NO NOTE MOVIMIENTO PERO TODO NORMAL` (delta pequeño para la escala del mundo, no reversión). ⇒ `object+0x4B80` es **escribible de forma persistente y propaga** — primitivo de teleport real. Detalle: [MVP2B_WRITE_TEST_01.md](MVP2B_WRITE_TEST_01.md).


## FASE 13 — cadena de control de locomoción (2026-09-08, PID 14042)

Detalle: **[LOCOMOTION_CONTROLLER_RESEARCH.md](LOCOMOTION_CONTROLLER_RESEARCH.md)**. Solo lectura/observación (probe + write-watchpoints + `detach`). Proceso vivo tras la sesión, hook Sigma2 re-verificado.

- **`character[group] + 0x30` (float4)** = **comando de dirección de movimiento (suavizado)**: `(0,0,0,0)` en reposo, específico de dirección al moverse, **idéntico para LOCAL_PLAYER y AI_PARTNER** (Momiji: no-cero solo cuando siguió a Ryu). Es lo que `0x14249A0` consume para construir el delta de W1 (`object+0x4B80 +=`). ⇒ **`REMOTE_CONTROL_INJECTION_CANDIDATE` (STRONG CANDIDATE)** — punto de convergencia input-local / cerebro-IA.
- **`character[group] + 0x04` (byte)** = **state code de locomoción / selector de animación**: `0x00` idle, `0x06` start, `0x0A` lateral, `0x26/0x28/0x2A` walk/run, `0x48` run de IA. Enum compartido; es el selector de la jump table de `0x14249A0`. Un teleport puro (solo `+0x4B80`) deja `char+0x04 = 0` → sin animación (lo observado en MVP 2B +10.0).
- **`character[group] + 0x24`** = parámetro de locomoción del estado (tabla de animación, escrito por `0xF1ECA0`), **no** magnitud de stick.
- **`object + 0x4BC0` (velocity)** = **resultado DERIVADO** (velocity real suavizada, ease-in ~0.5 s, publicada para animación/cámara) — **no** la entrada de la integración de locomoción.
- **Writer de `char+0x30`**: pc `0xF25054` (`movdqu [char+0x30], xmm3`) en fn `0xF24F4A`, hilo "Updating" — un **filtro EMA**: `char+0x30 = char+0x30_old*decay + input_sample*weight` (la `w` hace ease-in `0.25→1.0` al acelerar). La muestra viene de una tabla/ring indexada por un contador de frame global (`[rip+0x20815D8]` base — RVA exacta sin confirmar).
- Siguiente experimento (**solo diseño, NO ejecutado, NO autorizado**): escribir una dirección unitaria en `char+0x30` durante ~N frames (el EMA exige varios) en `LOCAL_PLAYER_STABLE` → Ryu debería **caminar con animación** (sin teleport, delta acotado por el speed-clamp `0x1469F60()`).


## FASE 13c — fuente de `object+0x5000` (2026-09-08)

Detalle: **[REMOTE_CONTROL_INJECTION_RESEARCH.md](REMOTE_CONTROL_INJECTION_RESEARCH.md)**. Solo observación (write-watchpoints + `detach`).

- **Writer de `object+0x5000` = `0xFF2E0B` en `0xFF282A`** (bucle per-actor sobre `game_object` table, `lea rcx,[r14+0x3195326]`), hilo "Updating". **Idéntico para LOCAL_PLAYER y AI_PARTNER** (46 hits cada uno; solo cambia `rsi` = obj del actor). Call stack byte-idéntica.
- `object+0x5000 = *(float4*)(object + 0x5C06 + off_tabla)` — `0xFF282A` copia desde el **área de comando crudo per-actor `object + ~0x5C06`** a `object + 0x5000`. La divergencia **input local (Ryu) vs cerebro de IA (Momiji)** está aguas arriba, en quién rellena `object + ~0x5C00` — **NO capturado**.
- Representación: float4, `(0,0,0,0)` en reposo (campo no escrito), `(dir_x, ~0, dir_z, w=1)` al moverse; **mismo formato ambos actores**.
- `REMOTE_CONTROL_INJECTION` = **STRONG CANDIDATE**: nivel de inyección preferido = `object + ~0x5C00` (comando crudo) o re-escritura per-frame de `object+0x5000`; `char+0x30` directo lo amortigua el EMA. Player 2 remoto sobre Ryu no requiere tocar la IA; sobre Momiji sí (neutralizar el cerebro que escribe su `object + ~0x5C00`). Experimento de movimiento natural: solo diseñado, NO ejecutado, NO autorizado.


## FASE 14 — fuente cruda del comando de movimiento por actor (2026-09-08)

Detalle: **[RAW_MOVEMENT_COMMAND_RESEARCH.md](RAW_MOVEMENT_COMMAND_RESEARCH.md)**. Solo observación (hardware watchpoints + `detach`).

- **El "área de comando crudo per-actor" queda pinneada a `object + 0x4B90`** (float4; bloque de estado de movimiento: `+0x4B80` posición · **`+0x4B90` comando crudo** · `+0x4BA0` facing · `+0x4BC0` velocity · `+0x4BD0` cápsula). `0xFF282A` copia `object+0x4B90 → object+0x5000` con offset **exacto** `0x5C06 - 0x1076` (`rdi = 1` para Ryu **y** Momiji). `object+0x5000` va **1 frame por detrás**. `(0,0,0,0)` en reposo ambos actores.
- **Writer de `object+0x4B90` (LOCAL_PLAYER, capturado):** `0x14210A0` (`movdqu [rax+0x4B90], xmm4`, `rax` = object) en el **bucle per-actor `0x1420F60`–`0x14215C3`**, hilo "Updating" — 50 hits, todos Ryu. Caller `0x142C499` en `0x142C460` (`for edx = 0 .. 0xA0 { call 0x1420F60(edx) }`). Lógica: si `byte[object+0x5B56] == 0` ⇒ `object+0x4B90 = (0,0,0,0)`; si no ⇒ `[module_base+0x63F16B0] = 0` (`0x142101B`), `call 0x14203E0` (`0x1421032`), `object+0x4B90 = [0x63F16B0] + character[group][0xFA0]`.
- `[module_base + 0x63F16B0]` = **scratch global float4** del comando; lo rellena `0x14203E0` por actor. Watchpoint: 46 hits/idle, 2 writers alternando — `0x142101B` (zero) y `0x142082B` (dentro del árbol de `0x14203E0`, fn `0x142015B`–`0x142099E`).
- `character[group] + 0xFA0` = término aditivo per-actor; **`(0,0,0,0)` para Ryu y Momiji** — watchpoint WRITE: **0 hits** durante movimiento (sin uso en este escenario; posible aim-assist / nudge).
- **`0x14203E0` = RAW_COMMAND_PRODUCER.** Head: manager de input `[rip+0x4FD12B0]` (bytes `+0x12`/`+0x13`/`+0xF8A`/`+0xF85`, `0xFF` = sin asignar; gate `+0xC` → si `!= 0` fuerza `bl = 0xFF` = **`CONTROL_MODE_CANDIDATE`**); managers `[rip+0x4FD1215]` (`word +0x1FA` state) y `[rip+0x4FD11DF]` (gate object `+0x5B6D`); jump-table interna. **La rama exacta input-device (Ryu) vs AI-brain (Momiji) DENTRO de `0x14203E0` NO se aisló.**
- **AI_PARTNER:** `0x1420F60` corre en el **mismo bucle** `for edx = 0 .. 0xA0` para **todos** los actores ⇒ el writer de `object+0x4B90` de Momiji es el mismo `0x14210A0` / `0x1420F60` / `0x14203E0`. El watchpoint combinado no disparó en la dirección de Momiji (Ryu, edx 0, llenó el `MAX=50` antes que edx 4). **Falta captura Momiji-only en runtime.**
- **Divergencia** = dentro de `0x14203E0` (sin aislar). **Convergencia** = `object + 0x4B90` (writer compartido `0x14210A0`). De ahí abajo (`0xFF282A` → `object+0x5000` → EMA `0xF24F4A` → `char+0x30` → `0x14249A0` → W1 `0x141BB90`) = código compartido RUNTIME VERIFIED (Fases 12/13).
- Representación del raw command: **float4**, `(0,0,0,0)` idle, `(dx, ~0, dz, w=1)` activo (`w` = comando activo); mismo layout `object+0x4B90` == `object+0x5000`; 1×/actor/frame; per-frame (no persiste solo).
- **`REMOTE_PLAYER_CONTROL_POINT` (candidato): `object + 0x4B90`** reescrito cada frame **después** de `0x1420F60`, o hook de `0x14203E0` / del escritor `0x1420833` de `[0x63F16B0]`. Downstream 100 % compartido y verificado, produce locomoción + animación naturales, delta acotado por el speed-clamp (sin teleport). `char+0x30` directo lo amortigua el EMA. Player 2 remoto sobre Ryu = bloquear el poll de input (hook de `0x14203E0` o el `CONTROL_MODE_CANDIDATE`); sobre Momiji = neutralizar la rama de IA dentro de `0x14203E0`.
- `REMOTE_CONTROL_INJECTION` = **STRONG CANDIDATE**. Falta: writer de `object+0x4B90` de Momiji en runtime; aislar la rama input↔IA de `0x14203E0`; confirmar `CONTROL_MODE_CANDIDATE` (`[rip+0x4FD12B0]+0xC`). Experimento de movimiento natural: solo diseñado, NO ejecutado, NO autorizado.
- Evidencia: `docs/research/locomotion/watch_ryu_obj4B90_moving.txt` (50 hits del writer `0x14210A0`), `watch_gcmd_63F16B0.txt` (writers de `[0x63F16B0]`), `watch_charFA0_none.txt` (0 hits), `wp_4b90.gdb`, `wp_g5b0.gdb`.


## FASE 15 — AI raw command confirmado + divergencia de control (2026-09-08)

Detalle: **[RAW_MOVEMENT_COMMAND_RESEARCH.md](RAW_MOVEMENT_COMMAND_RESEARCH.md)** §15. Solo observación (hardware watchpoints + `detach`).

- **`RAW_COMMAND_SHARED_WRITER = RUNTIME VERIFIED.`** Watchpoint sobre `MOMIJI object+0x4B90`: 40/40 hits en `0x14210A0` (`movdqu [rax+0x4B90], xmm4`), fn `0x1420F60`, thread "Updating", call stack byte-idéntica a Ryu, `rbx = 4` (índice de actor), `r9 = char[1]`, `xmm4 = [module_base+0x63F16B0] + char[1]+0xFA0` (fórmula idéntica), `object+0x5000` 1 frame por detrás, `char[1]+0x04` `0x06→0x26`.
- **`0x14203E0` es un chunk de una función per-actor GENÉRICA** (`~0x142015B–0x1420BF9`, encadenada). Sus punteros base son globales de bucle per-actor fijados por `0x1420F60`: `[rip+0x4FD12B0] = G_CHARACTER` (`0x63F16A8`), `[rip+0x4FD11DF]/4FD1271 = G_OBJECT` (`0x63F16A0`), `[rip+0x4FD112C] = G_GO_REC` (`0x63F1698`), store del comando `[rip+0x4FD0E7D] = g_scratch` (`0x63F16B0`). **Corrección Fase 14:** `[rip+0x4FD12B0]` NO es un "manager de input" — es `character[group]`; los bytes `[r9+0x12]`/`[r9+0x13]`/`[r9+0x0C]`/`[r9+0xF8A]`/`[r9+0xF85]` son campos de `character[group]`.
- `0x14203E0` lee el **action code** `char[group]+0x12` (fallback `+0x13`), y **NO ramifica por local/IA**. Única branch relevante: `0x142046B cmp byte [char[group]+0x0C], 0 ; 0x1420475 cmovne ebx, 0xFF` = **control-lock** (`!=0` ⇒ sin acción ⇒ `0x14204B4 je` ⇒ `g_scratch=0` ⇒ `object+0x4B90=(0,0,0,0)`). `char+0x0C = 0x00` para Ryu **y** Momiji (no es el discriminador). W2 (`0x14208DD`, commit de `object+0x4B80`, Fase 12) está DENTRO de esta misma función.
- **El writer de los action codes `char[group]+0x12` también es COMPARTIDO**: watchpoint sobre `char0+0x10`/`char1+0x10` (60 hits) → 3 RVAs (`0xF1ED0F` en `0xF1ECA0`; `0xF24BF7`; `0xF2480C`), **todas compartidas Ryu/Momiji, call stacks byte-idénticas**. `char[group]+0x12 = call 0xF88C40(...) ? result[7] : 0xFF` (lookup genérico en tabla de descriptores de acción; 41 call sites). `0xF1ECA0` corre dentro del árbol `0xF24F4A` (el del EMA de `char+0x30`).
- **La divergencia local↔IA NO está en la ruta del comando de movimiento** — toda `0xF1ECA0 → 0x14203E0 → 0x1420F60 → object+0x4B90 → 0xFF282A → object+0x5000 → EMA → char+0x30 → 0x14249A0 → W1` es código compartido genérico per-actor, RUNTIME VERIFIED para ambos. La divergencia está en la **capa de comportamiento / estado deseado** aguas arriba de `0xF1ECA0` (para Momiji: región `0xF31D8D–0xF324E5` / `0xF7BDE0–0xF7BE85` en la call stack — **no reconstruida**; para Ryu: el traductor input físico → estado deseado — **no localizado**). Discriminador de clase = `character[group]+0x00` (`0x00` local / `0x04` IA).
- **Clasificación:** `character[group]+0x00`, `character[group]+0x0C`, `object+0x5B56` = **CONTROL_MODE_CANDIDATE**. `[rip+0x4FD12B0]/4FD1215/4FD11DF/4FD112C` = **REJECTED** (son `G_CHARACTER`/`G_OBJECT`/`G_GO_REC`). Índice de actor (`rbx=4`, `G_ACTOR_INDEX 0x63F1690`) = **REJECTED** (var de bucle). Región `0xF31D8D`/`0xF7BDE0` = **AI_CONTROLLER_CANDIDATE**. Traductor de input de Ryu = **LOCAL_INPUT_OWNER_CANDIDATE** (sin dirección).
- **`AI_COMMAND_SOURCE_STRONG_CANDIDATE`** — entra por `char[1]+0x12/+0x13` + estado deseado; capa de comportamiento identificada en la pila, no reconstruida.
- **`PREFERRED_REMOTE_CONTROL_LEVEL = C`** (reescribir `object+0x4B90` cada frame tras `0x14210A0`: el más simple, downstream 100 % compartido y verificado, network-friendly), con **B** (hook de `0x14203E0` / `g_scratch`) como opción "más correcta". **Caveat C** (como MVP 2B): si el motor no lleva `char[group]+0x04` a walk, `0x14249A0` no integra el delta ⇒ posición sin animación; el test debe medirlo y escalar a B/A si hace falta.
- **`REMOTE_PLAYER_CONTROL_POINT = STRONG CANDIDATE`** (no RUNTIME VERIFIED: falta la branch local↔IA y la fuente de IA reconstruida). Confianza: ALTA en "`object+0x4B90` raw command compartido + downstream verificado ambos actores"; MEDIA en "reescribir sólo el raw command produce locomoción natural completa".
- Test de movimiento natural: **sólo diseñado** (RAW_MOVEMENT_COMMAND_RESEARCH.md §15.11), Execution authorized = **NO**.
- Evidencia: `docs/research/locomotion/watch_momiji_obj4B90_moving.txt` (40 hits), `watch_char12_action_moving.txt` (60 hits), `wp_4b90_momiji.gdb`, `wp_char12.gdb`.


## FASE 16 — NATURAL MOVEMENT TEST 01 (2026-09-07)

Detalle: **[NATURAL_MOVEMENT_TEST_01.md](NATURAL_MOVEMENT_TEST_01.md)**. Primer experimento con escritura desde MVP 2B; autorizado (un único test sobre LOCAL_PLAYER). Herramienta `tools/raw_command_movement_test.py` (fail-closed). Solo se escribió `LOCAL_PLAYER object+0x4B90` (16 B); `object+0x4B80` NO se restauró (no hizo falta: no se movió). AI_PARTNER intacto. Sin crash, sin teleport, proceso estable, hook re-verificado. Sin `git push`.

- Comando humano REAL capturado (no inventado): sample de caminar recto (`char+0x04 = 0x26`), `object+0x4B90 = (-0.068983, 0.000632, -0.001078, 1.0)`, bytes `1c478dbd8ba4253ab0458dba0000803f`, `|xz| = 0.069`.
- Inyección: 192 writes de 16 B en `object+0x4B90` a ~96–125 Hz durante ~2.0 s, muestreo read-only del downstream.
- **Propagación (RUNTIME VERIFIED por inyección):** `object+0x4B90` → `object+0x5000` (latcheó `(-0.069,-0.0011)` casi toda la ventana vía `0xFF282A`) → EMA `0xF24F4A` → `char+0x30` (convergió a `(-0.059…-0.068,-0.001)`).
- **Gap:** `char+0x04` se mantuvo `0x00` (idle) TODO el tiempo ⇒ `0x14249A0` (keyed en `char+0x04`) no integró el delta ⇒ `object+0x4BC0` = 0, `object+0x4B80` sin cambio (Δ 0.000), sin animación. **Usuario: "RYU NO SE MOVIÓ".**
- **Resultado: PARTIAL.** Confirma el caveat C de la Fase 15: reescribir solo el raw command NO basta para locomoción natural. `char+0x04` lo produce la máquina de animación compartida (`0xF1ECA0` / capa `0xF31D8D`/`0xF7BDE0`) desde el **estado deseado / action code `char+0x12`**, NO desde la magnitud de `char+0x30`.
- Al cesar la inyección: `object+0x5000`/`char+0x30`/velocity/`char+0x04` decayeron a idle limpiamente; `object+0x4B90` restaurado EXACT.
- **`REMOTE_PLAYER_CONTROL_POINT` = STRONG CANDIDATE** (sin cambio). Nivel C (solo raw command) **descartado** como suficiente. El punto de control válido para locomoción natural = **nivel B** (hook `0x14203E0` / store `0x142082B` a `g_scratch`), o nivel A (alimentar también `char+0x12` / estado deseado). Pendiente de probar (NATURAL MOVEMENT TEST 02, no autorizado).
- Evidencia: `docs/research/locomotion/natural_movement_test_01/` (`capture_fwd2/`, `run01/pre_write.json`, `run01/result.json`).
