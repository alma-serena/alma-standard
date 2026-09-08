# CHANGELOG — alma-standard

Todo cambio nombra su origen. Un cambio sin origen registrado no entra (SAD-08).

## v0.1.1 — 2026-09-07

Corrección de la **primera certificación externa real**. No añade normativa nueva: cierra
la clase de fallo que ese run reveló, y escribe la regla que la generaliza.

| | Qué | Por qué |
|---|---|---|
| **V-10 · D-C47** | El workflow pasa cada verificador a `bash` —igual que hace el hook—, los cuatro scripts pasan a modo `100755` en el índice, y `METODOLOGIA.md` gana la sección «Los dos niveles invocan igual» | El run `34152938074` sobre el commit `11b6d512` falló con `./verificadores/coherencia.sh: Permission denied` (exit 126). El hook aprobó en verde el mismo árbol: pasaba cada script a `bash`, que ignora el bit, mientras el workflow lo ejecutaba directamente, que lo exige. Sobre Windows con `core.filemode = false` el bit no existe en el sistema de archivos, así que **ninguna comprobación local podía verlo**. El caso incluye a `.githooks/pre-commit`, que tampoco era ejecutable: al clonar en Linux, git lo habría omitido **en silencio** y la prevención local habría desaparecido sin aviso |
| **V-11** | `INSTALACION.md` deja de declararse inedito y gana la seccion «Y el regimen que impone: a `main` no se empuja»; `RAIZ-DE-CONFIANZA.md` gana «La consecuencia que sorprende al dia siguiente» | Configurar la raiz de confianza vuelve `git push origin main` estructuralmente imposible: la comprobacion requerida no ha corrido sobre el commit nuevo y no puede correr, porque corre al empujar. Los dos documentos que llevan a esa configuracion no lo decian, asi que todo proyecto que los siguiera en orden se estrellaria en su segundo commit — nosotros nos estrellamos con la correccion de este mismo CHANGELOG en la mano. Se escribe en los dos: en el instalador porque es quien lo sufre, y en la raiz de confianza porque es quien lo causa |
| **V-12 · D-C48** | El manifest de integridad deja de calcularse y pasa a **publicarse**: lo produce `.github/workflows/manifest.yml` al empujarse un tag, desde `verificadores/manifest.sh`, y se adjunta al release. El arbol del estandar NO lo lleva y `verificadores/coherencia.sh` **falla** si aparece. `alma:upgrade` lo descarga en vez de regenerarlo, y `verificadores/catalogo.sh` **deriva de el** que rutas son andamiaje. El conjunto verbatim se declara una sola vez, en el bloque `verbatim` del paso 1 de `INSTALACION.md` | El registro se contradecia: `INSTALACION.md` decia que `verificadores/coherencia.sh` exige el manifest del estandar, y `ALMA-UPGRADE.md` decia que un checksum calculado contra si mismo no verifica nada. Las dos no podian ser verdad. Un manifest que el proyecto calcula sobre los archivos que se descargo comprueba que coinciden con lo que se descargo, no con lo que el estandar publico: un `alma:upgrade` alterado produce un manifest consistente de archivos alterados. Es la misma linea que ya separaba OPS-07 nivel 1 de nivel 2, aplicada a la integridad. De paso cierra el hueco que `verificadores/catalogo.sh` confesaba en un comentario: su lista blanca de andamiaje estaba escrita de memoria, y al estrenarse olvido dos archivos `[D-C46]` |
| **V-13** | `METODOLOGIA.md` se reordena: la tabla `Situación / Camino` vuelve bajo su encabezado `Caminos infelices`, y las tres secciones de principio —`[D-C47]`, `[D-C46]`, `[D-C41]`— pasan detras de ese bloque. Contenido identico, verificado linea a linea | Al insertarlas en sesiones anteriores quedaron **entre** el encabezado y la tabla que ese encabezado presenta, a 38 lineas de distancia, y ademas mezclaban principios transversales dentro de un bloque sobre excepciones operativas. Se corrige ahora porque ningun proyecto ha instalado todavia `v0.1.0`: es la ultima ventana en que mover texto verbatim cuesta cero atencion humana |
| **V-14** | El paso 4 de `RAIZ-DE-CONFIANZA.md` se reformula por su INTENCION —que ninguna credencial ponga codigo en `main` por su cuenta— con dos formas: restriccion por usuario en organizacion, «Require a pull request before merging» en cuenta personal. Excepcion declarada con sus cuatro campos, y el limite de la compensacion escrito | El paso estaba redactado por su MECANISMO, y ese mecanismo no existe en cuenta personal: la API responde que solo los repos de organizacion admiten restricciones por usuario. Un paso irrealizable se salta y deja de leerse. Al reformularlo aparecio ademas que no era redundante con el paso 1: el SHA de la cabeza de un PR en verde puede empujarse directo a `main`, y la comprobacion requerida se da por cumplida porque literalmente lo esta. El paso 4 cerraba ese atajo, y exigir PR lo cierra igual |

