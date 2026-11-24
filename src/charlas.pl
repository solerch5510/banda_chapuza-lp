% charlas.pl
% Hablar con los NPC (docs/12-npcs.md). Las zonas tienen gente, y la gente cuenta cosas.
%
% Una charla es una escena corta con opciones, como el evento del gato, pero SIN contrato: la abre
% `hablar(Npc)`, se resuelve con `elegir/1` y solo se puede hacer una vez. Cada opcion la hace un miembro de la
% Banda y da cosas pequenas (queso, moral) o INFORMACION (un fragmento de la historia del Gran Rancio, que
% apunta el diario). Los personajes no estan siempre: cada uno aparece entre dos dias.
%
% Todo son DATOS (presente/4, escena_de/2, opcion_charla/5, saber/1) y REGLAS puras que consultan el estado y
% devuelven efectos como datos; solo estado.pl los aplica. Los textos viven en narrador.pl.
% Estado: la marca charla_abierta(Npc) mientras esta a medias, charla_hecha(Npc) al resolverla y sabe(Marca)
% por cada fragmento averiguado.

:- module(charlas, [presente/4, escena_de/2, opcion_charla/5, saber/1, personaje_de_charla/1, hilo/1, hilo_completo/0,
                    suceso/3, suceso_aqui/1, suceso_pendiente/1,
                    presentes/1, puede_hablar/1, charla_abierta/1, charla_hecha/1, charla_elegida/1,
                    opciones_de/2, puede_elegir/2, resolver_opcion/3,
                    efectos_apertura/2, efectos_eleccion/3, saberes/1, sabe/1]).
:- discontiguous presente/4, escena_de/2, opcion_charla/5, suceso/3.
:- use_module(mundo).
:- use_module(estado).
:- use_module(compania).
:- use_module(economia).

% ---------------------------------------------------------------------------
% Los datos.
% presente(Npc, Zona, Desde, Hasta): donde esta y entre que dias (inclusive; 99 = todo el juego).
% ---------------------------------------------------------------------------
presente(mantecosa,        taberna,     1, 99).
presente(gruyere,          taberna,     1,  5).
presente(alcaldesa_nata,   aldea,       1, 99).
presente(ricota,           aldea,       1,  5).
presente(penicilio,        bosque,      1, 99).
presente(ganso_recaudador, camino_real, 1, 99).
presente(rey_brieto,       castillo,    1, 99).
presente(el_eco,           cuevas,      1, 99).

% escena_de(Npc, Escena): la escena que cuenta cada uno.
escena_de(mantecosa,        la_cuenta).
escena_de(gruyere,          la_carreta).
escena_de(alcaldesa_nata,   las_quejas).
escena_de(ricota,           la_oferta).
escena_de(penicilio,        el_hambre_del_moho).
escena_de(ganso_recaudador, el_peaje).
escena_de(rey_brieto,       la_audiencia).
escena_de(el_eco,           lo_que_repites).

% opcion_charla(Escena, Opcion, Quien, Condiciones, Efectos):
%   Quien la hace (tiene que estar en pie); Condiciones: en_pie(Id), queso_min(N);
%   Efectos: ganar_queso(N), perder_queso(N), objeto(O), curar(grupo, N), moral(grupo|Id, N), saber(Marca).
opcion_charla(la_cuenta, jurar_honor, baldomero,
              [en_pie(baldomero)],
              [moral(grupo, 1)]).
opcion_charla(la_cuenta, invitar_al_caldo, pimentina,
              [en_pie(pimentina), queso_min(1)],
              [perder_queso(1), saber(moho_en_la_despensa)]).
opcion_charla(la_cuenta, mirar_los_desagues, tuerca,
              [en_pie(tuerca)],
              [ganar_queso(1), moral(rufino, -1)]).

opcion_charla(la_carreta, vengar_al_viajante, baldomero,
              [en_pie(baldomero)],
              [moral(baldomero, 1), saber(bandidos_a_caballo)]).
opcion_charla(la_carreta, consolar_con_una_balada, rufino,
              [en_pie(rufino)],
              [moral(grupo, 1)]).
opcion_charla(la_carreta, ayudarle_a_recoger, tuerca,
              [en_pie(tuerca)],
              [ganar_queso(1)]).

