% main.pl
% Punto de entrada y bucle principal del juego.
%
% Solo lee, delega y muestra: todo lo demas lo hace juego:ejecutar/2.
% No hay :- initialization(main) aqui: cargar este archivo (por ejemplo desde las
% pruebas) no arranca el juego. Se arranca con:
%   swipl -q -s src/main -g main -t halt

:- module(main, [main/0]).
:- use_module(ui).
:- use_module(juego).
:- use_module(estado).

main :-
    ui:iniciar,
    estado:nueva_partida,
    ui:bienvenida,
    juego:ejecutar(mirar, Resultado),
    ui:mostrar(Resultado),
    bucle.

% El bucle es recursivo por la cola: sin repeat/fail y sin acumular elecciones.
bucle :-
    ui:leer_termino(Termino, _),
    juego:validar_comando(Termino, Validacion),
    despachar(Validacion, Seguir),
    (   Seguir == salir -> true ; bucle ).

despachar(error(Motivo), seguir) :-
    ui:mostrar(resultado([error(Motivo)])).
despachar(ok(Comando), Seguir) :-
    juego:ejecutar(Comando, Resultado),
    ui:mostrar(Resultado),
    Resultado = resultado(Items),
    % salir (y el fin de la entrada, que valida como salir) termina SIEMPRE, aunque
    % ejecutar devolviera un error: si no, una entrada agotada repetiria el bucle sin fin.
    (   ( Comando == salir ; memberchk(salir, Items) ) -> Seguir = salir ; Seguir = seguir ).