### Lo que este fallo demuestra

Es la primera evidencia empírica de que OPS-07 nivel 2 no es ceremonia. El defecto era
invisible desde dentro del working copy —no por descuido, sino porque el entorno local
carecía del concepto que el externo comprueba— y se manifestó en el primer run fuera del
perímetro del agente, sobre un commit ya empujado. Ninguna cantidad de prevención local
lo habría encontrado.

Queda registrado como el argumento de por qué el nivel 1 **no certifica**, escrito por el
propio estándar contra sí mismo.

---

## v0.1.0 — publicada 2026-09-07 · `11b6d512` · tag `v0.1.0`

Primera redacción de los artefactos normativos, derivada del **Documento Maestro de
Diseño ALMA Dev v0.2.1** (2026-08-13). Es el paso 5 de ALMA-PLAN-01, pendiente desde
entonces.

**Origen:** ejercicio de consolidación del proyecto Alma, decisiones D-C19 a D-C23.

### Decisiones que se apartan de v0.2.1, con su razón

| | Qué | Por qué |
|---|---|---|
| **V-1 · D-C20** | `AGENTS.md` se vacía de identidad, stack y comandos; se mudan a `proyecto-<nombre>.md` | EST-01 los pedía dentro, pero eso hacía imposible copiarlo verbatim y dejaba fuera del manifest el archivo con Prompt Defense. Medido: los dos `AGENTS.md` existentes compartían **cero** líneas |
| **V-2 · D-C21** | Reglas separadas en patrón universal + anexo por stack | v0.2.1 ya había establecido «el estándar fija el patrón, no el stack» y lo aplicó solo a `.agents/rules/frontend.md`. Los otros cuatro dejaban fuera a todo proyecto no-Laravel |
| **V-3 · D-C23 → D-C25** | Workflow nuevo: `.agents/workflows/intervencion.md`, **marcado NO NORMATIVO y fuera de v0.1.0** | v0.2.1 se escribió para un agente por misión. El traspaso entre agentes no existía, y D-C17/D-C18 lo requieren. La evaluación adversarial mostró que el archivo no tenía cuatro defectos sueltos: tenía un prerrequisito ausente. Sin certificación externa (OPS-07 nivel 2), un protocolo de intervención es agentes vigilando agentes. Se rediseñó contra el ataque (RI-1 a RI-4) y se dejó escrito sin fuerza normativa |
| **V-4** | La raíz de confianza se declara y se protege en la plataforma | OPS-07 no decía quién vigila la configuración del CI |
| **V-9 · D-C45, D-C46** | Tercera ronda externa (3 roles, 28 hallazgos, 12 bloqueantes): **se enumera lo permitido, nunca lo prohibido**, y el piso de diez roles pasa a ser condición de salida. Más diez correcciones objetivas | El adversario dijo seis veces la misma frase —«**el hueco se movió**»— sobre seis correcciones distintas de la ronda anterior. Todas habían sustituido un vacío por una **lista cerrada**, y una lista cerrada es un vacío con nombres. Y el rol de **misión real**, que usó el estándar en un proyecto con historia, encontró lo que ninguna lectura ni test sintético encontró: **el estándar no se podía commitear a sí mismo**, y **su barrido de secretos volcaba el secreto al contexto del agente** |
| **V-8 · D-C40…D-C44** | Segunda ronda externa (5 roles, 48 hallazgos, 14 bloqueantes): índice inverso del catálogo, condición de salida para los estados que eximen, `rutas_secretas` cableado, hook desacoplado, y el intérprete de propósito general derivando las cinco clases. Más ocho correcciones objetivas, cinco de ellas defectos de código en los verificadores | El quinto rol —**ejecutar y romper los verificadores**— produjo una clase de hallazgo que ninguna lectura encuentra: **los tres scripts decían «ok» cuando no podían comprobar**. Es el fail-open que el estándar existe para prohibir, dentro del código que lo hace cumplir |
| **V-7 · D-C34…D-C39** | Bloque de seguridad: criterio de reparto entre `AGENTS.md` y `.agents/rules/seguridad.md`, perímetro de salida, secretos unificados con obligación de rotación, mapa de verificabilidad con columna «¿falla cerrado hoy?», identidad del ejecutor, y el barrido de secretos extraído a `verificadores/secretos.sh`. `.agents/rules/seguridad.md` pasa de 46 a 173 líneas | v0.2.1 tenía la seguridad del producto y la del agente escritas en archivos distintos, sin criterio de reparto y sin mencionarse — dos mitades de la misma regla, con dos redacciones. Y el estándar tenía perímetro de **entrada** (Prompt Defense) y ninguno de **salida**, pese a que `M1 §21` de alma-spec ya define un régimen normativo GOV completo que capa 1 nunca referenciaba |
| **V-6 · D-C28…D-C33** | Capa de interfaz: catálogo de componentes obligatorio, maqueta viva, regla de cierre, cuatro reglas sin excepción y un verificador propio. `.agents/rules/diseno.md` pasa de 24 a 175 líneas; se añaden `plantillas/catalogo-EJEMPLO.md` y `verificadores/catalogo.sh` | v0.2.1 exigía «una instantánea versionada de la guía de interfaz» y «nunca improvisar componentes que la guía ya define», **sin obligar a que la guía existiera** — si la guía no define nada, nada se improvisa. Origen del hallazgo: daño medido en un proyecto real (varias versiones de la misma tabla, filtros por pantalla, colores literales en código), no razonamiento abstracto |
| **V-5 · D-C26** | Artefacto nuevo: `INSTALACION.md`, más el paso 0 del orden de lectura | v0.2.1 describe qué es el estándar y qué obliga, y nunca describió cómo se instala. Seis hallazgos de dos evaluadores independientes chocaron con el hueco; el más grave, medido: sin `git config core.hooksPath .githooks` el hook de OPS-07 n1 está presente y no se ejecuta — el archivo existe y no atrapa nada |

