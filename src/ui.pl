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

% iniciar: texto en UTF-8 (tildes y signos) y el indicador de entrada "> ".
iniciar :-
    set_stream(user_output, encoding(utf8)),
    set_stream(user_input, encoding(utf8)),
    prompt(_, '> ').

bienvenida :-
    escribir_lineas(['',
                     '=== BANDA CHAPUZA ===',
                     'Diriges una compañía de mercenarios incompetentes que cobran en queso.',
                     'Escribe ayuda. para ver los comandos (cada comando termina con un punto).',
                     '']).

% leer_termino(-Termino, -Nombres): lee un termino de la entrada actual.
% Un error de sintaxis no tumba el juego: devuelve '$error_sintaxis'.
leer_termino(Termino, Nombres) :-
    catch(read_term(Termino, [variable_names(Nombres)]),
          error(syntax_error(_), _),
          ( Termino = '$error_sintaxis', Nombres = [] )).

escribir_lineas(Lineas) :-
    forall(member(L, Lineas), format("~w~n", [L])).

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
    format("Día ~w · Queso en la despensa: ~w~n", [Dia, Queso]).
mostrar_conocido(vista(ayuda, Comandos)) :-
    format("Comandos disponibles ahora:~n", []),
    forall(member(Nombre, Comandos),
           (   narrador:ayuda_de(Nombre, Texto)
           ->  format("  ~w~n", [Texto])
           ;   format("  ~w~n", [Nombre])
           )).
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
               format("  [~w] ~w (~w, dificultad ~w): ~w~n", [Estado, Nombre, NombreZona, Dificultad, Premio])
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
mostrar_conocido(vista(prueba, accion_enemigo(E), Prueba)) :-
    narrador:nombre_visible(E, Nombre),
    explicar:prueba_a_lineas(Prueba, Lineas),
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
    narrador:comentario_prueba(Prueba, ambos, 0, Comentario),
    format("Narrador: ~w~n", [Comentario]).
mostrar_conocido(vista(prueba, Accion, Prueba)) :-
    explicar:prueba_a_lineas(Prueba, Lineas),
    format("Por qué se pudo ~w:~n", [Accion]),
    escribir_lineas(Lineas),
    narrador:comentario_prueba(Prueba, ambos, 0, Comentario),
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
