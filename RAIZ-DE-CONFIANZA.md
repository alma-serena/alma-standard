# Raíz de confianza — OPS-07 nivel 2

## El problema que este documento resuelve

OPS-07 dice que la única certificación válida es un run de CI **en infraestructura
que el agente no controla**. Pero la configuración de ese CI vive en el repositorio,
y el agente puede commitear en el repositorio.

**Un agente que puede escribir `.github/workflows/` puede debilitar a su propio
certificador.** v0.2.1 no lo aborda.

Y no se arregla metiendo el archivo en el manifest: la comprobación del manifest corre
**dentro** del CI, así que un CI modificado simplemente no la ejecuta. El guardián
guardándose a sí mismo. *(El archivo sí entra al manifest, pero como registro para el
nivel 1, no como protección.)*

## La única barrera realmente externa

**Las comprobaciones requeridas y la protección de rama se configuran en la
plataforma, no en el árbol de archivos.** Ningún commit las altera. Eso mueve la raíz
de confianza fuera del alcance del agente, que es exactamente lo que OPS-07 pide.

Es configuración manual, una vez por repositorio, y **no puede automatizarse desde
dentro del repositorio** — precisamente porque si se pudiera, no serviría.

### Antes de configurar: comprueba que tu combinación lo permite

La protección de rama **no está disponible en todas las combinaciones de plan y
visibilidad**, y donde no lo está no hay compensación parcial: faltan los cinco puntos,
no solo el 4. Compruébalo antes de seguir:

```
gh api repos/<owner>/<repo>/branches/main/protection
```

`Branch not protected` significa que se puede configurar y aún no lo está. Un **403**
significa que la plataforma no lo ofrece aquí.

| combinación | los cinco puntos | cómo lo sabemos |
|---|---|---|
| cuenta personal · repo **público** | **sí**, con el punto 4 en su forma de PR obligatorio | medido — es la configuración de este repositorio |
| cuenta personal · repo **privado** | **no**, ninguno | medido 2026-09-15 — `403: Upgrade to GitHub Pro or make this repository public` |
| organización · público o privado | **sin comprobar** | nadie lo ha medido todavía; las condiciones por plan cambian y no se afirman de memoria |

**Si tu combinación no lo permite, hay cuatro salidas y ninguna es cómoda:** pagar el
plan que lo habilita; hacer el repositorio público; mudarlo a una organización —
comprobando antes, porque una organización gratuita puede tener el mismo límite—; o
**declarar la excepción con sus cuatro campos** y aceptar que ese repositorio no tiene
raíz de confianza.

La cuarta es legítima y el estándar la admite, pero **cámbiale el nombre a lo que pasa**:
la certificación externa sigue corriendo y sigue significando lo que dice, pero nada
obliga a esperarla. El cerrojo pasa a ser una persona, y eso se escribe.

### Qué configurar en GitHub

En `Settings → Branches → Branch protection rules` sobre `main`:

1. **Require status checks to pass before merging**, y marcar `certificacion` como
   requerida.
2. **Require branches to be up to date before merging.**
3. **Do not allow bypassing the above settings** — incluidos administradores. Poder
   saltárselo «solo esta vez» es la puerta que anula todo lo demás.
4. **Que ninguna credencial pueda poner código en `main` por su cuenta.** Tiene dos
   formas según dónde viva el repositorio, y la segunda no es un sucedáneo de la
   primera: cierra el mismo atajo.
   - **Repositorio de organización:** restringir quién puede empujar a `main`, sin
     ninguna credencial de agente entre los autorizados.
   - **Repositorio de cuenta personal:** **Require a pull request before merging.** La
     restricción por usuario no existe aquí —la API responde *Only organization
     repositories can have users and team restrictions*—, pero exigir PR cierra lo que
     esa restricción cerraba. Ver el recuadro.
5. Y en `Settings → Actions`: **Read-only** para `GITHUB_TOKEN` por defecto.

> **Por qué el punto 4 no es redundante con el 1, y qué pasa si falta.**
>
> Parece que con la comprobación requerida ya está: un push a `main` rebota porque el
> check no corrió sobre ese commit. Pero hay un commit para el que **sí corrió**: el de
> la cabeza de un PR abierto. El workflow dispara en `pull_request`, la corrida se
> ancla a ese SHA, y una vez en verde ese SHA puede empujarse **directo a `main`**, sin
> merge y sin mirar el PR. La comprobación requerida se da por cumplida, porque
> literalmente lo está.
>
> Eso es lo que el punto 4 cierra. Sin él, el camino largo tiene un atajo del mismo
> largo, y una barrera que se rodea sin esfuerzo deja de ser una barrera.
>
> **Excepción declarada al punto 4 — repositorios de cuenta personal.**
> · **Qué:** no se puede restringir *quién* empuja a `main`. Ese cerrojo no existe
>   fuera de una organización.
> · **Por qué:** GitHub solo ofrece restricciones por usuario y equipo en repositorios
>   de organización. No es una decisión nuestra ni un paso pendiente.
> · **Qué lo compensa:** «Require a pull request before merging». `main` deja de
>   aceptar *cualquier* push —verde o no—, así que el atajo del párrafo anterior
>   desaparece y el único camino de entrada es el merge de un PR.
> · **Cuándo se revisa:** cuando los repos se muden a una organización, si se mudan.
>
> **Lo que la compensación NO cubre, dicho sin adornos:** el dueño. Con un solo
> participante no hay revisión aprobatoria posible —nadie puede aprobar su propio PR—,
> así que quien tiene la credencial mergea lo que quiera. Es exactamente lo que este
> documento declara más abajo: *ninguna barrera detiene al dueño; el nivel 2 hace la
> trampa más cara que el camino recto*. Pasar de un acto a dos es todo lo que este
> contexto puede lograr, y se registra como tal, no como seguridad.

