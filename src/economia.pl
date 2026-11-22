% economia.pl
% Queso, comida, sueldos y maduracion.
%
% El queso es la unica moneda y tambien la comida. Aqui solo hay REGLAS: calculan
% que efectos habria que aplicar (listas de terminos como gastar_queso(cheddar, 0, 1))
% pero nunca modifican el estado; eso lo hace estado:aplicar_efectos/1.
% Por ahora: lo que necesitan ir y descansar (categorias, despensa, racion y descanso).

:- module(economia, [categoria_queso/2, queso_total/1, hay_queso_para/1, despensa/1,
                     valor_queso/3, valor_despensa/1, inventario/1,
                     puede_descansar/0, efectos_racion/1, efectos_descanso/1,
                     total_sueldos/1, puede_pagar_sueldos/0, efectos_sueldos/1,
                     efectos_perdida/2, racion_diaria/1, dias_de_comida/1, riesgo_de_gasto/2,
                     dias_de_ayuno/1, derrota_por_hambre/0, efectos_ayuno/2,
                     puede_usar/2, efectos_usar/3]).
:- use_module(mundo).
:- use_module(estado).
:- use_module(compania).

% ---------------------------------------------------------------------------
% Categorias por edad. Tres clausulas excluyentes (sin corte): cada edad cae en una.
% categoria_queso(+Edad, -Categoria)
% ---------------------------------------------------------------------------
categoria_queso(Edad, fresco) :-
    mundo:parametro(edad_curado_min, Curado),
    Edad < Curado.
categoria_queso(Edad, curado) :-
    mundo:parametro(edad_curado_min, Curado),
    mundo:parametro(edad_rancio_min, Rancio),
    Edad >= Curado, Edad < Rancio.
categoria_queso(Edad, rancio) :-
    mundo:parametro(edad_rancio_min, Rancio),
    Edad >= Rancio.

% ---------------------------------------------------------------------------
% Despensa
% ---------------------------------------------------------------------------
% queso_total(-N): unidades totales (se cuentan unidades, no valor).
queso_total(N) :-
    findall(C, estado:queso(_, _, C), Cantidades),
    sumlist(Cantidades, N).

% hay_queso_para(+N): quedan al menos N unidades.
hay_queso_para(N) :-
    queso_total(Total),
    Total >= N.

% despensa(-Lista): lotes q(Tipo, Edad, Cantidad) en ORDEN DE RACION:
% primero lo fresco, luego lo curado y al final lo rancio; dentro de cada
% categoria, el mas viejo primero. Asi lo rancio solo se come cuando no queda otra cosa.
despensa(Lista) :-
    findall(clave(Rango, EdadNeg, Tipo)-q(Tipo, Edad, Cant),
            (   estado:queso(Tipo, Edad, Cant),
                categoria_queso(Edad, Cat),
                rango_categoria(Cat, Rango),
                EdadNeg is -Edad
            ),
            Pares),
    msort(Pares, Ordenados),
    quitar_claves(Ordenados, Lista).

rango_categoria(fresco, 1).
rango_categoria(curado, 2).
rango_categoria(rancio, 3).

quitar_claves([], []).
quitar_claves([_-Lote|Resto], [Lote|Lotes]) :- quitar_claves(Resto, Lotes).

% ---------------------------------------------------------------------------
% Valor (SOLO informativo: todo se paga y se cobra por unidades, no por valor).
% fresco = valor base; curado = valor base + 2; rancio = 1 como mucho (nunca mas que el fresco).
% valor_queso(+Tipo, +Edad, -Valor)
% ---------------------------------------------------------------------------
valor_queso(Tipo, Edad, Valor) :-
    mundo:tipo_queso(Tipo, Base),
    categoria_queso(Edad, Categoria),
    valor_segun(Categoria, Base, Valor).

valor_segun(fresco, Base, Base).
valor_segun(curado, Base, Valor) :- Valor is Base + 2.
valor_segun(rancio, Base, Valor) :- Valor is min(1, Base).

