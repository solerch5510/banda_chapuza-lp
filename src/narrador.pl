% narrador.pl
% Frases del narrador asociadas a reglas y hechos.
%
% Es PURO: construye texto y nada mas. No imprime (eso es de ui.pl), no modifica el
% estado y no usa azar: el texto depende solo de la clave, de los argumentos y de un
% contador de uso que le pasan (cuantas veces se ha narrado ya ese grupo). Asi la misma
% secuencia de comandos produce siempre la misma salida.
%
% Todo el texto visible esta en el banco frase(+Clave, +Nivel, +Plantilla):
%   - Clave: lo que se narra. suceso(Termino) para lo que pasa en el juego,
%     una meta (puede_viajar(Z)) para el comentario de explicar, generica(Tipo) como reserva.
%   - Nivel: resumido, detallado o ambos.
%   - Plantilla: un atomo, o Formato-Args con marcas ~w que se rellenan con las
%     variables de la clave, en orden.
% Las variantes son frases con la misma clave, en el orden en que se escriben: se rota
% entre ellas con Uso mod N. Si varias claves encajan, gana la mas especifica (menos variables).
% Texto provisional: el banco con todo el humor (docs/05-comedia-y-narracion.md) crece despues.

:- module(narrador, [frase/3, texto/4, texto_error/2, ayuda_de/2,
                     comentario/4, comentario_prueba/4, nombre_visible/2]).

% La declaracion de modulo va primero; el archivo tiene tildes, asi que se declara UTF-8 justo despues.
:- encoding(utf8).
:- use_module(mundo).

% frase/3 es un hecho ESTATICO (nadie hace assert sobre el). Es multifile para que las
% pruebas puedan anadir frases de ejemplo sin tocar el banco real.
:- multifile frase/3.
:- discontiguous frase/3.

% ===========================================================================
% El banco de frases
% ===========================================================================

% --- llegada a una zona (V01a a V06 de docs/05): una frase por zona y una general de reserva ---
frase(suceso(llegada(taberna)), ambos,
      'Llegas al Cuajo Torcido. Huele a sopa de ayer y a una promesa de pago que nadie ha visto cumplida.').
frase(suceso(llegada(aldea)), ambos,
      'Aldea Requesón: casitas blancas, leche tibia y vecinos preguntando cuándo se les paga.').
frase(suceso(llegada(bosque)), ambos,
      'El Bosque del Moho te recibe con pelusilla. Hasta la sombra tiene moho; las setas opinan de tu forma de caminar.').
frase(suceso(llegada(camino_real)), ambos,
      'Camino Real: un peaje cada cien pasos, corteza vieja pegada a las suelas y bandidos con más ambición que puntería.').
frase(suceso(llegada(castillo)), ambos,
      'El Castillo Camembert se hunde un poquito cada año, pero los guardias saludan con una rigidez ejemplar.').
frase(suceso(llegada(cuevas)), ambos,
      'Cuevas del Roquefort: aire de sótano, un goteo cada tres segundos y la sensación de que el suelo te mira.').
frase(suceso(llegada(Z)), ambos, 'Llegas a ~w.'-[Z]).

% --- descanso, comida y dinero ---
frase(suceso(descanso), ambos,
      'La Banda duerme en camas que han visto cosas. Recuperan vida y algo de moral, y nadie pregunta por las manchas.').
frase(suceso(sin_comida(P)), ambos,
      '~w no ha comido hoy. El estómago ha presentado una queja formal.'-[P]).
frase(suceso(come_rancio(P)), ambos,
      'A ~w le toca queso rancio en la ración y pierde moral. El estómago olvida; el gusto, no.'-[P]).
frase(suceso(pago(T)), ambos,
      'Sueldos pagados: ~w quesos. Doña Mantecosa asiente; los mercenarios también, y eso es raro.'-[T]).
frase(suceso(impago), ambos,
      'Sales de la taberna sin pagar los sueldos y la compañía no lo olvida: baja la moral.').
frase(suceso(fin_hambre), ambos,
      'La despensa está vacía y nadie quiere pelear con el estómago vacío: la Banda Chapuza se disuelve. Fin de la partida.').

