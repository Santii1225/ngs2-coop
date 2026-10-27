# Fase 6 — Player/XYZ, investigación de solo lectura

Estado inicial: 2026-09-06, HEAD 151ea14, Git limpio, últimos ocho commits verificados. CONTROLLED IN-GAME TEST 01 = PASS preservado. No cambios en core, build, DLL instaladas, loader o configuración. Esta preparación NO es un resolver validado y no se hace commit de hipótesis.

## Clasificación

LEGACY: declaraciones/usos en fuentes heredadas, no garantía de layout real. STATIC CANDIDATE: metadatos/relaciones propuestos para probar, sin demostración física. RUNTIME VERIFIED para Player/XYZ exige reposo, movimientos A/B/C y resolución reproducida tras reiniciar. La instancia Sigma2 tiene evidencia runtime histórica propia, pero no confirma ninguna relación con Player.

## Fuentes y estructuras

Revisados src/, docs/, fuentes effect de 0164b26 (12.6), fuentes actuales y ../ngs2-coop/src/main.cpp (solo logger de carga). No existe include/ independiente en este checkout. No hay definición completa de Player. No ejecutar los patches de effect como parte de esta investigación; solo leer sus fuentes. DLL históricas instaladas se conservan como contexto previo de la prueba.

Tamaños siguientes describen layout declarado x64, NO tamaños de allocations observados:

| Field | Offset | Evidence | Status |
|---|---|---|---|
| game_object table | module+0x3195300; stride 0x30 | effect/main.cpp:27,607; tabla inicializada con stride 0x30/count 0xa0 en captura runtime histórica | LEGACY; selección Player no demostrada |
| game_object.data_ptr0x0/8/10 | +0 / +8 / +0x10 | tres uintptr_t del struct, propósito incompleto | LEGACY |
| game_object.obj_id | +0x18, uint8 | usos en is_to_be_vanished para tipos de enemigos | LEGACY; no ID de personaje validado |
| game_object.data0x1a | +0x1a, uint8 | índice de columna en tabla offsets[48/65][data0x1a] | LEGACY |
| game_object.obj_group_index | +0x1f, uint8 | is_stationary accede character_ptr[grp] | LEGACY |
| character table | module+0x2f78b10; stride 0x1240 | effect/main.cpp:290,763; 0x210+1+0x102f bytes | LEGACY |
| character.dead | +0x210, uint8 | comparación con 4 en rutina de cadáveres; no HP | LEGACY |
| character otros campos | +0..0x20f, +0x211..0x123f | arrays sin tipos semánticos | LEGACY |
| object_data_offset_table | module+0x1e38710, filas 4 QWORD (stride 0x20) | effect/main.cpp:606 y dismember.hpp:75 | LEGACY |
| node_layer | tamaño declarado 0x68 | punteros nodeobj +0, hielay +8, tipo +0x10, next +0x18, parent +0x20, first_child +0x28, next_sibling +0x30; visibilidad +0x50/+0x51 | LEGACY |
| limb_data.matrix_ptr | +0x20 | alignas(16) del puntero; tabla miembros separados | LEGACY; descartar como Player directo |
| limb_data.location_vec | +0x28, float[4] | viene tras puntero de 8 bytes; nombre no garantiza offset +0x30 | LEGACY; NO Player XYZ |
| limb_data | tamaño declarado 0x70/alineación 16 | fuente rigidbody | LEGACY |
| afterimage_param.unknown0x0 | +0, uint32; tabla module+0x1e39b40 | comentario Character Id?; p[0..3] Ryu/Ayane/Momiji/Reichel en parámetros visuales | LEGACY; NO identidad instancia |
| Player resolver | desconocido | ninguna selección de jugador local demostrada | STATIC CANDIDATE pendiente |
| Position X / Y / Z | desconocidos | sin snapshots de movimiento | STATIC CANDIDATE pendiente |
| Rotation / movimiento / identidad | desconocidos | no deducir de animación/colores/índices | STATIC CANDIDATE pendiente |

Dos structs game_object diferentes: effect/main.cpp tiene 0x30 bytes; dismember.hpp omite trailing 0x10 y es una vista incompleta de 0x20. No usar su sizeof como stride de tabla. Nombres con hex de otros structs no garantizan offset real: por ejemplo game_model declara uint16+uint16 y después float llamado data0x8, cuyo offset declarado es +4; no usar nombres como layout verificado.

Funciones legacy relevantes (no invocarlas manualmente): get_pose_matrix(float[16] out, node_layer&, game_object&) RVA 0xc0fdc0; get_lump_pose_matrix(lump_data&, float[16], game_object&) RVA 0x144a330 para fragmentos; is_stationary(int32 index) RVA 0xf896d0 accede game_object[index] y character[group]. La fuente delega pose_matrix al original salvo fragmentos. Falta probar si matriz es local/model/world, hueso o raíz: una matriz que cambia no basta para posición de Player.

Cadenas explícitas en fuente, aún LEGACY:

- module+0x3195300 + index*0x30 -> leer byte +0x1f -> module+0x2f78b10 + group*0x1240. No se conoce index del jugador; no asumir 0.
- obj.data_ptr0x0 + offsets[48][obj.data0x1a] -> array de node_layer*.
- obj.data_ptr0x0 + offsets[65][obj.data0x1a] -> object_data* -> +8 tmc. Recurso de modelo, no posición.

12.6 conserva esos RVAs AE y también declara variantes JP (tabla object 0x3194300, character 0x2f77b10); no mezclar variantes. EXE actual AE SHA256 a66daf011d22dd6fd6676e0b8ccc68e85448d4570bbac635e25adc1f2d06ffef, buildid 6998211.

## Punto de partida Sigma2

Evidencia previa docs/research/runtime_instance.json: global module+0x1e66e60 contiene dirección module+0x1e66d00; vptr de instancia apunta a tabla module+0x18f9518. Instancia no es Ryu. Lectura histórica de código muestra acceso a self+0x150 y flag +0x158; tamaño completo desconocido. Ni +0x150 ni globals 0x2ee8358/0x2ee8360 tienen identidad Player/manager demostrada. Se reutiliza evidencia sin reinvestigar hook/ABI.

La relación de Sigma2 con inicialización de tabla game_object apoya priorizar esa tabla, pero NO demuestra un puntero directo Sigma2->Player. Primera ventana: 0x160 bytes de Sigma2 y global de 8 bytes; seguir +0x150 solo si es puntero legible y documentar, sin nombrarlo GameContext por suposición.

