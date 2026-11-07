% combate.pl
% Turnos, filas, calculo de dano e IA enemiga.
%
% Solo REGLAS puras: consultan el estado y deciden, pero nunca lo modifican (los efectos
% los aplica estado.pl). Por ahora, lo que hace falta para los rasgos del heroe:
%   - puede_atacar/2: la regla de la primera demostracion de explicar (el miedo de Baldomero);
%   - en_fila_alcanzable/2: las reglas de fila de las que depende;
%   - puede_habilidad/2: el rasgo hechizos_de_cocina de Pimentina.
% Y el orden de los turnos:
%   - iniciativa/2 y orden_turnos/1: quien actua primero en cada ronda;
%   - efectos_inicio/2 y efectos_ronda/1: los efectos que abren el combate y cada ronda.
% Y el dano:
%   - dano/3 con sus modificadores (moral, miedo, venda, defender);
%   - efectos_golpe/3: un golpe convertido en efectos.
% Y las acciones del jugador: efectos_accion/3 (atacar, defender).
% El resto del combate (bucle, IA) llega en las tareas siguientes.

:- module(combate, [puede_atacar/2, en_fila_alcanzable/2, aturdido/1,
                    puede_habilidad/2, tipo_de/2, clase_de/2,
                    ataque_base/2, defensa_base/2, puede_actuar/1,
                    iniciativa/2, orden_turnos/1,
                    ataque/2, defensa/2, modificador/3, dano/3, efectos_golpe/3,
                    efectos_accion/3, puede_defender/1, efectos_inicio_turno/2,
                    accion_enemigo/2, accion_enemigo_sin_corte/2, regla_ia/3, fin_combate/1, efectos_fin/2,
                    vida_baja/1, tiene_curativo/1, objetivo_mas_debil/2,
                    efectos_inicio/2, efectos_ronda/1]).
:- use_module(mundo).
:- use_module(estado).
:- use_module(compania).
:- use_module(economia).

% ---------------------------------------------------------------------------
% Identificadores de combatiente: un miembro es su atomo (baldomero); un enemigo es una
% instancia e(Tipo, N) (e(bandido_torpe, 1)). Los datos del catalogo son del TIPO.
% ---------------------------------------------------------------------------
% tipo_de(+Id, -Tipo): el tipo de un enemigo; un miembro es su propio "tipo".
tipo_de(Id, Tipo) :-
    (   nonvar(Id), Id = e(T, _) -> Tipo = T ; Tipo = Id ).

% clase_de(+Id, -Clase): la clase de criatura (roedor, humano, caballo...).
clase_de(Id, Clase) :-
    tipo_de(Id, Tipo),
    mundo:clase(Tipo, Clase).

% aturdido(+Id): un estado alterado (se escribe como derivado, nunca como estado/2).
aturdido(Id) :-
    estado:alterado(Id, aturdido, _).

% ---------------------------------------------------------------------------
% Atacar. Es la regla de la primera demostracion de explicar/por_que_no:
%   por_que_no(atacar(baldomero, bandido_montado)): Baldomero teme a los caballos.
% ---------------------------------------------------------------------------
puede_atacar(A, B) :-
    compania:vivo(A),
    compania:vivo(B),
    en_fila_alcanzable(A, B),
    \+ aturdido(A),
    \+ ( compania:teme(A, Clase), clase_de(B, Clase) ).

% Los de retaguardia solo pueden ser atacados cuando el frente cae, salvo ataques a distancia.
en_fila_alcanzable(A, B) :-
    bando_contrario(A, B),
    (   estado:fila(B, frente)
    ;   \+ frente_con_vivos(B)
    ;   ataca_a_distancia(A)
    ).

bando_contrario(A, B) :-
    estado:combatiente(A, BandoA),
    estado:combatiente(B, BandoB),
    BandoA \== BandoB.

% frente_con_vivos(+B): el bando de B todavia tiene a alguien vivo en primera fila.
frente_con_vivos(B) :-
    estado:combatiente(B, Bando),
    estado:combatiente(F, Bando),
    estado:fila(F, frente),
    compania:vivo(F).