### Tercera ronda externa `[D-C45, D-C46]`

**Diez correcciones objetivas.** Cinco de la primera tanda: `H-VER-2`/`H-MIS-8` el
cuerpo del propio `verificadores/secretos.sh` disparaba su propio patrón de firmas y **el
primer commit de la instalación fallaba** — el estándar no se podía commitear a sí mismo
sin `--no-verify` · `H-MIS-4` el barrido volcaba la línea completa del secreto a la
terminal y por tanto al contexto del agente, que es **la superficie 4 de D-C36**: el
verificador de los innegociables incumplía los innegociables · `H-VER-1` `RAIZ_ESTANDAR`
relativa dejaba de apuntar al anexo tras el `cd` y el bloque se saltaba en silencio ·
`H-MIS-1` `git config` respondía `fatal: not in a git directory` y había que inventar
`git init` · `H-ADV-8` la frase «el catálogo sigue bloqueando en el nivel 2», siendo que
ese nivel no existe — **tercera frase mía en la sesión que afirmaba una garantía
inexistente**, corregida con nota, no borrada.

Y cinco de la segunda: `H-MIS-5` el barrido fallaba por un `.env` local **ignorado por
git**, obligando a borrarlo para instalar; ahora mira lo **trackeado** · `H-MIS-9` el
modo `--diff` no decía en qué archivo estaba el hit, con ~100 archivos en el primer
commit · `H-MIS-2` el paso 1 sobrescribía el `AGENTS.md` del proyecto sin respaldo ·
`H-MIS-3` la tabla de instalación exigía verde al catálogo sin que ningún paso lo creara
· `H-MIS-7` `.agents/workflows/instruccion.md` fijaba estructura y ninguna ruta.