## RTTI en disco

research/player/rtti_candidates.json contiene coincidencias de nombres RTTI-like en secciones no ejecutables del EXE, con RVA de la cadena (no del TypeDescriptor). Búsqueda acotada de nombres hasta 180 caracteres; no recuperación exhaustiva de tipos. Hay numerosos efectos Transform/Ryu, audio StreamPlayer y falsos positivos Factory por substring actor. No identifican al jugador. Coincidencias incidentales de menús fuera de alcance no se investigan. No se halló aquí una definición inequívoca Player que resuelva XYZ. Nombres Sigma2 SingletonPtr/StoragePtr concuerdan con contexto conocido, no agregan una cadena Player.

## Plan acotado para PLAYER_SCAN_A_IDLE

Esperar respuesta RYU QUIETO antes de abrir /proc/PID/mem. Lecturas exclusivamente O_RDONLY/pread, sin attach, escrituras, breakpoints ni cambios de permisos. Reidentificar PID/base por EXE, verificar core en maps y log de la nueva ejecución; comprobar slot apuntando al callback conocido del core como chequeo de continuidad, sin nueva investigación del hook.

Capturar tabla candidata game_object (0xa0*0x30 = 7680 bytes), instancia Sigma2 y tabla offsets hasta fila 65 (2112 bytes). Resolver entradas/punteros solo dentro de mappings legibles; inspeccionar primero headers y grupos referenciados, con presupuesto explícito antes de ampliaciones (objetivo inicial inferior a 256 KiB por muestra). Nada de barrer todo el heap. Si límites/índices/punteros no son coherentes, registrar rechazo y revisar candidatos, no leer arbitrariamente memoria masiva.

Dos lecturas separadas en reposo permitirán filtrar animación/temporizadores. Buscar triples float/double finitos y matrices en bloques justificados; no fijar orden de ejes ni confundir cámara, huesos, enemigos o duplicados render con posición autoritativa. Guardar rango, procedencia/pointer chain, instante, tamaño y hash. Snapshots no atómicos, juego no suspendido.

B y C requieren interacción humana separada. Comparar bloques por procedencia/índice y pointer identity, no solo por dirección. Movimiento coherente repetido, estabilidad en reposo y validación tras reinicio obligatorios. Si solo existe copia de transform y no objeto jugador identificable, declarar límite. Rotación/identidad solo después de XYZ fuerte. Herramienta resolver CLI e integración core quedan pendientes hasta resolver y reproducir; no modificar core ahora.

## Estado de esta preparación

MVP 1 PARTIAL: inventario y candidatos preparados; ninguna posición capturada ni confirmada. No se lanzó juego, no hubo lectura runtime nueva, recompilación o instalación. No commit de hipótesis ni push. Siguiente acción manual: iniciar misión con Ryu y quedar quieto.

## PLAYER_SCAN_A_IDLE — 2026-09-06T18:33:47.505256-06:00

Usuario: RYU QUIETO. Proceso Linux 12404, base 0x140000000; core 0x6ffff9830000. Se verificaron SHA256 de EXE/core y slot activo 0x6ffff98316f2 = core+0x16f2, callback del binario validado. Log nuevo confirma loaded/guard PASS/installed/invoked/original true. Esto es continuidad del hito, no nueva investigación del hook.

Herramienta preparatoria `tools/player_snapshot.py`: solo O_RDONLY/pread, validación de mappings y tamaños, presupuesto máximo 256 KiB por muestra, rechazo de directorio de salida ya existente. NO es aún resolver Player. Captura A en research/player/PLAYER_SCAN_A_IDLE/: dos muestras separadas por 2 segundos, 166760 bytes por muestra, 8040 de lecturas previas de selección dentro de herramienta. Antes hubo exploración manual adicional de 8040 bytes (slot/Sigma2/tabla). Total leído en esta interacción: 349600 bytes de memoria de juego. Sin attach, writes, dump masivo, inputs ni modificaciones de instalación.

Tabla object y offsets, Sigma2/global y bloque +0x150 permanecen iguales entre las dos muestras. Tabla object contiene punteros a bloques en imagen del juego (no asumir heap); selección/metadata cambia respecto a la exploración inicial en algunas entradas, consistente con mundo activo: no presuponer coherencia atómica. Lecturas específicas registradas con address, size, source, hashes y rechazos en snapshot.json. Se inspeccionaron hasta 0x1000 bytes de cada bloque apuntado distinto y 0x1240 de cada grupo character referenciado <64. No se sigue toda la red de punteros.

Hay triples float estables de magnitud plausible en varios bloques, incluyendo object_0 y character_group_0, pero también otros grupos. Se guardó idle_comparison.json (bytes cambiados y triples filtrados) e idle_double_candidates.json. Filtro heurístico: tres números finitos abs<1e6, ceros permitidos, no subnormales/valores abs<=1e-4 distintos de cero; al menos dos componentes abs>2, bytes iguales en ambas muestras. Float alineación 4, double alineación 8. Esto puede excluir coordenadas reales cercanas al origen o incluir matrices y otros datos; no demuestra representación ni orden XYZ. Ningún campo se declara posición por reposo solamente.

Estado: STATIC CANDIDATE/observaciones de una sesión, NO RUNTIME VERIFIED Player. Relación Sigma2->Player sin demostrar. A es referencia inicial; falta movimiento B, C y reinicio. Próxima acción manual: mover Ryu considerablemente en una dirección, detenerlo, conservar cámara en lo posible, responder RYU MOVIDO. No nuevos commits de hipótesis.

## PLAYER_SCAN_B_MOVED — 2026-09-06T18:35:38.347083-06:00

Usuario confirma RYU MOVIDO. Mismo PID 12404 y starttime que A, base/core/slot activo sin cambios. Dos muestras separadas 2 s, 166760 bytes cada una y 8040 bytes de selección; solo lectura. Captura en research/player/PLAYER_SCAN_B_MOVED/.

Comparación de bloques con mismo label Y dirección; triples float finitos abs<1e6 (sin valores diminutos distintos de cero), estables bit a bit dentro de ambas parejas A y B, al menos dos componentes con delta absoluto>0.1. Produce 117 ventanas solapadas (NO 117 objetos independientes), guardadas AB_candidates.json. No ordena XYZ, no descarta dobles universalmente ni identifica coordenadas autoritativas por sí sola.