% valor_despensa(-Total): valor informativo de toda la despensa.
valor_despensa(Total) :-
    findall(V, ( estado:queso(Tipo, Edad, Cant), valor_queso(Tipo, Edad, Unidad), V is Unidad * Cant ), Vs),
    sumlist(Vs, Total).

% inventario(-Datos): lo que muestra el comando inventario.
inventario([dia(Dia), total(Total), valor(Valor), lotes(Lotes), objetos(Objetos)]) :-
    once(estado:dia(Dia)),
    queso_total(Total),
    valor_despensa(Valor),
    despensa(Despensa),
    findall(lote(Tipo, Edad, Cant, Categoria),
            ( member(q(Tipo, Edad, Cant), Despensa), categoria_queso(Edad, Categoria) ),
            Lotes),
    findall(Objeto-Cant, estado:lleva(compania, Objeto, Cant), Objetos).

% ---------------------------------------------------------------------------
% Descansar (solo en la taberna): cuesta quesos, cura a todos y sube la moral.
% ---------------------------------------------------------------------------
% puede_descansar: es la regla que se explica en el comando descansar.
puede_descansar :-
    estado:en_zona(taberna),
    mundo:parametro(coste_descanso, Coste),
    hay_queso_para(Coste).

% efectos_descanso(-Efectos): gasta el coste en quesos (en orden de racion),
% cura toda la vida de cada miembro activo y le suma 1 de moral.
efectos_descanso([mensaje(descanso, [])|Efectos]) :-
    mundo:parametro(coste_descanso, Coste),
    despensa(Despensa),
    tomar(Despensa, Coste, Gastos),
    findall(Efecto, efecto_de_descanso(Efecto), Cuidados),
    append(Gastos, Cuidados, Efectos).

efecto_de_descanso(Efecto) :-
    compania:activo(Id),
    (   estado:vida_maxima(Id, Max),
        Efecto = curar(Id, Max)
    ;   Efecto = mod_moral(Id, 1)
    ).

% tomar(+Despensa, +N, -Efectos): N gastar_queso(_, _, 1), uno por unidad, en orden de racion.
% (La lista va en el primer argumento para que Prolog distinga [] de [_|_] sin dejar elecciones abiertas.)
tomar([q(Tipo, Edad, Cant)|Resto], N, Efectos) :-
    (   N =< 0
    ->  Efectos = []
    ;   Efectos = [gastar_queso(Tipo, Edad, 1)|Efectos1],
        N1 is N - 1,
        (   Cant > 1
        ->  Cant1 is Cant - 1,
            Despensa1 = [q(Tipo, Edad, Cant1)|Resto]
        ;   Despensa1 = Resto
        ),
        tomar(Despensa1, N1, Efectos1)
    ).
tomar([], N, []) :-
    N =< 0.

% ---------------------------------------------------------------------------
% Racion diaria: cada miembro activo come una unidad. Se acumula la despensa que
% va quedando (estilo Conf. 1-2) porque los efectos aun no se han aplicado.
% ---------------------------------------------------------------------------
efectos_racion(Efectos) :-
    findall(Id, compania:activo(Id), Miembros),
    despensa(Despensa),
    racion(Miembros, Despensa, Efectos).

racion([], _, []).
racion([Id|Ids], Despensa, Efectos) :-
    (   Despensa = [q(Tipo, Edad, Cant)|Resto]
    ->  once(categoria_queso(Edad, Categoria)),
        penalizacion(Categoria, Id, Penalizacion),
        (   Cant > 1
        ->  Cant1 is Cant - 1,
            Despensa1 = [q(Tipo, Edad, Cant1)|Resto]
        ;   Despensa1 = Resto
        ),
        Propios = [gastar_queso(Tipo, Edad, 1)|Penalizacion]
    ;   hambre(Id, Propios),
        Despensa1 = []
    ),
    racion(Ids, Despensa1, Efectos1),
    append(Propios, Efectos1, Efectos).

