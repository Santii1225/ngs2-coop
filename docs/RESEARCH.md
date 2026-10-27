> **Hito vigente: INGAME_TEST_01 PASS (2026-09-06).** Core cargado, guard/hook/callback/original bool=true observados; menú y misión completados por usuario, salida normal y proceso terminado verificados. Alcance: una ejecución controlada. [Reporte final](INGAME_TEST_01.md). Los apartados previos conservan la historia del proyecto.

# Evidencia local e investigación

## Instalación
Biblioteca registrada: ~/.local/share/Steam (también ~/.steam/steam).
Juego: ~/.local/share/Steam/steamapps/common/[NINJA GAIDEN Master Collection] NINJA GAIDEN Σ２/
EXE: NINJA GAIDEN SIGMA2.exe, AMD64 PE32+, 37637472 bytes.
SHA256: a66daf011d22dd6fd6676e0b8ccc68e85448d4570bbac635e25adc1f2d06ffef.
Steam AppID 1580790, buildid 6998211, depot 1580791 manifest 7104107123850218097. BuildID no equivale a FileVersion PE.
Prefix: ~/.local/share/Steam/steamapps/compatdata/1580790/pfx; version 11.0-100. config_info y log señalan Proton 11.0. Una biblioteca registrada encontrada; no se afirma ausencia de copias no registradas.

El log ../steam-1580790-working.log coincide con esa ruta, muestra dbghelp=n,b y carga nativa. Instalados dbghelp.dll (14848 bytes), nmcombat (14336), nmeffect (34304), nmloader (17408), nmsteam-bugfixes (12800), NGS2Coop (105112). Son distintos de los nuevos artefactos; procedencia exacta no establecida. dbghelp instalado SHA256 8f20f4964be657d8d428fe52e9e5673c8fe05da34d8b40fa46411b55b384f4e6.

## Trabajo previo adicional
../ngs2-coop contiene src/main.cpp, src/main.cpp.backup y NGS2Coop.dll. Se leyeron ambos fuentes sin modificarlos: actual escribe ngs2coop_loaded.txt junto a la DLL; backup escribe ngs2coop.log con std::ofstream. El log existente del juego coincide con texto del backup, sin probar correspondencia exacta fuente/binario. No confundir esto con implementación de red.

## Bloqueos estáticos
PE SizeOfCode 0x179c400 coincide con discriminador AE histórico. .text cubre RVA 0x1000 hasta 0x179d2e0 (tamaño virtual); 0x1462a00 cae en código ejecutable. .rdata comienza 0x179e000; loader 0x18ef6f0 sí cae allí. Bytes en disco del supuesto hook virtual: 3b48c7bb7f6e9ca70d3cc1a115747c6f28e009953aa57cfd. Existe sección .bind y el código menciona decodificación SteamDRM: no interpretar bytes de disco como instrucciones ya inicializadas ni como validación de offsets.

get_chunk_info copia pair del mapa en lugar de referenciarlo: e.first se modifica solo en copia. load_data desreferencia find sin comprobar end y ReadFile no comprueba lectura completa. Registrar antes de evaluar mods de datos.

## Player / Team Missions
character.dead +0x210 se usa para cadáveres; limb_data.location_vec corresponde a miembros separados. No hay posición validada de Ryu. game_object y node_layer están definidos parcialmente en dos ámbitos; no deben tratarse como esquema completo fiable.
No se encontraron implementaciones de Team Missions, AI partner, player switching, input routing, cámara de segundo jugador o gestión de misión. La mención «co-op with our codes» en effect describe cooperación de rutinas de cadáveres, no multijugador. Hay que validar en el juego la disponibilidad y mecánica concreta del segundo personaje antes de usar esa hipótesis.

## COMPORTAMIENTO ESPERADO POR EL CÓDIGO

Revisión de src/core/main.cpp completa y Patch/VFPHook/SimpleInlineHook en src/util.hpp; evidencia de búsqueda en research/source_offsets_hooks.txt. 9034749 (12.7) introduce la única referencia de producción a 0x1462a00 en el historial inspeccionado.