Candidato prioritario: registro object[0] en module+0x3195300 apunta a 0x143197100, group byte +0x1f = 0. En el bloque apuntado, +0x2b0 y +0x2e0 (también +0xaf0/+0xb20) contienen el mismo triple que character_group_0+0x310, dirección 0x142f78e20. A=(65.14528656, 5.21999979, -109.88428497); B=(81.99269867, 6.41679859, -92.92471313); delta=(16.84741211, 1.19679880, 16.95957184). Los triples permanecen iguales entre las dos muestras en reposo de cada captura.

La coincidencia de valores entre tablas apoya priorizar este grupo sin asumir previamente índice 0. No demuestra aún Player local, tipo de copia, orden físico de ejes ni selección general entre personajes/arranques. Hay otros bloques con cambios (mundo activo), ventanas de rotación y entradas que pasan de cero a valores no nulos; se conservan sin atribuirlas al jugador. object_0+0x70 mantiene el mismo triple A/B, por tanto pierde prioridad como posición actual. No se necesita barrer heap ni modificar hook.

| Field | Offset | Evidence | Status |
|---|---|---|---|
| Posición triple candidata en object[0] | deref(module+0x3195300)+0x2b0 (float3) | A/B y dos muestras quietas por captura; copias coincidentes | STATIC CANDIDATE, observación runtime parcial |
| Posición triple candidata en character group 0 | module+0x2f78b10+0x310 (float3) | mismos tres valores A/B que object[0] | STATIC CANDIDATE, observación runtime parcial |
| X/Y/Z físicos | sin asignar | falta segundo desplazamiento y cambio de altura | STATIC CANDIDATE |

No RUNTIME VERIFIED hasta C y reinicio. Selección compacta AB_shortlist.json. Sin código core/instalación modificados, sin commit de hipótesis. Siguiente acción manual: desplazamiento en dirección diferente, idealmente terminando en otro nivel de altura, y responder RYU POSICIÓN C.

## PLAYER_SCAN_C — 2026-09-06T18:38:46.218434-06:00

Usuario confirma «RYU POSICIÓN C MAS ALTO». Mismo PID 12404/starttime; core y slot activos, log sin fallo. Dos muestras de 162664 bytes separadas por 2 segundos y 8040 bytes de selección; menos un bloque referenciado que B, reflejando tabla activa. Solo comparar labels/direcciones aún presentes. Ninguna escritura o input.

| Captura | Componente 0 | Componente 1 | Componente 2 | Observación |
|---|---|---|---|---|
| A | 65.14528656 | 5.21999979 | -109.88428497 | reposo inicial |
| B | 81.99269867 | 6.41679859 | -92.92471313 | primer desplazamiento |
| C | 109.80220032 | 7.99999952 | -138.06065369 | dirección diferente y más alto, confirmado usuario |

Candidato object[0].ptr0+0x2b0 coincide exactamente con character[group=0]+0x310 y copias previamente identificadas. Componente 1 aumenta de 6.4168 a 8.0, compatible con altura; componente 2 invierte signo de desplazamiento respecto a A->B. Esto refuerza una representación float3 de posición relacionada con Ryu, sin demostrar todavía eje vertical de forma aislada, orientación de ejes horizontales ni copia autoritativa.

ABC_candidates.json conserva 65 ventanas solapadas que pasan estabilidad exacta en cada pareja y cambios en >=2 componentes A->B y B->C (mismos filtros numéricos); no son 65 objetos ni 65 posiciones independientes. C_targeted_stability.json añade tres lecturas de solo 33 bytes, separadas 1 s, confirmando puntero, group y ambos triples iguales y estables, más tarde que la captura C. Total adicional 99 bytes. No se presentan snapshots discretos como traza continua de trayectoria.

Resolver candidato para reproducir: localizar base por mapping EXE/hash; leer QWORD en base+0x3195300 (entrada 0); leer group en base+0x3195300+0x1f; validar puntero legible y group coherente; float3 en ptr+0x2b0; corroborar con base+0x2f78b10+group*0x1240+0x310. En esta sesión ptr=0x143197100, group=0; dirección del triple object=0x1431973b0 y character=0x142f78e20. Los bloques pertenecen a imagen, no necesariamente heap: no exigir cambio de dirección absoluta tras reinicio, sí resolver de nuevo sin reutilizar el puntero capturado. Elección de entrada 0 solo respaldada para Ryu en esta misión; no generalizar a otros personajes/modos. Sigma2->Player continúa sin cadena directa demostrada.

Estado: candidato fuerte en una sesión, NO RUNTIME VERIFIED todavía. Próximo paso obligatorio: pedir cierre normal, esperar confirmación, verificar terminación; luego pedir otro arranque/misión con Ryu. No pedir reinicio en la misma acción ni asumirlo. Resolver y comparar en nuevo proceso, con movimiento adicional si hace falta para evitar confirmar estado inicial fijo. Rotación e identidad opcionales siguen pendientes; sin core debug hasta resolver reproducible. Sin commit de hipótesis.

## Cierre previo a validación de reinicio — 2026-09-06T18:43:48.304998-06:00

Usuario confirma cierre normal. PID 12404 ausente; ningún proceso NINJA activo encontrado. No se forzó salida ni se inició otro proceso. Evidencia: research/player/restart_shutdown.json. A/B/C permanecen como candidatos de la primera sesión; este cierre NO valida resolver ni XYZ tras reinicio. Siguiente acción manual: iniciar nuevamente desde Steam, entrar a misión controlando a Ryu y quedar quieto. En nueva sesión se descubrirán PID y base otra vez, se leerán puntero/grupo desde la tabla y se compararán las dos representaciones sin reutilizar direcciones absolutas previas.

## MVP 1 CHECKPOINT — pausa solicitada, 2026-09-06

**RESTART VALIDATION — NOT COMPLETED.** No continuar runtime hasta que el usuario reanude. Sesión investigada: PID Linux 12404, terminada normalmente; ausencia comprobada antes de este checkpoint en restart_shutdown.json. No se inició juego ni se hizo investigación adicional al guardar.

### Candidato y método para reproducir

