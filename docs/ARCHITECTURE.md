# Arquitectura observada

| Componente | Función por lectura del código |
|---|---|
| core → dbghelp.dll | Stub MiniDumpWriteDump; constructor estático instala inline hook de SetCurrentDirectoryW. pre_init instala check_dlls, patch de 7 bytes y supuesto hook virtual de Sigma2. Callback enumera plugin\*.dll y llama LoadLibrary. No comprueba errores de carga. |
| loader → nmloader.dll | Redirige lectura de chunks ProductionPackage a mods/%05d.dat, cambia tamaño descomprimido. Mantiene rutas NGS1 AE, NGS2 AE/JP. |
| effect → nmeffect.dll | Sangre, manchas limitadas mediante cola, desmembramiento, visibilidad de nodos, afterimages, persistencia de cuerpos/miembros y ampliación de model manager. No crea segundo jugador. |
| combat → nmcombat.dll | Multiplicadores HP/daño enemigo por dificultad y parches Flying Swallow, Story/Chapter Challenge. |
| steam-bugfixes → nmsteam-bugfixes.dll | Parche de índice para volver al menú y salto para cierre/deadlock, según comentarios. |
| util.hpp | Base del EXE vía GetModuleHandle; Patch escribe memoria con VirtualProtect; SimpleInlineHook usa mov rax/jmp rax de 12 bytes; VFPHook reemplaza puntero y conserva anterior. |

README especifica Steam Sigma 2 Master Collection, dbghelp.dll junto al EXE, plugin/ singular y mods/ opcional para datos. Proton requiere WINEDLLOVERRIDES=dbghelp=n,b según documentación local y log histórico. No se requieren version.dll/dinput8.dll/winmm.dll ni config según estas fuentes. CMake no instala datos del mod ni runtimes; se añadieron estos últimos a dist experimental.

No hay scanner de firmas, motor de red, sistema de input ni bucle propio. Las estructuras son parciales y orientadas a renderizado/cadáveres. Los nombres NG2 describen efectos restaurados, no compatibilidad binaria con Xbox/PS3. El commit 12.7 declara eliminar Steam JP, pero dejó ramas históricas en loader y declaraciones jp sin uso en effect.

Riesgos pendientes: Patch ignora fallo de VirtualProtect y no vacía caché de instrucciones; move assignment no transfiere protección. SimpleInlineHook destruye explícitamente m_patch y lo usa después sin reconstruir su lifetime, además de desparchear globalmente para llamadas (no thread-safe). La carga de módulos y patches desde inicializadores/DllMain requiere revisión de loader lock. No se corrigieron estos puntos por conjetura en este hito.
