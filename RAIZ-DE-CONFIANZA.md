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

### Qué configurar en GitHub

En `Settings → Branches → Branch protection rules` sobre `main`:

1. **Require status checks to pass before merging**, y marcar `certificacion` como
   requerida.
2. **Require branches to be up to date before merging.**
3. **Do not allow bypassing the above settings** — incluidos administradores. Poder
   saltárselo «solo esta vez» es la puerta que anula todo lo demás.
4. **Restringir quién puede empujar a `main`.** Ninguna credencial de agente entre
   los autorizados.
5. Y en `Settings → Actions`: **Read-only** para `GITHUB_TOKEN` por defecto.

Un cambio a `.github/workflows/` sigue siendo posible — pero pasa por rama, por CI y
por revisión humana. Deja de ser un commit y pasa a ser un acto.

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
