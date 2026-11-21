% api.pl
% El adaptador JSON: convierte lo que el juego produce (resultado(Items) y el estado) en terminos JSON para un
% frontend web. Es el gemelo de ui.pl para otro destino: ui escribe TEXTO en la consola, api devuelve DATOS
% (json([...])) y no escribe nada. Como ui, usa narrador para los textos; las reglas siguen sin conocerlo.
%
% Todo es funcion de lo que hay en el estado: no modifica nada (salvo ejecutar_orden/2, que ejecuta una orden como
% la consola y devuelve el resultado ya convertido). Nunca falla: un item que no se conoce sale como "desconocido".
%
% Formato (SWI-Prolog 5.10.4, library(http/json)): objetos json([Clave=Valor, ...]); las cadenas SON ATOMOS (los
% codigos se escribirian como lista de numeros); booleanos @(true)/@(false) y @(null).
%
% El arbol de explicar/por_que_no se entrega como lista PLANA de nodos con profundidad (nodos_de_lineas/2): se
% construye a partir de las mismas lineas que enseña la consola, asi la consola y la web no pueden contar cosas
% distintas. Cada nodo: profundidad, estado (ok|no|info), tipo (hecho, calculo, negacion, regla, corte,
% agregado, condicional, sin_clausula, limite, paso, comentario), texto, marca, clausula, corte, plegados.

:- module(api, [ejecutar_orden/2, resultado_json/2, items_json/2, estado_json/1, acciones_json/1,
                escenas_json/1, nodos_de_lineas/2, texto_de_orden/2, nueva_partida_json/1, fichas_json/1]).
:- encoding(utf8).

:- use_module(narrador).
:- use_module(explicar).
:- use_module(estado).
:- use_module(compania).
:- use_module(economia).
:- use_module(contratos).
:- use_module(mundo).
:- use_module(combate).
:- use_module(juego).
:- use_module(demo).

% ---------------------------------------------------------------------------
% Pequeños ayudantes de texto
% ---------------------------------------------------------------------------

% termino_texto(+Termino, -Atomo): un termino como lo teclearia el jugador.
termino_texto(Termino, Atomo) :-
    format(atom(Atomo), '~W', [Termino, [quoted(true), spacing(next_argument)]]).

mayuscula_inicial(Atomo, Texto) :-
    (   Atomo == ''
    ->  Texto = Atomo
    ;   sub_atom(Atomo, 0, 1, _, Primera),
        sub_atom(Atomo, 1, _, 0, Resto),
        upcase_atom(Primera, Mayuscula),
        atom_concat(Mayuscula, Resto, Texto)
    ).

% bonito(+Id, -Texto): teme_caballos -> 'Teme caballos'.
bonito(Id, Texto) :-
    atomic_list_concat(Palabras, '_', Id),
    atomic_list_concat(Palabras, ' ', Frase),
    mayuscula_inicial(Frase, Texto).

% nombre_corto(+Id, -Texto): el nombre que se ve, sin el articulo ("el Bandido Torpe" -> 'Bandido Torpe').
nombre_corto(Id, Texto) :-
    narrador:nombre_visible(Id, N0),
    (   atom(N0), member(Art, ['el ', 'la ', 'los ', 'las ']), atom_concat(Art, Resto, N0)
    ->  mayuscula_inicial(Resto, Texto)
    ;   Texto = N0
    ).

bool(Cond, B) :- ( Cond -> B = @(true) ; B = @(false) ).
:- meta_predicate bool(0, -).

% ---------------------------------------------------------------------------
% El arbol: de lineas de texto a nodos
% ---------------------------------------------------------------------------

% nodos_de_lineas(+Lineas, -Nodos): una linea de explicar/por_que_no = un nodo json. La profundidad sale
% de la sangria con una pila (una linea es hija de la ultima con MENOS sangria): vale igual para las pruebas
% (3 espacios por nivel) que para los diagnosticos (que mezclan sangrias y los prefijos |- y \-).
nodos_de_lineas(Lineas, Nodos) :-
    nodos(Lineas, [], Nodos).

nodos([], _, []).
nodos([Linea|Resto], Pila0, [Nodo|Nodos]) :-
    once(nodo_de_linea(Linea, Sangria, Estado, Texto, Marcas)),
    once(profundidad(Sangria, Pila0, Prof, Pila)),
    once(nodo_json(Prof, Estado, Texto, Marcas, Nodo)),
    nodos(Resto, Pila, Nodos).

profundidad(Sangria, Pila0, Prof, [Sangria|Pila1]) :-
    descartar_hasta(Sangria, Pila0, Pila1),
    length(Pila1, Prof).

% Se quitan de la pila las sangrias iguales o mayores: lo que queda son los antepasados.
descartar_hasta(_, [], []).
descartar_hasta(S, [T|R], Pila) :-
    (   T >= S
    ->  descartar_hasta(S, R, Pila)
    ;   Pila = [T|R]
    ).

% nodo_de_linea(+Linea, -Sangria, -Estado, -Texto, -Marcas)
nodo_de_linea(Linea, Sangria, Estado, Texto, Marcas) :-
    atom_codes(Linea, Cs0),
    espacios(Cs0, 0, Sangria, Cs1),
    quitar_prefijo(Cs1, Cs2),
    estado_y_resto(Cs2, Estado, Cs3),
    atom_codes(Cuerpo, Cs3),
    (   atomic_list_concat([T0|Ms0], '   ', Cuerpo)
    ->  Texto = T0, maplist(sin_corchetes, Ms0, Marcas)
    ;   Texto = Cuerpo, Marcas = []
    ).