`void Sigma2_vfunction1(Sigma2 *thisptr)` es una función libre de C++, no un método declarado; Sigma2 es incompleto. VFPHook espera que `base_address + 0x1462a00` sea la DIRECCIÓN DE UN SLOT que contenga un puntero a función. Lee 8 bytes anteriores, VirtualProtect permite escritura, escribe el puntero al callback. Después callback enumera plugin/*.dll y llama al puntero guardado pasando únicamente thisptr. No hace una indirección adicional para localizar una vtable.

La firma SUPUESTA es `void (*)(Sigma2*)`: ABI Windows x64 normal, RCX como único argumento puntero; no usa RDX/R8/R9 ni parámetros de pila; descarta retorno. No hay evidencia de tamaño/layout del objeto. El callback llama WinAPI antes del original: argumentos adicionales en registros volátiles no quedarían preservados por contrato. Por eso no basta cambiar la dirección sin comprobar la firma real.

## COMPORTAMIENTO OBSERVADO EN EL EJECUTABLE

### Función y límites

.pdata (entrada RVA 0x6fa686c) contiene BeginAddress=0x1462a00, EndAddress=0x1462cf7, UnwindInfoAddress=0x1c13db8. Tamaño 0x2f7=759 bytes. Inicio alineado a 16 bytes; siguiente entrada empieza 0x1462d00. Evidencia independiente: research/unwind_llvm.txt concuerda con tools/analyze_hook_pe.py.

UNWIND_INFO versión 1, flags EHANDLER|UHANDLER, prólogo 46 bytes, 7 slots. Describe push RDI al offset +4, reserva 0x120 bytes al +0xb (operando escalado 36*8), guarda RBX en [RSP+0x138] al +0x18 y RSI en [RSP+0x140] al +0x1c. No frame pointer; handler RVA 0xe7c818. Esto prueba metadatos de función con marco, no un simple slot de datos; no determina tipos, número de argumentos ni retorno. El epílogo real no es verificable con los bytes disponibles.

### Instrucciones disponibles y límites de la inferencia

research/hook_1462A00.asm conserva [RVA 0x1462900,0x1462c00); research/hook_function_disk.asm cubre la función completa desde su inicio conocido por .pdata. Decodificación literal en la dirección: `3b 48 c7 / cmp ecx,DWORD PTR [rax-0x39]`; después `mov ebx,0xa79c6e7f`, `or eax,0x15a1c13c`, instrucciones privilegiadas y (bad). No se puede considerar ese primer cmp una instrucción real ejecutada ni deducir ABI del uso aparente de ECX. No hay prólogo coherente con unwind. Tampoco se puede clasificar como call/jmp/thunk/stub a partir del ciphertext aparente.

El entry point está en .bind y el código fuente documenta decodificación SteamDRM antes de pre_init: fuerte evidencia de .text protegida en disco. No se descifró ni ejecutó el juego. La falsa referencia RIP-relative de RVA 0x1462add lleva a VA 0x1075e5586, fuera de imagen, y no justifica acceso a .rdata/.data. Calls, targets, registros volátiles y propósito concreto quedan pendientes de bytes en memoria. No interpretar ret/retf del desensamblado en disco como epílogos.

### Xrefs y vtable de Sigma2

Referencia absoluta encontrada en .rdata RVA 0x18f9518: QWORD=0x141462a00. Tiene relocación DIR64. En 0x18f9510 hay otro QWORD relocable hacia 0x1419c9448, interpretado como RTTI CompleteObjectLocator: signature=1, offset=0, cdOffset=0, TypeDescriptor RVA=0x1fa27e0, ClassHierarchyDescriptor RVA=0x19c9320, self RVA=0x19c9448. TypeDescriptor contiene `.?AVSigma2@?A0xdaaade58@@`. CHD tiene 4 bases. La siguiente entrada 0x18f9520 apunta a función 0x1462750; 0x18f9528 ya apunta a otro localizador RTTI. Ver research/vtable.txt y vtable_xrefs.txt.

Interpretación estática fuertemente respaldada: 0x18f9518 es slot 0 de la vftable primaria de Sigma2; 0x1462a00 es su función apuntada. Esto va mucho más allá de comprobar una sección. No demuestra la semántica de la función, que podría incluir inicialización, destrucción u otra operación virtual. No llamarla automáticamente destructor ni init. La equivalencia nombre RTTI/nombre de fuente apoya la intención del autor; no prueba `void(Sigma2*)`.

Escaneo de todas las secciones del archivo: una coincidencia VA64 al destino (slot descrito), una RVA32 en .pdata. En secciones ejecutables no hay candidatos raw E8/E9 rel32 al inicio, ni disp32 que terminen en el inicio/slot/localizador buscados. Este resultado NO descarta callers: el código está protegido y las llamadas virtuales son indirectas. No se pueden reconstruir preparaciones RCX/RDX/R8/R9 de callers todavía. No hay xrefs ejecutables validadas ni dispatch adicional identificado. No se afirmó exhaustividad sobre instrucciones de longitud variable o referencias calculadas.

### ABI provisional

Solo la fuente propone `void Function(Sigma2* arg1)`. En el ejecutable podemos sostener «función virtual candidata de Sigma2 con marco y preservación de RDI/RBX/RSI». Prototipo honesto: `unknown_return Function(unknown_arg1, /* argumentos desconocidos */)`; `arg1` como this en RCX es inferencia del contexto de vftable, no observación de caller. El retorno RAX y potenciales argumentos en RDX/R8/R9/stack requieren ejecución observada/desensamblado de memoria.

Reglas de interpretación: [ABI x64 de Microsoft](https://learn.microsoft.com/en-us/cpp/build/x64-calling-convention?view=msvc-170) y [unwind x64 de Microsoft](https://learn.microsoft.com/en-us/cpp/build/exception-handling-x64?view=msvc-170). Estos documentos describen el ABI, no identifican funciones del juego.

### dbghelp.dll histórico

SHA256 8f20f4964be657d8d428fe52e9e5673c8fe05da34d8b40fa46411b55b384f4e6, 14848 bytes, AMD64 PE32+, base preferida 0x180000000, entry RVA 0x19e0. Timestamp PE 2025-01-26 13:46:34 UTC. Exports DllMain RVA 0x15b0 y MiniDumpWriteDump RVA 0x15d0 (ret). Imports KERNEL32, VCRUNTIME140, CRT heap/runtime; listado completo y secciones guardados. Strings ASCII/bytes no contienen los términos hook/vtable/Sigma ni literal RVA/VA objetivo; sí plugin\ y *.dll. La ausencia de un literal aislado no prueba ausencia de un cálculo equivalente.

Análisis positivo: rutina RVA 0x1340 discrimina SizeOfCode 0x91aa00,0x179c000,0x179c400; en rama AE prepara R8=callback DLL+0x1190, EDX=0xb5c460, RCX=objeto hook y llama constructor DLL+0x1100 (0x1388–0x1397). Constructor escribe `48 b8 <callback64> ff e0` en base EXE+RVA, conservando 12 bytes. Instala también patch en 0x1340d3b. Callback DLL+0x1190 enumera plugins, usa LoadLibraryA en DLL+0x12b5, restaura bytes del hook y devuelve AL=1 (DLL+0x131e). No utiliza la vftable Sigma2 en esta ruta.

Esto coincide estructuralmente con core anterior a 12.7 (comparación local con 0164b26), no con el nuevo Sigma2_vfunction1. Timestamp anterior a release 12.7 es corroboración, no identificación exacta de release ni prueba de build reproducible. No hay API NM de registro de plugins ni GetProcAddress importado en este loader; no se debe inferir equivalencia por nombre dbghelp.dll.

### nmsteam-bugfixes histórico e interfaz de carga

SHA256 7ba0e0f19d7373d4d1d746dcb7a6cb7ebc7d7d783c2c757b701d7c6669b10c4b, 12800 bytes, AMD64 PE32+, base 0x180000000, entry RVA 0x1504, timestamp 2025-01-26 13:46:36 UTC. Export único DllMain en RVA 0x1040. Imports KERNEL32, VCRUNTIME140, CRT heap/runtime, sin imports desde dbghelp ni API NM. Secciones y símbolos completos conservados en historical_bugfixes.*.

DllMain comprueba EDX==1, llama DisableThreadLibraryCalls con RCX y discrimina AE/JP. Rama AE parchea base EXE+0x13ddfa9 con 7 y base+0xc43060 con E9 DE 00 00 00; rama JP usa otros RVAs. El cargador histórico descubre el nombre por FindFirstFile/FindNextFile en plugin/ y llama LoadLibraryA; Windows/Proton invoca entry CRT y DllMain. No llama el export DllMain manualmente ni busca entry points NM. El export es incidental a la compilación MSVC; para este modelo de plugin basta una DLL cargable con DllMain/CRT válidos y dependencias satisfechas. Log anterior registra carga nativa, sin probar comportamiento completo de los patches.

### Versionado y PATTERN CANDIDATE

Fuente 12.7 introduce un destino que sí corresponde a Sigma2 en esta imagen AE; la explicación mejor respaldada es confusión slot/función, no un simple desplazamiento global de versión. Otros RVAs AE coinciden con inmediatos del binario histórico; los JP/NGS1 son variantes explícitas. No validar todos los offsets por esta coincidencia parcial.

PATTERN CANDIDATE: **no hay secuencia de instrucciones defendible todavía** para la función. No usar `3B 48 C7 ...` del archivo protegido como firma. Alternativa de investigación estática: localizar TypeDescriptor por el literal RTTI Sigma2, verificar COL self/type/hierarchy, hallar slot con DIR64 y destino cubierto por .pdata. Es un candidato estructural específico de este build; no implementado ni probado entre versiones.

Para proponer firma de código: obtener bytes inicializados, desensamblar con límites de instrucción, enmascarar disp32 de call/jmp y accesos RIP-relative que cambien de layout y operandos absolutos cubiertos por relocaciones (8 bytes DIR64). RIP-relative no cambia solo por ASLR, aunque sí por recompilación/layout. Verificar unicidad en .text y estabilidad en más de un ejecutable antes de llamarla estable. RTTI puede desaparecer/cambiar en otra compilación.

### Acción segura siguiente

Mantener hooks y binarios instalados intactos. Obtener una captura de solo lectura del módulo ya inicializado en una sesión normal del juego, registrar base ASLR y bytes de función/vftable, localizar callers indirectos y verificar argumentos/retorno. No había proceso activo en esta fase y no se lanzó el juego. No fabricar ABI ni implementar un cambio de RVA/tipo con solo metadata. No hay que sustituir 0x1462a00 por 0x18f9518 todavía.

## Actualización dinámica — RUNTIME VERIFIED

La limitación anterior «sin proceso activo» corresponde al hito estático, ahora superada. PID 51579 permite lectura O_RDONLY. Vtable Sigma2 y función confirmadas en memoria: slot 0x18f9518 → 0x1462a00 relativo a base 0x140000000. Instancia en RVA 0x1e66d00 contiene ese vptr. Caller 0xb5c8aa ejecuta call [rax], test AL en 0xb5c8ac, y solo invoca slot+8 si verdadero. Callee prepara 0/1 en AL/EAX. CASE C: dirección de función confundida con slot y retorno void incompatible. Firma probable bool(Sigma2*). Las instrucciones provienen de memoria, pero no se trazó su ejecución ni se capturaron registros. Detalle, niveles de confianza y diseño no aplicado: RUNTIME_ANALYSIS.md. Los apartados previos son STATIC ONLY salvo indicación expresa del nuevo hito.

## CASE C corregido en código — 2026-09-06 (BUILD/HARNESS VERIFIED)

La evidencia RUNTIME VERIFIED anterior corresponde al juego con DLL históricas; la corrección nueva NO se ejecutó en el juego. core ahora usa SlotHook<bool(*)(Sigma2*),WindowsSlotOps>, con slot RVA 0x18f9518 y target esperado RVA 0x1462a00. module_base sale de GetModuleHandleW(nullptr); no hay VA de juego absoluta. ReadProcessMemory del propio proceso comprueba lecturas y tamaño; no se usa un CAS como lectura sobre página readonly.

Guard estructural: PE AMD64, firma/OptionalHeader válidos, timestamp 1625735769, SizeOfCode 0x179c400, SizeOfImage 0x72ce000; después slot exacto == base+function_rva. No es una comprobación criptográfica SHA256 ni una garantía universal de offsets. Un mismatch inicial no fija el módulo, no cambia protección y no escribe. Los patches legacy de check_dlls y 0x1340d3b solo se instalan tras éxito; el bootstrap temporal existente de SetCurrentDirectoryW se retira también al abortar.

Pin del módulo antes de publicación mediante GetModuleHandleEx(PIN|FROM_ADDRESS); original preservado en atomic antes del CAS. Solo se solicita VirtualProtect(slot,8,PAGE_READWRITE), con restauración inmediata a la protección anterior. Windows redondea a página: no afirmar que el SO cambia permisos únicamente de ocho bytes. InterlockedCompareExchangePointer valida otra vez el original al escribir; instrucciones generadas contienen lock cmpxchg QWORD. Si falla restaurar protección, intenta rollback condicional y restauración de protección otra vez; fallo persistente queda registrado y recuperable mediante restore. Nunca se promete restauración de permisos si el SO sigue rechazándola.

Instalación única por objeto, incluso si falló el primer intento; operaciones concurrentes/reentrantes devuelven busy. Restore no escribe si un tercero sustituyó el slot y verifica de nuevo con CAS ante carreras. Mantiene original y módulo vivos; no hay auto-restore ni unload en DllMain/destructor. Export nuevo NMRestoreSigma2Hook devuelve TRUE para restaurado/inactivo, FALSE para fallo/conflicto; solo desactiva este slot, no los patches legacy ni plugins. Consultar resultados internos en slot_hook.hpp.

Callback mantiene carga de plugin/ antes de invocar original, con call_once y guard thread_local contra deadlock por reentrada en el mismo hilo; otros hilos esperan. Devuelve exactamente original(self), probado true/false en harness y confirmado por desensamblado de core (call rax seguido solo de epílogo). La carga de terceros puede bloquear o fallar: no se declara resuelto el comportamiento de plugins arbitrarios. No hay lógica de gameplay ni networking nueva.

## Fase 5 — preflight INGAME_TEST_01: PARTIAL

HEAD inicial fe481da y hash del artefacto confirmados sin recompilar. El target core produce dbghelp.dll (238504 bytes), no un plugin core.dll independiente. Loader histórico confirmado: enumera plugin/*.dll desde check_dlls, después de su bootstrap SetCurrentDirectoryW. El core actual depende de interceptar esa llamada temprana; renombrarlo no valida su inicialización como plugin. Reemplazar dbghelp.dll está expresamente prohibido. Ningún archivo instalado ni juego iniciado; logging detallado/log-once pendiente hasta resolver integración. Tres runtimes MinGW requeridos, ninguno instalado. Backup preparado solo con registro de cero modificaciones. Guard/retorno conservados en código; no hay nueva evidencia runtime. Detalles, inventario y siguiente paso en [INGAME_TEST_01.md](INGAME_TEST_01.md).

## Fase 5 — core como plugin instalado, READY TO LAUNCH

Adaptación autorizada posterior al preflight bloqueado: core produce plugin/core.dll; elimina bootstrap proxy/patches .text y carga duplicada de plugins. DllMain programa un hilo sin esperar; inicialización fuera de loader lock con atomic_flag, log nuevo por ejecución y guard. SlotHook y sigma2_hook.hpp idénticos a fe481da. Callback conserva bool original y registra una sola invocación/retorno. Limitación: no se garantiza instalar antes del primer call Sigma2; debe comprobarse, sin reinvocar manualmente.

Build y auditoría estricta PASS; 13 escenarios con ASan/UBSan PASS. PE32+ AMD64. core SHA256 `ca2849b56c3543351f8a56556e80424cc42cdd685ac8a962543384f726e1db1d`. Se instalaron únicamente core.dll y libstdc++-6/libgcc_s_seh-1/libwinpthread-1 en plugin/. Linking dinámico conservado: SetDllDirectoryA del histórico incluye plugin/ en búsqueda; resolución Proton pendiente. Loader/EXE/plugins históricos conservan hashes. Backup `backups/pre-core-runtime-test-20260906-180142`, cuatro archivos nuevos, manifest sin originales reemplazados.

No se inició juego ni inspeccionó runtime. Resultado global PARTIAL, listo para pedir menú al usuario. Detalles, hashes, limitaciones y rollback en [INGAME_TEST_01.md](INGAME_TEST_01.md), apartado adaptación autorizada. Los apartados previos describen hitos históricos.

## INGAME_TEST_01 — menú verificado, misión pendiente

PID 8894 activo; usuario confirma menú. Core y tres runtimes cargados desde plugin/. Log de esta ejecución: base 0x140000000, slot 0x1418F9518, target observado=esperado 0x141462A00, guard PASS, installed, invoked y original retornó true. Retorno preservado por diseño/ASM; caller AL no muestreado. Errores Proton detectados tienen equivalentes históricos; sin crash nuevo identificado. Evidencia en evidence/ingame_test_01/menu/ y detalle en INGAME_TEST_01.md. Resultado PARTIAL: falta misión y salida normal. Ningún cambio de código/binarios ni escritura de memoria. Siguiente paso manual: misión 30–60 segundos y volver al menú.

## INGAME_TEST_01 — misión completada, salida pendiente

Usuario confirma misión terminada y regreso al menú. PID 8894 conserva starttime y sigue activo; core.log idéntico (460 bytes), sin errores nuevos del plugin. Proton añade 1188 mensajes HID TODO Process Report (21, 0) en proceso Wine 0094, distinto del juego 013c; ese mensaje exacto no consta en histórico, sin causalidad demostrada con core. Sin marcadores nuevos de crash/import_dll en captura. No rollback. Resultado PARTIAL: pedir cierre normal y verificar salida antes de PASS. Detalle/evidencia en INGAME_TEST_01.md y evidence/ingame_test_01/mission/.

## INGAME_TEST_01 final — PASS, 2026-09-06T18:23:14.042566-06:00

Usuario confirma cierre normal. PID 8894 ausente; ningún proceso NINJA encontrado. Log core idéntico (460 bytes), sin mensajes nuevos del plugin. RPC 0x6be/0x6ba y error de servicio 1726 al cierre en proceso Wine 0120, distinto del juego 013c, tienen equivalentes en histórico funcional. No crash atribuible al core observado; no atribuir ausencia universal de errores. Restore explícito no invocado: módulo pinned hasta salida, sin auto-restore en DllMain.

Criterios completos de la prueba satisfechos: carga, base/slot/target, guard, instalación, invocación, original true, retorno preservado por diseño/ASM, menú, misión y salida. Sin captura del exit code ni AL del caller; confirmación humana cubre gameplay/cierre. Cuatro archivos instalados y todos los binarios históricos conservan hashes. No rollback; no nuevas escrituras de instalación, código, memoria ni configuración. Evidencia final en evidence/ingame_test_01/shutdown/. Mantener hito; no iniciar otra fase ni push.

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

### Player resolver — RESTART VALIDATION, 2026-09-06 (PID 16942)

Segunda sesión de juego, arranque nuevo. Solo lectura (`O_RDONLY`/`pread`); sin attach, escrituras ni inputs. Hook 151ea14 / INGAME_TEST_01 PASS intacto; no se tocó core/DLL/loader/Proton/prefix.

Proceso: PID Linux **16942** (≠ 12404), `comm` «NINJA GAIDEN SI», TracerPid 0, exe wine64-preloader. Module base 0x140000000 (delta ASLR 0). core.dll base 0x6ffff9830000. Slot Sigma2 `base+0x18F9518` = `0x1418F9518` → `0x6ffff98316F2` = `core_base + 0x16F2`: callback del hook validado presente, gate de continuidad **PASS**. SHA256 EXE a66daf… y core ca2849… verificados.

Resolver ejecutado desde estado module-relative, sin reutilizar direcciones previas:

```
root address = module_base + 0x3195300 = 0x143195300   (tabla game_object, stride 0x30)
root value   = u64[root + 0*0x30]       = 0x143197100   (entrada 0; +0/+8/+0x10 iguales)
group        = u8[root + 0*0x30 + 0x1F] = 0
object addr  = 0x143197100  =  module_base + 0x3197100
position     = f32x3[object + 0x2B0]                     @ 0x1431973B0
corrobora    = f32x3[module_base + 0x2F78B10 + group*0x1240 + 0x310]  @ 0x142F78E20
```

`0x143197100` **no es heap**: RVA 0x3197100 está dentro de `SizeOfImage` (0x72ce000) y del mapping anónimo de la imagen del EXE (`0x141c4b000-0x146e94000`, región de datos estáticos). La cadena entera es relativa al módulo; resuelve a la misma RVA que la sesión previa porque no hay ASLR ni componente de heap en esta imagen bajo este Proton. El checkpoint la llamó "dirección HEAP de aquella ejecución"; la evidencia lo corrige.

Lecturas: `PLAYER_SCAN_RESTART_IDLE` mostró deriva de C0/C2 mientras el usuario reportaba reposo (probe de 8 lecturas/7 s: C0 59.6→60.4, C2 −94.6→−96.3; Y clavado ~5.2200) — la causa **no** es atribuible a una sola fuente: pudo ser input, gameplay externo, enemigos, knockback, caída o física del entorno (`LOCAL_PLAYER_IDLE ≠ GAME_WORLD_IDLE`). La posición la demostró la ventana realmente estable. `PLAYER_SCAN_RESTART_MOVED` en reposo real: triple `(74.63035583, 5.21999931, -135.97770691)` **bit-idéntico** en 2 muestras snapshot + 8 lecturas probe/7 s en los tres ejes, con `object == character` exacto en las 10 lecturas — reproduce el comportamiento de A/B/C. Movimiento IDLE→MOVED: delta (+4.24, ~0, −12.33), unidireccional, Y constante en suelo plano; la Y (5.2200) coincide con la Y de reposo de la sesión A (5.21999979) a ~4 decimales.

Estado: **Player resolver RUNTIME VERIFIED** (reproducido tras reinicio real, descubrimiento automático, gate de hook OK). **Position float3 en object+0x2B0/+0x2B4/+0x2B8 RUNTIME VERIFIED** como float3 ligado a posición (estable en reposo, se mueve con el jugador, corroborado en dos tablas y dos procesos). Semántica por eje (X vs Z, handedness) sigue **CANDIDATE**: C1 es vertical (sesión C), C0/C2 son el plano horizontal sin asignar. Generalidad (otros personajes/misiones, Team Missions, selección del jugador local) y cadena directa Sigma2→Player siguen **CANDIDATE / sin demostrar**. Confianza MEDIA-ALTA; matiz: el delta ASLR fue 0 en ambas sesiones, así que el reinicio no venció aleatorización, sí demostró persistencia de tabla/entrada/offset/régimen de valores y re-verificación viva del hook.

Herramientas solo lectura añadidas: `tools/player_resolver.py` (descubre Player, imprime PID/base/address/posición, valida hashes+slot, sin escritura/attach/inputs) y `tools/player_stability_probe.py` (sonda acotada de estabilidad). Evidencia: `docs/research/player/PLAYER_SCAN_RESTART_IDLE/`, `PLAYER_SCAN_RESTART_MOVED/`, `restart_validation.json`. Sin cambios en core/hook/instalación; sin push.

### Player transform — FASE 7 (semántica XYZ + rotación), 2026-09-06 (PID 16942)

Continuación solo-lectura sobre el mismo proceso 16942 (sin reiniciar). Sin escrituras/teleport/inputs/HP/hooks nuevos; hook 151ea14 y `core.dll` intactos. Herramientas nuevas: `tools/player_transform_probe.py` (captura acotada `object+0..0x1000` y `character+0..0x1240`, 2 muestras/2 s, ~17 KiB/run), `tools/analyze_transform.py` (offline).

**Semántica de ejes — RUNTIME VERIFIED (MEDIA-ALTA):** `C0 (+0x2B0) = world X`, `C1 (+0x2B4) = world Y (arriba)`, `C2 (+0x2B8) = world Z`; sistema **right-handed, Y-up**. Prueba: AXIS_TEST_ORIGIN/A/B (desplazamientos controlados) + correlación con el vector forward de la matriz de rotación — `row2` sigue la dirección de caminata dentro de ~3° en tres desplazamientos independientes; `row1 ≈ world +Y`; `row0×row1 = row2` (tríada right-handed); posición y matriz comparten base.

**Rotación — RUNTIME VERIFIED (yaw):** matriz 3×3 row-major en `char+0x80` = `module_base + 0x2F78B10 + group*0x1240 + 0x80` (filas +0x80 right / +0x90 up / +0xA0 forward, 4 floats con pad). `det = +1` en 6 capturas; ortonormal. ROTATION_TEST A→B→C: Δyaw idéntico calculado vía row0 y vía row2 (-173.23° / +91.10° / -82.13°), giro rígido sobre el eje vertical, coherente. Copias en `char+0x100/+0x67C/+0x1020/+0x1040/+0x10EC`. Pitch/roll no ejercitados. Descartados por no cambiar al girar: `char+0x76C` (quat yaw fijo -45.3°) y `obj+0x60/0xB0/0x1B0/0x1D0`.

**Otra misión — RUNTIME VERIFIED:** resolver desde cero en una 2ª misión (mismo proceso) → misma raíz `module_base + 0x3195300`, misma entrada 0 → `0x143197100`, mismos offsets, rotación igual (det +1, ortonormal). Posición bit-idéntica en 12 lecturas/11 s con Ryu en suelo firme; región de mapa distinta (C0≈106.9, Y≈1.20, C2≈-75.5). El resolver **no es específico del escenario**.

**Identidad — CANDIDATE:** el objeto resuelto sigue al personaje controlado (posición y facing siguen el input; `obj+0x310` retrasa a `obj+0x2B0`, la autoritativa; `obj+0x2B0` es la cabeza de una tabla-anillo de historial de posición, stride 0x30). No es cámara/proxy visual. Que sea específicamente Ryu vs otros personajes jugables **no** está establecido (`game_object[0].obj_id = 0`, sin nombre/RTTI).

`tools/player_resolver.py` ampliado (solo lectura): imprime PID, Module base, Player address, Position (C0/X, Y, C2/Z), Rotation (matriz + yaw), Character (obj_id/group). Evidencia: `docs/research/player/{AXIS_TEST_*,ROTATION_TEST_*,OTHER_MISSION_IDLE}/`, `transform_characterization.json`. Sin cambios en core/hook/instalación; sin push. No continuar automáticamente con MVP 2.

### FASE 8 — clasificación de actores (metodología), 2026-09-06 (PID 16942)

Solo lectura. `LOCAL_PLAYER_IDLE` ≠ `GAME_WORLD_IDLE`: el personaje local puede moverse sin input (knockback/golpes/caídas/animación/física); en Team Missions el compañero IA actúa con el jugador local quieto. Criterio nuevo `LOCAL_PLAYER_STABLE` (XYZ de `game_object[0]→object+0x2B0` dentro de tolerancia en N muestras; otros actores pueden moverse) y `UNSTABLE_LOCAL_PLAYER` (causa no atribuible a una sola fuente). Parámetros: 10 muestras / 0.5 s / tol. h 0.05 u / tol. v 0.05 u — justificación en [TEAM_MISSION_RESEARCH.md](TEAM_MISSION_RESEARCH.md). Corregidas las frases previas que atribuían la deriva de RESTART_IDLE a «entrada del usuario». Herramienta `tools/actor_classifier.py` (solo lectura, acotada a la `game_object` table conocida + estructuras cercanas ya documentadas; modo `--compare`). Pendiente: `TEAM_ACTORS_A/B/C` en Team Mission, correlación visual del aliado, discriminador local-vs-IA, `CHARACTER_ID_CANDIDATE`. No escribir memoria; no continuar con MVP 2.

### FASE 8 — compañero IA identificado (STRONG CANDIDATE), 2026-09-06 (PID 16942)

Solo lectura. 2 Team Missions (compañero de Ryu + Ayane), capturas TEAM_ACTORS_A/B/C/D. `LOCAL_PLAYER_STABLE = True` con combate activo. **LOCAL_PLAYER** = `game_object[0]` (obj RVA 0x3197100, id 0, grp 0, `char[0]+0x00 = 0x00`), estable en 4 misiones. **AI_PARTNER (STRONG CANDIDATE)** = `game_object[4]` / objeto RVA `0x319cdb0`; presente en las 2 Team Missions (id 219 con Ryu, id 220 con Ayane), siguió el desplazamiento deliberado de Ryu 28 u, layout de objeto idéntico al del jugador (quat vivo `obj+0x60`, cabecera `obj+0x90` poblada; enemigos a ceros, muertos con quat 0,0,0,0). Discriminador: `char[group][4:6] ∈ {9898,c2c2,ffff}` ⇒ enemigo; `char[group]+0x210 = 4` ⇒ derrotado; `char[0][0] = 0x00` ⇒ jugador local. `obj_id` **no** es id de personaje (219→220 = contador de spawn) → `CHARACTER_ID_CANDIDATE` REJECTED vía obj_id; id real sin localizar. Índices altos de `game_object` se reciclan dentro de una misión; 0 y 4 estables entre misiones (falta reinicio del juego para `RUNTIME VERIFIED`). Herramienta `tools/actor_classifier.py --roles`. **READY FOR CONTROLLED WRITE TEST: NO.** No escribir memoria; no continuar con MVP 2. Detalle en [TEAM_MISSION_RESEARCH.md](TEAM_MISSION_RESEARCH.md).

### FASE 9 — Actor restart validation, 2026-09-06 (PID 29318, arranque nuevo)

Juego cerrado (PID 16942 ausente) y relanzado. "Misión Acólito 01", compañero IA Ayane. Solo lectura. Gates desde cero OK (SHA256 EXE/core, slot Sigma2 → `core+0x16F2`). Base determinista (delta ASLR 0). **LOCAL_PLAYER RUNTIME VERIFIED** re-resuelto desde cero por estructura (`game_object[0]` → obj RVA `0x3197100`, única entrada con layout de personaje vivo **y** `char[group]+0x00 == 0x00`). **AI_PARTNER RUNTIME VERIFIED (rol)**: `game_object[4]` / obj RVA `0x319cdb0` (o búsqueda por propiedad), 3ª Team Mission + reinicio; 2 correlaciones de movimiento post-reinicio (IA ~10.8 u y ~10.1 u mientras el local ~estable; en C convergió sobre la posición nueva del jugador, dist 2.55); 11 criterios §8 cumplidos. Caveat: base determinista ⇒ identidad de RVA esperada; lo significativo es la re-resolución del rol + discriminadores estructurales tras un reinicio real. `CONTROL_DISCRIMINATOR_CANDIDATE = char[group]+0x00` (0x00 local / 0x04 IA+enemigos; también `game_object` rec +0x1D y `object+0x98`). `CHARACTER_ID_CANDIDATE = char[group]+0x16` (Ryu 0x4e / Ayane 0xb6, baja confianza; `obj_id` sigue REJECTED). **PITCH/ROLL = NOT VERIFIED**; yaw/matriz siguen RUNTIME VERIFIED. `tools/actor_classifier.py --roles` ampliado. **READY FOR MVP 2 CONTROLLED POSITION WRITE: YES**; experimento solo diseñado en [MVP2_WRITE_PLAN.md](MVP2_WRITE_PLAN.md), NO ejecutado. Evidencia: `docs/research/player/actor_restart_*`. Detalle en [TEAM_MISSION_RESEARCH.md](TEAM_MISSION_RESEARCH.md) §4h.

### MVP 2 — primera escritura controlada de posición: PARTIAL, 2026-09-06 (PID 29318)

Autorizada por el usuario. `tools/player_write_test.py` (independiente del core, sin hook/ptrace/VirtualProtect): un `pwrite` de 4 bytes en `object+0x2B0` (LOCAL_PLAYER world X), con gates completos + `LOCAL_PLAYER_STABLE` + backup + restauración automática. X `67.845779` → `68.145779`; readback inmediato = valor escrito; a los ~150 ms el motor ya lo había revertido; restauración `EXACT`; sin crash; Y/Z/rotación/mirror/AI_PARTNER no tocados; usuario `NO NOTE MOVIMIENTO`. **Verdict PARTIAL**: `object+0x2B0` es copia de lectura (RUNTIME VERIFIED para lectura, Fase 7), **no escribible de forma persistente** — el motor la re-deriva de un estado canónico cada tick. Siguiente objetivo (fase posterior): localizar el estado autoritativo de posición. Detalle en [MVP2_WRITE_TEST_01.md](MVP2_WRITE_TEST_01.md). No se repite la escritura.

### FASE 10 — posición canónica del jugador: NO localizada, 2026-09-06 (PID 29318)

Solo lectura. `object+0x2B0` (y ~13 copias más en `object`/`character`) es RENDER/OBSERVABLE COPY: watchpoints de hardware read-only (gdb `awatch`/`hbreak`) muestran que se escribe **cada frame por rutinas genéricas de copia de bloque** (RVA 0x8C7B4 memcpy inline; también 0x1353E41, 0xEAD02E) en el hilo «Updating»; con Ryu quieto el watchpoint de cambio de valor no dispara (mismo valor cada frame); no hay instrucción dedicada de actualización de posición. Clasificación: 7 obj + 7 char = RENDER/OBSERVABLE; `object+0x310` = INTERPOLATED; `object+0x340/+0x370` = HISTORICAL ring. AI_PARTNER tiene la misma arquitectura (no escrito). **La posición canónica no se aisló** (probablemente derivada de locomoción/animación en registros por frame). Confianza LOW. **Ready for MVP 2b: NO.** Herramienta `tools/position_sources_probe.py`. Detalle en [CANONICAL_POSITION_RESEARCH.md](CANONICAL_POSITION_RESEARCH.md). Siguiente paso (fase posterior): RE estática de la función de sync de transform del hilo «Updating», o un hook temporizado por frame (hook nuevo, fuera de alcance). No se reintenta la escritura.

### FASE 11 — traza de la sincronización de transform en runtime, 2026-09-07 (PID 14042)

Solo lectura: volcado del `.text` inicializado en runtime (`tools/runtime_text_dump.py`, `O_RDONLY`+`pread`, secciones `.text`/`.bind`/`.rdata`/`.pdata`, manifest con SHA256 por segmento), desensamblado offline con capstone (`tools/rt_image.py`), `awatch` de gdb read-only + `detach`, traza temporal (`tools/canonical_trace_probe.py`). Proceso vivo tras la sesión, `starttime` estable, hook Sigma2 re-verificado. Detalle en [TRANSFORM_SYNC_RESEARCH.md](TRANSFORM_SYNC_RESEARCH.md).

- **Writer real de `object+0x2B0`**: `0x1353E37` (`movdqa [obj+0x60+0x250], xmm6`) en la rutina per-actor `0x1353D00`. Corrige la Fase 10: de sus tres RVA, `0x8C7B4` y `0xEAD02E` **solo leen** `+0x2B0` (rellenan mirrors `+0xAF0`/`+0x1330`, hacen snapshot-out `obj → 0x1433c3xxx`); no son el writer.
- **Cadena per-frame (hilo «Updating»)**: `0x1462160` (dispatch `call [rcx+0x10]`) → `0x136CBC0` → `0x1354390` (bucle `game_object[0..0xA0]`, stride 0x30) → `0x1353D00(rec, idx)` → `call 0xF7BB70` → `call 0xF8E420` → `xmm6` → `0x1353E37`.
- **`0xF7BB70` lee `object + 0x4B80`** (posición) y `character[group]+0x10E0` (referencia) para producir el valor de `+0x2B0`.
- **`CANONICAL_POSITION_STRONG_CANDIDATE = object + 0x4B80`** (confianza MEDIA-ALTA): bloque de estado de movimiento `+0x4B80` posición / `+0x4BC0` **velocity** (`(0,0,0)` reposo, `(0,0,1.985)` caminando) / `+0x4BD0` centro de cápsula. Lockstep con `+0x2B0` (xcorr r=1.0) pero aguas arriba en la misma frame. AI_PARTNER (`game_object[4]`, Momiji) tiene el mismo layout. 4 sitios de escritura de `[reg+0x4b80]`; el principal `0xF8190E` integra `+0x4BC0` velocity + matriz `+0x1AB0` → `+0x4B80` (paso de movimiento/física). Writer identificado **estático**, no capturado vivo (solo corre en movimiento).
- **MVP 2b**: solo diseñado ([MVP2_WRITE_PLAN.md](MVP2_WRITE_PLAN.md) §MVP 2B). **NO ejecutado. No push.**

### FASE 12 — writer de `object+0x4B80` capturado en movimiento, 2026-09-07 (PID 14042)

Solo observación: hardware write-watchpoints de gdb + `detach`. Detalle en [CANONICAL_WRITER_TRACE.md](CANONICAL_WRITER_TRACE.md). 130 hits en el thread "Updating" — 2 movimientos del LOCAL_PLAYER (direcciones distintas) + AI_PARTNER Momiji autónomo. Proceso vivo tras la sesión, `starttime` estable, hook Sigma2 re-verificado.

- **Writer de `object+0x4B80`** — dos rutas, ninguna `memcpy`/`memmove`: **W1 `0x141BB90`** (`object+0x4B80 += movement_vector*scale`, primitiva leaf con guard NaN; caller `0x14249A0` @ `0x1429B92`, dispatcher `0x1420F60` que indexa `game_object`); **W2 `0x14208DD`** (`movdqu [obj+0x4B80], transform_result` de matriz `0x6FDE0`, w=1; commit de transform / snap de suelo). LOCAL_PLAYER y AI_PARTNER **comparten W1 y W2** (capturados en vivo para ambos). Para el AI_PARTNER, la familia transform-sync `0x1353xxx` también toca `+0x4B80`.
- `+0x4BC0` velocity: `(0,0,0)` reposo (Ryu y Momiji), rampa monótona con aceleración, reset por frame, dirección coherente; writers en el mismo subsistema `0x142xxxx`/`0xF81xxx` (`0xF8190E` escribe posición **y** velocity). `+0x4BD0` cápsula desplazándose con `+0x4B80`.
- Los 9 criterios §12 del plan cumplidos ⇒ **`object + 0x4B80` = `CANONICAL_POSITION_RUNTIME_VERIFIED`**, confianza **ALTA**. Caveats: 2 escrituras/frame; input de la matriz de W2 sin descartar `character[group]`; prueba definitiva = MVP 2B (diseñada, NO ejecutada). **No push.**


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
