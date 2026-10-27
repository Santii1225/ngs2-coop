# Resultado final — CONTROLLED IN-GAME TEST 01: PASS

Cierre verificado: 2026-09-06T18:23:14.042566-06:00. PASS limitado a esta ejecución y este ejecutable; no implica garantía entre arranques/versiones ni validación de gameplay nuevo.

- Game executable SHA256: `a66daf011d22dd6fd6676e0b8ccc68e85448d4570bbac635e25adc1f2d06ffef`.
- core.dll SHA256: `ca2849b56c3543351f8a56556e80424cc42cdd685ac8a962543384f726e1db1d`.
- Loader: dbghelp.dll histórico intacto; plugin/core.dll con tres runtimes MinGW locales, hashes verificados al terminar.
- Hora: inicio log 2026-09-06 18:05:15 local (2026-09-07 00:05:15 UTC), menú observado 18:06, misión confirmada/observada 18:13, cierre verificado 18:23 America/Mexico_City. Horas de observación, no cronometraje exacto del gameplay.
- Base: 0x140000000; slot: 0x1418F9518 (RVA 0x18F9518).
- Target previo observado = esperado: 0x141462A00 (base+0x1462A00).
- Core loaded YES; version guard PASS; hook installed YES; callback invoked YES; original called YES, retornó bool=true.
- Retorno original preservado por diseño y ASM, con log posterior a llamada original. Sin captura independiente del retorno recibido por caller.
- Menú estable YES; misión estable YES, completada y regreso al menú confirmados por usuario, mismo proceso activo. Sin medición independiente de duración exacta ni inspección visual del agente.
- Normal shutdown YES: usuario confirma cierre normal; /proc/8894 ausente y ningún proceso NINJA encontrado. No se forzó el cierre. Exit code no capturado.
- Sin crash atribuible al plugin observado. No se afirma log Proton libre de errores: HID repetido en proceso Wine 0094 durante misión; RPC 0x6be/0x6ba y servicio error 1726 al cierre en 0120, distinto del juego 013c. Los RPC/servicio tienen equivalentes en histórico funcional; HID exacto no. Sin causalidad demostrada con core. Extractos conservados.
- core.log final idéntico al de menú: 460 bytes, SHA256 `c813689df355ad0565b41d97b4f8dffa365f1ad77c05d9b0721831199fc4a257`.
- Restore path: NO invocado/NO observado. No hay restore automático en DllMain; módulo pinned hasta terminar proceso. Cierre normal no prueba NMRestoreSigma2Hook en juego; restore sigue cubierto por harness.
- Rollback required NO; no ejecutado. Cuatro DLL nuevas permanecen instaladas; loader, EXE, steam_api64 y cinco plugins históricos conservan hashes.
- Backup/manifest: `backups/pre-core-runtime-test-20260906-180142/`. No originales reemplazados. Rollback documentado: juego cerrado, comprobar cuatro hashes y mover solo cuatro DLL propias a backup/withdrawn/, sin borrar archivos ajenos; conservar logs de evidencia.

## Criterios de éxito de esta prueba

- [x] Juego arranca (confirmación usuario, proceso observado).
- [x] core.dll cargada (maps + log propio + Proton).
- [x] Module base válida.
- [x] Slot RVA 0x18F9518 válido.
- [x] Target == base + 0x1462A00.
- [x] Hook instalado.
- [x] Callback ejecutado.
- [x] Función original llamada.
- [x] Retorno original preservado por diseño.
- [x] Menú estable durante prueba.
- [x] Misión estable durante prueba.
- [x] Salida normal confirmada, proceso terminado.
- [x] Sin crash atribuible al plugin observado.

Evidencia final en `evidence/ingame_test_01/shutdown/`; evidencia previa de menú y misión conservada. Implementación: commit 75c8c64; menú: 1a35a13; misión: 4946a83. Build y 13 escenarios ASan/UBSan ya pasaron; no se recompiló ni reinstaló durante runtime. No inputs automatizados, escrituras externas de memoria, cambios de Proton/prefix/sysctl/Steam, saves o EXE, ni push. No networking/Player/Team Missions.

