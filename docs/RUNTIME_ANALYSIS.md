> **Hito vigente: INGAME_TEST_01 PASS (2026-09-06).** Core cargado, guard/hook/callback/original bool=true observados; menú y misión completados por usuario, salida normal y proceso terminado verificados. Alcance: una ejecución controlada. [Reporte final](INGAME_TEST_01.md). Los apartados previos conservan la historia del proyecto.

# Inspección dinámica de solo lectura — 2026-09-06

## Alcance y etiquetas

RUNTIME VERIFIED significa bytes, punteros, mappings o instrucciones obtenidos del proceso vivo PID 51579; NO significa traza de ejecución de cada instrucción. No se detuvo el proceso, no se capturaron registros con debugger y no se instalaron breakpoints. Inferencias de ABI/semántica se califican por separado. STATIC ONLY corresponde a metadatos/fuentes/EXE en disco. Ninguna escritura en memoria del juego ni cambios de DLL/configuración/seguridad.

Lectura permitida mediante open(/proc/51579/mem, O_RDONLY) + pread. ptrace_scope observado=1; no se alteró. No se necesitó gdb, sudo ni attach. maps/smaps accesibles. Se conservó solo la selección de mappings del módulo, no el smaps completo.

## Proceso, módulo y ASLR — RUNTIME VERIFIED

PID Linux 51579, comm «NINJA GAIDEN SI», PPid 51463, TracerPid 0, UID 1000. /proc/PID/exe apunta a Proton 11.0/files/lib/wine/x86_64-unix/wine64-preloader. Command line: S:\steamapps\common\[NINJA GAIDEN Master Collection] NINJA GAIDEN Σ２\NINJA GAIDEN SIGMA2.exe. No confundir con steam.exe, wineserver o el script proton.

Mapping de cabecera: 140000000-140001000 r--p, offset archivo 0, ruta real ~/.local/share/Steam/steamapps/common/[NINJA GAIDEN Master Collection] NINJA GAIDEN Σ２/NINJA GAIDEN SIGMA2.exe. Secciones posteriores aparecen como mappings anónimos. El rango de la función está en mapping 141461000-141467000 r-xp; la vtable está en 1418f0000-141c4b000 r--p. Ver research/runtime_module_maps.txt.

Preferred ImageBase (STATIC ONLY): 0x140000000. Loaded ImageBase (RUNTIME VERIFIED): 0x140000000. Delta=0. No extrapolar a otra ejecución. El proceso también tiene mappings de dbghelp.dll (base 0x6ffffd7e0000) y nmsteam-bugfixes.dll (base 0x6ffff92f0000); presencia del mapping no prueba toda su lógica.

| Elemento | RVA | VA runtime |
|---|---|---|
| Función | 0x1462a00 | 0x141462a00 |
| Puntero a RTTI COL | 0x18f9510 | 0x1418f9510 |
| Vtable/slot 0 | 0x18f9518 | 0x1418f9518 |
| Slot 1 | 0x18f9520 | 0x1418f9520 |

## Disco frente a memoria

STATIC ONLY, primeros 32 bytes desde RVA 0x1462a00:
```
3b 48 c7 bb 7f 6e 9c a7 0d 3c c1 a1 15 74 7c 6f 28 e0 09 95 3a a5 7c fd cb 1a ea 9d b6 cd 0c 93
```
RUNTIME VERIFIED, mismos 32 bytes:
```
48 8b c4 57 48 81 ec 20 01 00 00 48 c7 44 24 40 fe ff ff ff 48 89 58 10 48 89 70 18 48 8b 05 2d
```
Clasificación: PATCHED/DECRYPTED. Ventana solicitada [0x1462980,0x1462b80), 512 bytes: 510 diferentes. Se amplió justificadamente hasta 0x1462d00 para incluir el epílogo conocido por .pdata: 896 bytes, 893 distintos. Cero relocaciones DIR64 en el intervalo y delta ASLR=0: no es RELOCATIONS ONLY. El mecanismo/actor exacto de transformación no fue trazado; la combinación de .bind, fuente SteamDRM y código inicializado apoya descifrado, sin atribuirlo automáticamente a Proton.

Segunda lectura 18:49:31 UTC coincide en toda la captura y los tres QWORD de vtable. Capturas no atómicas del proceso; las dos lecturas no equivalen a una prueba general de ausencia de carreras. Hashes en research/runtime_comparison.json. El binario .bin es únicamente evidencia local del fragmento leído, no un EXE modificado.