espacios([32|R], N0, N, Resto) :- !, N1 is N0 + 1, espacios(R, N1, N, Resto).
espacios(Cs, N, N, Cs).

quitar_prefijo([124, 45, 32|R], R) :- !.
quitar_prefijo([92, 45, 32|R], R) :- !.
quitar_prefijo(Cs, Cs).

estado_y_resto(Cs, ok, R) :- append("[ok] ", R, Cs), !.
estado_y_resto(Cs, no, R) :- append("[no] ", R, Cs), !.
estado_y_resto(Cs, info, Cs).

sin_corchetes(M, Interior) :-
    (   atom_concat('[', R, M), atom_concat(Interior, ']', R) -> true ; Interior = M ).

% nodo_json(+Prof, +Estado, +Texto, +Marcas, -Json)
nodo_json(Prof, Estado, Texto, Marcas, json([profundidad=Prof, estado=Estado, tipo=Tipo, texto=Texto, legible=Legible,
                                              marca=Marca, clausula=Clausula, corte=Corte, plegados=Plegados])) :-
    legible(Texto, Legible),
    partir_marcas(Marcas, Plegados, Otras),
    (   Otras = [Marca|_] -> true ; Marca = '' ),
    tipo_de_nodo(Estado, Texto, Marca, Tipo),
    clausula_de(Marca, Clausula),
    (   sub_atom(Marca, _, _, _, '+ corte') -> Corte = @(true) ; Corte = @(false) ).

% La marca "+N nodos" o "+1 nodo" es el pliegue del nivel resumido; las demas describen el nodo.
partir_marcas([], 0, []).
partir_marcas([M|Ms], Plegados, Otras) :-
    partir_marcas(Ms, P0, O0),
    (   atom_concat('+', R, M), atomic_list_concat([N|_], ' ', R), atom_number(N, K)
    ->  Plegados is P0 + K, Otras = O0
    ;   Plegados = P0, Otras = [M|O0]
    ).

tipo_de_nodo(Estado, Texto, Marca, Tipo) :-
    (   Marca == hecho                              -> Tipo = hecho
    ;   Marca == builtin                            -> Tipo = calculo
    ;   Marca == falso                              -> Tipo = calculo
    ;   Marca == 'no demostrable'                   -> Tipo = negacion
    ;   atom_concat(clausula, _, Marca)             -> Tipo = regla
    ;   atom_concat('corte', _, Marca)              -> Tipo = corte
    ;   atom_concat(findall, _, Marca)              -> Tipo = agregado
    ;   atom_concat(forall, _, Marca)               -> Tipo = agregado
    ;   atom_concat(rama, _, Marca)                 -> Tipo = condicional
    ;   atom_concat('no hay ningun', _, Marca)      -> Tipo = sin_clausula
    ;   atom_concat('se agoto', _, Marca)           -> Tipo = limite
    ;   Marca \== '', sub_atom(Marca, 0, 1, _, D), char_type(D, digit(_)) -> Tipo = regla
    ;   Estado == info                              -> Tipo = comentario
    ;   atom_concat('\\+', _, Texto)                -> Tipo = negacion
    ;   Tipo = paso
    ).

clausula_de(Marca, N) :-
    (   atom_concat('clausula ', R, Marca), atomic_list_concat([K|_], ' ', R), atom_number(K, N0) -> N = N0
    ;   N = @(null)
    ).

% ---------------------------------------------------------------------------
% Los items de un resultado
% ---------------------------------------------------------------------------

resultado_json(resultado(Items), json([items=Js])) :-
    items_json(Items, Js).

items_json(Items, Js) :-
    maplist(item_json, Items, Js).

% item_json(+Item, -Json): nunca falla; lo que no se conoce sale como "desconocido".
item_json(Item, Json) :-
    (   catch(item(Item, J), _, fail)
    ->  Json = J
    ;   termino_texto(Item, T),
        Json = json([tipo=desconocido, texto=T])
    ).

nivel_actual(Nivel) :-
    (   estado:ajuste(nivel_explicacion, N) -> Nivel = N ; Nivel = resumido ).

item(msg(Clave, Args, Uso), json([tipo=msg, clave=C, texto=Texto])) :-
    narrador:texto(Clave, Args, Uso, Texto),
    termino_texto(Clave, C).
item(error(Motivo), json([tipo=error, motivo=M, texto=Texto, por_que_no=Accion])) :-
    narrador:texto_error(Motivo, Texto),
    ( compound(Motivo) -> functor(Motivo, M, _) ; M = Motivo ),
    (   error_de_accion(Motivo, A) -> termino_texto(A, Accion) ; Accion = @(null) ).
item(salir, json([tipo=salir])).
item(fase(F), json([tipo=fase, fase=F])).
item(vista(zona, Datos), Json) :- zona_json(Datos, Json).
item(vista(comida, Riesgo), json([tipo=aviso_comida, riesgo=Riesgo, texto=Texto])) :-
    narrador:texto_riesgo(Riesgo, Texto).
item(vista(objetivo, Paso, Faltas), json([tipo=objetivo, paso=P, faltas=Fs, texto=Texto])) :-
    narrador:texto_objetivo(Paso, Faltas, Texto),
    termino_texto(Paso, P),
    maplist(termino_texto, Faltas, Fs).