opcion_charla(las_quejas, escuchar_la_lista, baldomero,
              [en_pie(baldomero)],
              [saber(vacas_azules)]).
opcion_charla(las_quejas, curar_las_vacas, pimentina,
              [en_pie(pimentina), queso_min(1)],
              [perder_queso(1), ganar_queso(2)]).
opcion_charla(las_quejas, ojear_el_registro, tuerca,
              [en_pie(tuerca)],
              [moral(tuerca, 1)]).

opcion_charla(la_oferta, cantar_el_anuncio, rufino,
              [en_pie(rufino)],
              [objeto(pocion)]).
opcion_charla(la_oferta, regatear, tuerca,
              [en_pie(tuerca)],
              [ganar_queso(1), moral(tuerca, -1)]).
opcion_charla(la_oferta, preguntar_por_los_precios, pimentina,
              [en_pie(pimentina)],
              [moral(pimentina, 1)]).

opcion_charla(el_hambre_del_moho, hablar_con_el_moho, pimentina,
              [en_pie(pimentina)],
              [saber(moho_con_hambre)]).
opcion_charla(el_hambre_del_moho, amenazar_con_fuego, baldomero,
              [en_pie(baldomero)],
              [moral(baldomero, -1)]).
opcion_charla(el_hambre_del_moho, cantarle_al_moho, rufino,
              [en_pie(rufino)],
              [moral(rufino, 1), saber(moho_con_hambre)]).

opcion_charla(el_peaje, discutir_el_peaje, baldomero,
              [en_pie(baldomero)],
              [moral(baldomero, -1)]).
opcion_charla(el_peaje, pagar_el_peaje, pimentina,
              [en_pie(pimentina), queso_min(1)],
              [perder_queso(1), saber(gremio_sin_peaje)]).
opcion_charla(el_peaje, esquivar_al_ganso, tuerca,
              [en_pie(tuerca)],
              [moral(tuerca, 1)]).

opcion_charla(la_audiencia, hacer_la_reverencia, baldomero,
              [en_pie(baldomero)],
              [moral(grupo, 1)]).
opcion_charla(la_audiencia, preguntar_por_la_despensa, pimentina,
              [en_pie(pimentina)],
              [saber(brieto_firmo)]).
opcion_charla(la_audiencia, registrar_los_bolsillos_reales, tuerca,
              [en_pie(tuerca)],
              [ganar_queso(2), moral(baldomero, -1)]).

opcion_charla(lo_que_repites, cantar_a_la_cueva, rufino,
              [en_pie(rufino)],
              [moral(grupo, 1)]).
opcion_charla(lo_que_repites, gritarle_al_eco, baldomero,
              [en_pie(baldomero)],
              [moral(baldomero, -1)]).
opcion_charla(lo_que_repites, susurrar_una_pregunta, tuerca,
              [en_pie(tuerca)],
              [saber(el_eco_habla_solo)]).

% --- el segundo lote: los diez personajes de los grupos A y B (docs/12-npcs.md) ---
% Grupo A (dias 1 a 5) y grupo B (del 6 en adelante): en cada zona, uno fijo y uno que rota.
presente(inspectora_cuajaron, taberna,     6, 99).
presente(eustaquio,           aldea,       6, 99).
presente(seta_chismosa,       bosque,      1,  5).
presente(aldeano_perdido,     bosque,      6, 99).
presente(capitan_pecorino,    camino_real, 1,  5).
presente(bandido_arrepentido, camino_real, 6, 99).
presente(lord_tapanarices,    castillo,    1,  5).
presente(reina_viuda,         castillo,    6, 99).
presente(rata_exiliada,       cuevas,      1,  5).
presente(murcielago_azul,     cuevas,      6, 99).

escena_de(inspectora_cuajaron, la_auditoria).
escena_de(eustaquio,           la_cena).
escena_de(seta_chismosa,       el_cotilleo).
escena_de(aldeano_perdido,     el_camino).
escena_de(capitan_pecorino,    el_sermon).
escena_de(bandido_arrepentido, la_confesion).
escena_de(lord_tapanarices,    la_nariz).
escena_de(reina_viuda,         el_pesame).
escena_de(rata_exiliada,       la_guia).
escena_de(murcielago_azul,     los_chillidos).