> **Excepción declarada al punto 5.** El workflow `.github/workflows/manifest.yml`
> pide `contents: write`, porque adjuntar el manifest al release exige escritura.
> · **Qué:** un job con permiso de escritura sobre releases.
> · **Por qué:** el manifest tiene que producirlo alguien que no sea el agente, y ese
>   alguien tiene que poder publicarlo.
> · **Qué lo compensa:** el permiso se declara por job y no por repositorio, el job
>   solo dispara sobre tags, y crear un tag ya pasa por `main`, que está protegido.
> · **Cuándo se revisa:** si alguna vez el job hace algo más que subir ese activo.

Un cambio a `.github/workflows/` sigue siendo posible — pero pasa por rama, por CI y
por revisión humana. Deja de ser un commit y pasa a ser un acto.

### La consecuencia que sorprende al día siguiente

No solo los cambios al workflow. **Ningún** cambio vuelve a entrar por `git push origin
main`, y conviene saberlo antes de chocar con ello:

```
remote: error: GH006: Protected branch update failed for refs/heads/main.
remote: - Required status check "certificacion" is expected.
```

La comprobación requerida no ha corrido sobre el commit nuevo, y no puede correr,
porque corre al empujar. El primer push tras configurar estos cinco pasos es siempre
el que rebota — **incluido el push que corrige el CI**. Nos pasó a nosotros, con la
corrección de `v0.1.1` en la mano.

El camino está previsto: el workflow dispara tambien en `pull_request`, así que el
cambio entra por rama y PR. Lo que no está previsto es desmarcar la comprobación para
pasar «solo esta vez» — eso es el punto 3 de esta misma lista, leído al revés.

Si alguna vez el rebote se vuelve intolerable, la salida honesta no es abrir el
candado: es preguntarse por qué hay tanta prisa por meter algo a `main` sin
certificar.

## Por qué el runner autoalojado está descartado

Es la salida que uno busca primero cuando aparece el problema de cuota: minutos
gratis incluso en repositorios privados, porque la máquina es tuya.

**Y es la peor de las opciones, exactamente por eso.** Si el runner vive en el equipo
donde trabajan los agentes, el certificador está dentro del perímetro de lo
certificado. La separación física que define el nivel 2 desaparece, y lo que queda es
prevención local con otro nombre.

Parece resolver el problema y lo que hace es vaciar la regla. Queda descartado con su
razón escrita, para que no se reproponga dentro de seis meses como solución obvia.

## Lo que «certificado» significa, y lo que no

v0.2.1 ya lo dijo y aquí se aplica en su punto más exacto:

> En un sistema de un solo dueño, el adversario es el **tú-apurado** que controla
> también el CI. Ninguna barrera detiene al dueño. El nivel 2 no defiende contra un
> atacante: **hace la trampa más cara que el camino recto**. Es todo lo que este
> contexto puede lograr, y basta.

Así que **«certificado» significa: un tercero puede reproducir esto sin creerle a
nadie.** No significa que sea imposible falsearlo. Declararlo es lo que impide que
dentro de un año alguien lea la insignia verde y crea que dice más de lo que dice.

## Dónde corre cada CI

| Repo | Dónde | Por qué |
|---|---|---|
| `alma-standard` | GitHub Actions, repo **público** | CI de segundos —checksums y coherencia de markdown—, sin cuota en público; y SAD-05 exige que el estándar sea alcanzable por tag remoto. La publicación ya está autorizada por SAD-00 |
| Repos con suite pesada | por decidir | La cuota de Actions en privado es finita y las suites de Laravel la consumen. Alternativa candidata: el GitLab propio — **pendiente de verificar en qué máquina corre**. Si está en el mismo equipo que los agentes, no sirve como nivel 2 |

> **Comprobado el 2026-09-03: `192.168.1.101` no responde.** Da igual en qué máquina
> corra: un certificador que no está en pie no certifica nada. La opción del GitLab
> propio queda **descartada por disponibilidad**, no por arquitectura — si algún día
> vuelve a estar en línea y se confirma que corre en otra máquina, se puede reabrir.
>
> Mientras tanto, los repos con suite pesada usan Actions con disparo acotado a
> `main`. Una infraestructura que hay que levantar antes de poder certificar tiene el
> mismo problema que el hook local: depende de que alguien se acuerde.