% --- combate: un golpe, una caida y ponerse a la defensiva (X08 a X10 de docs/05, version corta) ---
frase(suceso(golpe(A, B, D)), ambos,
      '~w golpea a ~w y le quita ~w de vida. Cuentas claras, modales mejorables.'-[A, B, D]).
frase(suceso(golpe(A, B, D)), ambos,
      '~w le suelta un golpe a ~w: ~w de vida menos. Ha sido casi técnico.'-[A, B, D]).
frase(suceso(cae(B)), ambos,
      '~w cae redondo. Se levantará luego con 1 de vida y ninguna dignidad.'-[B]).
frase(suceso(aparece(T)), ambos,
      '~w se interpone en tu camino. Nadie ha preguntado si tenía permiso.'-[T]).
frase(suceso(victoria), ambos,
      'Victoria. Nadie la esperaba, y menos que nadie la propia Banda.').
frase(suceso(botin(1)), ambos,
      'Botín: 1 queso fresco. Lo guardaba «para emergencias». Esto lo era.').
frase(suceso(botin(N)), ambos,
      'Botín: ~w quesos frescos. Los guardaban «para emergencias». Esto lo era.'-[N]).
frase(suceso(derrota_combate), ambos,
      'La Banda Chapuza cae entera. Los bardos del futuro lo cantarán mal. Fin de la partida.').
frase(suceso(aturdido(A)), ambos,
      '~w pierde el turno, aturdido de pies a cabeza. Mira las estrellas, que hoy están muy cerca.'-[A]).
frase(suceso(pasa(E)), ambos,
      '~w no sabe qué hacer y se queda mirando. Es su mejor táctica.'-[E]).
frase(suceso(defiende(A)), ambos,
      '~w se pone a la defensiva: escudo arriba, ojos cerrados y una plegaria a medias.'-[A]).

% --- comentario de explicar: la clave es la meta que se ha demostrado ---
frase(puede_viajar(Z), ambos,
      'Hay camino hasta ~w, y tan pegajoso que cuesta un día entero. Ley de la Ruta Pegajosa.'-[Z]).
frase(puede_descansar, ambos,
      'Las camas del Cuajo Torcido aceptan clientes. Han visto cosas y siguen aceptando.').
frase(puede_pagar_sueldos, ambos,
      'Hay queso para todos los sueldos. Que conste en acta, por si alguien lo duda dentro de una semana.').

% --- frases genericas de reserva (G01 a G08): neutras y cortas; si salen mucho, falta cobertura ---
frase(generica(exito),      ambos,     'Todo conforme al reglamento. En esta compañía, eso es una noticia.').
frase(generica(fallo),      ambos,     'No se cumple. El reglamento es así de terco y yo solo leo el acta.').
frase(generica(hecho),      detallado, 'Hecho comprobado. De los pocos que no han discutido con nadie.').
frase(generica(negacion),   detallado, 'No consta nada en contra. Y lo que no consta, no estorba.').
frase(generica(impide),     detallado, 'Algo lo impide, y esta vez está registrado. Eso es raro en esta compañía.').
frase(generica(predefinido),detallado, 'Aritmética pura: aquí nadie discute, ni siquiera el narrador.').
frase(generica(sin_prueba), ambos,     'No hay prueba que mostrar: eso no se puede demostrar. Prueba con por_que_no(...), que se le da mejor.').
frase(generica(sin_fallo),  ambos,     'No falla nada: la acción es perfectamente posible. Prueba con explicar(...) y verás por qué.').
frase(generica(regla),      detallado, 'Regla aplicada. Nadie ha preguntado por los detalles, y yo, de momento, tampoco.').