opcion_charla(la_auditoria, firmar_sin_leer, baldomero,
              [en_pie(baldomero)],
              [moral(baldomero, -1)]).
opcion_charla(la_auditoria, pagar_la_tasa, pimentina,
              [en_pie(pimentina), queso_min(1)],
              [perder_queso(1), saber(gremio_oculta)]).
opcion_charla(la_auditoria, ojear_el_maletin, tuerca,
              [en_pie(tuerca)],
              [saber(gremio_oculta), moral(tuerca, -1)]).

opcion_charla(la_cena, escuchar_la_historia_entera, rufino,
              [en_pie(rufino)],
              [moral(grupo, 1), saber(principe_madura)]).
opcion_charla(la_cena, exigir_que_se_vaya, baldomero,
              [en_pie(baldomero)],
              [moral(baldomero, -1)]).
opcion_charla(la_cena, ofrecerle_una_cena, pimentina,
              [en_pie(pimentina), queso_min(1)],
              [perder_queso(1), saber(principe_madura)]).

opcion_charla(el_cotilleo, preguntar_por_si_mismo, baldomero,
              [en_pie(baldomero)],
              [moral(baldomero, -1)]).
opcion_charla(el_cotilleo, pedir_una_critica_de_baladas, rufino,
              [en_pie(rufino)],
              [moral(rufino, 1)]).
opcion_charla(el_cotilleo, preguntar_por_el_queso_escondido, tuerca,
              [en_pie(tuerca)],
              [ganar_queso(1)]).

opcion_charla(el_camino, acompanarle_a_casa, baldomero,
              [en_pie(baldomero)],
              [moral(baldomero, 1)]).
opcion_charla(el_camino, darle_de_comer, pimentina,
              [en_pie(pimentina), queso_min(1)],
              [perder_queso(1), objeto(pocion)]).
opcion_charla(el_camino, seguirle_por_un_atajo, tuerca,
              [en_pie(tuerca)],
              [moral(tuerca, -1)]).

opcion_charla(el_sermon, saludar_con_firmeza, baldomero,
              [en_pie(baldomero)],
              [moral(baldomero, 1)]).
opcion_charla(el_sermon, ofrecerle_una_marcha, rufino,
              [en_pie(rufino)],
              [moral(rufino, 1)]).
opcion_charla(el_sermon, preguntar_por_su_ronda, pimentina,
              [en_pie(pimentina)],
              [saber(pecorino_celoso)]).

opcion_charla(la_confesion, perdonarle_en_nombre_del_honor, baldomero,
              [en_pie(baldomero)],
              [moral(baldomero, 1)]).
opcion_charla(la_confesion, aceptar_el_queso_robado, tuerca,
              [en_pie(tuerca)],
              [ganar_queso(1)]).
opcion_charla(la_confesion, escribirle_una_balada_de_perdon, rufino,
              [en_pie(rufino)],
              [moral(grupo, 1)]).

opcion_charla(la_nariz, prestarle_un_panuelo, baldomero,
              [en_pie(baldomero)],
              [moral(baldomero, 1)]).
opcion_charla(la_nariz, cantar_para_distraer_la_nariz, rufino,
              [en_pie(rufino)],
              [moral(rufino, 1)]).
opcion_charla(la_nariz, venderle_aire_perfumado, tuerca,
              [en_pie(tuerca)],
              [moral(tuerca, 1)]).

opcion_charla(el_pesame, hacer_la_reverencia_de_luto, baldomero,
              [en_pie(baldomero)],
              [moral(grupo, 1)]).
opcion_charla(el_pesame, preguntar_por_su_hijo, pimentina,
              [en_pie(pimentina)],
              [saber(brieto_firmo)]).
opcion_charla(el_pesame, cantar_una_nana, rufino,
              [en_pie(rufino)],
              [moral(rufino, 1)]).

opcion_charla(la_guia, disculparse_por_el_granero, baldomero,
              [en_pie(baldomero)],
              [moral(baldomero, 1)]).