item(vista(ayuda, Comandos), json([tipo=ayuda, comandos=Js, consejo=Consejo])) :-
    findall(json([nombre=N, texto=T]),
            ( member(N, Comandos), ( narrador:ayuda_de(N, T) -> true ; T = N ) ),
            Js),
    (   narrador:consejo_de_ayuda(Comandos, C) -> Consejo = C ; Consejo = @(null) ).
item(vista(escena, Nombre, Titulo, Descripcion, Sugerencias),
     json([tipo=escena, nombre=Nombre, titulo=Titulo, descripcion=Descripcion, sugerencias=Ss])) :-
    maplist(termino_texto, Sugerencias, Ss).
item(vista(escenas, _), json([tipo=escenas, escenas=Js])) :-
    escenas_json(Js).
item(vista(compania, Filas), json([tipo=compania, miembros=Js])) :-
    maplist(miembro_json, Filas, Js).
item(vista(inventario, Datos), json([tipo=inventario, despensa=Js])) :-
    despensa_json(Datos, Js).
item(vista(contratos, Fichas), json([tipo=contratos, contratos=Js])) :-
    maplist(contrato_json, Fichas, Js).
item(vista(combate, Datos), Json) :- combate_json(Datos, Json).
item(vista(evento, E, Quedan, Opciones), json([tipo=evento, descripcion=D, opciones=Os, quedan=Quedan])) :-
    narrador:descripcion_evento(E, D),
    findall(json([numero=N, nombre=Op, texto=T, quien=Q, disponible=Disp]),
            (   member(opcion(N, Op, Quien, Si), Opciones),
                narrador:descripcion_opcion(E, Op, T),
                nombre_corto(Quien, Q),
                bool(Si == si, Disp)
            ),
            Os).
item(vista(prueba, Accion, Prueba),
     json([tipo=prueba, accion=A, nivel=Nivel, nodos=Nodos, narrador=Comentario, notas=Notas])) :-
    nivel_actual(Nivel),
    termino_texto(Accion, A),
    explicar:lineas_de_prueba(Prueba, Nivel, Lineas),
    nodos_de_lineas(Lineas, Nodos),
    ( narrador:comentarios_de_nodo(Prueba, Nivel, 0, Notas) -> true ; Notas = [] ),
    narrador:comentario_prueba(Prueba, Nivel, 0, Comentario).
item(vista(diag, Accion, Diag),
     json([tipo=diag, accion=A, nivel=Nivel, nodos=Nodos, porque=Porque, porque_legible=PorqueL, narrador=Comentario])) :-
    nivel_actual(Nivel),
    termino_texto(Accion, A),
    explicar:diag_a_lineas(Diag, Nivel, Lineas),
    nodos_de_lineas(Lineas, Nodos),
    (   member(json(Campos), Nodos),
        memberchk(tipo=comentario, Campos),
        memberchk(texto=T, Campos),
        atom_concat(porque, _, T)
    ->  mayuscula_inicial(T, Porque), legible(Porque, PorqueL)
    ;   Porque = @(null), PorqueL = @(null)
    ),
    narrador:comentario_diag(Diag, Nivel, 0, Comentario).
item(vista(decision, E, Prueba, Descartes),
     json([tipo=decision, enemigo=Nombre, nivel=Nivel, regla=Regla, accion=Accion, nodos=Nodos,
           descartes=Ds, narrador=Comentario])) :-
    nivel_actual(Nivel),
    nombre_corto(E, Nombre),
    explicar:lineas_de_prueba(Prueba, Nivel, Lineas),
    nodos_de_lineas(Lineas, Nodos),
    regla_ganadora(Prueba, Regla),
    accion_elegida(Prueba, Accion),
    maplist(descarte_json(Nivel), Descartes, Ds),
    narrador:comentario_prueba(Prueba, Nivel, 0, Comentario).

% Los errores de una accion VALIDA que no se pudo hacer: ahi tiene sentido "ver por que no".
error_de_accion(no_puede_viajar(Z), ir(Z)).
error_de_accion(no_puede_descansar, descansar).
error_de_accion(no_puede_pagar, pagar).
error_de_accion(no_puede_aceptar(C), aceptar(C)).
error_de_accion(no_puede_atacar(A, O), atacar(A, O)).
error_de_accion(no_puede_defender(_), defender).

% regla_ganadora(+Prueba, -Json): como en la consola (ui.pl): prioridad de la regla y cuantas hay.
regla_ganadora(Prueba, json([tipo=Tipo, prioridad=Prioridad, total=Total])) :-
    (   predicate_property(combate:accion_enemigo(_, _), number_of_clauses(T)) -> Total = T ; Total = 0 ),
    (   Prueba = regla(accion_enemigo(_, _), P, _)
    ->  Tipo = corte, Prioridad = P
    ;   Prueba = regla(golpea_a_clotilde(_), _, _)
    ->  Tipo = escolta, Prioridad = @(null)
    ;   Prueba = hecho(accion_enemigo(_, _))
    ->  Tipo = comodin, Prioridad = Total
    ;   Tipo = otra, Prioridad = @(null)
    ).

accion_elegida(Prueba, Json) :-
    (   explicar:meta_de_prueba(Prueba, accion_enemigo(_, Accion))
    ->  accion_legible(Accion, Texto),
        termino_texto(Accion, Crudo),
        Json = json([texto=Texto, termino=Crudo])
    ;   Json = @(null)
    ).