## Callee — RUNTIME VERIFIED

research/runtime_hook_1462A00.asm conserva la función completa y padding. objdump llama .data a un archivo raw; NO es la sección PE original (es .text).

Inicio:
```asm
141462a00  mov rax,rsp
141462a03  push rdi
141462a04  sub rsp,0x120
141462a0b  mov qword ptr [rsp+0x40],-2
141462a14  mov [rax+0x10],rbx
141462a18  mov [rax+0x18],rsi
141462a2e  mov rsi,rcx
141462a31  call 0x141341a90
141462a36  test al,al
141462a38  je 0x141462cd2
```
Prólogo/epílogo coinciden con metadata STATIC ONLY de .pdata: rango [0x1462a00,0x1462cf7), unwind 0x1c13db8. RSI conserva arg1. El cuerpo usa [RSI+0x150] y [RSI+0x158]. Inicializa una tabla de 0xa0 elementos con stride 0x30 en RVA 0x3195300 y otros estados globales; prepara recursos y una llamada con callback 0xc12d90. Propósito PROBABLE: inicialización de contexto Sigma2 previa a segunda operación virtual; no controlador de jugador ni game-loop identificado.

Retorno:
```asm
141462cac  mov bl,1
141462cae  jmp 0x141462cb2
141462cb0  xor bl,bl
141462cb2  mov [rsi+0x158],bl
...
141462ccf  movzx eax,bl
...
141462cf6  ret
```
El fallo temprano salta al epílogo después de test AL. No se debe reclamar que los bits altos de RAX contienen un contrato útil: el caller solo utiliza AL. La función de comprobación inicial 0x1341a90 consulta [RCX+0x49]; su captura cubre solo la primera entrada .pdata (tiene saltos a fragments fuera de ella), no se presenta como desensamblado completo.

Referencias RIP y llamadas se conservan completas en ASM. Ejemplos: cookie 0x1c4dd50 en .data, constantes SIMD 0x19151a0/0x1909fe0/0x1908be0/0x1908220 en .rdata, tabla 0x3195300 y globals 0x2ee8358/0x2ee8360 en .data; llamadas 0x1341a90,0xff4e10,0xe4f62c,0x1464b20,0xdacf00 y varias rutinas 0xe50xxx. Nombres semánticos de estas rutinas no confirmados.

## Vtable, RTTI e instancia — RUNTIME VERIFIED

Lecturas QWORD:
- [0x1418f9510] = 0x1419c9448 (COL).
- [0x1418f9518] = 0x141462a00 (slot 0 apunta exactamente a la función).
- [0x1418f9520] = 0x141462750 (slot 1).

COL y TypeDescriptor se leyeron también de memoria y coinciden con disco: nombre literal `.?AVSigma2@?A0xdaaade58@@`. El texto de la solicitud omite una «a»; la evidencia contiene «daaade58». No normalizarlo para búsquedas binarias.

La referencia de código 0x1340ddb carga la vtable y en 0x1340de2 la escribe en global 0x1e66d00. Lectura dirigida, sin escanear heap: [VA 0x141e66d00] = 0x1418f9518; [VA 0x141e66e60] = 0x141e66d00; byte en self+0x158 = 1. Identifica una instancia estática existente, con estructura completa desconocida. No identifica personaje/Ryu. Ver research/runtime_instance.json.

## Callers — RUNTIME VERIFIED (código leído, no traza)

Para localizar referencias se leyó una vez solo .text, 24762992 bytes incluyendo solapamiento de 16 bytes, en bloques de 64 KiB. No se guardó el volcado de .text ni se inspeccionó el heap. Justificación: las xrefs del archivo protegido no eran utilizables. Se buscaron E8/E9 y LEA/MOV RIP a la función/vtable. Seis xrefs a vtable, cero E8/E9 directos a función; no implica ausencia de toda forma de llamada calculada. Cada hit se desensambló desde .pdata; snippets guardados en runtime_xref_*.asm.

