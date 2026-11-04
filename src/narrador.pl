% narrador.pl
% Frases del narrador asociadas a reglas y hechos.
%
% Version minima: solo texto claro para los mensajes y los errores de los comandos
% de exploracion. El banco de frases con humor, las variantes y la voz sarcastica
% llegan despues (docs/05-comedia-y-narracion.md). Este modulo solo CONSTRUYE texto:
% no imprime nada (eso es de ui.pl) ni modifica el estado.

:- module(narrador, [texto/4, texto_error/2, ayuda_de/2]).

% La declaracion de modulo va primero; el archivo tiene tildes, asi que se declara UTF-8 justo despues.
:- encoding(utf8).
:- use_module(mundo).

% nombre_de(+Id, -Nombre): nombre visible de un personaje o de una zona (o el propio id).
nombre_de(Id, Nombre) :-
    (   mundo:personaje(Id, N, _, _, _, _, _) -> Nombre = N
    ;   mundo:zona(Id, N)                     -> Nombre = N
    ;   Nombre = Id
    ).

% ---------------------------------------------------------------------------
% texto(+Clave, +Argumentos, +Uso, -Texto): un mensaje que producen los efectos.
% Uso es cuantas veces se ha dicho ya este grupo (servira para rotar variantes).
% ---------------------------------------------------------------------------
texto(llegada, [Zona], _, Texto) :-
    nombre_de(Zona, Nombre),
    format(atom(Texto), 'Llegas a ~w.', [Nombre]).
texto(descanso, [], _,
      'La compañía duerme a pierna suelta, se levanta como nueva y con un poco más de ánimo.').
texto(sin_comida, [Id], _, Texto) :-
    nombre_de(Id, Nombre),
    format(atom(Texto), '~w se acuesta sin cenar.', [Nombre]).
texto(come_rancio, [Id], _, Texto) :-
    nombre_de(Id, Nombre),
    format(atom(Texto), '~w mastica queso rancio con cara de resignación.', [Nombre]).
texto(fin_hambre, [], _,
      'La despensa está vacía y nadie quiere pelear con el estómago vacío: la Banda Chapuza se disuelve. Fin de la partida.').

% ---------------------------------------------------------------------------
% texto_error(+Motivo, -Texto): por que un comando no se pudo ejecutar.
% ---------------------------------------------------------------------------
texto_error(no_puede_viajar(Zona), Texto) :-
    (   mundo:zona(Zona, Nombre)
    ->  format(atom(Texto), 'No puedes ir a ~w desde aquí: no hay camino directo.', [Nombre])
    ;   format(atom(Texto), 'No conozco ningún lugar llamado "~w".', [Zona])
    ).
texto_error(no_puede_descansar, Texto) :-
    mundo:parametro(coste_descanso, Coste),
    format(atom(Texto), 'Descansar cuesta ~w quesos y la despensa no llega.', [Coste]).
texto_error(fuera_de_fase(Cmd, Fase), Texto) :-
    (   Fase == fin
    ->  Texto = 'La partida ha terminado.'
    ;   functor(Cmd, descansar, _)
    ->  Texto = 'Solo se puede descansar en la taberna.'
    ;   format(atom(Texto), 'Ahora mismo no puedes hacer eso (fase: ~w).', [Fase])
    ).
texto_error(no_entiendo(Termino), Texto) :-
    format(atom(Texto), 'No entiendo "~w". Escribe ayuda. para ver los comandos.', [Termino]).
texto_error(falta_argumento(Termino), Texto) :-
    functor(Termino, Nombre, _),
    format(atom(Texto), 'A ~w le falta decir a dónde o a qué; escribe el nombre completo, por ejemplo: ir(aldea).', [Nombre]).
texto_error(sintaxis,
            'Eso no está bien escrito. Recuerda terminar cada comando con un punto, por ejemplo: mirar.').
texto_error(comando_vacio,
            'Escribe un comando (ayuda. te dice cuáles hay).').
texto_error(sin_efecto(Cmd), Texto) :-
    format(atom(Texto), 'No he podido ejecutar ~w.', [Cmd]).
texto_error(interno(Causa), Texto) :-
    format(atom(Texto), 'Algo ha fallado por dentro: ~w', [Causa]).

% ---------------------------------------------------------------------------
% ayuda_de(+NombreDeComando, -Texto): lo que muestra el comando ayuda.
% ---------------------------------------------------------------------------
ayuda_de(ayuda, 'ayuda.         lista los comandos disponibles ahora').
ayuda_de(mirar, 'mirar.         describe dónde estás y a dónde puedes ir').
ayuda_de(ir,    'ir(Zona).      viaja a una zona conectada (cuesta un día)').
ayuda_de(descansar, Texto) :-
    mundo:parametro(coste_descanso, Coste),
    format(atom(Texto),
           'descansar.     solo en la taberna: cuesta ~w quesos, cura a todos y pasa un día', [Coste]).
ayuda_de(salir, 'salir.         termina la partida').
