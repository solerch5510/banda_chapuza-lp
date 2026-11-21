% ui.pl
% Entrada y salida por consola (unico modulo con E/S); lee el termino del comando y lo pasa al parser de juego.
%
% Aqui y solo aqui se lee y se escribe. Todo lo demas calcula: juego devuelve
% resultado(Items) y este modulo lo convierte en texto (con ayuda de narrador).

:- module(ui, [iniciar/0, bienvenida/0, leer_termino/2, escribir_lineas/1, mostrar/1]).

% La declaracion de modulo va primero; el archivo tiene tildes, asi que se declara UTF-8 justo despues.
:- encoding(utf8).
:- use_module(narrador).
:- use_module(explicar).
:- use_module(estado).

% nivel_actual(-Nivel): el nivel de explicacion de la sesion (resumido si no se ha pedido otro).
% Es lo unico que ui lee del estado: un ajuste que cambia COMO se muestra, no lo que se muestra.
nivel_actual(Nivel) :-
    (   estado:ajuste(nivel_explicacion, N) -> Nivel = N ; Nivel = resumido ).

% iniciar: texto en UTF-8 (tildes y signos) y el indicador de entrada "> ".
iniciar :-
    set_stream(user_output, encoding(utf8)),
    set_stream(user_input, encoding(utf8)),
    prompt(_, '> ').

bienvenida :-
    narrador:bienvenida(Lineas),
    append([[''], Lineas, ['']], Todas),
    escribir_lineas(Todas).

% leer_termino(-Termino, -Nombres): lee un termino de la entrada actual.
% Un error de sintaxis no tumba el juego: devuelve '$error_sintaxis'.
leer_termino(Termino, Nombres) :-
    catch(read_term(Termino, [variable_names(Nombres)]),
          error(syntax_error(_), _),
          ( Termino = '$error_sintaxis', Nombres = [] )).

escribir_lineas(Lineas) :-
    forall(member(L, Lineas), format("~w~n", [L])).

% escribir_descartes(+Descartes): las reglas de mayor prioridad que no se aplicaron y por que.
escribir_descartes([]).
escribir_descartes(Descartes) :-
    Descartes = [_|_],
    format("Las reglas de más prioridad no se aplicaron:~n", []),
    forall(member(descarte(Prioridad, Nombre, Diag), Descartes),
           (   format("  prioridad ~w (~w):~n", [Prioridad, Nombre]),
               explicar:diag_detalle_a_lineas(Diag, Lineas),
               forall(member(L, Lineas), format("  ~w~n", [L]))
           )).

% mostrar(+Resultado): imprime cada item del resultado. Nunca falla: si un item no se
% conoce, lo muestra tal cual para que el fallo se vea y no se pierda.
mostrar(resultado(Items)) :-
    forall(member(Item, Items), mostrar_item(Item)).

mostrar_item(Item) :-
    (   mostrar_conocido(Item) -> true ; format("[~q]~n", [Item]) ).

mostrar_conocido(msg(Clave, Args, Uso)) :-
    narrador:texto(Clave, Args, Uso, Texto),
    format("~w~n", [Texto]).
mostrar_conocido(error(Motivo)) :-
    narrador:texto_error(Motivo, Texto),
    format("~w~n", [Texto]).
mostrar_conocido(vista(zona, Datos)) :-
    memberchk(nombre(Nombre), Datos),
    memberchk(descripcion(Descripcion), Datos),
    memberchk(salidas(Salidas), Datos),
    memberchk(dia(Dia), Datos),
    memberchk(queso(Queso), Datos),
    format("~n== ~w ==~n~w~n", [Nombre, Descripcion]),
    escribir_salidas(Salidas),
    format("Día ~w · Queso en la despensa: ~w", [Dia, Queso]),
    (   memberchk(racion(R), Datos), memberchk(dias(D), Datos)
    ->  format(" · ración ~w al día (te alcanza para ~w)", [R, D])
    ;   true
    ),
    nl,
    (   memberchk(riesgo(Riesgo), Datos), narrador:texto_riesgo(Riesgo, Aviso)
    ->  format("~w~n", [Aviso])
    ;   true
    ),
    (   memberchk(por_explorar(si), Datos)
    ->  format("Aquí hay algo especial que explorar (explorar.).~n", [])
    ;   true
    ),
    (   memberchk(ayuno(Dias, Max), Datos), Dias > 0
    ->  format("Ayuno: llevas ~w de ~w días seguidos sin comer; al llegar al límite sin nada por cobrar, la partida se pierde.~n", [Dias, Max])
    ;   true
    ),
    (   memberchk(objetivo(Paso, Faltas), Datos), narrador:texto_objetivo(Paso, Faltas, Objetivo)
    ->  format("~w~n", [Objetivo])
    ;   true
    ).
mostrar_conocido(vista(objetivo, Paso, Faltas)) :-
    narrador:texto_objetivo(Paso, Faltas, Texto),
    format("~w~n", [Texto]).