opcion_charla(la_guia, compartir_un_queso, pimentina,
              [en_pie(pimentina), queso_min(1)],
              [perder_queso(1), moral(grupo, 1)]).
opcion_charla(la_guia, preguntarle_por_las_cuevas, tuerca,
              [en_pie(tuerca)],
              [saber(ratas_huyen_de_abajo)]).

opcion_charla(los_chillidos, escuchar_los_chillidos, rufino,
              [en_pie(rufino)],
              [saber(sumiller_del_principe)]).
opcion_charla(los_chillidos, espantarlo_con_la_espada, baldomero,
              [en_pie(baldomero)],
              [moral(baldomero, -1)]).
opcion_charla(los_chillidos, ofrecerle_queso_azul, pimentina,
              [en_pie(pimentina), queso_min(1)],
              [perder_queso(1), moral(pimentina, 1)]).

% --- el tercer lote: las zonas del norte (paquete C, docs/12-npcs.md §8). Igual que las demas: uno fijo y dos que
% rotan (grupo A, dias 1 a 5; grupo B, del 6 en adelante) ---
presente(tia_feta,            granja,      1, 99).
presente(burrata,             granja,      1,  5).
presente(halloumi,            granja,      6, 99).
presente(bruja_gorgonzola,    pantano,     1, 99).
presente(rana_taleggio,       pantano,     1,  5).
presente(barquero_emmental,   pantano,     6, 99).
presente(capataz_manchego,    mina_de_sal, 1, 99).
presente(minero_cabrales,     mina_de_sal, 1,  5).
presente(topo_parmigiano,     mina_de_sal, 6, 99).

escena_de(tia_feta,          el_corral).
escena_de(burrata,           el_mugido).
escena_de(halloumi,          la_parrilla).
escena_de(bruja_gorgonzola,  el_caldero).
escena_de(rana_taleggio,     el_concierto).
escena_de(barquero_emmental, la_barca).
escena_de(capataz_manchego,  el_turno).
escena_de(minero_cabrales,   la_galeria).
escena_de(topo_parmigiano,   los_tuneles).

opcion_charla(el_corral, examinar_las_barbas, pimentina,
              [en_pie(pimentina)],
              [saber(barbas_azules)]).
opcion_charla(el_corral, ayudar_con_el_heno, baldomero,
              [en_pie(baldomero)],
              [moral(baldomero, 1)]).
% La gente del norte no da queso neto al hablar: el total de las charlas sigue en 8 (docs/12 §4, la economia no se toca).
% Lo que dan es moral, vida y diario; el queso del norte sale de los sucesos y de los contratos.
opcion_charla(el_corral, birlar_un_queso_de_la_quesera, tuerca,
              [en_pie(tuerca)],
              [moral(tuerca, -1)]).

opcion_charla(el_mugido, llamarla_vaca_con_respeto, baldomero,
              [en_pie(baldomero)],
              [moral(grupo, 1)]).
opcion_charla(el_mugido, ensenarle_a_balar, rufino,
              [en_pie(rufino)],
              [moral(rufino, 1)]).
opcion_charla(el_mugido, darle_queso_de_vaca, pimentina,
              [en_pie(pimentina), queso_min(1)],
              [perder_queso(1), curar(grupo, 3)]).

opcion_charla(la_parrilla, pedir_la_receta, pimentina,
              [en_pie(pimentina)],
              [moral(pimentina, 1), saber(queso_que_no_se_funde)]).
opcion_charla(la_parrilla, probar_sin_permiso, tuerca,
              [en_pie(tuerca)],
              [curar(grupo, 2)]).
opcion_charla(la_parrilla, cantar_junto_al_fuego, rufino,
              [en_pie(rufino)],
              [moral(grupo, 1)]).

opcion_charla(el_caldero, cocinar_con_ella, pimentina,
              [en_pie(pimentina), queso_min(1)],
              [perder_queso(1), moral(pimentina, 1), saber(moho_sube_por_los_arroyos)]).
opcion_charla(el_caldero, vigilar_el_caldero, baldomero,
              [en_pie(baldomero)],
              [moral(baldomero, -1)]).
opcion_charla(el_caldero, cantarle_al_caldero, rufino,
              [en_pie(rufino)],
              [saber(moho_sube_por_los_arroyos)]).