% ===========================================================================
% Nombres visibles: los de zonas, quesos (y mas adelante enemigos y objetos) llevan su
% articulo; los de personajes, no. Un enemigo e(Tipo, N) se muestra como su tipo.
% ===========================================================================
nombre(taberna,     'la Taberna del Cuajo Torcido').
nombre(aldea,       'la Aldea Requesón').
nombre(bosque,      'el Bosque del Moho').
nombre(camino_real, 'el Camino Real').
nombre(castillo,    'el Castillo Camembert').
nombre(cuevas,      'las Cuevas del Roquefort').
nombre(cheddar,     'el cheddar').
nombre(brie,        'el brie').
nombre(rata_quesera,    'la Rata Quesera').
nombre(bandido_torpe,   'el Bandido Torpe').
nombre(moho_saltarin,   'el Moho Saltarín').
nombre(bandido_montado, 'el Bandido Montado').
nombre(gran_roquefort,  'el Gran Roquefort').

% nombre_visible(+Id, -Texto): los numeros y lo desconocido pasan tal cual.
nombre_visible(Id, Texto) :-
    (   var(Id)
    ->  Texto = Id
    ;   Id = e(Tipo, _)
    ->  nombre_visible(Tipo, Texto)
    ;   nombre(Id, N)
    ->  Texto = N
    ;   atom(Id), mundo:personaje(Id, N, _, _, _, _, _)
    ->  Texto = N
    ;   Texto = Id
    ).

% ===========================================================================
% Seleccion de la frase
% ===========================================================================

% comentario(+Clave, +Nivel, +Uso, -Texto): semidet. Entre las frases que encajan con la clave
% elige las de la clave mas especifica (menos variables) y de ellas la numero Uso mod N.
comentario(Clave, Nivel, Uso, Texto) :-
    findall(NV-T,
            (   frase(K, N, Plantilla),
                nivel_aplica(N, Nivel),
                term_variables(K, Vs), length(Vs, NV),      % se cuentan ANTES de unificar
                casa(K, Clave),
                formatear(Plantilla, T)
            ),
            Ternas),
    Ternas = [_|_],
    keysort(Ternas, [NV0-_|_]),                              % keysort es estable: se conserva el orden
    findall(T, member(NV0-T, Ternas), Textos),
    length(Textos, L),
    I is Uso mod L,
    nth0(I, Textos, Texto).

% Una frase vale para su nivel y para ambos; si se pide ambos, vale cualquiera.
nivel_aplica(Frase, Pedido) :-
    (   Frase == ambos -> true
    ;   Pedido == ambos -> true
    ;   Frase == Pedido
    ).

% casa(+ClaveDeLaFrase, +ClavePedida): unifica, salvo que la frase nombre el TIPO de un
% enemigo (rata_quesera) y lo pedido sea una instancia e(rata_quesera, 1).
casa(C, M) :-
    (   var(C)
    ->  C = M
    ;   atomic(C)
    ->  (   nonvar(M), M = e(T, _) -> C == T ; C == M )
    ;   compound(C), compound(M)
    ->  C =.. [F|As],
        M =.. [F|Bs],
        maplist(casa, As, Bs)
    ).

% formatear(+Plantilla, -Texto): rellena las marcas ~w con los nombres visibles, contrae
% "a el" en "al" y "de el" en "del", y pone la primera letra en mayuscula.
formatear(Plantilla, Texto) :-
    (   nonvar(Plantilla), Plantilla = (Formato-Args)
    ->  maplist(nombre_visible, Args, Visibles),
        format(atom(Crudo), Formato, Visibles),
        contraer(Crudo, Contraido),
        mayuscula_inicial(Contraido, Texto)
    ;   mayuscula_inicial(Plantilla, Texto)
    ).

contraer(Crudo, Texto) :-
    sustituir(Crudo, ' a el ',  ' al ',  T1),
    sustituir(T1,    ' de el ', ' del ', T2),
    sustituir(T2,    'A el ',   'Al ',   T3),
    sustituir(T3,    'De el ',  'Del ',  Texto).

sustituir(Entrada, De, A, Salida) :-
    atomic_list_concat(Partes, De, Entrada),
    atomic_list_concat(Partes, A, Salida).

mayuscula_inicial(T0, T) :-
    sub_atom(T0, 0, 1, _, Primera),
    upcase_atom(Primera, Mayuscula),
    sub_atom(T0, 1, _, 0, Resto),
    atom_concat(Mayuscula, Resto, T).