mostrar_conocido(vista(presentes, Presentes)) :-
    (   Presentes == []
    ->  format("Aquí no hay nadie con quien hablar.~n", [])
    ;   format("Aquí hay con quien hablar (hablar(Nombre).):~n", []),
        forall(member(presente(Id, Estado), Presentes),
               (   narrador:nombre_visible(Id, Nombre),
                   narrador:descripcion_personaje(Id, Quien),
                   (   Estado == hecha -> Marca = ' [ya hablado]' ; Estado == abierta -> Marca = ' [a medias]' ; Marca = '' ),
                   format("  ~w: ~w~w~n", [Id, Nombre, Marca]),
                   format("      ~w~n", [Quien])
               ))
    ).
mostrar_conocido(vista(charla, Npc, Opciones)) :-
    forall(member(opcion(N, Opcion, Quien, Disponible), Opciones),
           (   narrador:descripcion_opcion_charla(Npc, Opcion, Texto),
               narrador:nombre_visible(Quien, NombreQuien),
               (   Disponible == si -> Marca = '' ; Marca = ' [no disponible]' ),
               format("  ~w. ~w (~w)~w~n", [N, Texto, NombreQuien, Marca])
           )),
    format("Elige con elegir(Opcion). (el número o el nombre).~n", []).
mostrar_conocido(vista(diario, Marcas)) :-
    (   Marcas == []
    ->  format("El diario está en blanco: todavía no sabéis nada del Gran Rancio. Hablad con la gente (hablar.).~n", [])
    ;   format("El diario de la Banda (lo que sabéis del Gran Rancio):~n", []),
        forall(member(M, Marcas),
               (   narrador:texto_saber(M, Texto), format("  - ~w~n", [Texto]) )),
        (   charlas:hilo_completo
        ->  narrador:texto(diario_completo, [], 0, Cierre), format("~n~w~n", [Cierre])
        ;   true
        )
    ).
mostrar_conocido(vista(comida, Riesgo)) :-
    narrador:texto_riesgo(Riesgo, Texto),
    format("~w~n", [Texto]).
mostrar_conocido(vista(ayuda, Comandos)) :-
    format("Comandos disponibles ahora:~n", []),
    forall(member(Nombre, Comandos),
           (   narrador:ayuda_de(Nombre, Texto)
           ->  format("  ~w~n", [Texto])
           ;   format("  ~w~n", [Nombre])
           )),
    (   narrador:ayuda_de(demo, Demo) -> format("  ~w~n", [Demo]) ; true ),
    (   narrador:consejo_de_ayuda(Comandos, Consejo) -> format("~n~w~n", [Consejo]) ; true ).
mostrar_conocido(vista(escena, _, Titulo, Descripcion, Sugerencias)) :-
    format("~n=== ESCENA: ~w ===~n~w~n", [Titulo, Descripcion]),
    format("Para probar:~n", []),
    forall(member(S, Sugerencias), format("  ~W.~n", [S, [quoted(true), spacing(next_argument)]])).
mostrar_conocido(vista(escenas, Escenas)) :-
    format("Escenas de la demostración (escribe demo(Nombre). para prepararla):~n", []),
    forall(member(Nombre-Titulo, Escenas), format("  demo(~w).   ~w~n", [Nombre, Titulo])).
mostrar_conocido(vista(compania, Filas)) :-
    format("La compañía:~n", []),
    forall(member(miembro(_, Nombre, Rol, Vida, VidaMax, Ataque, Defensa, Moral, Fila, Rasgo, Sueldo, Estado), Filas),
           format("  ~w (~w)  vida ~w/~w  ataque ~w  defensa ~w  moral ~w/10  fila ~w  sueldo ~w  rasgo ~w  [~w]~n",
                  [Nombre, Rol, Vida, VidaMax, Ataque, Defensa, Moral, Fila, Sueldo, Rasgo, Estado])).
mostrar_conocido(vista(inventario, Datos)) :-
    memberchk(dia(Dia), Datos),
    memberchk(total(Total), Datos),
    memberchk(valor(Valor), Datos),
    memberchk(lotes(Lotes), Datos),
    memberchk(objetos(Objetos), Datos),
    format("Despensa (día ~w): ~w quesos (valor informativo: ~w)~n", [Dia, Total, Valor]),
    forall(member(lote(Tipo, Edad, Cant, Categoria), Lotes),
           format("  ~w x~w   edad ~w (~w)~n", [Tipo, Cant, Edad, Categoria])),
    escribir_objetos(Objetos).
mostrar_conocido(vista(evento, E, Quedan, Opciones)) :-
    narrador:descripcion_evento(E, Descripcion),
    format("~w~n", [Descripcion]),
    forall(member(opcion(N, Opcion, Quien, Disponible), Opciones),
           (   narrador:descripcion_opcion(E, Opcion, Texto),
               narrador:nombre_visible(Quien, NombreQuien),
               (   Disponible == si -> Marca = '' ; Marca = ' [no disponible]' ),
               format("  ~w. ~w: ~w (~w)~w~n", [N, Opcion, Texto, NombreQuien, Marca])
           )),
    format("Intentos que quedan: ~w. Elige con elegir(Opcion). (el número o el nombre).~n", [Quedan]).