% Comer queso rancio baja un poco la moral; lo fresco y lo curado no tienen coste.
penalizacion(rancio, Id, [mod_moral(Id, Menos), mensaje(come_rancio, [Id])]) :-
    mundo:parametro(moral_rancio, Perdida),
    Menos is -Perdida.
penalizacion(fresco, _, []).
penalizacion(curado, _, []).

% Sin comida: baja la moral y la vida, pero el hambre nunca deja a nadie por debajo de 1.
hambre(Id, [mensaje(sin_comida, [Id]), mod_moral(Id, Menos)|Dano]) :-
    mundo:parametro(moral_hambre, Perdida),
    Menos is -Perdida,
    estado:vida(Id, Vida),
    mundo:parametro(dano_hambre, Maximo),
    Dano1 is min(Maximo, Vida - 1),
    (   Dano1 > 0 -> Dano = [dano(Id, Dano1)] ; Dano = [] ).

% ---------------------------------------------------------------------------
% Sueldos: se pagan con el comando pagar en la taberna, en quesos (unidades).
% La bandera marca(sueldos_pagados) dice que no se debe nada: se pone al empezar y
% al pagar, y se quita al llegar a la taberna (llegar trae sueldos pendientes).
% ---------------------------------------------------------------------------
% total_sueldos(-Total): suma de los sueldos de los miembros activos.
total_sueldos(Total) :-
    findall(S, ( compania:activo(Id), compania:sueldo_de(Id, S) ), Sueldos),
    sumlist(Sueldos, Total).

% puede_pagar_sueldos: hay sueldos pendientes y queso para cubrirlos todos
% (no se paga a medias). Es la regla que se explica en el comando pagar.
puede_pagar_sueldos :-
    \+ estado:marca(sueldos_pagados),
    total_sueldos(Total),
    hay_queso_para(Total).

% efectos_sueldos(-Efectos): marca los sueldos como pagados y gasta el total en quesos,
% con el MAS RANCIO PRIMERO ("una forma de reciclar", dice el Gremio).
efectos_sueldos([marcar(sueldos_pagados), mensaje(pago, [Total])|Gastos]) :-
    total_sueldos(Total),
    despensa_para_pago(Despensa),
    tomar(Despensa, Total, Gastos).

% racion_diaria(-N): lo que come la Banda en un dia (la racion de cada miembro activo).
racion_diaria(N) :-
    findall(Id, compania:activo(Id), Miembros),
    length(Miembros, K),
    mundo:parametro(racion_por_miembro, Racion),
    N is K * Racion.