Base observada: 0x140000000. Tabla game_object candidata en module_base+0x3195300, stride legacy 0x30. Entrada 0 contiene puntero 0x143197100 en +0 (también +8/+0x10); group byte +0x1f = 0. Triple float32 contiguo candidato en object_pointer+0x2b0, dirección de ejemplo 0x1431973b0. Offsets provisionales de componentes: +0x2b0/+0x2b4/+0x2b8. NO son todavía ejes físicos XYZ confirmados.

Corroboración: character_candidate = module_base+0x2f78b10+group*0x1240, ejemplo 0x142f78b10. Triple coincidente en +0x310/+0x314/+0x318, dirección 0x142f78e20. Copias adicionales en object+0x2e0/+0xaf0/+0xb20 y character+0xfe0/+0x1010/+0x10e0/+0x1120/+0x1160. No se ha identificado cuál es autoritativa. No hay cadena directa Sigma2->Player demostrada; entrada/group 0 no generalizados a otros personajes o modos. Los bloques observados están en imagen del juego: no asumir heap ni exigir cambio de dirección en otro arranque.

| Snapshot | Componente 0 | Componente 1 | Componente 2 | Evidencia humana |
|---|---|---|---|---|
| PLAYER_SCAN_A_IDLE | 65.14528656 | 5.21999979 | -109.88428497 | RYU QUIETO |
| PLAYER_SCAN_B_MOVED | 81.99269867 | 6.41679859 | -92.92471313 | RYU MOVIDO |
| PLAYER_SCAN_C | 109.80220032 | 7.99999952 | -138.06065369 | RYU POSICIÓN C MAS ALTO |

A->B: delta (16.84741211,1.19679880,16.95957184). B->C cambia de dirección y componente 1 sube a ~8, compatible con altura sin aislamiento de eje. Triples idénticos en dos muestras de cada snapshot separadas 2 s y entre las representaciones object/character. C además tiene tres comprobaciones posteriores separadas 1 s (99 bytes totales), puntero/grupo/triples estables. Son muestras discretas, no traza continua ni medición física independiente. Otros objetos también cambian; 117 ventanas float A/B y 65 A/B/C incluyen ventanas solapadas y no equivalen a objetos únicos.

### Confirmado y pendiente

Confirmado en esta sesión: PID/base, identidad EXE/core, core cargado y hook activo; bytes/valores capturados, coincidencias entre bloques y estabilidad de muestras; usuario realizó dos desplazamientos y terminó más alto; proceso terminó. Hito hook 151ea14 / INGAME_TEST_01 PASS intacto.

**Player resolver, selección del jugador local, XYZ semánticos y layout siguen CANDIDATE.** No se marcan RUNTIME VERIFIED Player/XYZ hasta reproducir tras reinicio. Componente 1 es candidato vertical; yaw/rotación, movimiento e identidad no validados. No existe todavía herramienta final de resolver validado ni integración Player en core.

### Archivos conservados y reproducción

- tools/player_snapshot.py: capturador preparatorio solo O_RDONLY/pread, valida hashes/mappings/slot, límite 256 KiB por muestra, sin escrituras, attach ni inputs. No es resolver Player definitivo. Recibe PID y directorio NUEVO; descubre base/punteros de esa sesión. Para futura captura, después de confirmación humana: `python3 tools/player_snapshot.py <PID_NUEVO> docs/research/player/PLAYER_SCAN_RESTART_IDLE`. No reutilizar PID 12404 ni asumir base/objeto anterior.
- docs/research/player/PLAYER_SCAN_A_IDLE/, PLAYER_SCAN_B_MOVED/, PLAYER_SCAN_C/: binarios de rangos acotados, snapshot.json con direcciones/procedencia/horas/hashes, mappings y core.log. A incluye comparación quieta float y candidatos double.
- docs/research/player/AB_candidates.json, AB_shortlist.json, ABC_candidates.json, C_targeted_stability.json, restart_shutdown.json, rtti_candidates.json. Comparaciones generadas con Python ad hoc y filtros documentados arriba; no existe script independiente de comparación guardado. Los binarios y JSON permiten recalcularlas.
- docs/PLAYER_RESEARCH.md, STATUS.md, RESEARCH.md, OFFSETS.md: método, fuentes legacy, limitaciones y progreso.

Siguiente paso exacto tras reset: leer este checkpoint y comprobar Git; mantener core/hook/instalación intactos. Pedir al usuario iniciar normalmente desde Steam, entrar en misión con Ryu y quedar quieto; esperar «RYU QUIETO TRAS REINICIO». Solo entonces descubrir nuevo PID/base, capturar PLAYER_SCAN_RESTART_IDLE, resolver de nuevo desde tabla estática y corroborar triples/estabilidad. No asumir que ya abrió el juego. Pedir movimiento de confirmación si hace falta, antes de declarar resolver reproducido. No networking, teleport, HP/input/enemigos, Team Missions, cambios de Proton ni push.

## RESTART VALIDATION — COMPLETADA, 2026-09-06 (PID 16942)

Segunda sesión de juego, arranque nuevo desde Steam. Solo lectura (`O_RDONLY`/`pread`), sin attach/escrituras/inputs. Hito hook 151ea14 / INGAME_TEST_01 PASS intacto; no se tocó core/DLL/loader/Proton.

### Proceso y continuidad

| Elemento | Sesión previa | Esta sesión |
|---|---|---|
| PID Linux | 12404 | **16942** (comm `NINJA GAIDEN SI`, TracerPid 0, exe `wine64-preloader`) |
| Module base | 0x140000000 | 0x140000000 (delta ASLR 0) |
| core.dll base | — | 0x6ffff9830000 |
| Slot Sigma2 `base+0x18F9518` | — | → `0x6ffff98316F2` = `core_base + 0x16F2` → **hook validado vivo, PASS** |
| SHA256 EXE / core | a66daf… / ca2849… | idénticos, verificados |

### Resolver ejecutado desde cero

```
root address = module_base + 0x3195300 = 0x143195300   (tabla game_object, stride 0x30)
root value   = u64[root + 0*0x30]       = 0x143197100   (entrada 0; campos +0/+8/+0x10 iguales)
group        = u8[root + 0*0x30 + 0x1F] = 0
object addr  = 0x143197100  ->  RVA 0x3197100
position     = f32x3[object + 0x2B0]                     @ 0x1431973B0
corrobora    = f32x3[module_base + 0x2F78B10 + group*0x1240 + 0x310]  @ 0x142F78E20
```

