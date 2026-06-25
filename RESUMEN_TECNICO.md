# Resumen tecnico del proyecto

## Proyecto

`Aethermoor-Game` es un proyecto Godot 4.6 en 2D. La escena principal configurada es `mundo__valecrest.tscn`, que contiene un mapa con `TileMap`, una instancia del jugador y tres instancias de enemigo.

El gameplay implementado actualmente permite:

- Mover al jugador con WASD.
- Seleccionar enemigos con click izquierdo.
- Atacar al enemigo seleccionado con `ui_accept` (espacio/Enter por defecto).
- Que los enemigos detecten, persigan y ataquen al jugador por distancia.
- Gestionar vida, dano y muerte basica de jugador y enemigos.

## Arquitectura actual

La arquitectura es simple y directa, basada en escenas de Godot y scripts asociados a nodos concretos.

### Escena principal

- `mundo__valecrest.tscn`
  - Nodo raiz: `Node2D` llamado `Mundo- Valecrest`.
  - Contiene un `TileMap` con capas `Suelo` y `Decoracion`.
  - Instancia `jugador.tscn` como nodo `Jugador`.
  - Instancia `enemigo.tscn` tres veces: `Enemigo`, `Enemigo2` y `Enemigo3`.

### Jugador

- Escena: `jugador.tscn`
- Script: `jugador.gd`
- Nodo raiz: `CharacterBody2D`
- Hijos principales:
  - `Sprite2D`
  - `CollisionShape2D`
  - `Camera2D`

Responsabilidades actuales:

- Leer input de movimiento.
- Mover al jugador con `move_and_slide()`.
- Aplicar una animacion procedural simple de salto visual al caminar.
- Guardar el enemigo actualmente seleccionado en `objetivo_actual`.
- Atacar al objetivo si esta vivo y dentro de rango.
- Recibir dano.
- Gestionar muerte del jugador.

### Enemigo

- Escena: `enemigo.tscn`
- Script: `enemigo.gd`
- Nodo raiz: `CharacterBody2D`
- Hijos principales:
  - `Sprite2D`
  - `CollisionShape2D`
  - `ProgressBar`
  - `Timer`

Responsabilidades actuales:

- Inicializar la barra de vida.
- Detectar click izquierdo sobre el enemigo.
- Asignarse como objetivo actual del jugador.
- Recibir dano.
- Morir, ocultar la barra de vida y desactivar la colision.
- Detectar al jugador por distancia.
- Perseguir al jugador.
- Atacar al jugador con cooldown manual.

## Estructura de carpetas y archivos

```text
Aethermoor-Game/
├── Assets/
│   ├── roguelikeChar_transparent.png
│   ├── roguelikeChar_transparent.png.import
│   ├── roguelikeSheet_magenta.png
│   ├── roguelikeSheet_magenta.png.import
│   ├── roguelikeSheet_transparent.png
│   └── roguelikeSheet_transparent.png.import
├── .godot/
│   └── archivos generados/cacheados por Godot
├── .gitattributes
├── .gitignore
├── enemigo.gd
├── enemigo.gd.uid
├── enemigo.tscn
├── icon.svg
├── icon.svg.import
├── jugador.gd
├── jugador.gd.uid
├── jugador.tscn
├── mundo__valecrest.tscn
└── project.godot
```

Notas:

- `.godot/` esta ignorada por Git segun `.gitignore`.
- Los recursos visuales usados por jugador, enemigos y mapa estan en `Assets/`.
- Los scripts y escenas principales estan actualmente en la raiz del proyecto.

## Configuracion del proyecto

Archivo: `project.godot`

- Nombre del proyecto: `Aethermoor-Game`
- Version/caracteristicas: Godot `4.6`, renderer `Forward Plus`
- Escena principal: `mundo__valecrest.tscn`
- Icono: `icon.svg`
- Motor de fisica 3D configurado: `Jolt Physics`
- Driver de render en Windows: `d3d12`

No se detectaron autoloads/singletons configurados.

## Convenciones observadas

Estas convenciones se observan en el estado actual del proyecto:

- Nombres de scripts y escenas en espanol: `jugador`, `enemigo`, `mundo__valecrest`.
- Logica del jugador separada en `jugador.gd`.
- Logica del enemigo separada en `enemigo.gd`.
- Escenas reutilizables para jugador y enemigo.
- El enemigo accede al jugador buscando un nodo llamado exactamente `Jugador` dentro de la escena actual.
- El combate usa referencias directas entre jugador y enemigo.
- Los mensajes de estado se muestran por consola con `print()`.
- El input de movimiento se lee con teclas directas (`KEY_W`, `KEY_A`, `KEY_S`, `KEY_D`).
- El ataque del jugador usa la accion predefinida `ui_accept`.

## Flujo principal del juego

1. Godot carga `mundo__valecrest.tscn` como escena principal.
2. La escena principal crea el mapa, el jugador y tres enemigos.
3. El jugador se mueve usando WASD.
4. Cada enemigo procesa su IA en `_physics_process`.
5. Si el jugador entra en el rango de deteccion de un enemigo, el enemigo se mueve hacia el jugador.
6. Si el enemigo esta en rango de ataque y paso su cooldown, llama a `recibir_dano_jugador()` en el jugador.
7. El jugador puede seleccionar un enemigo haciendo click izquierdo sobre el enemigo.
8. El enemigo seleccionado se guarda en `jugador.objetivo_actual`.
9. Al presionar `ui_accept`, el jugador intenta atacar al objetivo seleccionado.
10. Si el objetivo esta vivo y dentro del rango de ataque, recibe dano.
11. Si la vida del enemigo llega a cero, el enemigo muere, se oscurece, oculta su barra de vida y desactiva su colision.
12. Si la vida del jugador llega a cero, el jugador muere, se oscurece y se detiene su procesamiento fisico.