% dias_de_comida(-D): cuantos dias enteros de racion hay en la despensa.
dias_de_comida(D) :-
    queso_total(Queso),
    racion_diaria(Racion),
    (   Racion > 0 -> D is Queso // Racion ; D = 0 ).

% riesgo_de_gasto(+Coste, -Riesgo): que le pasa a la despensa si se gasta Coste y ademas pasa un dia (la racion).
%   hambre_mortal  se queda a cero y no hay nada por cobrar: fin de la partida (ver juego:comprobar_fin)
%   sin_queso      se queda a cero, pero hay algo por cobrar
%   escaso         queda menos de un dia de racion
%   ninguno        hay margen
riesgo_de_gasto(Coste, Riesgo) :-
    queso_total(Queso),
    racion_diaria(Racion),
    Resto is Queso - Coste - Racion,
    dias_de_ayuno(Ayuno0),
    mundo:parametro(dias_de_ayuno_max, Max),
    (   Resto < 0 -> Ayuno is Ayuno0 + 1 ; Ayuno = 0 ),     % ese dia pasa hambre quien no llega a su racion
    (   Resto =< 0, \+ estado:contrato_por_cobrar(_, _), Ayuno >= Max -> Riesgo = hambre_mortal
    ;   Resto =< 0, estado:contrato_por_cobrar(_, _)                  -> Riesgo = sin_queso
    ;   Resto =< 0                                                    -> Riesgo = a_cero
    ;   Resto < Racion                                                -> Riesgo = escaso
    ;   Riesgo = ninguno
    ).

% ---------------------------------------------------------------------------
% El ayuno (docs/11-balance.md): quedarse sin queso NO acaba la partida en el acto. La Banda aguanta unos dias
% seguidos sin comer (mundo:parametro(dias_de_ayuno_max, N)); se pierde por hambre cuando, sin queso y sin nada
% por cobrar, ya se han aguantado todos. Un dia en que todos comen vuelve a ponerlo a cero. Asi el jugador
% llega a la zona, acepta el contrato y puede volver a cobrar, en vez de perder antes de poder actuar.
% ---------------------------------------------------------------------------
% dias_de_ayuno(-N): dias seguidos en que alguien se ha quedado sin comer.
dias_de_ayuno(N) :-
    (   estado:contador(dias_de_ayuno, V) -> N = V ; N = 0 ).

% derrota_por_hambre: sin queso, sin nada por cobrar y con todos los dias de ayuno ya aguantados.
derrota_por_hambre :-
    queso_total(0),
    \+ estado:contrato_por_cobrar(_, _),
    dias_de_ayuno(Dias),
    mundo:parametro(dias_de_ayuno_max, Max),
    Dias >= Max.

% efectos_ayuno(+EfectosDeLaRacion, -Efectos): un dia mas de ayuno si alguien se quedo sin comer; si no, la cuenta vuelve a cero.
efectos_ayuno(EfectosRacion, Efectos) :-
    (   memberchk(mensaje(sin_comida, _), EfectosRacion)
    ->  Efectos = [contar(dias_de_ayuno, 1)]
    ;   Efectos = [borrar_contador(dias_de_ayuno)]
    ).

% ---------------------------------------------------------------------------
% Usar un objeto (comando usar/2): una pocion cura a un miembro herido. El objeto sale del inventario comun de la
% compania y la cura nunca pasa de la vida maxima. Fuera de combate no cuesta tiempo; en combate es la accion del
% turno (ver juego:ejecutar_en_fase/3).
% ---------------------------------------------------------------------------
% puede_usar(?Objeto, ?Miembro): la compania lo lleva, cura, y el miembro esta vivo y herido (la regla que explica `usar`).
puede_usar(Objeto, Miembro) :-
    mundo:curacion(Objeto, _),
    estado:lleva(compania, Objeto, N), N > 0,
    compania:activo(Miembro),
    estado:vida(Miembro, Vida),
    estado:tope_vida(Miembro, Maximo),
    Vida < Maximo.

% efectos_usar(+Objeto, +Miembro, -Efectos): gasta el objeto y cura lo que cura (sin pasar del maximo).
efectos_usar(Objeto, Miembro, [gastar_objeto(compania, Objeto, 1), curar(Miembro, Cura), mensaje(usa_objeto, [Objeto, Miembro, Cura])]) :-
    puede_usar(Objeto, Miembro),
    mundo:curacion(Objeto, Total),
    estado:vida(Miembro, Vida),
    estado:tope_vida(Miembro, Maximo),
    Cura is min(Total, Maximo - Vida).

% efectos_perdida(+N, -Efectos): se pierden N quesos (los mas rancios primero) o todos si hay menos.
efectos_perdida(N, Efectos) :-
    queso_total(Total),
    Real is min(N, Total),
    despensa_para_pago(Despensa),
    tomar(Despensa, Real, Efectos).

% despensa_para_pago(-Lotes): la despensa con el lote mas viejo primero.
despensa_para_pago(Lista) :-
    findall(clave(EdadNeg, Tipo)-q(Tipo, Edad, Cant),
            ( estado:queso(Tipo, Edad, Cant), EdadNeg is -Edad ),
            Pares),
    msort(Pares, Ordenados),
    quitar_claves(Ordenados, Lista).