ataca_a_distancia(A) :-
    tipo_de(A, Tipo),
    mundo:alcance(Tipo, distancia).

% ---------------------------------------------------------------------------
% Atributos base (los del catalogo, sin rasgos ni moral; los efectivos llegan con el dano).
% ---------------------------------------------------------------------------
ataque_base(Id, A) :-
    mundo:personaje(Id, _, _, _, ataque(A), _, _).
ataque_base(Id, A) :-
    tipo_de(Id, Tipo),
    mundo:enemigo(Tipo, _, ataque(A), _).

defensa_base(Id, D) :-
    mundo:personaje(Id, _, _, _, _, defensa(D), _).
defensa_base(Id, D) :-
    tipo_de(Id, Tipo),
    mundo:enemigo(Tipo, _, _, defensa(D)).

% puede_actuar(+Id): esta vivo y no esta en huelga (un enemigo no tiene moral: nunca hace huelga).
puede_actuar(Id) :-
    compania:vivo(Id),
    \+ compania:esta_en_huelga(Id).

% ---------------------------------------------------------------------------
% Iniciativa: I = base + ataque - defensa + moral (la moral solo cuenta en los miembros).
% Los mas rapidos actuan antes: un guerrero fuerte y poco protegido llega primero.
% ---------------------------------------------------------------------------
iniciativa(Id, I) :-
    ataque_base(Id, A),
    defensa_base(Id, D),
    ajuste_moral(Id, M),
    mundo:parametro(base_iniciativa, B),
    I is B + A - D + M.

% ajuste_moral(+Id, -M): lo que suma o resta la moral; los enemigos no tienen moral, suman 0.
% Lo usan la iniciativa y el dano.
ajuste_moral(Id, M) :- compania:miembro(Id), compania:modificador_moral(Id, M).
ajuste_moral(Id, 0) :- \+ compania:miembro(Id).

% orden_turnos(-Ids): los que pueden actuar, de mayor a menor iniciativa. Si empatan, el jugador
% actua primero y, entre iguales, manda el orden estandar de los identificadores: el orden es
% siempre el mismo para el mismo estado. (K = -I porque msort ordena de menor a mayor.)
orden_turnos(Ids) :-
    findall(K-P-Id,
            (   estado:combatiente(Id, Bando),
                puede_actuar(Id),
                iniciativa(Id, I),
                K is -I,
                prioridad_bando(Bando, P)
            ),
            Pares),
    msort(Pares, Ordenados),
    ids_de(Ordenados, Ids).

prioridad_bando(jugador, 0).
prioridad_bando(enemigo, 1).

ids_de([], []).
ids_de([_-_-Id|Pares], [Id|Ids]) :- ids_de(Pares, Ids).

% ---------------------------------------------------------------------------
% Dano: D = max(1, ataque - defensa + modificador). Siempre se hace al menos 1 de dano.
%   dano(baldomero, e(bandido_torpe, 1), D)   ->   D = 9   (11 - 2 + 0)
% ---------------------------------------------------------------------------
dano(A, B, D) :-
    ataque(A, Atq),
    defensa(B, Def),
    modificador(A, B, M),
    D is max(1, Atq - Def + M).

% ataque(+Id, -A): el ataque efectivo. Hoy es el del catalogo; la moral y los rasgos entran
% por modificador/3 (para que cada ajuste se vea por separado en la explicacion).
ataque(Id, A) :- ataque_base(Id, A).

% defensa(+Id, -D): la del catalogo, mas el bono de quien esta defendiendo.
defensa(Id, D) :-
    defensa_base(Id, Base),
    bono_defensa(Id, Bono),
    D is Base + Bono.

bono_defensa(Id, Bono) :-
    (   estado:alterado(Id, defendiendo, _)
    ->  mundo:parametro(bono_defender, Bono)
    ;   Bono = 0
    ).