**`0x143197100` NO es heap.** RVA 0x3197100 cae dentro del cuerpo de imagen del EXE (mapping anón `0x141c4b000-0x146e94000`, dentro de `SizeOfImage` 0x72ce000, región de datos estáticos del EXE). La cadena completa es relativa al módulo. Se redescubrió desde el root estático, no se reutilizó el valor previo; resuelve a la misma RVA porque no hay componente de heap ni ASLR en esta imagen bajo este Proton. El checkpoint anterior lo etiquetó "HEAP de aquella ejecución"; la evidencia lo corrige: es imagen estática, tal como `PLAYER_RESEARCH.md` ya anticipaba ("no asumir heap").

### Lecturas

| Snapshot | C0 | C1 (Y) | C2 | Evidencia humana | Estabilidad |
|---|---|---|---|---|---|
| PLAYER_SCAN_RESTART_IDLE m0 | 70.39479065 | 5.21999979 | -123.64601135 | RYU QUIETO TRAS REINICIO | **NO limpia**: C0/C2 derivan entre m0 y m1 y en probe de 8 lecturas/7 s (C0 59.6→60.4, C2 -94.6→-96.3); Y clavado ~5.2200 |
| PLAYER_SCAN_RESTART_MOVED | 74.63035583 | 5.21999931 | -135.97770691 | RYU MOVIDO TRAS REINICIO | **limpia**: bit-idéntico en 2 muestras snapshot + 8 lecturas probe/7 s en los 3 ejes; object == character exacto en las 10 lecturas |

La deriva de RESTART_IDLE **no** se puede atribuir automáticamente a entrada del usuario: pudo venir de input, gameplay externo, enemigos, knockback, empujón, caída, animación forzada o física del entorno (ver [TEAM_MISSION_RESEARCH.md](TEAM_MISSION_RESEARCH.md), «LOCAL_PLAYER_IDLE ≠ GAME_WORLD_IDLE»). Lo que sí demostró la posición fue la ventana **realmente estable**: cuando Ryu quedó en reposo verificable (RESTART_MOVED, y luego OTHER_MISSION en suelo firme) el triple es bit-estable y ambas representaciones coinciden, reproduciendo el comportamiento de A/B/C. El criterio de estabilidad se formalizó en la Fase 8 como `LOCAL_PLAYER_STABLE`.

Movimiento IDLE(m0) → MOVED: delta (+4.24, ~0, -12.33), magnitud horizontal 13.0, dY≈0 — desplazamiento coherente en una dirección sobre suelo plano. Y de esta sesión (5.2200) coincide con la Y de reposo de la sesión A (5.21999979) a ~4 decimales: mismo plano de suelo / misma zona.

### Criterios de validación (§9 del plan)

| Criterio | Resultado |
|---|---|
| PID diferente | ✅ 16942 ≠ 12404 |
| dirección heap redescubierta | N/A — la cadena es module-relative; el objeto está en la imagen del EXE, no en heap |
| no uso de 0x143197100 | ✅ redescubierto desde el root estático, no reutilizado |
| resolver parte de estado module-relative estable | ✅ `module_base + 0x3195300` |
| objeto encontrado automáticamente | ✅ QWORD de entrada 0 + byte group |
| triple float plausible | ✅ (74.63, 5.22, -135.98), finito, magnitud sana |
| estabilidad con Ryu quieto | ✅ en ventana realmente estable (RESTART_MOVED); la deriva de RESTART_IDLE pudo venir de input, enemigos, knockback, caída o física — no atribuida a una sola causa |
| cambio coherente al desplazarse | ✅ delta unidireccional, Y constante en suelo plano |
| consistente con A/B/C | ✅ misma Y de plano, misma pareja object+0x2B0 / character+0x310, mismos offsets |

### Estado

| Elemento | Estado |
|---|---|
| **Player resolver** (module_base + 0x3195300 → entrada 0 → objeto) | **RUNTIME VERIFIED** — reproducido tras reinicio real, descubrimiento automático, gate de hook OK |
| **Position float3 en object + 0x2B0/+0x2B4/+0x2B8** | **RUNTIME VERIFIED** como float3 ligado a posición: estable en reposo, se mueve con el jugador, corroborado en dos tablas y dos procesos |
| Semántica por eje (cuál es X vs Z, signo/handedness) | **CANDIDATE** — C1 es vertical (confirmado en sesión C); C0/C2 son el plano horizontal, sin asignar individualmente |
| Generalidad (otros personajes, misiones, Team Missions, selección del jugador local) | **CANDIDATE** — solo probado con entrada 0 / group 0 / Ryu en solitario en esta misión |
| Cadena directa Sigma2 → Player | sin demostrar |

Confianza: **MEDIA-ALTA**. Alta para "el resolver relocaliza al jugador y un float3 de posición real sobrevive al reinicio"; media para el etiquetado exacto de ejes y para la generalidad. Matiz honesto: como toda la cadena es module-relative y el delta ASLR fue 0 en ambas sesiones, el reinicio no tuvo que vencer aleatorización de direcciones; lo que sí demostró es que la tabla estática sigue resolviendo, que la entrada 0 sigue correspondiendo a Ryu, que el offset +0x2B0 se mantiene, que los valores están en el régimen esperado y que el hook se re-verifica vivo de forma independiente.

### Herramienta read-only

`tools/player_resolver.py` — descubre el proceso (`comm == "NINJA GAIDEN SI"`) o acepta PID; `O_RDONLY`/`pread`, sin escritura de memoria, attach ni inputs; valida SHA256 de EXE/core y continuidad del slot del hook antes de leer. Imprime PID, module base, Player address y posición (C0 / Y / C2), con corroboración de la tabla character. `--no-strict` omite los gates; `--index N` para otras entradas.

`tools/player_stability_probe.py` — sonda acotada (unos cientos de bytes) que re-lee el triple object y character N veces a intervalo fijo, revalidando base y slot en cada lectura. Evidencia en `docs/research/player/PLAYER_SCAN_RESTART_*/targeted_stability.json`.

### Archivos de evidencia de esta validación