opcion_charla(el_concierto, hacer_un_duo, rufino,
              [en_pie(rufino)],
              [moral(rufino, 1)]).
opcion_charla(el_concierto, exigir_silencio, baldomero,
              [en_pie(baldomero)],
              [moral(baldomero, -1)]).
opcion_charla(el_concierto, buscar_entre_los_juncos, tuerca,
              [en_pie(tuerca)],
              [moral(tuerca, 1)]).

opcion_charla(la_barca, tapar_los_agujeros, pimentina,
              [en_pie(pimentina), queso_min(1)],
              [perder_queso(1), moral(grupo, 1)]).
opcion_charla(la_barca, remar_con_honor, baldomero,
              [en_pie(baldomero)],
              [moral(baldomero, 1)]).
opcion_charla(la_barca, regatear_el_pasaje, tuerca,
              [en_pie(tuerca)],
              [moral(tuerca, 1)]).

opcion_charla(el_turno, picar_un_turno, baldomero,
              [en_pie(baldomero)],
              [moral(baldomero, 1)]).
opcion_charla(el_turno, revisar_los_albaranes, tuerca,
              [en_pie(tuerca)],
              [saber(gremio_se_lleva_la_sal)]).
opcion_charla(el_turno, pedir_sal_para_las_heridas, pimentina,
              [en_pie(pimentina)],
              [curar(grupo, 3)]).

opcion_charla(la_galeria, cantar_una_cancion_de_mina, rufino,
              [en_pie(rufino)],
              [moral(grupo, 1)]).
opcion_charla(la_galeria, buscar_una_veta, tuerca,
              [en_pie(tuerca)],
              [moral(tuerca, 1)]).
opcion_charla(la_galeria, preguntar_por_el_sol, baldomero,
              [en_pie(baldomero)],
              [moral(baldomero, -1)]).

opcion_charla(los_tuneles, escuchar_sus_tuneles, pimentina,
              [en_pie(pimentina)],
              [saber(tuneles_hasta_las_cuevas)]).
opcion_charla(los_tuneles, ofrecerle_el_brazo, baldomero,
              [en_pie(baldomero)],
              [moral(baldomero, 1)]).
opcion_charla(los_tuneles, pedirle_un_atajo, tuerca,
              [en_pie(tuerca)],
              [moral(tuerca, -1)]).

% --- los sucesos de zona (docs/13-ampliacion.md §4): escenas unicas de un lugar, no de un personaje ---
% suceso(Id, Zona, Condiciones): se abren solos la primera vez que se llega o con `explorar`.
suceso(el_puente_de_setas,    bosque,      []).
suceso(el_pozo_de_los_deseos, aldea,       []).
suceso(la_carreta_del_gremio, camino_real, []).
suceso(la_bodega_del_rey,     castillo,    []).
suceso(el_altar_del_moho,     cuevas,      [sabe(moho_con_hambre)]).
suceso(la_valla_de_las_cabras, granja,      []).
suceso(la_isla_que_flota,      pantano,     []).
suceso(el_lago_de_salmuera,    mina_de_sal, []).

escena_de(el_puente_de_setas,    el_puente_de_setas).
escena_de(el_pozo_de_los_deseos, el_pozo_de_los_deseos).
escena_de(la_carreta_del_gremio, la_carreta_del_gremio).
escena_de(la_bodega_del_rey,     la_bodega_del_rey).
escena_de(el_altar_del_moho,     el_altar_del_moho).
escena_de(la_valla_de_las_cabras, la_valla_de_las_cabras).
escena_de(la_isla_que_flota,      la_isla_que_flota).
escena_de(el_lago_de_salmuera,    el_lago_de_salmuera).

opcion_charla(el_puente_de_setas, cruzar_de_puntillas, tuerca,
              [en_pie(tuerca)],
              [ganar_queso(1)]).
opcion_charla(el_puente_de_setas, endurecer_el_puente, pimentina,
              [en_pie(pimentina), queso_min(1)],
              [perder_queso(1), moral(grupo, 1)]).
opcion_charla(el_puente_de_setas, cruzar_con_la_armadura, baldomero,
              [en_pie(baldomero)],
              [moral(baldomero, -1)]).