En rutina de arranque RVA 0x1340ae0 se construye la instancia y pasa su dirección como contexto al programar callback 0xb5c890 (0x1340eff–0x1340f10). Las convenciones internas de la rutina programadora no se reconstruyeron completamente. El caller encontrado en 0xb5c890:
```asm
140b5c896  mov rbx,rdx            ; contexto recibido por ESTA rutina
140b5c899  call 0x140e4f62c
140b5c89e  mov [0x146be35ac],eax
140b5c8a4  mov rcx,rbx            ; self para la función virtual
140b5c8a7  mov rax,[rbx]          ; vptr
140b5c8aa  call qword ptr [rax]   ; slot 0
140b5c8ac  test al,al
140b5c8ae  je 0x140b5c8b9
140b5c8b0  mov rax,[rbx]
140b5c8b3  mov rcx,rbx
140b5c8b6  call qword ptr [rax+8] ; slot 1 solo si éxito
```

Esto enlaza el contrato del slot con el retorno del callee. El valor concreto de RCX al ejecutar esa llamada no se muestreó: no se debe presentar la dirección de instancia como registro capturado. No se establecen RDX/R8/R9 ni argumentos de pila adicionales para el slot 0 después de la llamada previa que puede clobber registros volátiles.

## ABI y error conceptual

| Elemento | Clasificación | Evidencia |
|---|---|---|
| RCX = puntero self | CONFIRMADO | Caller RCX=RBX y vptr=[RBX]; callee RSI=RCX y campos self |
| Identidad self Sigma2 | CONFIRMADO | Instancia/vptr/RTTI leídos, junto con código de construcción |
| RDX arg2 | DESCONOCIDO como valor; PROBABLE sin argumento formal | Caller no lo prepara para este call; no conserva valor entrante en callee |
| R8 arg3 | DESCONOCIDO como valor; PROBABLE sin argumento formal | Igual |
| R9 arg4 | DESCONOCIDO como valor; PROBABLE sin argumento formal | Igual |
| Argumentos adicionales de pila | PROBABLE ninguno | No preparación visible en caller ni uso evidente de entradas adicionales |
| AL resultado de éxito | CONFIRMADO | Callee prepara 0/1 y caller test AL controla slot 1 |
| Tipo C++ bool exacto | PROBABLE | Patrón compatible con bool; no símbolos de tipos completos |
| Bits restantes de RAX | DESCONOCIDO/no requeridos por este caller | Solo AL consumido |
| RDI/RBX/RSI preservados | CONFIRMADO | Código runtime de prólogo/epílogo y unwind estático |

Firma mínima PROBABLE compatible con evidencia: `bool Sigma2Virtual(Sigma2* self)` usando ABI Microsoft x64. No inferir `BOOL` (32 bits) ni retorno void. Los valores instantáneos de registros no se capturaron.

Se releyeron core y VFPHook. VFPHook lee/escribe 8 bytes en base+RVA y llama después el QWORD anterior. En base+0x1462a00 los primeros 8 bytes son instrucciones, QWORD 0x20ec814857c48b48, no un puntero canónico a función. El slot correcto identificado es otro lugar: RVA 0x18f9518. Además `void Sigma2_vfunction1(Sigma2*)` descarta el retorno y no garantiza AL al caller. Conservarlo accidentalmente en un build no satisface el ABI.

Clasificación CASE C: error de dirección slot/función Y error de firma/retorno. Confianza HIGH para ambos errores y la cadena de punteros; MEDIUM para propósito semántico y tipo bool exacto. No hay evidencia de intención de inline detour que justifique cambiar a ese mecanismo.

## Diseño del hook — propuesta histórica previa a implementación

Preferir reemplazo del slot de vtable 0 (RVA 0x18f9518) con callback que preserve el contrato booleano. Afectaría todas las instancias que compartan esta tabla; no equivale a reemplazar el vptr de una instancia. Inline detour exige relocación de instrucciones/trampoline y no resuelve el retorno; call-site hook limita cobertura y no es necesario con slot identificado.