% modificador(+Atacante, +Objetivo, -M): moral del atacante, miedo y venda de Baldomero.
modificador(A, B, M) :-
    ajuste_moral(A, Moral),
    mod_miedo(A, B, Miedo),
    mod_venda(A, B, Venda),
    M is Moral + Miedo + Venda.

% Quien teme a la clase del atacante recibe mas dano (teme_caballos: +2 de un caballo).
mod_miedo(A, B, M) :-
    (   compania:teme(B, Clase), clase_de(A, Clase)
    ->  mundo:parametro(dano_miedo, M)
    ;   M = 0
    ).

% Con la venda, Baldomero se atreve con los caballos, pero a ciegas: ataca con penalizacion.
mod_venda(A, B, M) :-
    (   mundo:rasgo(A, teme_caballos), compania:ignora_miedo(A), clase_de(B, caballo)
    ->  mundo:parametro(penal_venda, P), M is -P
    ;   M = 0
    ).

% ---------------------------------------------------------------------------
% Un golpe como efectos: el dano al objetivo y, si lo deja sin vida, que cae.
% efectos_golpe(+A, +B, -Efectos): falla si A no puede atacar a B. No modifica el estado.
% ---------------------------------------------------------------------------
efectos_golpe(A, B, Efectos) :-
    puede_atacar(A, B),
    dano(A, B, D),
    efectos_caida(B, D, Caida),
    append([dano(B, D), mensaje(golpe, [A, B, D])], Caida, Efectos).

efectos_caida(B, D, Efectos) :-
    estado:vida(B, V),
    (   D >= V
    ->  Efectos = [mensaje(cae, [B])]
    ;   Efectos = []
    ).

% ---------------------------------------------------------------------------
% Acciones de combate como efectos. efectos_accion(+Actor, +Accion, -Efectos) falla si la
% accion no es legal; no modifica el estado.
%   atacar(B)  : un golpe (efectos_golpe/3)
%   defender   : durante una ronda la defensa sube (estado defendiendo, 1 turno)
% ---------------------------------------------------------------------------
efectos_accion(A, atacar(B), Efectos) :-
    efectos_golpe(A, B, Efectos).
efectos_accion(A, defender, [alterar(A, defendiendo, 1), mensaje(defiende, [A])]) :-
    puede_defender(A).
efectos_accion(E, curarse, [gastar_objeto(E, Objeto, 1), curar(E, Cura), mensaje(se_cura, [E, Cura])]) :-
    curativos_de(E, [Objeto|_]),
    mundo:curacion(Objeto, Cura).
efectos_accion(E, invocar_moho, [invocar(moho_saltarin), mensaje(invoca_moho, [E])]) :-
    debe_invocar_moho(E).
efectos_accion(E, robar_queso, [gastar_queso(Tipo, Edad, 1), contar(quesos_robados, 1), mensaje(roba_queso, [E])]) :-
    puede_robar_queso(E),
    economia:despensa([q(Tipo, Edad, _)|_]).                 % lo primero que ve: lo mas fresco
efectos_accion(E, embestir(B), Efectos) :-
    puede_embestir(E, B),
    dano(E, B, D0),
    mundo:parametro(dano_embestida, Extra),
    D is D0 + Extra,
    efectos_caida(B, D, Caida),
    append([dano(B, D), alterar(E, embistio, fijo), mensaje(embiste, [E, B, D])], Caida, Efectos).
efectos_accion(A, pasar, [mensaje(pasa, [A])]) :-            % lo unico que le queda a quien no puede nada
    estado:combatiente(A, _).

% puede_defender(+Id): esta en el combate, puede actuar y no esta aturdido.
puede_defender(Id) :-
    estado:combatiente(Id, _),
    puede_actuar(Id),
    \+ aturdido(Id).