opcion_charla(el_pozo_de_los_deseos, sacar_agua_para_todos, baldomero,
              [en_pie(baldomero)],
              [curar(grupo, 5)]).
opcion_charla(el_pozo_de_los_deseos, cantarle_al_fondo, rufino,
              [en_pie(rufino)],
              [moral(rufino, 1)]).
opcion_charla(el_pozo_de_los_deseos, pedir_un_deseo_de_queso, pimentina,
              [en_pie(pimentina), queso_min(1)],
              [perder_queso(1), moral(grupo, 1)]).

opcion_charla(la_carreta_del_gremio, colarse_en_la_carreta, tuerca,
              [en_pie(tuerca)],
              [ganar_queso(1)]).
opcion_charla(la_carreta_del_gremio, cantar_a_los_carreteros, rufino,
              [en_pie(rufino)],
              [moral(rufino, 1)]).
opcion_charla(la_carreta_del_gremio, hacerse_pasar_por_el_gremio, pimentina,
              [en_pie(pimentina), sabe(gremio_sin_peaje)],
              [objeto(pocion)]).

opcion_charla(la_bodega_del_rey, husmear_la_despensa, tuerca,
              [en_pie(tuerca)],
              [ganar_queso(1)]).
opcion_charla(la_bodega_del_rey, catar_el_queso_del_rey, pimentina,
              [en_pie(pimentina)],
              [moral(pimentina, -1)]).
opcion_charla(la_bodega_del_rey, bajar_a_la_bodega, baldomero,
              [en_pie(baldomero), sabe(moho_en_la_despensa)],
              [moral(baldomero, 1), saber(moho_en_la_bodega)]).

opcion_charla(el_altar_del_moho, dejarle_un_queso_al_moho, pimentina,
              [en_pie(pimentina), queso_min(1)],
              [perder_queso(1), moral(grupo, 1), saber(altar_alimentado)]).
opcion_charla(el_altar_del_moho, cantarle_una_nana_al_altar, rufino,
              [en_pie(rufino)],
              [moral(rufino, 1)]).
opcion_charla(el_altar_del_moho, tocar_el_moho, baldomero,
              [en_pie(baldomero)],
              [moral(baldomero, -1)]).

opcion_charla(la_valla_de_las_cabras, arreglar_la_valla, baldomero,
              [en_pie(baldomero)],
              [moral(baldomero, 1)]).
opcion_charla(la_valla_de_las_cabras, colarse_en_la_quesera, tuerca,
              [en_pie(tuerca)],
              [ganar_queso(1)]).
opcion_charla(la_valla_de_las_cabras, pastorear_con_musica, rufino,
              [en_pie(rufino)],
              [moral(grupo, 1)]).

opcion_charla(la_isla_que_flota, saltar_a_la_isla, tuerca,      % sin queso: los sucesos no pasan de 4 entre todos
              [en_pie(tuerca)],
              [moral(tuerca, 1)]).
opcion_charla(la_isla_que_flota, cuajar_la_isla, pimentina,
              [en_pie(pimentina), queso_min(1)],
              [perder_queso(1), objeto(pocion)]).
opcion_charla(la_isla_que_flota, vadear_con_la_armadura, baldomero,
              [en_pie(baldomero)],
              [moral(baldomero, -1)]).

opcion_charla(el_lago_de_salmuera, lavar_las_heridas_con_sal, pimentina,
              [en_pie(pimentina)],
              [curar(grupo, 5)]).
opcion_charla(el_lago_de_salmuera, banarse_con_la_armadura, baldomero,
              [en_pie(baldomero)],
              [moral(baldomero, -1)]).
opcion_charla(el_lago_de_salmuera, cantarle_al_lago, rufino,
              [en_pie(rufino)],
              [moral(rufino, 1)]).