- `docs/research/player/PLAYER_SCAN_RESTART_IDLE/` y `PLAYER_SCAN_RESTART_MOVED/`: snapshots acotados (`player_snapshot.py`, 2 muestras/2 s, <256 KiB/muestra), `snapshot.json`, `mappings.txt`, `core.log`, más `resolver_chain.json` (IDLE) y `targeted_stability.json` (ambos).
- `docs/research/player/restart_validation.json`: consolidado — cadena, lecturas, movimiento, criterios y veredicto.

Cadena de punteros para documentación (representación equivalente, solo la demostrada):

```
module base
  + 0x3195300                          (game_object table RVA; STATIC CANDIDATE -> ahora root del resolver)
    entrada[0] -> puntero              (= module_base + 0x3197100 en esta build; datos estáticos del EXE)
      + 0x2B0 / +0x2B4 / +0x2B8        (float3 posición; RUNTIME VERIFIED como posición, ejes C0/Y/C2)
corrobora: module base + 0x2F78B10 + group*0x1240 + 0x310/+0x314/+0x318
```

Siguiente paso seguro: conservar este hito. Cualquier avance a semántica de ejes exacta, rotación/yaw, identidad del jugador local, o generalización a otros personajes/misiones, es fase posterior y sigue siendo solo lectura hasta nueva autorización. No continuar automáticamente con MVP 2. No networking, teleport, HP/input/enemigos, Team Missions, cambios de Proton ni push.

## FASE 7 — Semántica XYZ + rotación del Player, 2026-09-06 (PID 16942)

Continuación solo-lectura sobre el mismo proceso 16942 (sin reiniciar el juego). Sin escrituras de memoria, teleport, inputs, HP ni hooks nuevos. Hook 151ea14 / INGAME_TEST_01 PASS y `core.dll` intactos. Herramientas nuevas: `tools/player_transform_probe.py` (captura acotada `object+0..0x1000` y `character+0..0x1240`, 2 muestras/2 s, ~17 KiB/run) y `tools/analyze_transform.py` (análisis offline, no toca proceso).

### Estructura del objeto resuelto

`obj+0x2B0` es la cabeza de una **tabla-anillo de historial de posición**, stride 0x30: `+0x2B0` (actual) = `+0x2E0` (copia), `+0x310` (visual/interpolada, retrasa al actual durante el movimiento), `+0x340` / `+0x370` (posiciones anteriores; en OTHER_MISSION contenían literalmente las coords de ~2 min antes). El resolver lee la autoritativa `+0x2B0`. El bloque del objeto no tiene vtable/RTTI/strings en los primeros 0x400 — es datos de transform, no un objeto C++ polimórfico.

### Semántica de ejes — pruebas AXIS_TEST

| Captura | C0 (+0x2B0) | Y (+0x2B4) | C2 (+0x2B8) |
|---|---|---|---|
| AXIS_TEST_ORIGIN | 74.63036 | 5.22000 | -135.97771 |
| AXIS_TEST_A (MOVIMIENTO EJE A) | 65.89988 | 5.22000 | -135.99066 |
| AXIS_TEST_B (MOVIMIENTO EJE B) | 74.63471 | 5.22000 | -134.07336 |

ORIGIN→A: dC0=-8.730, dC2=-0.013 (eje único limpio). A→B retrocedió (~168° respecto a A) y añadió dC2≈+1.9. Los movimientos de caminata no bastan por sí solos para separar X/Z (el personaje encara la dirección de avance). Se resolvió con la rotación (abajo).

### Rotación — RUNTIME VERIFIED

Representación: **matriz de rotación 3×3** (row-major) en **`char+0x80`** = `module_base + 0x2F78B10 + group*0x1240 + 0x80`. Filas: `+0x80` = X local/right, `+0x90` = Y local/up (≈ world +Y constante), `+0xA0` = Z local/forward. Cada fila son 4 floats (xyz + pad 0). Copias en `char+0x100`, `+0x67C`, `+0x1020`, `+0x1040`, `+0x10EC` (slots bind/actual/interpolado/nodos).

Pruebas ROTATION_TEST (giro en el sitio, <1.2 u de desplazamiento):

| | Δyaw vía row0 | Δyaw vía row2 | consistente |
|---|---|---|---|
| A → B | -173.23° | -173.23° | sí |
| B → C | +91.10° | +91.10° | sí |
| A → C | -82.13° | -82.13° | sí |

- `det = +1` en las 6 capturas (rotación propia, sin reflexión); filas ortonormales.
- row0 y row2 dan Δyaw idénticos → giro rígido sobre el eje vertical; row1 ≈ (0,1,0) constante. Coherente en A/B/C.
- Descartados por no cambiar al girar: `char+0x76C` (quat yaw fijo -45.3°, probable orientación de spawn/objetivo) y `obj+0x60/0xB0/0x1B0/0x1D0` (quats del objeto; probable cámara/pose estática).

### Correlación movimiento ↔ rotación → C0 = X, C2 = Z

`row2` (forward) sigue la dirección de caminata dentro de ~3° en tres desplazamientos independientes:

| Movimiento | heading `atan2(dC0,dC2)` | heading de row2 al final | desfase |
|---|---|---|---|
| ORIGIN→A | -90.09° | -87.15° | 2.9° |
| A→B | +77.62° | +79.29° | 1.7° |
| ROT_A→ROT_B | -93.52° | -93.94° | 0.4° |

`row2` y la posición comparten base: componente 0 ↔ C0, componente 2 ↔ C2. `row1` ≈ world +Y. `row0 × row1 = row2` (verificado numéricamente) → tríada right-handed.

**⟹ C0 (+0x2B0) = world X · C1 (+0x2B4) = world Y (arriba) · C2 (+0x2B8) = world Z. Sistema RIGHT-HANDED, Y-up.** Confianza MEDIA-ALTA (desfase ~3° y ausencia de símbolos del motor son la incertidumbre residual; pitch/roll no ejercitados, solo yaw).

### Otra misión — OTHER_MISSION_IDLE

Mismo proceso, misión distinta. Resolver desde cero: **misma raíz** `module_base + 0x3195300`, **misma entrada 0** → `0x143197100`, **mismos offsets** `+0x2B0/+0x2B4/+0x2B8`, **rotación encontrada igual** (`char+0x80`, det +1, ortonormal, `row0×row1 = row2`). Región de mapa distinta (C0≈106.9, Y≈1.20, C2≈-75.5). Con Ryu en suelo firme y mando soltado: posición **bit-idéntica en 12 lecturas / 11 s**. La deriva vista antes era Ryu moviéndose de verdad (no en suelo firme), no un fallo del resolver. `obj+0x2B0` vs `char+0x310`: desfase constante <1e-4 en esta misión (bit-igual en la misión 1); ambos siguen el mismo punto. **El resolver NO es específico del escenario.**