% efectos_inicio_turno(+Id, -Efectos): al empezar el turno de Id, lo que dura N turnos baja en
% uno y lo que llegaba a cero desaparece (lo fijo no cambia). Asi defender dura hasta el
% siguiente turno de quien defendio.
efectos_inicio_turno(Id, Efectos) :-
    findall(E,
            (   estado:alterado(Id, Estado, Turnos),
                integer(Turnos),
                efecto_de_paso(Id, Estado, Turnos, E)
            ),
            Efectos).

efecto_de_paso(Id, Estado, Turnos, Efecto) :-
    (   Turnos =< 1
    ->  Efecto = quitar_alteracion(Id, Estado)
    ;   Menos is Turnos - 1,
        Efecto = alterar(Id, Estado, Menos)
    ).

% ---------------------------------------------------------------------------
% La IA enemiga: reglas por PRIORIDAD. Gana la primera cuyas condiciones se cumplen y el corte
% (!) descarta las demas (Conferencia 4: el corte establece prioridades). La ultima, defender,
% no repite las condiciones negadas de las anteriores: es el unico comodin. Por eso es un corte
% "rojo": la version con corte solo es correcta en modo (+Enemigo, -Accion).
%   1 curarse       si le queda poco de vida y lleva algo que cure (pocion, esporas del jefe)
%   2 invocar_moho  el jefe, si no queda un moho aliado en pie (y como mucho dos por combate)
%   3 robar_queso   la rata, si hay queso en la despensa del grupo
%   4 embestir(O)   el bandido montado, en su primer turno (dano +2)
%   5 atacar(O)     al mas debil de los que alcanza
%   6 defender      si no hay nada mejor
% Cada regla tiene su gemela sin corte en regla_ia/3 (abajo), que sirve de oraculo en las pruebas.
% ---------------------------------------------------------------------------
accion_enemigo(E, curarse)      :- vida_baja(E), tiene_curativo(E), !.
accion_enemigo(E, invocar_moho) :- debe_invocar_moho(E), !.
accion_enemigo(E, robar_queso)  :- puede_robar_queso(E), !.
accion_enemigo(E, embestir(O))  :- puede_embestir(E, O), !.
accion_enemigo(E, atacar(O))    :- objetivo_mas_debil(E, O), !.
accion_enemigo(_, defender).

% La misma IA como DATOS: el numero de regla es un argumento y gana el menor que se cumple.
regla_ia(1, E, curarse)      :- vida_baja(E), tiene_curativo(E).
regla_ia(2, E, invocar_moho) :- debe_invocar_moho(E).
regla_ia(3, E, robar_queso)  :- puede_robar_queso(E).
regla_ia(4, E, embestir(O))  :- puede_embestir(E, O).
regla_ia(5, E, atacar(O))    :- objetivo_mas_debil(E, O).
regla_ia(6, _, defender).

accion_enemigo_sin_corte(E, A) :-
    regla_ia(N, E, A),
    \+ ( regla_ia(M, E, _), M < N ).

% --- condiciones de las reglas ---
% vida_baja(+E): le queda el umbral (30 %) o menos de su vida maxima (aritmetica entera).
vida_baja(E) :-
    estado:vida(E, V),
    tipo_de(E, Tipo),
    mundo:enemigo(Tipo, vida(Max), _, _),
    mundo:parametro(umbral_vida_baja, P),
    V * 100 =< Max * P.

% curativos_de(+E, -Objetos): lo que lleva E y cura, en el orden en que lo tiene.
curativos_de(E, Objetos) :-
    findall(Obj, ( estado:lleva(E, Obj, N), N > 0, mundo:curacion(Obj, _) ), Objetos).

tiene_curativo(E) :-
    curativos_de(E, [_|_]).

% El jefe invoca un moho si no le queda ninguno aliado en pie y aun no ha invocado el maximo.
debe_invocar_moho(E) :-
    tipo_de(E, gran_roquefort),
    \+ ( estado:instancia(M, moho_saltarin), compania:vivo(M) ),
    findall(x, estado:instancia(_, moho_saltarin), Nacidos),
    length(Nacidos, N),
    mundo:parametro(max_mohos, Max),
    N < Max.

