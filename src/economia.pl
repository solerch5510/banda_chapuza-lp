% economia.pl
% Queso, comida, sueldos y maduracion.
%
% El queso es la unica moneda y tambien la comida. Aqui solo hay REGLAS: calculan
% que efectos habria que aplicar (listas de terminos como gastar_queso(cheddar, 0, 1))
% pero nunca modifican el estado; eso lo hace estado:aplicar_efectos/1.
% Por ahora: lo que necesitan ir y descansar (categorias, despensa, racion y descanso).

:- module(economia, [categoria_queso/2, queso_total/1, hay_queso_para/1, despensa/1,
                     puede_descansar/0, efectos_racion/1, efectos_descanso/1]).
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
    (   mundo:personaje(Id, _, _, vida(Max), _, _, _),
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