### Identidad del Player

El objeto resuelto **sigue al personaje controlado** (no cámara/proxy/transform visual):
- posición bit-estable en reposo real; se mueve exactamente con la caminata deliberada; ~0 al girar en el sitio;
- `row2` (forward) sigue la dirección de caminata a ~3°;
- Y constante en suelo plano, subió al ir más alto (sesión C);
- cadena de resolver = tablas de gameplay (`is_stationary` / `character.dead` / corpses), no estructuras de render/cámara;
- `obj+0x310` retrasa a `obj+0x2B0` durante el movimiento → `+0x2B0` es la líder/autoritativa, no un proxy visual suavizado.

**No establecido:** que sea específicamente Ryu vs otros personajes jugables (`game_object[0].obj_id = 0`, sin nombre/RTTI; requiere captura multi-personaje). → `CANDIDATE`.

### Tabla de estado (Fase 7)

| Campo | Offset | Representación | Evidencia | Estado |
|---|---|---|---|---|
| Player resolver | `module_base + 0x3195300` → entrada 0 → objeto | tabla game_object + puntero | reinicio + 2ª misión, descubrimiento automático | **RUNTIME VERIFIED** |
| Position C0 | object + 0x2B0 | float32, world X | correlación movimiento↔forward (~3°), base compartida con la matriz | **RUNTIME VERIFIED** (X; MEDIA-ALTA) |
| Position Y | object + 0x2B4 | float32, world Y (arriba) | sesión C (altura) + row1≈+Y + estable en suelo plano | **RUNTIME VERIFIED** |
| Position C2 | object + 0x2B8 | float32, world Z | correlación movimiento↔forward (~3°) | **RUNTIME VERIFIED** (Z; MEDIA-ALTA) |
| Rotation | `char+0x80` (`module_base + 0x2F78B10 + group*0x1240 + 0x80`) | matriz 3×3 row-major (right/up/forward), det +1, right-handed | ROTATION_TEST A/B/C coherentes, det +1, ortonormal, 2ª misión | **RUNTIME VERIFIED** (yaw; pitch/roll sin ejercitar) |
| Coordinate handedness | — | right-handed, Y-up | det +1, `row0×row1=row2`, row1≈+Y | CANDIDATE→FUERTE (MEDIA-ALTA) |
| Character identity | `game_object[0].obj_id` = 0, group 0 | sin id/nombre | sigue al personaje controlado; Ryu específico sin probar | **CANDIDATE** |

`tools/player_resolver.py` ampliado (solo lectura): imprime PID, module base, Player address, Position (C0/X, Y, C2/Z), Rotation (matriz + yaw derivado) y Character (obj_id/group). Sin escritura de memoria.

Evidencia: `docs/research/player/{AXIS_TEST_ORIGIN,AXIS_TEST_A,AXIS_TEST_B,ROTATION_TEST_A,ROTATION_TEST_B,ROTATION_TEST_C,OTHER_MISSION_IDLE}/`, `docs/research/player/transform_characterization.json`.

Siguiente paso seguro: conservar este hito. Pendiente para fase posterior (solo lectura hasta autorización): pitch/roll de la matriz, identidad Ryu-vs-otros con captura multi-personaje, y sólo entonces evaluar MVP 2 (escritura). No continuar automáticamente con MVP 2.

## FASE 8 — pointer: metodología de estabilidad + clasificación de actores

Investigación separada en [TEAM_MISSION_RESEARCH.md](TEAM_MISSION_RESEARCH.md). Resumen:
- **`LOCAL_PLAYER_IDLE` ≠ `GAME_WORLD_IDLE`**. La posición del personaje local puede cambiar sin input (knockback, golpes, caídas, animación forzada, física); en Team Missions el compañero IA actúa aunque el jugador local esté quieto. Una captura IDLE válida ya no exige escenario inmóvil.
- Criterio formal `LOCAL_PLAYER_STABLE` (XYZ de `game_object[0] → object+0x2B0` dentro de tolerancia en N muestras) y `UNSTABLE_LOCAL_PLAYER` (causa no atribuible a una sola fuente). Parámetros: 10 muestras / 0.5 s / tol. horizontal 0.05 u / tol. vertical 0.05 u.
- Las frases previas que atribuían la deriva de RESTART_IDLE a «entrada del usuario» quedan corregidas: pudo venir de input, gameplay externo, enemigos, knockback, caída o física.
- Herramienta `tools/actor_classifier.py` (solo lectura): observa la `game_object` table, calcula `LOCAL_PLAYER_STABLE` y clasifica actores (`LOCAL_PLAYER` / `AI_PARTNER_CANDIDATE` / `ENEMY_CANDIDATE` / `OTHER_ACTOR_CANDIDATE` / `UNKNOWN`); modo `--compare` para A/B/C.

## FASE 8 — resultado (pointer)

Detalle en [TEAM_MISSION_RESEARCH.md](TEAM_MISSION_RESEARCH.md). LOCAL_PLAYER = `game_object[0]` (obj RVA 0x3197100, id 0, grp 0, `char[0]+0x00 = 0x00`), estable en 4 misiones. AI_PARTNER = **STRONG CANDIDATE**: `game_object[4]` / objeto RVA `0x319cdb0`, cross-validado en 2 Team Missions (compañero de Ryu + Ayane); siguió el desplazamiento deliberado de Ryu; layout de objeto idéntico al del jugador. `char[group][4:6] ∈ {9898,c2c2,ffff}` distingue enemigos; `char[group]+0x210 = 4` = derrotado. `obj_id` NO es id de personaje (contador de spawn). Falta reinicio del juego para `RUNTIME VERIFIED` del slot del compañero. `LOCAL_PLAYER_STABLE` (10 muestras / 0.5 s / 0.05 u) funciona con el mundo en movimiento.

## FASE 9 — pointer: actor restart validation