| | Decisión |
|---|---|
| **D-C45** | **El piso de diez roles canónicos es condición de salida de `en convergencia`, no puerta de entrada.** En el primer recorrido real, un proyecto con dos componentes falló ocho roles: *«habría que inventar ocho componentes que el producto no usa. Estuve a punto de abandonar ahí»*. Y contradecía a D-C33, que promete catalogar lo que hay. Consecuencia asumida y escrita: **casi todo proyecto real nace `en convergencia`** — el estado honesto de quien adopta a mitad de camino |
| **D-C46** | **Se enumera lo permitido, nunca lo prohibido.** `genesis` deja de depender de trece extensiones y pasa a **lista blanca de andamiaje**: lo que el estándar aportó es andamiaje, todo lo demás es producto. Y donde no se puede enumerar lo permitido —las herramientas, porque cualquier intérprete produce cualquier efecto— **no se enumera: se autoriza**. D-C43 dejaba de derivar por nombres (`bash`, `sh`, `python`, `node`) y pasa a alcance firmado por un humano al abrir la misión. `interfaz: no` deja de presentarse como comprobable: el anexo detecta el caso común y nada más, y así se dice |

**Sobre saturación.** Esta ronda produjo **dos clases nuevas** —la lista cerrada como
defecto sistemático de nuestro propio método de corrección, y «el estándar incumpliéndose
a sí mismo al usarse»—. El eje no está saturado y el rol de misión real se queda.

### Segunda ronda externa `[D-C40 … D-C44]`

**Ocho correcciones objetivas** (errores, no preferencias), cinco de ellas de código:
`H-VER-1` archivo temporal de nombre fijo que colgaba el script · `H-VER-2` el patrón
solo veía nombres en minúscula, así que `API_KEY=…` pasaba en verde · `H-VER-3` `--diff`
fuera de un repo git imprimía «sin fallas» · `H-VER-4`/`H-VER-5` sin anclaje a la raíz,
un proyecto roto se certificaba como génesis desde un subdirectorio · `H-CIS-8`
exclusiones asimétricas entre los dos llamadores · `H-LEC-1` la tabla de instalación
exigía `verificadores/coherencia.sh` en verde, imposible en un proyecto copiado ·
`H-LEC-2` el recuento de «cinco secciones» omitía `interfaz:`.

**Y una corrección de una decisión propia:** D-C39 decía «con CI, un hook inactivo cuesta
velocidad, no seguridad». Es falso como estaba escrito — la corrección está en esa fila,
con su razón, sin borrar la frase original.

| | Decisión |
|---|---|
| **D-C40** | La regla de cierre se comprueba por **índice inverso**: todo archivo bajo una raíz de componentes tiene ficha. La forma anterior se cumplía con una línea en blanco, o escribiendo en una raíz no declarada, o dejándolo al CI —que llama sin `--diff` y nunca corría esa comprobación—. `componentes:` pasa a ser **lista**, y **el anexo del stack declara las raíces conocidas**: si una existe y no está declarada, falla |
| **D-C41** | **Todo estado que exime declara su condición de salida, y es comprobable.** Enunciado una vez en `METODOLOGIA.md` en vez de parcheado por estado. `genesis` falla si hay código de producto; `interfaz: no` falla si existe una raíz conocida — comprobado **antes** de la salida temprana. Uno de los cuatro estados ya cumplía sin que lo dijéramos: `en convergencia`. La regla generaliza el que salió bien |
| **D-C42** | `rutas_secretas` deja de ser capacidad afirmada. El estándar comprueba tres cosas concretas —ninguna ruta declarada trackeada, ninguna ruta secreta conocida del anexo fuera de la lista ni sin ignorar, y el barrido de patrones— y **dice que el resto es del Runtime**. La frase «el agente no las tiene disponibles» se reescribe: era una capacidad que el campo no construía, y dos evaluadores independientes lo vieron |
| **D-C43** | **Un intérprete de propósito general deriva TODAS las clases de efecto.** `bash` no es una herramienta con mapeo acotable: es un entorno. Derivar «ninguna» era la mentira. Rechazada la propuesta del adversario de declarar clases en la misión: reintroduce el campo autodeclarado que `R-054` corrigió |
| **D-C44** | El hook **desacopla la palanca por reversibilidad del daño**: el barrido de secretos bloquea, el catálogo avisa. Un catálogo lento o con deuda enseñaba `--no-verify`, y `--no-verify` apagaba también el único chequeo del archivo sin excepciones. **Corrección (ronda v0.3.0, H-ADV-8):** la primera redacción decía «el catálogo sigue bloqueando en el nivel 2». El nivel 2 **no existe todavía** —`.agents/rules/seguridad.md` lo dice en su propia tabla—, así que en el primer proyecto el catálogo avisa indefinidamente y nadie lo detiene: el bloqueo no se movió al nivel 2, se movió a un piso sin construir. Mientras el nivel 2 no exista, el índice inverso es **detección diferida, no cierre**, y así queda escrito |