% La rata roba mientras haya queso que robar.
puede_robar_queso(E) :-
    tipo_de(E, rata_quesera),
    economia:queso_total(N),
    N > 0.

% El bandido montado embiste una sola vez por combate (la marca embistio se borra al terminar).
puede_embestir(E, O) :-
    tipo_de(E, bandido_montado),
    \+ estado:alterado(E, embistio, _),
    objetivo_mas_debil(E, O).

% objetivo_mas_debil(+Atacante, -B): de los que puede atacar, el de menos vida (empate: el id menor).
objetivo_mas_debil(A, B) :-
    findall(V-Id, ( estado:combatiente(Id, _), puede_atacar(A, Id), estado:vida(Id, V) ), Pares),
    Pares = [_|_],
    msort(Pares, [_-B|_]).

% ---------------------------------------------------------------------------
% Fin del combate. Se pierde cuando todos los miembros han caido; se gana cuando no queda
% ningun enemigo en pie. (Dentro del combate se cae; al terminar, todos se levantan.)
% ---------------------------------------------------------------------------
fin_combate(derrota) :-
    estado:en_combate(_),
    \+ bando_en_pie(jugador).
fin_combate(victoria) :-
    estado:en_combate(_),
    bando_en_pie(jugador),
    \+ bando_en_pie(enemigo).

bando_en_pie(Bando) :-
    estado:combatiente(Id, Bando),
    compania:vivo(Id).

% efectos_fin(+Resultado, -Efectos): lo que pasa al cerrar el combate.
%   victoria: el botin (1 cheddar fresco por cada enemigo que llevaba queso), la moral sube y se
%             termina el combate (los caidos se levantan con 1 de vida);
%   derrota : fin de la partida.
efectos_fin(victoria, Efectos) :-
    findall(x, ( estado:instancia(_, Tipo), mundo:lleva_queso(Tipo) ), Botin),
    length(Botin, N),
    mundo:parametro(moral_victoria, Sube),
    findall(mod_moral(Id, Sube), compania:miembro(Id), Moral),
    (   N > 0
    ->  Queso = [ganar_queso(cheddar, 0, N), mensaje(botin, [N])]
    ;   Queso = []
    ),
    append([[mensaje(victoria, [])], Queso, Moral, [terminar_combate]], Efectos).
efectos_fin(derrota, [fin(derrota(derrota_combate)), mensaje(derrota_combate, [])]).

% ---------------------------------------------------------------------------
% Efectos que abren el combate y cada ronda (se devuelven como datos; los aplica estado).
% ---------------------------------------------------------------------------
% efectos_inicio(+Grupo, -Efectos): empieza un combate contra Grupo (lista de tipos de enemigo).
% Falla si ya hay un combate o si el grupo esta vacio o tiene un tipo desconocido.
efectos_inicio(Grupo, [iniciar_combate(Grupo)]) :-
    \+ estado:en_combate(_),
    ground(Grupo), Grupo = [_|_],
    \+ ( member(Tipo, Grupo), \+ mundo:enemigo(Tipo, _, _, _) ).

% efectos_ronda(-Efectos): con la cola vacia empieza la ronda siguiente, con el orden recalculado
% (alguien puede haber caido o entrado en huelga).
efectos_ronda([siguiente_ronda(Orden)]) :-
    estado:en_combate(_),
    estado:cola_turnos([]),
    orden_turnos(Orden).

% ---------------------------------------------------------------------------
% Rasgo hechizos_de_cocina (Pimentina): "toda magia necesita queso". Cada hechizo gasta
% quesos de la despensa; sin queso suficiente no se puede lanzar.
% puede_habilidad(+Id, +Habilidad)
% ---------------------------------------------------------------------------
puede_habilidad(Id, Habilidad) :-
    mundo:rasgo(Id, hechizos_de_cocina),
    mundo:habilidad_de(Id, Habilidad),
    compania:vivo(Id),
    \+ aturdido(Id),
    mundo:coste_queso(Habilidad, Coste),
    economia:hay_queso_para(Coste).