- Original pointer: leer y validar base+0x1462a00 en el slot después de inicialización/relocación, para hash de EXE exacto. Detectar y rechazar terceros hooks inesperados.
- Hook pointer: función ABI compatible (probable bool(Sigma2*)), cargar plugins una vez, invocar original con self y devolver SU resultado. No fabricar éxito si el original falla. Gestionar reentrada por inicializadores de plugins.
- Trampoline: no requerido para slot replacement; llamar directamente el original guardado sin desparchear temporalmente la tabla.
- Protección: slot hoy r--p. En futura implementación usar VirtualProtect sobre página correspondiente, comprobar resultado y restaurar protección inmediatamente. No ejecutar nada de esto ahora.
- Lifetime: original y estado válidos mientras pueda invocarse callback; mantener módulo cargado. Evitar destrucción prematura de Patch y trabajo complejo bajo loader lock.
- Restore path: restaurar solo si el slot todavía contiene nuestro callback (compare-and-exchange); no sobreescribir otro mod. Antes de descargar, coordinar ausencia de callbacks en vuelo y de threads que hayan leído el puntero. Un contador solo no elimina esa carrera.
- Thread safety: publicación de puntero alineado con operación interlocked y sincronización adecuada; CAS evita pisar cambios ajenos pero no resuelve por sí solo unloading/reentrada. Preparar estado antes de publicar. Instalar en fase controlada anterior al primer call, o posponer a reinicio futuro; no llamar manualmente la inicialización ahora.
- Esta función parece inicialización, no tick: instalar después de arrancar puede no ejecutar callback. Falta validar temporalidad al integrar.

Siguiente acción segura: revisar este diseño y, en una fase autorizada para código, preparar corrección aislada con validación de identidad/slot/ABI. No instalarla en el juego ni intentar reinvocar esta función de inicialización en la sesión actual.

## Implementación autorizada CASE C — BUILD/HARNESS VERIFIED, NO IN-GAME TEST

El diseño anterior queda implementado en src/core/{main.cpp,sigma2_hook.hpp,slot_hook.hpp}. Se preserva la ABI bool(Sigma2*), se sustituye exclusivamente el slot 0x18f9518 y se valida target base+0x1462a00 antes de publicar. Comparación inicial de solo lectura más CAS evita aceptar una sustitución entre comprobación y escritura.

Original release/acquire y estado preparados antes de publicación; atomics serializan install/restore sin hacer esperar al callback. Se impide doble instalación y no se permite reinstalar después de restore. El módulo se fija hasta terminación del proceso, incluidas instalaciones fallidas después de pin. Esta decisión resuelve el riesgo de un callback ya leído por otro hilo; no intenta descargar ni esperar bajo loader lock.

API explícita NMRestoreSigma2Hook, fuera de DllMain: restauración condicionada al callback propio, conserva original para llamadas en vuelo. TRUE indica slot restaurado/inactivo, no que plugins o hooks legacy hayan sido descargados. No pisa un tercero. Ante fallo de VirtualProtect no se asume éxito: instalación revierte su puntero mediante CAS si puede y reintenta restaurar permisos; estado pendiente permite reintento explícito.

DllMain sigue solo llamando DisableThreadLibraryCalls. La nueva instalación/PE guard/pin ocurre en pre_init, no en DllMain; carga de plugins ocurre en el callback. Límite heredado: el bootstrap SetCurrentDirectoryW se instala por inicializador estático (bajo inicialización del loader) usando SimpleInlineHook; no se reescribió ese mecanismo en este cambio. TLS/call_once y dependencias MinGW requieren validación Windows/Proton.

Pruebas: tests/slot_hook_test.cpp usa el mismo SlotHook con Ops simuladas; 13 escenarios pasan con ASan/UBSan y -Wall -Wextra -Werror. Cubren true/false y self, callback retenido tras restore, slot ajeno, lectura fallida, alineación, pin/protect fallidos, carrera de instalación, tercero antes/durante restore, rollback por fallo de protección, reintento de permisos y reentrada. No simulan el kernel Windows ni prueban todos los interleavings reales. El desensamblado Windows muestra lock cmpxchg de 64 bits y conservación del retorno del callback.

Compilación build-codex completa y auditoría core con -Wall -Wextra -Wpedantic -Werror sin warnings. Staging dist actualizado; ningún archivo instalado, proceso manipulado o Proton ejecutado. Core SHA256 0154a3861b09d896dc47cd712654bfc6cd99e56d351b629e6c7eabaa98cb7a0f. Evidencia en research/sigma2_fix/.

Listo para diseñar/realizar una prueba controlada del core: YES, como binario experimental, no como mod validado. La prueba debe observar guard, carga única de plugins, bool de inicialización y compatibilidad del CRT, manteniendo respaldo y sin asumir que otros módulos ya son seguros. No se ejecuta en este hito.

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