## Dependencias entre escenas y scripts

### `mundo__valecrest.tscn`

Depende de:

- `jugador.tscn`
- `enemigo.tscn`
- `Assets/roguelikeSheet_transparent.png`
- `Assets/roguelikeSheet_magenta.png`
- `icon.svg`

### `jugador.tscn`

Depende de:

- `jugador.gd`
- `Assets/roguelikeChar_transparent.png`

### `enemigo.tscn`

Depende de:

- `enemigo.gd`
- `Assets/roguelikeChar_transparent.png`

### `jugador.gd`

Depende de que el objetivo actual tenga:

- `esta_muerto`
- `global_position`
- metodo `recibir_dano(cantidad)`

### `enemigo.gd`

Depende de:

- Un nodo llamado `Jugador` en la escena actual.
- Que ese nodo tenga:
  - variable `jugador_muerto`
  - metodo `recibir_dano_jugador(cantidad)`
  - propiedad `global_position`

## Mecanicas implementadas

- Movimiento top-down del jugador.
- Camara asociada al jugador.
- Animacion simple de movimiento mediante desplazamiento vertical del sprite.
- Seleccion de enemigo por click.
- Combate cuerpo a cuerpo por rango.
- Vida del jugador.
- Vida del enemigo con barra visual.
- Muerte del jugador.
- Muerte del enemigo.
- IA simple de persecucion por distancia.
- Ataque enemigo con intervalo aproximado de 1 segundo.
- Feedback visual mediante cambios de `modulate`.

## Observaciones tecnicas

- El proyecto es pequeno y todavia no tiene una capa de arquitectura global.
- No hay autoloads, gestores centrales ni sistemas compartidos.
- No hay clases globales registradas en la cache de Godot.
- No se detectaron grupos de escena configurados.
- El `TileMap` usa capas `Suelo` y `Decoracion`.
- No se detecto configuracion textual de colisiones en el `TileSet` dentro de `mundo__valecrest.tscn`.
- El nodo `Timer` de `enemigo.tscn` existe y tiene `autostart = true`, pero no se observa uso desde `enemigo.gd`.

## Recomendaciones de mejora

Estas recomendaciones salen de la arquitectura actual observada y no describen funcionalidades existentes.

### Reducir acoplamiento por nombre de nodo

Actualmente `enemigo.gd` busca al jugador con:

```gdscript
get_tree().current_scene.get_node("Jugador")
```

Esto depende de que el nodo se llame exactamente `Jugador` y este directamente bajo la escena principal. Se podria mejorar usando grupos, referencias exportadas, senales o una capa de coordinacion.

### Separar seleccion y combate

La seleccion de enemigo esta mezclada con el script del enemigo y modifica directamente `jugador.objetivo_actual`. A futuro podria separarse en un sistema de seleccion o en senales, para evitar dependencias directas entre enemigo y jugador.

### Usar Input Map propio

El movimiento usa teclas directas (`KEY_W`, `KEY_A`, `KEY_S`, `KEY_D`) y el ataque usa `ui_accept`. Conviene definir acciones propias como:

- `move_up`
- `move_down`
- `move_left`
- `move_right`
- `attack`

Esto facilita cambiar controles, agregar gamepad y mantener consistencia.

### Revisar duplicacion en muerte del jugador

`morir_jugador()` contiene operaciones repetidas: asignacion de `jugador_muerto`, `print`, cambio de `modulate` y `set_physics_process(false)`. Conviene limpiar esa duplicacion para evitar errores futuros.

### Revisar el `Timer` del enemigo

`enemigo.tscn` incluye un `Timer` con `autostart`, pero el script usa una variable `tiempo_ultimo_ataque` para el cooldown. Conviene elegir una sola estrategia.

### Agregar UI de estado del jugador

La vida del jugador solo se informa por consola. Si el juego necesita feedback visible, podria agregarse una barra o texto de vida.

### Definir estados de juego

Actualmente la muerte del jugador imprime `Game Over` y detiene el procesamiento fisico del jugador. No hay pantalla de derrota, reinicio ni estado global de partida.

### Organizar carpetas

El proyecto todavia tiene escenas y scripts principales en la raiz. Si crece, podria ordenarse en carpetas como:

```text
scenes/
scripts/
assets/
```

Esto es solo una recomendacion de organizacion; actualmente el proyecto funciona con la estructura presente.

### Evaluar colisiones del mapa

No se detecto configuracion textual de colisiones en el `TileSet`. Si el mapa debe bloquear movimiento, habria que revisar o agregar colisiones en los tiles correspondientes desde Godot.

## Dudas abiertas

- No hay documentacion interna sobre el objetivo final del juego.
- No se puede inferir si el mapa debe ser solo visual o tambien bloquear movimiento.
- No se puede inferir si habra mas tipos de enemigos.
- No se puede inferir si el combate sera melee simple, por turnos, con habilidades o con otro sistema.
- No se puede inferir si el proyecto necesitara menu principal, guardado, inventario, niveles o progresion.