% accion_legible(+Accion, -Texto): atacar(tuerca) -> 'Atacar a Tuerca'; embestir -> 'Embestir'.
accion_legible(Accion, Texto) :-
    (   Accion = atacar(B)
    ->  nombre_corto(B, N), format(atom(T0), 'atacar a ~w', [N]), mayuscula_inicial(T0, Texto)
    ;   compound(Accion)
    ->  Accion =.. [F|Args],
        atomic_list_concat(Ps, '_', F), atomic_list_concat(Ps, ' ', Fb),
        maplist(nombre_corto, Args, Ns), atomic_list_concat(Ns, ', ', Lista),
        format(atom(T0), '~w (~w)', [Fb, Lista]), mayuscula_inicial(T0, Texto)
    ;   bonito(Accion, Texto)
    ).

descarte_json(Nivel, descarte(Prioridad, Nombre, Diag),
              json([prioridad=Prioridad, nombre=Nombre, titulo=Titulo, motivo=Motivo, motivo_legible=MotivoL, nodos=Nodos,
                    comentario=Comentario])) :-
    bonito(Nombre, Titulo),
    explicar:diag_detalle_a_lineas(Diag, Lineas),
    nodos_de_lineas(Lineas, Nodos),
    motivo_corto(Nodos, Motivo),
    legible(Motivo, MotivoL),
    narrador:comentario_diag(Diag, Nivel, 0, Comentario).

% legible(+Texto, -Legible): las instancias de enemigo e(Tipo, N) como las ve el jugador. e(bandido_torpe, 1) -> "Bandido Torpe";
% la segunda del mismo tipo, "Bandido Torpe #2". El texto original no se toca (la consola lo enseña tal cual):
% la web usa este campo para mostrar y el otro como pista.
legible(Texto, Legible) :-
    atom_codes(Texto, Cs),
    once(legibles(Cs, 32, Out)),
    atom_codes(Legible, Out).