mostrar_conocido(vista(contratos, Fichas)) :-
    format("El tablón de contratos:~n", []),
    forall(member(contrato(Id, Zona, Dificultad, Recompensa, Estado), Fichas),
           (   narrador:nombre_visible(Id, Nombre),
               narrador:nombre_visible(Zona, NombreZona),
               narrador:texto_recompensa(Recompensa, Premio),
               format("  [~w] ~w (~w, dificultad ~w): ~w~n", [Estado, Nombre, NombreZona, Dificultad, Premio]),
               (   narrador:descripcion_contrato(Id, Descripcion)
               ->  format("      ~w~n", [Descripcion])
               ;   true
               )
           )).
mostrar_conocido(vista(combate, combate(Ronda, Turno, Enemigos))) :-
    narrador:nombre_visible(Turno, QuienJuega),
    format("Combate · ronda ~w · turno de ~w~n", [Ronda, QuienJuega]),
    forall(member(enemigo(E, Vida, Max, Fila), Enemigos),
           (   narrador:nombre_visible(E, Nombre),
               (   Vida =:= 0
               ->  format("  ~w: caído~n", [Nombre])
               ;   format("  ~w: vida ~w/~w (~w)~n", [Nombre, Vida, Max, Fila])
               )
           )).
% La decision de un enemigo (explicar tras su turno): la prueba de la regla que gano, plegada a lo
% esencial, y por que no gano ninguna de mayor prioridad (Descartes, calculado al decidir).
mostrar_conocido(vista(decision, E, Prueba, Descartes)) :-
    narrador:nombre_visible(E, Nombre),
    nivel_actual(Nivel),
    explicar:lineas_de_prueba(Prueba, Nivel, Lineas),
    format("Por qué ~w hizo eso:~n", [Nombre]),
    (   predicate_property(combate:accion_enemigo(_, _), number_of_clauses(Total))
    ->  (   Prueba = regla(accion_enemigo(_, _), Prioridad, _)
        ->  format("Eligió la regla de prioridad ~w de ~w (el corte descartó las demás).~n", [Prioridad, Total])
        ;   Prueba = regla(golpea_a_clotilde(_), _, _)
        ->  format("Lady Clotilde va escoltada: el primero en actuar de cada ronda se ceba con ella.~n", [])
        ;   Prueba = hecho(accion_enemigo(_, _))
        ->  format("Eligió la última regla (prioridad ~w de ~w): el comodín, cuando no hay nada mejor.~n", [Total, Total])
        ;   true
        )
    ;   true
    ),
    escribir_lineas(Lineas),
    escribir_descartes(Descartes),
    narrador:comentario_prueba(Prueba, Nivel, 0, Comentario),
    format("Narrador: ~w~n", [Comentario]).
mostrar_conocido(vista(prueba, Accion, Prueba)) :-
    nivel_actual(Nivel),
    explicar:lineas_de_prueba(Prueba, Nivel, Lineas),
    format("Por qué se pudo ~w:~n", [Accion]),
    escribir_lineas(Lineas),
    narrador:comentarios_de_nodo(Prueba, Nivel, 0, Notas),          % solo en el nivel detallado
    forall(member(Nota, Notas), format("  · ~w~n", [Nota])),
    narrador:comentario_prueba(Prueba, Nivel, 0, Comentario),
    format("Narrador: ~w~n", [Comentario]).
mostrar_conocido(vista(diag, Accion, Diag)) :-
    nivel_actual(Nivel),
    explicar:diag_a_lineas(Diag, Nivel, Lineas),
    format("Por qué no se puede ~w:~n", [Accion]),
    escribir_lineas(Lineas),
    narrador:comentario_diag(Diag, Nivel, 0, Comentario),
    format("Narrador: ~w~n", [Comentario]).
mostrar_conocido(salir) :-
    format("Hasta la próxima, Banda Chapuza.~n", []).
mostrar_conocido(fase(_)).

escribir_objetos([]) :-
    format("Objetos: ninguno~n", []).
escribir_objetos([O|Os]) :-
    findall(Texto,
            (   member(Objeto-Cant, [O|Os]),
                format(atom(Texto), '~w x~w', [Objeto, Cant])
            ),
            Textos),
    atomic_list_concat(Textos, ', ', Unidos),
    format("Objetos: ~w~n", [Unidos]).

escribir_salidas([]) :-
    format("Salidas: ninguna~n", []).
escribir_salidas([S|Ss]) :-
    findall(Texto,
            (   member(Id-Nombre, [S|Ss]),
                format(atom(Texto), '~w (~w)', [Id, Nombre])
            ),
            Textos),
    atomic_list_concat(Textos, ', ', Unidos),
    format("Salidas: ~w~n", [Unidos]).
