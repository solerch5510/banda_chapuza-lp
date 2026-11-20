% demo.pl
% Las escenas de la demostracion para la exposicion: estados del juego preparados de antemano, para no
% depender de jugar desde cero delante del tribunal. Son DATOS (como los contratos o los finales): cada
% escena dice que se prepara y que se le sugiere probar; juego:preparar_escena/2 la monta y
% main:demo/1 la presenta. El meta-comando es `demo.` (lista las escenas) o `demo(Escena).`
%
% Cada escena PARTE DE UNA PARTIDA NUEVA (salvo `venda`, que continua la actual): asi el estado es el
% mismo se haya jugado lo que se haya jugado antes, y la demostracion es reproducible. La semilla del
% generador la fija nueva_partida; no se usa random/1 en ninguna parte del juego.
%
% Preparacion = lista de pasos:
%   reiniciar         una partida nueva
%   efectos(Lista)    efectos de estado (los mismos que usan las reglas)
%   combate(Tipos)    empieza un combate contra esos enemigos (como si se hubiera llegado a la zona)

:- module(demo, [escena/5]).
:- encoding(utf8).

% escena(+Nombre, -Titulo, -Descripcion, -Preparacion, -Sugerencias)

escena(economia,
       'La economía: el queso madura (min. 3:00 de la exposición)',
       'Día 12, en la taberna, con queso fresco, curado y rancio mezclados y los sueldos por pagar. Cada día que pasa los quesos envejecen y, al pagar, se gasta primero lo más rancio.',
       [ reiniciar,
         efectos([ avanzar_dia, avanzar_dia, avanzar_dia, avanzar_dia, avanzar_dia, avanzar_dia,
                   avanzar_dia, avanzar_dia, avanzar_dia, avanzar_dia, avanzar_dia,
                   ganar_queso(cheddar, 8, 2), ganar_queso(brie, 14, 1),
                   desmarcar(sueldos_pagados) ]) ],
       [mirar, inventario, pagar, ir(aldea), ir(bosque), inventario]).

escena(combate,
       'Demostración 1: el combate y el miedo de Baldomero (min. 5:00)',
       'Camino Real, combate contra un Bandido Torpe y un Bandido Montado. Baldomero, sin la venda de caballos, no puede atacar al montado: por_que_no lo explica.',
       [ reiniciar,
         efectos([viajar(camino_real)]),
         combate([bandido_torpe, bandido_montado]) ],
       [ explicar(atacar(baldomero, bandido_torpe)),
         por_que_no(atacar(baldomero, bandido_montado)),
         nivel(detallado),
         por_que_no(atacar(baldomero, bandido_montado)),
         nivel(resumido) ]).

escena(ia,
       'Demostración 3: la IA enemiga, el corte y las prioridades (min. 9:30)',
       'Un Bandido Torpe, a solas, contra la Banda. Tras su turno, explicar cuenta por qué eligió esa regla de su lista y por qué no se aplicó ninguna de mayor prioridad.',
       [ reiniciar,
         efectos([viajar(camino_real)]),
         combate([bandido_torpe]) ],
       [defender, defender, defender, explicar]).

escena(gallina,
       'Demostración 2: Lady Clotilde y el miedo a los caballos (min. 11:00)',
       'Camino Real. Baldomero lleva sin venda y teme a los caballos: la gallina exige una escolta sin miedo. por_que_no baja hasta la negación que lo impide.',
       [ reiniciar,
         efectos([viajar(camino_real)]) ],
       [ contratos, por_que_no(aceptar(gallina_noble)), nivel(detallado), por_que_no(aceptar(gallina_noble)), nivel(resumido) ]).

% Continua la partida actual: es lo que pasa tras el contrato del gato (Baldomero recibe la venda).
escena(venda,
       'Continuación: tras el contrato del gato, Baldomero lleva la venda',
       'Se le pone a Baldomero la venda de caballos (el premio del contrato del gato). Ahora la misma pregunta ya no falla y la gallina se puede aceptar.',
       [ efectos([equipar(baldomero, venda_de_caballos)]) ],
       [por_que_no(aceptar(gallina_noble)), aceptar(gallina_noble)]).