% ===========================================================================
% Lo que usan los demas modulos
% ===========================================================================

% texto(+Clave, +Argumentos, +Uso, -Texto): un mensaje que producen los efectos
% (mensaje(llegada, [aldea]) se narra con la clave suceso(llegada(aldea))).
texto(Clave, Args, Uso, Texto) :-
    Termino =.. [Clave|Args],
    comentario(suceso(Termino), ambos, Uso, Texto).

% comentario_prueba(+Prueba, +Nivel, +Uso, -Texto): la frase de cierre de una explicacion.
% Es la de la meta raiz; si no la tiene, la de la primera meta de la prueba (en preorden)
% que la tenga; si ninguna, la generica de exito. Siempre hay texto.
comentario_prueba(Prueba, Nivel, Uso, Texto) :-
    (   metas_de_prueba(Prueba, Metas),
        member(Meta, Metas),
        comentario(Meta, Nivel, Uso, T)
    ->  Texto = T
    ;   comentario(generica(exito), Nivel, Uso, Texto)
    ).

% metas_de_prueba(+Prueba, -Metas): las metas de hechos y reglas, en preorden (la raiz primero).
metas_de_prueba(Prueba, Metas) :-
    findall(M, meta_en(Prueba, M), Metas).

meta_en(hecho(G), G).
meta_en(regla(G, _, Hijos), M) :-
    (   M = G
    ;   member(H, Hijos), meta_en(H, M)
    ).
meta_en(izq(P), M)  :- meta_en(P, M).
meta_en(der(P), M)  :- meta_en(P, M).
meta_en((A, B), M)  :- ( meta_en(A, M) ; meta_en(B, M) ).
meta_en(si(PC, PT), M) :- ( meta_en(PC, M) ; meta_en(PT, M) ).
meta_en(sino(PE), M)   :- meta_en(PE, M).

% como_texto(+Termino, -Texto): para repetirle al jugador lo que escribio. Una lista de
% codigos (lo que Prolog 5.10.4 hace con "aldea" entre comillas dobles) se muestra como
% texto y lo muy largo se recorta, para que pegar un parrafo no inunde la consola.
como_texto(Termino, Texto) :-
    (   is_list(Termino), Termino \== [], maplist(integer, Termino),
        catch(atom_codes(Atomo, Termino), _, fail)
    ->  Base = Atomo
    ;   format(atom(Base), '~w', [Termino])
    ),
    atom_length(Base, Largo),
    (   Largo > 60
    ->  sub_atom(Base, 0, 57, _, Corto),
        atom_concat(Corto, '...', Texto)
    ;   Texto = Base
    ).

% con_a(+Nombre, -ConA): el complemento "a ..." con la contraccion: "al Bandido", "a Sir Baldomero".
con_a(Nombre, ConA) :-
    (   atom_concat('el ', Resto, Nombre)
    ->  atom_concat('al ', Resto, ConA)
    ;   atom_concat('a ', Nombre, ConA)
    ).

% ---------------------------------------------------------------------------
% texto_error(+Motivo, -Texto): por que un comando no se pudo ejecutar.
% (Aun fuera del banco: sus variantes llegan con el resto del humor.)
% ---------------------------------------------------------------------------
texto_error(no_puede_viajar(Zona), Texto) :-
    (   mundo:zona(Zona, Nombre)
    ->  format(atom(Texto), 'No puedes ir a ~w desde aquí: no hay camino directo.', [Nombre])
    ;   como_texto(Zona, Dicho),
        format(atom(Texto), 'No conozco ningún lugar llamado "~w".', [Dicho])
    ).
texto_error(no_puede_descansar, Texto) :-
    mundo:parametro(coste_descanso, Coste),
    format(atom(Texto), 'Descansar cuesta ~w quesos y la despensa no llega.', [Coste]).
texto_error(fuera_de_fase(Cmd, Fase), Texto) :-
    (   Fase == fin
    ->  Texto = 'La partida ha terminado.'
    ;   functor(Cmd, descansar, _)
    ->  Texto = 'Solo se puede descansar en la taberna.'
    ;   ( functor(Cmd, atacar, _) ; functor(Cmd, defender, _) )
    ->  Texto = 'Solo se puede atacar o defender en pleno combate.'
    ;   format(atom(Texto), 'Ahora mismo no puedes hacer eso (fase: ~w).', [Fase])
    ).