legibles([], _, []).
legibles(Cs, Prev, Out) :-
    \+ char_de_nombre(Prev),
    Cs = [0'e, 0'(|R0],
    span(R0, char_de_nombre, TipoCs, [0',|R1]), TipoCs \== [],
    span(R1, espacio, _, R2),
    span(R2, es_digito, NumCs, [0')|Resto]), NumCs \== [],
    !,
    atom_codes(Tipo, TipoCs), number_codes(K, NumCs),
    nombre_corto(Tipo, Nombre),
    (   K > 1 -> format(atom(Rep), '~w #~w', [Nombre, K]) ; Rep = Nombre ),
    atom_codes(Rep, RepCs),
    append(RepCs, Out1, Out),
    legibles(Resto, 41, Out1).
legibles([C|Cs], _, [C|Out]) :-
    legibles(Cs, C, Out).

char_de_nombre(C) :- ( code_type(C, alnum) ; C == 95 ), !.
espacio(32).
es_digito(C) :- code_type(C, digit).

span([C|R], P, [C|S], Rest) :- call(P, C), !, span(R, P, S, Rest).
span(R, _, [], R).

% motivo_corto(+Nodos, -Texto): la ultima linea del diagnostico es la mas concreta ("12*100=<12*30 es falso").
motivo_corto(Nodos, Texto) :-
    (   last(Nodos, json(Campos)), memberchk(texto=Texto0, Campos) -> Texto = Texto0 ; Texto = '' ).

% ---------------------------------------------------------------------------
% Piezas del estado
% ---------------------------------------------------------------------------

zona_json(Datos, json([tipo=zona, id=Id, nombre=Nombre, descripcion=Descripcion, salidas=Salidas,
                       dia=Dia, queso=Queso])) :-
    memberchk(nombre(Nombre), Datos),
    memberchk(descripcion(Descripcion), Datos),
    memberchk(dia(Dia), Datos),
    memberchk(queso(Queso), Datos),
    memberchk(salidas(Ss), Datos),
    ( estado:en_zona(Id0) -> Id = Id0 ; Id = @(null) ),
    findall(json([id=S, nombre=N]), member(S-N, Ss), Salidas).

miembro_json(miembro(Id, Nombre, Rol, Vida, VidaMax, Ataque, Defensa, Moral, Fila, Rasgo, Sueldo, Estado),
             json([id=Id, nombre=Nombre, rol=Rol, vida=Vida, vida_max=VidaMax, ataque=Ataque,
                   defensa=Defensa, moral=Moral, moral_max=10, fila=Fila, rasgo=Rasgo, rasgo_texto=RT,
                   sueldo=Sueldo, estado=Estado])) :-
    bonito(Rasgo, RT).

despensa_json(Datos, json([dia=Dia, total=Total, valor=Valor, categorias=json(Cats), lotes=Lotes, objetos=Objetos])) :-
    memberchk(dia(Dia), Datos),
    memberchk(total(Total), Datos),
    memberchk(valor(Valor), Datos),
    memberchk(lotes(Ls), Datos),
    memberchk(objetos(Os), Datos),
    findall(json([tipo=Tipo, edad=Edad, cantidad=Cant, categoria=Cat]), member(lote(Tipo, Edad, Cant, Cat), Ls), Lotes),
    findall(Cat=N,
            (   member(Cat, [fresco, curado, rancio]),
                findall(C, member(lote(_, _, C, Cat), Ls), Cs),
                sumlist(Cs, N)
            ),
            Cats),
    findall(json([id=O, nombre=NombreO, cantidad=C]),
            ( member(O-C, Os), nombre_corto(O, NombreO) ),
            Objetos).

contrato_json(contrato(Id, Zona, Dificultad, Recompensa, Estado),
              json([id=Id, nombre=Nombre, zona=Zona, zona_nombre=NZ, dificultad=Dificultad,
                    recompensa=Premio, estado=Estado, descripcion=Descripcion])) :-
    narrador:nombre_visible(Id, Nombre),
    ( mundo:zona(Zona, NZ) -> true ; NZ = Zona ),
    narrador:texto_recompensa(Recompensa, Premio),
    (   narrador:descripcion_contrato(Id, D) -> Descripcion = D ; Descripcion = '' ).

combate_json(combate(Ronda, Turno, Enemigos),
             json([tipo=combate, ronda=Ronda, turno=json([id=Turno, nombre=NT]), enemigos=Es, orden=Orden])) :-
    nombre_corto(Turno, NT),
    findall(json([id=Ide, nombre=N, tipo_enemigo=Tipo, vida=V, vida_max=Max, fila=Fila, caido=Caido]),
            (   member(enemigo(E, V, Max, Fila), Enemigos),
                nombre_corto(E, N),
                ( E = e(Tipo, _) -> true ; Tipo = E ),
                termino_texto(E, Ide),
                bool(V =:= 0, Caido)
            ),
            Es),
    (   estado:cola_turnos(Cola)
    ->  findall(json([id=Q, nombre=NQ, enemigo=EQ]),
                ( member(Q0, Cola), termino_texto(Q0, Q), nombre_corto(Q0, NQ), bool(Q0 = e(_, _), EQ) ),
                Orden)
    ;   Orden = []
    ).

% ---------------------------------------------------------------------------
% El estado completo (lo que pinta el frontend entre orden y orden)
% ---------------------------------------------------------------------------

estado_json(json([fase=Fase, dia=Dia, nivel=Nivel, zona=Zona, mapa=Mapa, banda=Banda, despensa=Despensa, comida=Comida,
                  objetivo=Objetivo, contratos=Contratos, combate=Combate, fin=Fin, acciones=Acciones])) :-
    ( once(estado:fase(Fase)) -> true ; Fase = desconocida ),
    ( once(estado:dia(Dia)) -> true ; Dia = 0 ),
    nivel_actual(Nivel),
    juego:datos_de_zona(DZ),
    zona_json(DZ, Zona),
    mapa_json(Mapa),
    compania:informe(Filas),
    maplist(miembro_json, Filas, Banda),
    economia:inventario(DI),
    despensa_json(DI, Despensa),
    comida_json(Comida),
    objetivo_json(DZ, Objetivo),
    findall(F, ( contratos:contrato(C, _, _, _, _), contratos:ficha(C, F) ), Fichas),
    maplist(contrato_json, Fichas, Contratos),
    (   estado:en_combate(_), juego:datos_de_combate(DC)
    ->  combate_json(DC, Combate)
    ;   Combate = @(null)
    ),
    (   estado:fin_partida(Motivo) -> termino_texto(Motivo, MT), Fin = json([motivo=MT]) ; Fin = @(null) ),
    acciones_json(Acciones).

% objetivo_json(+DatosDeZona, -Json): el objetivo actual en texto, con el paso y lo que falta para el contrato final.
objetivo_json(DZ, Json) :-
    (   memberchk(objetivo(Paso, Faltas), DZ)
    ->  narrador:texto_objetivo(Paso, Faltas, Texto),
        termino_texto(Paso, P),
        maplist(termino_texto, Faltas, Fs),
        Json = json([texto=Texto, paso=P, faltas=Fs])
    ;   Json = @(null)
    ).

% comida_json(-Json): cuanto queso hay, lo que come la Banda al dia, para cuantos dias llega y el aviso si esta justa.
comida_json(json([queso=Queso, racion=Racion, dias=Dias, riesgo=Riesgo, aviso=Aviso, ayuno=Ayuno, ayuno_max=AyunoMax])) :-
    economia:queso_total(Queso),
    economia:dias_de_ayuno(Ayuno),
    mundo:parametro(dias_de_ayuno_max, AyunoMax),
    economia:racion_diaria(Racion),
    economia:dias_de_comida(Dias),
    economia:riesgo_de_gasto(0, Riesgo),
    (   narrador:texto_riesgo(Riesgo, T) -> Aviso = T ; Aviso = @(null) ).

mapa_json(json([zonas=Zonas, conexiones=Conex])) :-
    findall(json([id=Id, nombre=N]), mundo:zona(Id, N), Zonas),
    findall([A, B], mundo:conexion(A, B), Conex).

% ---------------------------------------------------------------------------
% Acciones: que se puede hacer ahora y, si no, por que no
% ---------------------------------------------------------------------------

acciones_json(Acciones) :-
    (   once(estado:fase(Fase)) -> true ; Fase = fin ),
    findall(J,
            (   candidata(Fase, Cmd, Familia),
                accion_json(Fase, Cmd, Familia, J)
            ),
            Acciones).

% candidata(+Fase, -Comando, -Familia): los comandos que el frontend ofrece como botones.
candidata(Fase, Cmd, Familia) :-
    Fase \== fin,
    (   member(Cmd, [mirar, inventario, compania]), Familia = Cmd
    ;   Fase \== combate,
        (   Cmd = contratos, Familia = contratos
        ;   Cmd = pagar, Familia = pagar
        ;   Cmd = descansar, Familia = descansar
        ;   mundo:zona(Z, _), once(estado:en_zona(Aqui)), mundo:adyacente(Aqui, Z), Cmd = ir(Z), Familia = ir
        )
    ;   Fase == combate,
        (   Cmd = defender, Familia = defender
        ;   enemigos_vivos(Tipos), member(T, Tipos), Cmd = atacar(T), Familia = atacar
        ;   habilidad_candidata(Cmd), Familia = habilidad
        )
    ).

enemigos_vivos(Tipos) :-
    findall(T, ( estado:instancia(E, T), compania:vivo(E) ), Ts),
    sort(Ts, Tipos).

% Rufino canta sin objetivo; las demas habilidades piden un enemigo.
habilidad_candidata(Cmd) :-
    juego:actor_del_turno(Actor),
    mundo:habilidad_de(Actor, H),
    (   combate:objetivo_de_habilidad(H, ninguno)
    ->  Cmd = habilidad
    ;   enemigos_vivos(Tipos), member(T, Tipos), Cmd = habilidad(T)
    ).

accion_json(Fase, Cmd, Familia,
            json([comando=Texto, familia=Familia, etiqueta=Etiqueta, habilitada=Hab, motivo=Motivo,
                  por_que_no=PQN, aviso=Aviso])) :-
    termino_texto(Cmd, Texto),
    aviso_de_gasto(Cmd, Aviso),
    etiqueta_de(Cmd, Etiqueta),
    functor(Cmd, Nombre, _),
    (   catch(once(juego:objetivo_de_accion(Cmd, Meta)), _, fail)
    ->  (   once(explicar:por_que_no(Meta, Diag))
        ->  Hab = @(false),
            narrador:comentario_diag(Diag, resumido, 0, Motivo),
            PQN = Texto
        ;   permitido_o_motivo(Fase, Nombre, Cmd, Hab, Motivo, PQN)
        )
    ;   permitido_o_motivo(Fase, Nombre, Cmd, Hab, Motivo, PQN)
    ).

% aviso_de_gasto(+Cmd, -Aviso): viajar cuesta la racion de un dia y descansar, ademas, su coste. Si la despensa
% queda justa, el aviso (si no, null). Solo tiene sentido en las acciones que gastan queso.
aviso_de_gasto(Cmd, Aviso) :-
    (   Cmd = ir(_) -> Coste = 0
    ;   Cmd == descansar -> mundo:parametro(coste_descanso, Coste)
    ),
    economia:riesgo_de_gasto(Coste, Riesgo),
    narrador:texto_riesgo(Riesgo, Texto),
    !,
    Aviso = Texto.
aviso_de_gasto(_, @(null)).

permitido_o_motivo(Fase, Nombre, Cmd, Hab, Motivo, PQN) :-
    (   juego:permitido(Fase, Nombre)
    ->  Hab = @(true), Motivo = @(null), PQN = @(null)
    ;   Hab = @(false), PQN = @(null),
        narrador:texto_error(fuera_de_fase(Cmd, Fase), Motivo)
    ).

etiqueta_de(Cmd, Etiqueta) :-
    (   Cmd = ir(Z)
    ->  ( mundo:zona(Z, N) -> true ; N = Z ), format(atom(Etiqueta), 'Ir a ~w', [N])
    ;   Cmd = atacar(T)
    ->  nombre_corto(T, N), format(atom(Etiqueta), 'Atacar a ~w', [N])
    ;   Cmd = habilidad(T)
    ->  nombre_corto(T, N), format(atom(Etiqueta), 'Habilidad contra ~w', [N])
    ;   Cmd = habilidad
    ->  Etiqueta = 'Habilidad'
    ;   functor(Cmd, F, _), bonito(F, Etiqueta)
    ).

% ---------------------------------------------------------------------------
% Las fichas de los personajes: que son, que hacen y que NO hay (niveles)
% ---------------------------------------------------------------------------
% Todo sale de los datos del juego (mundo, combate, compania): las cifras, el coste y el efecto de cada habilidad,
% la tabla de moral y los parametros. Las comparaciones de «lo mas alto de la Banda» se calculan, no se escriben.

fichas_json(json([miembros=Ms, moral=Moral, reglas=Reglas, progresion=Prog])) :-
    findall(Id, mundo:personaje(Id, _, _, _, _, _, _), Ids),
    findall(Id-s(V, A, D), ( member(Id, Ids), mundo:personaje(Id, _, _, vida(V), ataque(A), defensa(D), _) ), Todos),
    maplist(ficha_json(Todos), Ids, Ms),
    moral_json(Moral),
    mundo:parametro(moral_huelga, Huelga), mundo:parametro(moral_victoria, Victoria),
    mundo:parametro(bono_defender, Defender), mundo:parametro(coste_descanso, Descanso),
    mundo:parametro(moral_impago, Impago), mundo:parametro(moral_max, MoralMax),
    Reglas = json([moral_max=MoralMax, huelga_si_moral_hasta=Huelga, moral_por_victoria=Victoria, bono_defender=Defender,
                   coste_descanso=Descanso, moral_perdida_por_impago=Impago]),
    Prog = json([sube_de_nivel= @(false),
                 texto='En esta versión los personajes no suben de nivel ni ganan experiencia: sus cifras base son fijas.',
                 cambia=['vida', 'moral', 'equipo'],
                 detalle='Lo que sí cambia durante la partida es la vida (se cura al descansar), la moral (sube al ganar un combate o con la balada de Rufino y baja si no se paga a la Banda o no se come) y el equipo (la venda de caballos de Baldomero).']).

ficha_json(Todos, Id, json([id=Id, nombre=Nombre, rol=Rol, vida_max=V, ataque=A, defensa=D, sueldo=S, fila=Fila,
                            alcance=Alcance, alcance_texto=AlcanceT, rasgo=Rasgo, rasgo_nombre=RasgoN, rasgo_texto=RasgoT,
                            habilidad=Hab, fuertes=Fuertes, debiles=Debiles, maximos=json([vida=MV, ataque=MA, defensa=MD])])) :-
    mundo:personaje(Id, Nombre, Rol, vida(V), ataque(A), defensa(D), sueldo(S)),
    mundo:fila_preferida(Id, Fila),
    mundo:alcance(Id, Alcance), alcance_texto(Alcance, AlcanceT),
    mundo:rasgo(Id, Rasgo), bonito(Rasgo, RasgoN), rasgo_texto(Id, Rasgo, RasgoT),
    mundo:habilidad_de(Id, Habilidad), habilidad_json(Id, Habilidad, Hab),
    findall(X, member(_-s(X, _, _), Todos), Vs), max_list(Vs, MV),
    findall(X, member(_-s(_, X, _), Todos), As), max_list(As, MA),
    findall(X, member(_-s(_, _, X), Todos), Ds), max_list(Ds, MD),
    extremos(Id, Todos, Alcance, Rasgo, Habilidad, Fuertes, Debiles).

alcance_texto(cuerpo, 'Cuerpo a cuerpo: solo alcanza a la primera fila enemiga mientras haya alguien vivo en ella.').
alcance_texto(distancia, 'A distancia: llega también a la retaguardia enemiga.').

rasgo_texto(_, teme_caballos, Texto) :- !,
    mundo:parametro(dano_miedo, Miedo), mundo:parametro(penal_venda, Venda),
    format(atom(Texto), 'Teme a los caballos: no puede atacarlos y recibe +~w de daño de ellos. Con la venda de caballos se atreve, pero ataca con -~w contra ellos.', [Miedo, Venda]).
rasgo_texto(Id, hechizos_de_cocina, Texto) :-
    mundo:habilidad_de(Id, Hab), mundo:coste_queso(Hab, N), !,
    ( N =:= 1 -> Q = 'queso' ; Q = 'quesos' ),
    format(atom(Texto), 'Toda su magia necesita queso: lanzar su habilidad gasta ~w ~w (el más rancio), y sin queso en la despensa no puede lanzarla.', [N, Q]).
rasgo_texto(_, _, 'Es de ambientación: de momento no cambia las reglas del juego.').

% habilidad_json(+Id, +Habilidad, -Json): lo que hace, lo que cuesta, contra quien y como se escribe.
habilidad_json(Id, Habilidad, json([id=Habilidad, nombre=Nombre, efecto=Efecto, coste=Coste, objetivo=Objetivo, comando=Comando])) :-
    nombre_corto(Habilidad, Nombre),
    combate:efecto_habilidad(Habilidad, Datos), efecto_texto(Datos, Efecto),
    (   mundo:rasgo(Id, hechizos_de_cocina), mundo:coste_queso(Habilidad, N)
    ->  ( N =:= 1 -> Q = 'queso' ; Q = 'quesos' ), format(atom(Coste), 'Cuesta ~w ~w', [N, Q])
    ;   Coste = 'Gratis'
    ),
    combate:objetivo_de_habilidad(Habilidad, Tipo),
    (   Tipo == ninguno
    ->  Objetivo = 'No necesita objetivo', Comando = 'habilidad.'
    ;   Objetivo = 'Se usa contra un enemigo', Comando = 'habilidad(Tipo).'
    ).

efecto_texto(golpe_extra(N), T) :- format(atom(T), 'Su golpe de siempre, con +~w de daño.', [N]).
efecto_texto(dano_fijo(N), T) :- format(atom(T), '~w de daño fijo: ignora la defensa del enemigo.', [N]).
efecto_texto(moral_grupo(N), T) :- format(atom(T), '+~w de moral a toda la Banda.', [N]).
efecto_texto(queso_del_bolsillo(N), T) :-
    ( N =:= 1 -> Q = 'queso' ; Q = 'quesos' ),
    format(atom(T), 'Si el enemigo lleva queso, te llevas ~w ~w. Solo una vez por enemigo en cada combate.', [N, Q]).

% extremos(+Id, +Todos, +Alcance, +Rasgo, +Habilidad, -Fuertes, -Debiles): lo que destaca, comparado con el resto de la Banda.
extremos(Id, Todos, Alcance, Rasgo, Habilidad, Fuertes, Debiles) :-
    findall(F, extremo(Id, Todos, alto, F), F1),
    findall(D, extremo(Id, Todos, bajo, D), D1),
    ( Alcance == distancia -> F2 = ['Ataca a distancia: llega a la retaguardia enemiga'] ; F2 = [] ),
    (   combate_gratis(Id, Habilidad) -> F3 = ['Su habilidad no gasta queso'] ; F3 = [] ),
    append([F1, F2, F3], Fuertes),
    ( Rasgo == teme_caballos -> D2 = ['Teme a los caballos'] ; D2 = [] ),
    (   \+ combate_gratis(Id, Habilidad) -> D3 = ['Su habilidad gasta queso'] ; D3 = [] ),
    append([D1, D2, D3], Debiles).

combate_gratis(Id, Habilidad) :- \+ ( mundo:rasgo(Id, hechizos_de_cocina), mundo:coste_queso(Habilidad, _) ).

% extremo(+Id, +Todos, +Sentido, -Texto): la cifra de Id es la mas alta (alto) o la mas baja (bajo) de la Banda.
extremo(Id, Todos, Sentido, Texto) :-
    member(Pos-p(Alto, Bajo, Nombre), [1-p(alta, baja, 'Vida'), 2-p(alto, bajo, 'Ataque'), 3-p(alta, baja, 'Defensa')]),
    columna(Todos, Pos, Valores),
    valor_de(Todos, Id, Pos, Mio),
    max_list(Valores, Max), min_list(Valores, Min), Max =\= Min,
    (   Sentido == alto, Mio =:= Max -> Palabra = Alto
    ;   Sentido == bajo, Mio =:= Min -> Palabra = Bajo
    ),
    format(atom(Texto), '~w más ~w de la Banda (~w)', [Nombre, Palabra, Mio]).

columna(Todos, Pos, Valores) :-
    findall(X, ( member(_-S, Todos), arg(Pos, S, X) ), Valores).
valor_de(Todos, Id, Pos, X) :-
    memberchk(Id-S, Todos), arg(Pos, S, X).

% moral_json(-Tramos): la tabla de moral (nivel, de que moral a que moral, y lo que suma o resta), sacada de compania.
moral_json(Tramos) :-
    mundo:parametro(moral_max, Max),
    findall(M-N-Mod, ( between(0, Max, M), compania:nivel_de_moral(M, N), compania:mod_de_nivel(N, Mod) ), L),
    agrupar_moral(L, Tramos).

agrupar_moral([], []).
agrupar_moral([M-N-Mod|R], [json([nivel=N, desde=M, hasta=H, modificador=Mod])|Gs]) :-
    tramo_moral(R, N, M, H, Resto),
    agrupar_moral(Resto, Gs).

tramo_moral([M-N-_|R], N, _, H, Resto) :- !, tramo_moral(R, N, M, H, Resto).
tramo_moral(R, _, H, H, R).

% ---------------------------------------------------------------------------
% Las escenas de demostracion
% ---------------------------------------------------------------------------

escenas_json(Js) :-
    findall(json([nombre=N, titulo=T, descripcion=D, sugerencias=Ss]),
            (   demo:escena(N, T, D, _, S),
                maplist(termino_texto, S, Ss)
            ),
            Js).

% ---------------------------------------------------------------------------
% Ejecutar una orden escrita (como la consola, pero devolviendo JSON)
% ---------------------------------------------------------------------------

% nueva_partida_json(-Respuesta): una partida nueva, con lo mismo que ve el jugador en la consola al arrancar
% (la bienvenida: objetivo y primeros pasos) y la descripcion de la zona. Es lo que devuelve /api/nueva.
nueva_partida_json(json([bienvenida=Lineas|Campos])) :-
    estado:nueva_partida,
    ejecutar_orden(mirar, json(Campos)),
    narrador:bienvenida(Lineas).

% texto_de_orden(+Texto, -Termino): lo que el jugador escribio ("ir(aldea)." o sin punto) como termino.
texto_de_orden(Texto, Termino) :-
    (   atom_codes(Texto, Cs0),
        recortar(Cs0, Cs)
    ->  (   Cs == []
        ->  Termino = _
        ;   catch(( atom_codes(A, Cs), term_to_atom(Termino, A) ),
                  error(syntax_error(_), _),
                  Termino = '$error_sintaxis')
        )
    ;   Termino = '$error_sintaxis'
    ).

% quita espacios de los extremos y un punto final
recortar(Cs0, Cs) :-
    exclude(==(0'\r), Cs0, Cs1),
    reverse(Cs1, R1), borrar_espacios(R1, R2), borrar_punto(R2, R3), borrar_espacios(R3, R4),
    reverse(R4, F), borrar_espacios(F, Cs).

borrar_espacios([C|R], Cs) :- code_type(C, space), !, borrar_espacios(R, Cs).
borrar_espacios(Cs, Cs).

borrar_punto([0'.|R], R) :- !.
borrar_punto(Cs, Cs).

% ejecutar_orden(+Texto, -Respuesta): Respuesta = json([orden, items, estado]). Atiende demo y demo(Escena) como
% hace main:procesar/2 y todo lo demas pasa por la validacion y por ejecutar/2 de siempre. Nunca falla.
ejecutar_orden(Texto, json([orden=Texto, items=Items, estado=Estado])) :-
    texto_de_orden(Texto, Termino),
    (   catch(items_de_orden(Termino, Items0), E, items_de_error(E, Items0))
    ->  true
    ;   Items0 = [json([tipo=error, motivo=interno, texto='Algo ha ido mal.', por_que_no= @(null)])]
    ),
    Items = Items0,
    (   catch(estado_json(Estado0), _, fail) -> Estado = Estado0 ; Estado = @(null) ).

items_de_error(E, [json([tipo=error, motivo=interno, texto=T, por_que_no= @(null)])]) :-
    narrador:texto_error(interno(E), T).

items_de_orden(Termino, Items) :-
    (   nonvar(Termino), Termino == demo
    ->  items_json([vista(escenas, [])], Items)
    ;   nonvar(Termino), Termino = demo(Escena), atom(Escena)
    ->  juego:preparar_escena(Escena, Is), items_json(Is, Items)
    ;   juego:validar_comando(Termino, Validacion),
        (   Validacion = ok(Cmd)
        ->  juego:ejecutar(Cmd, resultado(Is)), items_json(Is, Items)
        ;   Validacion = error(Motivo)
        ->  items_json([error(Motivo)], Items)
        )
    ).