**Sobre saturación.** De las siete causas raíz de esta ronda, **una sola es de clase
nueva** —los defectos de ejecución—; las demás son instancias de familias que la primera
ronda ya nombró. Criterio adoptado: *una ronda se repite mientras produzca **clases** de
causa raíz nuevas; cuando solo produce instancias, el eje está saturado y el siguiente
evaluador debe ser de otro tipo.*

### Bloque de seguridad `[D-C34 … D-C39]`

| | Decisión |
|---|---|
| **D-C34** | Reparto **por supervivencia**, no por tema: `AGENTS.md` lleva lo que debe aplicar aunque no se cargue ninguna regla —un agente que rutea mal igual lo lee, es verbatim y primero—; `.agents/rules/seguridad.md` lleva el tratamiento completo en dos mitades declaradas. Rechazado un tercer archivo: repartir en tres lo que ya estaba mal repartido en dos |
| **D-C35** | Perímetro de salida: **toda misión declara qué efectos externos puede producir; sin declaración, ninguno.** Lo que se declara son las **herramientas**; el efecto **se deriva** y nunca se afirma —hereda R-054, que corrige A-02/F-1—. El catálogo cerrado **no se copia**: se delega en `M1 §21` para los proyectos que son Almas. Límite escrito: un hook y un CI ven el diff, no el acto; el perímetro real lo fija lo que se le entrega al agente, y eso es del Runtime |
| **D-C36** | Secretos: **una regla, seis superficies** —log, notificación, mensaje de error, contexto del agente, diff, efecto externo—. Y la colisión que el cruce destapó: `AGENTS.md` prohíbe borrar una línea de un log append-only y este archivo prohíbe un secreto en un log; cuando la segunda se incumple, la primera impide el remedio. Se resuelve con **redacción al anexar** (no en el cierre, que llega tarde) y **rotación obligatoria** cuando ocurre igual. El estándar no decía una palabra sobre rotación |
| **D-C37** | Identidad del ejecutor registrada por misión, más la autoridad bajo la que se ejecutó. Sin ella, «este modelo fue corregido tres veces» es un recuerdo, no un hecho, y OPS-03 y D-C18 se quedan sin sujeto. **No es autenticación** y no se presenta como tal: lo que la hace confiable es el humano que ancló el push. Para Almas se deriva de `C-20`, que es CORE. **Rechazado especificar niveles de acceso**: el dueño dijo que su problema era control de interfaz, no privacidad, y apoyarse en `alma/auth` —capa 5, pre-release— repetiría la inversión de dependencia |
| **D-C38** | El mapa de verificabilidad gana la columna **«¿falla cerrado hoy?»**. Contadas las nueve reglas contra sus cinco filas anteriores, faltaban tres —cubiertas solo por el anexo Laravel— y de las cinco existentes, tres no fallaban cerrado. **Cuenta actual: 9 de 12 filas no fallan cerrado, y ocho apuntan al mismo prerrequisito.** Rechazado degradar a «excepción declarable» las reglas sin verificador: *degradar una norma porque no sabemos comprobarla es dejar que la herramienta decida la norma* |
| **D-C39** | El fail-open de D-C26 **reclasificado**, sin revertir esa decisión: no es un defecto de la instalación, es la consecuencia de que el nivel 2 no exista. `core.hooksPath` no se puede verificar desde el CI —es configuración local del clon— y un archivo marcador sería autodeclaración, rechazada por cuarta vez. El barrido de secretos se extrae a `verificadores/secretos.sh` y lo corren **el hook y el job `certificacion`**. **Corrección (ronda v0.2.0, H-CIS-1):** la primera redacción decía «con CI, un hook inactivo cuesta velocidad, no seguridad». Es falso tal como estaba escrito — el job corre en `push` a `main`, así que cuando barre, el secreto ya está en la rama. La frase solo vale con las **tres** piezas de `RAIZ-DE-CONFIANZA.md` puestas: remoto, `certificacion` como comprobación requerida, y push directo a `main` prohibido. Sin ellas, **el fail-open de D-C26 sigue siendo de seguridad** |