texto_error(no_entiendo(Termino), Texto) :-
    como_texto(Termino, Dicho),
    format(atom(Texto), 'No entiendo "~w". Escribe ayuda. para ver los comandos.', [Dicho]).
texto_error(grupo_desconocido(Grupo), Texto) :-
    como_texto(Grupo, Dicho),
    format(atom(Texto), 'No conozco a esos enemigos: "~w". Prueba con pelear(rata_quesera).', [Dicho]).
texto_error(no_es_tu_turno, 'Ahora no te toca a ti: espera a tu turno.').
texto_error(no_puede_atacar(Actor, Objetivo), Texto) :-
    nombre_visible(Actor, A),
    nombre_visible(Objetivo, B),
    con_a(B, ConA),
    format(atom(Texto), '~w no puede atacar ~w ahora mismo.', [A, ConA]).
texto_error(no_puede_defender(Actor), Texto) :-
    nombre_visible(Actor, A),
    format(atom(Texto), '~w no puede defenderse ahora mismo.', [A]).
texto_error(objetivo_desconocido(Objetivo), Texto) :-
    como_texto(Objetivo, Dicho),
    format(atom(Texto), 'No hay nada llamado "~w" a lo que atacar.', [Dicho]).
texto_error(nada_que_pagar, 'No debes nada: los sueldos ya están pagados.').
texto_error(no_puede_pagar, 'Los sueldos no se pueden pagar a medias y la despensa no llega.').
texto_error(nada_que_explicar, 'Todavía no has hecho nada que explicar. Prueba con explicar(ir(aldea)).').
texto_error(no_hay_prueba(Accion), Texto) :-
    como_texto(Accion, Dicho),
    format(atom(Texto), 'Ahora mismo no se puede hacer ~w, así que no hay prueba que enseñar.', [Dicho]).
texto_error(no_se_explica(Accion), Texto) :-
    como_texto(Accion, Dicho),
    format(atom(Texto), 'No sé explicar "~w". Puedo explicar ir(Zona), descansar, pagar, atacar(Objetivo) y defender.', [Dicho]).
texto_error(falta_argumento(Termino), Texto) :-
    functor(Termino, Nombre, _),
    format(atom(Texto), 'A ~w le falta decir a dónde o a qué; escribe el nombre completo, por ejemplo: ir(aldea).', [Nombre]).
texto_error(sintaxis,
            'Eso no está bien escrito. Recuerda terminar cada comando con un punto, por ejemplo: mirar.').
texto_error(comando_vacio,
            'Escribe un comando (ayuda. te dice cuáles hay).').
texto_error(sin_efecto(Cmd), Texto) :-
    como_texto(Cmd, Dicho),
    format(atom(Texto), 'No he podido ejecutar ~w.', [Dicho]).
texto_error(interno(Causa), Texto) :-
    como_texto(Causa, Dicho),
    format(atom(Texto), 'Algo ha fallado por dentro: ~w', [Dicho]).

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
ayuda_de(pagar, 'pagar.         solo en la taberna: paga los sueldos pendientes con lo más rancio').
ayuda_de(pelear, 'pelear(Tipo). (provisional) empieza un combate de prueba, p. ej. pelear(rata_quesera)').
ayuda_de(atacar, 'atacar(Objetivo). solo en combate: golpea a un enemigo (un tipo o e(Tipo, N))').
ayuda_de(defender, 'defender.      solo en combate: sube tu defensa hasta tu próximo turno').
ayuda_de(compania,'compania.      muestra a los miembros, su vida, su moral y su estado').
ayuda_de(inventario, 'inventario.    muestra la despensa (con la edad del queso) y los objetos').
ayuda_de(explicar, 'explicar.      la prueba de lo último que hiciste; explicar(Accion). la de esa acción').
ayuda_de(salir, 'salir.         termina la partida').