Siguiente paso seguro: conservar este hito validado. Cualquier repetición futura deberá volver a observar la invocación: el hilo de inicialización no garantiza orden en todos los arranques. No se inicia otra fase en este trabajo.

---

Los apartados siguientes son el historial cronológico: PARTIAL y bloqueos anteriores describen esos momentos, no el resultado final.

# CONTROLLED IN-GAME TEST 01 — preflight

Fecha: 2026-09-06T17:56:22.029839-06:00. Final verdict: **PARTIAL**. Prueba dentro del juego NO iniciada.

## Estado y binario

Git inicial limpio, HEAD fe481da (`fix: correct Sigma2 vtable hook address and return ABI`), verificados últimos ocho commits. No se reconstruyó trabajo previo ni recompiló.
`build-codex/` y `dist/` existen. El target CMake `core` produce **dbghelp.dll**, no core.dll: `OUTPUT_NAME dbghelp`, instalación en raíz. Ambos artefactos tienen 238504 bytes y SHA256 `0154a3861b09d896dc47cd712654bfc6cd99e56d351b629e6c7eabaa98cb7a0f`, idéntico al esperado. PE32+ AMD64 x86-64. Exports: DllMain, MiniDumpWriteDump, NMRestoreSigma2Hook. Imports completos y dependencias transitivas en evidence/ingame_test_01/*.pe.txt; inventario de rutas, tamaños y SHA256 en inventory.json.

## Instalación real

Game: `~/.local/share/Steam/steamapps/common/[NINJA GAIDEN Master Collection] NINJA GAIDEN Σ２/NINJA GAIDEN SIGMA2.exe`.
Game executable SHA256: `a66daf011d22dd6fd6676e0b8ccc68e85448d4570bbac635e25adc1f2d06ffef`; 37637472 bytes.
Steam libraryfolders.vdf y appmanifest_1580790.acf confirman biblioteca e installdir, buildid 6998211. Prefix existente: `~/.local/share/Steam/steamapps/compatdata/1580790/pfx`, version 11.0-100. Solo lectura; no se modificó.
No se observó proceso NINJA en /proc durante el preflight. No se lanzó Steam/juego.

## Loader y destino

LOADER PATH CONFIRMED: dbghelp.dll histórico junto al EXE, SHA256 `8f20f4964be657d8d428fe52e9e5673c8fe05da34d8b40fa46411b55b384f4e6`, 14848 bytes. Su callback DLL+0x1190 llama LoadLibraryA en DLL+0x12b5. FindFirstFileA/FindNextFileA enumera plugin\*.dll; GetModuleHandleA evita recargar nombres ya presentes; SetDllDirectoryA establece plugin\. No hay filtro de prefijo nm ni ordenación explícita: usa orden de enumeración. Intenta cada DLL no cargada; no hay API NM de registro.
PLUGIN DIRECTORY: `~/.local/share/Steam/steamapps/common/[NINJA GAIDEN Master Collection] NINJA GAIDEN Σ２/plugin`.
CORE INSTALL DESTINATION: el build actual está diseñado para `~/.local/share/Steam/steamapps/common/[NINJA GAIDEN Master Collection] NINJA GAIDEN Σ２/dbghelp.dll`. **NO autorizado** por prohibición explícita del usuario. `plugin/core.dll` NO es una integración validada de este artefacto.
DEPENDENCIES REQUIRED: libgcc_s_seh-1.dll, libstdc++-6.dll, libwinpthread-1.dll y APIs KERNEL32/UCRT; ninguna DLL nm del proyecto importada. Los tres runtimes existen en dist; no están en raíz/plugin del juego. No se inspeccionó ni alteró su resolución global en prefix. Para una futura carga temprana como proxy, la colocación local propuesta es junto al EXE, pendiente de resolver el bloqueo; no instalar runtimes en plugin/ a ciegas porque el loader enumera todas las DLL. Ninguna dependencia instalada.

Evidencia reutilizada y recontrastada: research/historical_dbghelp.asm (RVA 0x1190–0x1338 y pre_init 0x1340), imports históricos y `git show 0164b26:src/core/main.cpp`. El hash instalado sigue coincidiendo con el histórico analizado. ../steam-1580790-working.log líneas 14–15, 888, 3981–3987 demuestra override histórico dbghelp=n,b, carga nativa y plugins; no prueba nueva ejecución. Plugins existentes: NGS2Coop, nmcombat, nmeffect, nmloader, nmsteam-bugfixes; todos conservados.

## Bloqueo de inicialización

El core nuevo engancha SetCurrentDirectoryW mediante inicializador estático y solo instala Sigma2 en pre_init. El histórico ya pasó por ese bootstrap cuando carga plugin/ desde check_dlls (EXE RVA 0xb5c460). Renombrar dbghelp.dll a core.dll no hace que pre_init se ejecute al recibir DLL_PROCESS_ATTACH. No hay evidencia de otra llamada apropiada posterior a SetCurrentDirectoryW. Si ocurriera, el core además instalaría su propio hook legacy de check_dlls y patch 0x1340d3b, coexistiendo con el loader histórico: no es una integración demostrada. Copiarlo como plugin/dbghelp.dll tampoco resuelve el problema: el histórico omite ese nombre ya cargado.

Por tanto no pasan todas las comprobaciones de instalación. Se necesita adaptar explícitamente el arranque para funcionar como plugin del loader histórico, conservando guard y ABI, o revisar la prohibición de reemplazo del proxy. No se eligió ni implementó silenciosamente una arquitectura distinta.

## Guard, logging y retorno

Revisión de código: slot = base+0x18f9518, expected = base+0x1462a00; SlotHook comprueba igualdad antes de pin/protección y otra vez mediante CAS. Mismatch no escribe el slot. Guard estructural PE conservado. **VERSION GUARD runtime: NOT TESTED**.
Logging actual insuficiente: solo OutputDebugStringA con éxito/error genéricos; faltan log persistente, base/slot/target observado/esperado y marca de primera invocación. No se implementó ni recompiló instrumentación mientras el mecanismo de carga está bloqueado; requisito pendiente, NO listo para lanzar.
Callback llama `return Sigma2_vfunction1_hook.original()(thisptr);`: retorno preservado por diseño y harness histórico true/false, no nueva evidencia runtime. Restore explícito NMRestoreSigma2Hook; sin restore automático en DllMain. No invocado.

## Backup, instalación y rollback

Backup preparado: `backups/pre-core-runtime-test-20260906-175622`. Contiene solo README de ausencia de modificaciones; no se copiaron archivos ajenos que no van a reemplazarse.
`plugin/core.dll`: **NO PREVIOUS FILE — NEW PLUGIN**, observación de inexistencia, NO compromiso de destino válido.
Installed files: ninguno. SOURCE/DESTINATION/SHA256/PURPOSE de copias: no aplican, cero copias.
Rollback required: NO. Instalación intacta, no eliminar/restaurar nada. Si en una continuación se instala un plugin nuevo, registrar su hash y retirarlo solo tras salida y coincidencia inequívoca (preferir moverlo al respaldo para cumplir no borrar). Si se autoriza reemplazo futuro, respaldar y verificar bytes ANTES; este directorio aún no contiene ese backup.

## Resultados observables

- Juego arranca con core nuevo: NOT TESTED.
- Core DLL loaded: NO (no instalada).
- Module base/slot/observed target de esta prueba: NOT OBSERVED.
- Expected target: module_base + 0x1462A00.
- Hook installed / callback executed / original called: NO evidencia nueva.
- Original return preserved: por diseño; no directamente observado.
- Menu result / mission result / shutdown result: NOT TESTED.
- Errors: bloqueo de empaquetado/bootstrap; sin ejecución nueva para atribuir crashes o errores Wine/Proton.
- Final verdict: PARTIAL — preflight verificó binario, instalación, loader y dependencias; instalación detenida antes de cualquier escritura.

Siguiente paso: resolver integración de core como plugin conservando dbghelp histórico; completar logging, build/harness y commit separado antes de instalar. No pedir abrir el juego mientras falten estas comprobaciones. No gameplay, networking, Player/Team Missions research, inputs, cambios de saves/EXE/Proton/Steam/sysctl ni push.

## Adaptación autorizada e instalada — 2026-09-06T18:01:42.997387-06:00

Este apartado sustituye el bloqueo del preflight anterior; ese apartado conserva evidencia histórica del artefacto proxy, NO describe el core instalado ahora. Estado global: **PARTIAL — READY TO LAUNCH, sin ejecución de juego todavía**.

### Arquitectura y bootstrap

CMake core antes generaba dbghelp.dll por OUTPUT_NAME y se instalaba en raíz. Ahora genera core.dll y el componente core-runtime instala solo plugin/core.dll. Se retiraron de este core: include util.hpp, inicializador estático de SimpleInlineHook(SetCurrentDirectoryW), check_dlls y patch 0x1340d3b, enumeración/carga de plugins, MiniDumpWriteDump. Esas responsabilidades del loader histórico no se duplican. No se cambió ningún archivo del loader.

DllMain únicamente llama DisableThreadLibraryCalls, crea un hilo de inicialización, cierra su handle y retorna sin esperar. Si CreateThread falla devuelve FALSE, sin instalar hook. El hilo no comienza su entry hasta completar notificaciones del loader; hace pin, logging, PE guard y slot install fuera de DllMain. No hay espera/sincronización con ese hilo en DllMain ni hooks de .text en el core. Datos propios inicializados estáticamente; no hay constructores propios que parcheen código. No se depende de recibir otra llamada a SetCurrentDirectoryW.

Limitación explícita: Microsoft considera CreateThread dentro de DllMain arriesgado aunque puede funcionar sin sincronización. Se eligió como puente mínimo porque el loader histórico solo usa LoadLibrary y no llama un export de inicialización. Ese loader mantiene la referencia de LoadLibrary (no descarga); el hilo hace pin, y SlotHook vuelve a asegurar pin antes de publicación. No se ofrece soporte de unload arbitrario entre LoadLibrary y arranque del hilo. No hay teardown/esperas en DLL_PROCESS_DETACH.

No se garantiza que el scheduler ejecute el hilo antes del primer call virtual Sigma2. Si el hook se instala tarde y el callback no aparece, la prueba seguirá PARTIAL; nunca se reinvocará manualmente original ni se falseará evidencia. No se añade prioridad, suspensión de threads ni escrituras externas para forzar esa secuencia.

Fuentes: [Microsoft: DLL best practices](https://learn.microsoft.com/en-us/windows/win32/dlls/dynamic-link-library-best-practices), [CreateThread](https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-createthread).

### Protecciones y logging

src/core/slot_hook.hpp y sigma2_hook.hpp siguen **idénticos a fe481da**: base dinámica, PE guard, slot RVA 0x18F9518, target RVA 0x1462A00, igualdad antes de pin/protección y CAS de 64 bits al publicar; protección restaurada y restore condicional. El hilo añade lectura/log del target y rechazo explícito antes de llamar install. Doble inicialización: atomic_flag; doble instalación/reentrada: SlotHook existente. No se modificó la ABI probable bool(Sigma2*).

El callback ya no enumera plugins (lo hace el histórico). Llama al original exactamente una vez por callback, guarda bool local, registra solo para la primera invocación y devuelve el mismo bool. Primer callback: `NGS2Coop: Sigma2 hook invoked`; después del retorno normal: `NGS2Coop: Sigma2 original returned bool=true/false; forwarding unchanged`. Si original no retorna no habrá segunda marca. El ASM confirma call rax, guardar AL, logging y recargar el mismo byte para devolver EAX/AL. No asegura bits altos de RAX ajenos al contrato bool.

Log nuevo: `plugin/ngs2coop-core-YYYYMMDD-HHMMSS-mmm-PID.log` (UTC), ruta obtenida de la propia DLL, CREATE_NEW; no sobrescribe logs anteriores ni depende de CWD. File handle publicado atómicamente; escrituras serializadas, WriteFile con WRITE_THROUGH, OutputDebugString de respaldo y LastError preservado. No se cierra el handle mientras pueda existir callback; SO lo libera al salir. Fallo de crear log aborta instalación. Mensajes: core plugin loaded, initialization starting, module base, slot, expected, current target, guard PASS/FAIL, hook installed/refused y resultado numérico de SlotHook. Callback puede intercalarse antes del mensaje installed por concurrencia; no interpretar solo orden de líneas como fallo.

NMRestoreSigma2Hook sigue exportado y mantiene restore seguro, emite marca debug al pedir restore explícito. No se invoca en este turno; no hay auto-restore al terminar el proceso ni evidencia de shutdown todavía.

### Build y dependencias

Build completo build-codex PASS. Harness existente completo: **13 escenarios PASS**, ASan/UBSan, -Wall -Wextra -Werror. Auditoría core: -Wall -Wextra -Wpedantic -Werror PASS. Avisos CMake CMP0177 de destinos legacy ./plugin aparecieron al regenerar, sin warnings de compilador; no se alteraron targets ajenos. Una edición intermedia con constinit de INVALID_HANDLE_VALUE fue rechazada por el compilador; se corrigió a atomic<HANDLE> inicializado a nullptr y el build final pasó. No se distribuyó el intento fallido.

PE32+ x86-64, 225191 bytes. Export único NMRestoreSigma2Hook; entry CRT invoca DllMain normalmente, no necesita exportar DllMain. Imports: KERNEL32, APIs UCRT y libstdc++-6.dll (assert_fail y personality). libstdc++ necesita libgcc_s_seh-1 y libwinpthread-1; libgcc también requiere winpthread. **Los tres runtimes siguen siendo necesarios**, dos transitivamente. No se añadieron -static-libgcc/-static-libstdc++ ni opciones de linking estático.

El loader histórico llama SetDllDirectoryA(plugin\) en DLL RVA 0x1206 antes de LoadLibraryA en 0x12b5, omite nombres ya cargados y enumera *.dll. Esa ruta permite resolver dependencias en plugin/ durante LoadLibrary, aunque core aparezca antes en la enumeración. APIs del sistema/UCRT corresponden a Windows/Proton; no se instalaron copias globales. Conclusión respaldada por binario histórico y [contrato SetDllDirectoryA](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-setdlldirectorya); resolución efectiva en este Proton pendiente de ejecución. No se promete preferencia sobre módulos con el mismo nombre ya cargados.

Dist anterior se movió íntegro, sin borrar, a la ruta registrada en evidence/core_plugin/staging.json bajo build-codex/. Dist actual contiene exclusivamente plugin/core.dll y los tres runtimes. No instalar con cmake --install sin componente; reproducir staging de core con `cmake --install build-codex --prefix "$PWD/dist" --component core-runtime` y copiar solamente esos runtimes locales.

Nuevo core SHA256: `ca2849b56c3543351f8a56556e80424cc42cdd685ac8a962543384f726e1db1d`. Cambió porque se recompiló tras adaptar bootstrap y logging; no es el artefacto proxy original 0154a386… . Build y dist coinciden con instalación. Evidencia completa: evidence/core_plugin/build.log, tests.log, warnings.log, *.pe.txt, callback-and-cas.asm, staging.json, installation.json.

### Instalación mínima y backup

Backup: `backups/pre-core-runtime-test-20260906-180142`. Todos los destinos eran nuevos; README y manifest, ningún original que respaldar. core: **NO PREVIOUS FILE — NEW PLUGIN**. Runtimes: NO PREVIOUS FILE — NEW DEPENDENCY. Antes y después se contrastaron hashes de TODOS los archivos de instalación del inventario previo, incluidos EXE, dbghelp.dll y nmsteam-bugfixes.dll: sin cambios. No se tocó prefix, configuración, saves ni .text externamente.

| Archivo | SHA256 | Motivo |
|---|---|---|
| core.dll | `ca2849b56c3543351f8a56556e80424cc42cdd685ac8a962543384f726e1db1d` | Sigma2 guarded slot hook |
| libgcc_s_seh-1.dll | `6d4d1e8b48a06a591cf60599ec6e3dd2ba31e0bf5e81dd198ed25cfea9a86117` | MinGW runtime dependency |
| libstdc++-6.dll | `055d42d37df160bc1d2bae503363fc49b64becb495b32f2efb6de50c3411f466` | MinGW runtime dependency |
| libwinpthread-1.dll | `9230fabfb5b5909d6f223327d2ac72cf17e161dfe51e9c7537517ae61a05e62e` | MinGW runtime dependency |

SOURCE de cada archivo: `<ruta-del-repo>/dist/plugin/<nombre>`. DESTINATION: `~/.local/share/Steam/steamapps/common/[NINJA GAIDEN Master Collection] NINJA GAIDEN Σ２/plugin/<nombre>`. Tamaños, hashes y estado previo exactos en manifest.json e installation.json.

Rollback preparado, NO ejecutado: cerrar normalmente el juego primero; comprobar los cuatro SHA256 del manifest antes de hacer nada; mover solo esos cuatro archivos a backup/withdrawn/ (fuera de plugin, sin borrarlos). Si alguno difiere, detenerse sin tocarlo. No restaurar/eliminar DLL ajenas. Conservar los logs nuevos como evidencia. La ausencia original de esos cuatro archivos está registrada; no hay originales que restaurar.

### Estado al detenerse

Historical loader preserved: YES. Ready to launch: YES, para prueba controlada experimental. Core loaded / guard runtime / hook installed / invoked / original called: NOT TESTED en esta ejecución. Expected target: module_base+0x1462A00; observado: pendiente. Menú, misión, salida: NOT TESTED. No se inició Steam ni Sigma2, no se inspeccionaron módulos/memoria/proceso runtime. No hay crash nuevo observado que atribuir al plugin. Final verdict sigue PARTIAL; instalar no equivale a PASS.

Acción manual siguiente: iniciar normalmente desde Steam y dejar en menú, sin misión; responder YA ESTÁ EN EL MENÚ o error exacto. Después se observará carga/logs y se decidirá si procede misión. Sin inputs automatizados, networking ni investigación Player/Team Missions. Sin push.

## Primera validación de menú — 2026-09-06T18:06:22.261514-06:00

Usuario confirma «YA ESTÁ EN EL MENÚ». Proceso Linux PID 8894 activo, TracerPid 0; EXE en ruta Steam confirmada. Maps muestra core.dll, dbghelp histórico y los tres runtimes desde plugin/. Los cuatro SHA256 instalados coinciden con manifest. No se leyó/escribió memoria del proceso ni se automatizaron inputs.

Log nuevo `~/.local/share/Steam/steamapps/common/[NINJA GAIDEN Master Collection] NINJA GAIDEN Σ２/plugin/ngs2coop-core-20260907-000515-563-316.log` (PID Windows 316 = 0x13c; PID Linux 8894), 460 bytes, preservado en evidence/ingame_test_01/menu/core.log. Se distingue del log histórico.

- CORE DLL LOADED: YES (maps, log propio y carga native en Proton línea 3983).
- Module base: 0x140000000.
- Slot: 0x1418F9518 = base + 0x18F9518.
- Expected target: 0x141462A00.
- Observed target antes de CAS: 0x141462A00.
- VERSION GUARD: PASS.
- VTABLE HOOK INSTALLED: YES (log del resultado installed, posterior al CAS y restauración de permisos).
- HOOK CALLBACK EXECUTED: YES, marca única `NGS2Coop: Sigma2 hook invoked`.
- ORIGINAL CALLED: YES; marca posterior `Sigma2 original returned bool=true; forwarding unchanged`.
- ORIGINAL RETURN PRESERVED: evidencia runtime de retorno true del original + código/desensamblado que conserva y devuelve ese bool. Sin captura independiente de AL en caller.
- Menú: estable según confirmación del usuario y proceso activo durante inspección; no inspección visual propia.
- Misión/salida: NOT TESTED. Final verdict: PARTIAL hasta completar ambas.

Proton registra installed a 1003.267 e invoked a 1003.270; esta ejecución sí alcanzó el callback tras instalar. No extrapolar garantía de orden a todos los arranques. Se encontraron err HID parent device, winebth c0000142, VR info y COM class e018945b; todos tienen equivalentes en steam-1580790-working.log (incluido RPC 6ba), anteriores al core nuevo. Las excepciones rotuladas DBG_PRINTEXCEPTION_C corresponden a debug strings y EXCEPTION_WINE_NAME_THREAD a nombres de hilos. No se encontraron marcadores de page fault/unhandled exception/backtrace ni error import_dll en el log inspeccionado; no prueba ausencia universal de errores. Extractos de ambos logs conservados. Ningún error nuevo atribuible al core identificado. No se requiere rollback.

Siguiente acción autorizada: pedir misión normal de 30–60 segundos y vuelta al menú; detenerse hasta confirmación. No cerrar aún ni automatizar gameplay.

## Validación después de misión — 2026-09-06T18:13:28.166767-06:00

Usuario confirma «MISIÓN TERMINADA, ESTOY EN EL MENÚ», sin reportar incidencias. PID Linux 8894 sigue activo y su starttime coincide con la captura inicial (no hubo reemplazo del proceso entre observaciones). Core, loader y runtimes siguen mapeados. No se automatizó gameplay ni se leyó/escribió memoria.

Log core permanece idéntico, 460 bytes, SHA256 c813689df355ad0565b41d97b4f8dffa365f1ad77c05d9b0721831199fc4a257: guard PASS, hook installed/invoked y original bool=true. No hay mensajes nuevos del plugin; el log-once no permite contar llamadas adicionales ni demuestra que no las hubo.

Comparación Proton con extractos del menú: **1188 líneas nuevas**, todas `err:hid:set_report_from_event TODO: Process Report (21, 0)`, identificadas como proceso Wine 0094/hilo 00bc, distinto del juego 013c. El mensaje exacto no estaba en el log histórico funcional; no llamarlo error histórico equivalente. No hay nuevos err de core/import_dll, page fault, unhandled exception o backtrace en la captura. Evidencia ubica los mensajes en HID de Wine, sin relación causal demostrada con el hook; no se modifican drivers, Proton ni configuración para silenciarlos. No se observó crash del juego y el usuario regresó al menú. No se ejecuta rollback.

Mission result: completada y vuelta al menú confirmada por usuario, proceso vivo; duración exacta y evaluación visual no medidas por el agente. Shutdown result: NOT TESTED. Final verdict: PARTIAL hasta salida normal. Evidencia: evidence/ingame_test_01/mission/ (maps, log, observación y extractos Proton). Siguiente acción manual: cerrar normalmente desde el juego y confirmar; no forzar cierre.
