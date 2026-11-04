% ui.pl
% Entrada y salida por consola (unico modulo con E/S); lee el termino del comando y lo pasa al parser de juego.
%
% Aqui y solo aqui se lee y se escribe. Todo lo demas calcula: juego devuelve
% resultado(Items) y este modulo lo convierte en texto (con ayuda de narrador).

:- module(ui, [iniciar/0, bienvenida/0, leer_termino/2, escribir_lineas/1, mostrar/1]).

% La declaracion de modulo va primero; el archivo tiene tildes, asi que se declara UTF-8 justo despues.
:- encoding(utf8).
:- use_module(narrador).

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
mostrar_conocido(salir) :-
    format("Hasta la próxima, Banda Chapuza.~n", []).
mostrar_conocido(fase(_)).

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