% saber(Marca): los fragmentos de historia, en el orden en que los ensena el diario: primero las seis piezas
% del hilo del Gran Rancio y despues los de ambientacion.
saber(moho_en_la_despensa).
saber(moho_con_hambre).
saber(principe_madura).
saber(el_eco_habla_solo).
saber(gremio_oculta).
saber(brieto_firmo).
saber(gremio_sin_peaje).
saber(vacas_azules).
saber(bandidos_a_caballo).
saber(pecorino_celoso).
saber(ratas_huyen_de_abajo).
saber(sumiller_del_principe).
saber(moho_en_la_bodega).
saber(altar_alimentado).
saber(barbas_azules).                 % los del norte (paquete C): ambientacion, no entran en el hilo
saber(queso_que_no_se_funde).
saber(moho_sube_por_los_arroyos).
saber(gremio_se_lleva_la_sal).
saber(tuneles_hasta_las_cuevas).

% hilo(Marcas): las seis piezas con las que se entiende al Gran Roquefort. Con las seis, el diario cuenta la historia.
hilo([moho_en_la_despensa, moho_con_hambre, principe_madura, el_eco_habla_solo, gremio_oculta, brieto_firmo]).

% hilo_completo: ya se saben las seis piezas.
hilo_completo :-
    hilo(Marcas),
    \+ ( member(M, Marcas), \+ sabe(M) ).

% personaje_de_charla(?Npc): los que tienen escena.
personaje_de_charla(Npc) :-
    presente(Npc, _, _, _),
    escena_de(Npc, _).

% ---------------------------------------------------------------------------
% Quien esta y se puede hablar.
% ---------------------------------------------------------------------------
% puede_hablar(?Npc): esta en esta zona hoy y no hay combate (la regla que explica `hablar`).
puede_hablar(Npc) :-
    \+ estado:en_combate(_),
    estado:en_zona(Zona),
    estado:dia(Dia),
    presente(Npc, Zona, Desde, Hasta),
    Dia >= Desde,
    Dia =< Hasta.

% presentes(-Lista): los que hay aqui hoy, en el orden del reparto.
presentes(Lista) :-
    findall(Npc, ( presente(Npc, _, _, _), puede_hablar(Npc) ), Lista).

charla_hecha(Npc) :-
    estado:marca(charla_hecha(Npc)).

% charla_abierta(?Npc): se empezo, no se ha resuelto y sigue aqui.
charla_abierta(Npc) :-
    estado:marca(charla_abierta(Npc)),
    (   puede_hablar(Npc) ; suceso_aqui(Npc) ),
    !.

% charla_elegida(-Npc): la charla a la que va elegir/1. Puede haber dos abiertas a la vez (un suceso de la zona y la de
% un personaje con quien se acaba de hablar): manda la ULTIMA que se enseño (la marca charla_en_curso), si sigue abierta;
% si no, la primera abierta.
charla_elegida(Npc) :-
    estado:marca(charla_en_curso(N)),
    charla_abierta(N),
    !,
    Npc = N.
charla_elegida(Npc) :-
    charla_abierta(Npc),
    !.

% ---------------------------------------------------------------------------
% Los sucesos de zona: escenas unicas que pertenecen a un LUGAR y no a un personaje. Se abren solas la primera vez
% que se llega (si no hay otra cosa en marcha) o con `explorar`, y se resuelven con elegir/1 como una charla. Usan el
% mismo motor: sus opciones son opcion_charla/5 con el id del suceso en lugar del de un personaje.
%   suceso(Id, Zona, Condiciones): Condiciones del mismo vocabulario que las de las opciones (sabe(Marca), en_pie...).
% ---------------------------------------------------------------------------
% suceso_aqui(?Id): hay un suceso de esta zona cuyas condiciones se cumplen (se haya hecho o no).
suceso_aqui(Id) :-
    estado:en_zona(Zona),
    suceso(Id, Zona, Condiciones),
    cumple_condiciones(Condiciones).

% suceso_pendiente(?Id): esta aqui y aun no se ha resuelto (puede estar abierto a medias).
suceso_pendiente(Id) :-
    suceso_aqui(Id),
    escena_de(Id, _),
    \+ estado:marca(charla_hecha(Id)).

% sabe(?Marca): ya se ha averiguado.
sabe(Marca) :-
    estado:marca(sabe(Marca)).

% saberes(-Marcas): lo averiguado, en el orden de saber/1.
saberes(Marcas) :-
    findall(M, ( saber(M), sabe(M) ), Marcas).