Detalle en [TEAM_MISSION_RESEARCH.md](TEAM_MISSION_RESEARCH.md) §4h. Arranque nuevo (PID 29318). LOCAL_PLAYER RUNTIME VERIFIED re-resuelto por estructura (`game_object[0]` / obj RVA `0x3197100` / `char[group]+0x00 == 0x00` / layout de personaje vivo). AI_PARTNER RUNTIME VERIFIED (rol): `game_object[4]` / obj RVA `0x319cdb0`, 3 Team Missions + reinicio, 2 correlaciones de movimiento post-reinicio. `CONTROL_DISCRIMINATOR_CANDIDATE = char[group]+0x00` (0x00 local vs 0x04). `CHARACTER_ID_CANDIDATE = char[group]+0x16` (baja confianza). PITCH/ROLL NOT VERIFIED. READY FOR MVP 2 CONTROLLED POSITION WRITE: YES — plan en [MVP2_WRITE_PLAN.md](MVP2_WRITE_PLAN.md), no ejecutado.

## MVP 2 — pointer: primera escritura controlada de posición (PARTIAL)

Detalle en [MVP2_WRITE_TEST_01.md](MVP2_WRITE_TEST_01.md). Escritura única y reversible en `object+0x2B0` (LOCAL_PLAYER world X, +0.30 u) con `tools/player_write_test.py` (independiente del core). La escritura entra (readback inmediato = valor escrito) pero el motor la **sobrescribe en < ~150 ms** desde un estado canónico; restauración `EXACT`, sin crash, Y/Z/rotación/AI_PARTNER intactos, usuario no notó movimiento. `object+0x2B0` queda **RUNTIME VERIFIED como lectura** (Fase 7) y **NO escribible de forma persistente**. Falta localizar el estado autoritativo de posición para un teleport real (fase posterior).

## FASE 10 — pointer: posición canónica NO localizada

Detalle en [CANONICAL_POSITION_RESEARCH.md](CANONICAL_POSITION_RESEARCH.md). `object+0x2B0` y ~13 copias más (7 en `object`, 7 en `character[grp]`) son RENDER/OBSERVABLE COPY, escritas cada frame por copia de bloque genérica (RVA 0x8C7B4 etc., hilo «Updating»); `object+0x310` INTERPOLATED; `object+0x340/+0x370` HISTORICAL ring. Sin instrucción dedicada de actualización de posición; la fuente canónica no se aisló con solo lectura. AI_PARTNER tiene la misma arquitectura. Confianza canónica LOW; MVP 2b NO listo. Herramienta `tools/position_sources_probe.py`.

## FASE 11 — pointer: fuente autoritativa de transform localizada (PID 14042, 2026-09-07)

Detalle en [TRANSFORM_SYNC_RESEARCH.md](TRANSFORM_SYNC_RESEARCH.md). Solo lectura: volcado del `.text` inicializado en runtime (`tools/runtime_text_dump.py`), desensamblado offline (`tools/rt_image.py`, capstone), `awatch` de gdb read-only + `detach`, traza temporal (`tools/canonical_trace_probe.py`).

- **Writer real de `object+0x2B0`**: instrucción `0x1353E37` (`movdqa [obj+0x60+0x250], xmm6`), en la rutina per-actor `0x1353D00`. Los RVA `0x8C7B4`/`0xEAD02E` de la Fase 10 **solo leen** `+0x2B0` (mirrors + snapshot-out). Cadena: `0x1462160` (dispatch) → `0x136CBC0` → `0x1354390` (bucle `game_object[0..0xA0]`) → `0x1353D00` → `call 0xF7BB70` → `call 0xF8E420` → `xmm6` → `0x1353E37`.
- **`0xF7BB70` lee `object + 0x4B80`** (posición) y `character[group]+0x10E0` (referencia) para producir el valor de `+0x2B0`.
- **`CANONICAL_POSITION_STRONG_CANDIDATE = object + 0x4B80`** (confianza MEDIA-ALTA). Bloque de estado de movimiento: `+0x4B80` posición · `+0x4BC0` **velocity** (`(0,0,0)` reposo, `(0,0,1.985)` caminando −Z) · `+0x4BD0` centro de cápsula. Se mueve en lockstep con `+0x2B0` (r=1.0) pero aguas arriba en la misma frame. `game_object[4]` (Momiji) tiene el mismo layout. Writer de `+0x4B80` = `0xF8190E` (integra `+0x4BC0` velocity + matriz `+0x1AB0`), identificado estático, no capturado vivo (solo corre en movimiento).
- **MVP 2b**: solo diseñado ([MVP2_WRITE_PLAN.md](MVP2_WRITE_PLAN.md) §MVP 2B), NO ejecutado.

## FASE 12 — pointer: writer de `object+0x4B80` capturado en movimiento (PID 14042, 2026-09-07)

Detalle en [CANONICAL_WRITER_TRACE.md](CANONICAL_WRITER_TRACE.md). Hardware write-watchpoints de solo observación + `detach`; 130 hits en el thread "Updating" (2 movimientos del LOCAL_PLAYER en direcciones distintas + AI_PARTNER Momiji autónomo). Proceso vivo tras la sesión, hook Sigma2 re-verificado.

- **Writer de `object+0x4B80`** — dos rutas, **ninguna `memcpy`**: **W1 `0x141BB90`** = `object+0x4B80 += (movement_vector * scale)` (primitiva leaf con guard NaN), llamada desde `0x14249A0` (update per-actor ≈21 KB) @ `0x1429B92`, dispatcher `0x1420F60` (indexa `game_object`); **W2 `0x14208DD`** = `movdqu [obj+0x4B80], transform_result` (matriz `0x6FDE0`, w=1) — commit de transform (probable snap de suelo/colisión). LOCAL_PLAYER y AI_PARTNER **comparten W1 y W2** (capturados en vivo para ambos).
- `+0x4BC0` velocity: `(0,0,0)` reposo (ambos), rampa con aceleración, reset por frame, dirección coherente; writers en el mismo subsistema (`0xF8190E` escribe posición+velocity juntas). `+0x4BD0` cápsula = `(x, y+~1.05, z, 1)`, se desplaza con `+0x4B80`.
- Los 9 criterios §12 del plan cumplidos ⇒ **`object + 0x4B80` = `CANONICAL_POSITION_RUNTIME_VERIFIED`**, confianza **ALTA**. Caveats: 2 escrituras/frame (W1 integración + W2 commit); input de la matriz de W2 sin descartar que venga de `character[group]`; prueba definitiva = MVP 2B (diseñada, NO ejecutada).


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