### Bloque de interfaz `[D-C28 … D-C33]`

| | Decisión |
|---|---|
| **D-C28** | El catálogo es **artefacto obligatorio de cada proyecto**; el estándar fija la lista canónica mínima de roles, el contrato de ficha y las reglas; el anexo recomienda la base por stack; el proyecto declara el **origen** de su catálogo. **El estándar no nombra ninguna base concreta** — un paquete compartido es capa 5 y la dependencia debe apuntar hacia abajo, o el primer proyecto Android queda fuera. `alma/ui` nace después, como refactor con dos catálogos delante |
| **D-C29** | Ficha mínima: `rol`, `estado`, `no-usar-cuando`, `excepciones`, más `archivo` como campo mecánico. Lo derivable no se escribe — la maqueta renderiza variantes y estados desde el componente real. El campo `estado` (`vigente` · `en revisión` · `superado por <id>`) existe porque el daño no es solo que nazcan componentes fuera del catálogo: es que convivan tres versiones del mismo |
| **D-C30** | Cuatro reglas **sin excepción** —tokens, un solo `vigente` por rol, la regla de cierre, confirmación destructiva con nombre— y tres con excepción declarable. Criterio explícito: va sin excepción lo que tiene verificador y no cuesta más cumplir que violar. **«Innegociables» queda reservado a `.agents/rules/seguridad.md`** |
| **D-C31** | Maqueta: una fuente, dos representaciones. Ruta viva normativa hoy; publicación estática desde CI **escrita y marcada no exigible** hasta que exista el nivel 2 — la lección de D-C25 aplicada antes de repetir el error |
| **D-C32** | Un verificador, dos llamadores: `verificadores/catalogo.sh` lo invoca el hook local hoy y el job `certificacion` mañana. Seis comprobaciones deterministas y cuatro huecos con nombre; `.agents/rules/diseno.md` deja de declararse «el archivo menos verificable del estándar» |
| **D-C33** | Proyectos con deuda: **congelar y converger.** El catálogo se escribe con lo que hay, la regla de cierre aplica al 100 % para lo nuevo, y la deuda se paga cuando cada pantalla se toca por otra razón. Mientras haya entradas `superado por` con usos vivos el proyecto está **en convergencia** — estado declarado, no suspenso, y medido por el verificador |

**La regla que ordena el bloque, aportada por el dueño:** componente nuevo que no está
en el catálogo entra al catálogo; componente que se actualiza actualiza el catálogo; en
el mismo commit. Su disparo es objetivo —archivos bajo el directorio de componentes
declarado—, y el hueco que deja está escrito: una tabla a mano dentro de una pantalla no
pasa por ese directorio y solo la ve una revisión humana.

### Poda de la ronda externa `[D-C27 · R-7]`

El rol minimalista aportó diez hallazgos, ninguno bloqueante, con una sola tesis
repetida: el estándar guarda ensayo de diseño dentro de archivos que los agentes
cargan. La tesis se acepta y **se aplica con el criterio de carga que el propio
estándar ya declara** en `.agents/rules/README.md` — se poda lo que un agente carga en
cada misión; no se poda lo que lee un humano una vez.