% ---------------------------------------------------------------------------
% Las opciones.
% ---------------------------------------------------------------------------
% opciones_de(+Npc, -Lista): opcion(N, Opcion, Quien, Disponible) en orden de definicion.
opciones_de(Npc, Lista) :-
    escena_de(Npc, Escena),
    findall(Opcion-Quien, opcion_charla(Escena, Opcion, Quien, _, _), Pares),
    numerar(Pares, 1, Escena, Lista).

numerar([], _, _, []).
numerar([Opcion-Quien|Resto], N, Escena, [opcion(N, Opcion, Quien, Disponible)|Lista]) :-
    (   cumple_opcion(Escena, Opcion) -> Disponible = si ; Disponible = no ),
    N1 is N + 1,
    numerar(Resto, N1, Escena, Lista).

% cumple_opcion(+Escena, +Opcion): quien la hace esta en pie y se cumplen sus condiciones.
cumple_opcion(Escena, Opcion) :-
    opcion_charla(Escena, Opcion, Quien, Condiciones, _),
    compania:activo(Quien),
    cumple_condiciones(Condiciones).

cumple_condiciones([]).
cumple_condiciones([C|Resto]) :-
    condicion_ok(C),
    cumple_condiciones(Resto).

condicion_ok(en_pie(Id))   :- compania:en_pie(Id).
condicion_ok(queso_min(N)) :- economia:hay_queso_para(N).
condicion_ok(sabe(Marca))  :- sabe(Marca).                    % una opcion o suceso que solo existe si ya se sabe algo

% puede_elegir(?Npc, ?Opcion): la regla que explica `elegir` en una charla: esta abierta y la opcion se puede.
puede_elegir(Npc, Opcion) :-
    charla_abierta(Npc),
    escena_de(Npc, Escena),
    cumple_opcion(Escena, Opcion).

% resolver_opcion(+Npc, +LoEscrito, -Opcion): un numero (la N-esima) o el nombre de la opcion.
resolver_opcion(Npc, Escrito, Opcion) :-
    opciones_de(Npc, Lista),
    (   integer(Escrito)
    ->  memberchk(opcion(Escrito, Opcion, _, _), Lista)
    ;   atom(Escrito),
        memberchk(opcion(_, Escrito, _, _), Lista),
        Opcion = Escrito
    ).

% ---------------------------------------------------------------------------
% Efectos (datos; los aplica estado).
% ---------------------------------------------------------------------------
% efectos_apertura(+Npc, -Efectos): la charla se abre; el personaje habla.
efectos_apertura(Npc, [marcar(charla_abierta(Npc)), mensaje(charla_abre, [Npc])]).

% efectos_eleccion(+Npc, +Opcion, -Efectos): lo que pasa al elegir; la charla queda hecha para siempre.
efectos_eleccion(Npc, Opcion, Efectos) :-
    escena_de(Npc, Escena),
    opcion_charla(Escena, Opcion, _, _, Efectos04),
    expandir_todos(Efectos04, Propios),
    findall(mensaje(saber_nuevo, [M]), ( member(saber(M), Efectos04), \+ sabe(M) ), Nuevos),
    append([[mensaje(charla_elige, [Npc, Opcion])], Propios, Nuevos,
            [desmarcar(charla_abierta(Npc)), marcar(charla_hecha(Npc))]], Efectos).

expandir_todos([], []).
expandir_todos([E|Es], Efectos) :-
    expandir(E, Efs1),
    expandir_todos(Es, Efs2),
    append(Efs1, Efs2, Efectos).

expandir(ganar_queso(N), [ganar_queso(cheddar, 0, N)]).
expandir(perder_queso(N), Efs) :-
    economia:efectos_perdida(N, Efs).
expandir(moral(grupo, N), Efs) :-
    findall(mod_moral(Id, N), compania:activo(Id), Efs).
expandir(moral(Id, N), [mod_moral(Id, N)]) :-
    Id \== grupo.
expandir(saber(M), [marcar(sabe(M))]).
expandir(curar(grupo, N), Efs) :-
    findall(curar(Id, N), compania:activo(Id), Efs).
expandir(objeto(O), [ganar_objeto(compania, O, 1)]).