**Aplicado:**

| | Qué |
|---|---|
| H-MIN-6 | La «Nota de diseño, para quien escriba reglas aquí» sale de `AGENTS.md` — el único archivo que se carga en toda misión — y queda registrada abajo |
| H-MIN-1 | El orden de siete pasos se enuncia **una sola vez**, en `.agents/workflows/migracion-estandar.md`. `ALMA-UPGRADE.md` deja de repetirlo y conserva lo suyo: firma, precisiones de los pasos 1, 4 y 5, condiciones de fallo, `--dry-run`, manifest |
| — | `.agents/rules/README.md` tenía **dos** tablas solapadas; queda la operativa («qué escribe la misión → qué regla lee»). El hallazgo no lo nombró |

**Rechazado, con razón:**

| | Por qué no |
|---|---|
| H-MIN-2 · borrar `.agents/rules/anexos/android.md` | El archivo vacío con criterios de llenado es el sitio donde se escribirá la primera regla del stack; una línea en el README no lo es |
| H-MIN-3 · borrar `.agents/rules/README.md` | Se apoya en un hecho falso: «la tabla ya está en AGENTS.md». **No está** — `AGENTS.md` no contiene ninguna tabla de dominios. Borrarlo dejaría al agente sin el criterio de qué regla cargar |
| H-MIN-4 · borrar `.agents/workflows/README.md` | La tabla de `METODOLOGIA.md` va de situación a camino; esta va de workflow a cuándo. Además es donde se declara que `.agents/workflows/intervencion.md` no es normativo |
| H-MIN-5 · borrar «3 · Implementación» | Es la bisagra del ciclo. Sin ella, `METODOLOGIA.md` salta de misión a cierre y el ciclo deja de leerse como ciclo |
| H-MIN-7 · borrar «Pausa y bifurca» de `.agents/rules/paquetes.md` | La regla general y su forma dentro de `packages/` no son la misma frase; se carga solo en misiones de paquete |
| H-MIN-8 · mover el runner autoalojado al CHANGELOG | La razón está pegada a la configuración **a propósito**: es la salida obvia al problema de cuota y la peor. Quien configure la plataforma tiene que tropezar con ella; en el CHANGELOG no la lee |
| H-MIN-9 · mover «qué significa certificado» | `RAIZ-DE-CONFIANZA.md` lo lee un humano una vez, no un agente por misión: no hay coste de contexto que ahorrar, y la distinción es lo que impide llamar certificado a un run local |
| H-MIN-10 · reducir `.agents/workflows/intervencion.md` a ~30 líneas | Superado por D-C25: el archivo pasó a **no normativo** y salió de v0.1.0. Ya no se carga en ninguna misión, y lo que queda es registro de diseño, donde el rationale es el contenido |

### Nota de diseño, para quien escriba reglas del estándar

Movida desde `AGENTS.md` (H-MIN-6). Al redactar una regla, pregúntate **«¿cómo la evade
un optimizador literal?»**, no «¿la cumpliría alguien razonable?». Y recuerda que el
abandono por fricción es un modo de falla tan real como una vulnerabilidad: si cumplir
cuesta más que evadir, la regla está mal diseñada, no el que la evade.

### Pendiente

Se poda cuando algo se cierra. Los dos primeros ítems de esta lista —publicar el repo
con su primer tag, y configurar las comprobaciones requeridas en la plataforma— se
cumplieron el 2026-09-07 y salieron de aquí.

- **`.agents/rules/anexos/android.md` sigue vacío a propósito**, hasta la primera
  misión real que lo necesite. Un anexo escrito sin proyecto que lo use es adivinación.
- **El paso 4 de `RAIZ-DE-CONFIANZA.md` no existe en una cuenta personal de GitHub**
  —restringir quién puede empujar a `main` requiere organización—. Necesita excepción
  declarada con sus cuatro campos, o mudanza a una organización.
- **`v0.1.1` sin anclar.** El tag se crea después del verde de `certificacion` sobre el
  PR, no antes. `v0.1.0` se ancló antes de que ninguna corrida externa hubiera pasado
  nunca, y esa corrida falló.
