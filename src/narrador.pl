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

:- module(narrador, [frase/3, texto/4, texto_error/2, ayuda_de/2, bienvenida/1, consejo_de_ayuda/2, texto_riesgo/2, texto_objetivo/3, texto_saber/2, descripcion_personaje/2, descripcion_opcion_charla/3,
                     comentario/4, comentario_prueba/4, nombre_visible/2, texto_recompensa/2,
                     descripcion_evento/2, descripcion_opcion/3,
                     claves_de_diag/2, clave_de_diag/2, comentario_diag/4,
                     comentarios_de_nodo/4, descripcion_contrato/2]).

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
      'Sin ración. No quedan quesos, ni ánimo, ni puntos de apoyo: la Banda se disuelve entre bostezos.\nNarrador: «Un mercenario sin queso es un caballero sin caballo. Con la salvedad de que Baldomero lo prefiere.»\nFin de la partida.').
frase(suceso(final(chapuza)), ambos,
      'Chapuza de toda la vida. Ganáis. Más o menos. El Gran Roquefort cae, el moho retrocede y el rey os paga... en dos plazos: el primero, hoy; el segundo, «cuando la despensa se recupere», que es una forma de decir «nunca».\nEl Registro os sube al puesto 31, con una nota a lápiz: «a confirmar». Baldomero jura que lo planeó todo y Pimentina ha probado el moho y opina que le falta fondo.\nNarrador: «Un éxito rotundo, en el sentido de que rodó escaleras abajo y llegó.»\nFin de la partida.').

% --- combate: un golpe, una caida y ponerse a la defensiva (X08 a X10 de docs/05, version corta) ---
frase(suceso(golpe(A, B, D)), ambos,
      '~w golpea a ~w y le quita ~w de vida. Cuentas claras, modales mejorables.'-[A, B, D]).
frase(suceso(golpe(A, B, D)), ambos,
      '~w le suelta un golpe a ~w: ~w de vida menos. Ha sido casi técnico.'-[A, B, D]).
frase(suceso(cae(B)), ambos,
      '~w cae redondo. Se levantará luego con 1 de vida y ninguna dignidad.'-[B]).
frase(suceso(evento_abre(rescate_gato)), ambos,
      'Su Excelencia Bigotes lleva tres días en lo alto del árbol y dice que desde allí se juzga mejor. Tenéis tres intentos y ninguna idea.').
frase(suceso(evento_elige(rescate_gato, trepar)), ambos,
      'Tuerca trepa sin ruido, saluda al gato con una reverencia y baja con él bajo el brazo. Las alturas le sientan bien.').
frase(suceso(evento_elige(rescate_gato, hechizo_de_raclette)), ambos,
      'Madame Pimentina enciende un hechizo de raclette y el gato baja solo, atraído por el olor y por la dignidad perdida. Cuesta un queso.').
frase(suceso(evento_elige(rescate_gato, sacudir_arbol)), ambos,
      'Sir Baldomero sacude el árbol por su honor. El gato cae, el árbol también y el pozo de la alcaldesa recibe a los dos.').
frase(suceso(evento_elige(rescate_gato, cantar)), ambos,
      'Rufino canta una balada. El gato la escucha entera y sube más alto, por prudencia.').
frase(suceso(intento_fallido(E, 0)), ambos,
      'Se acabaron los intentos en «~w». El gato se muda a otro árbol y la alcaldesa suspira con experiencia.'-[E]).
frase(suceso(intento_fallido(_, 1)), ambos,
      'Os queda un intento. Uno solo. El gato lo sabe.').
frase(suceso(intento_fallido(_, N)), ambos,
      'Os quedan ~w intentos.'-[N]).
frase(suceso(objetivo(C)), ambos,
      'Habéis llegado: «~w» os espera. Ahora toca ganarse el queso, que es lo que se espera de unos mercenarios.'-[C]).
frase(suceso(contrato_resuelto(C, exito)), ambos,
      'Contrato resuelto con éxito: «~w». La recompensa os espera en la taberna, en cuanto Doña Mantecosa deje de contarla.'-[C]).
frase(suceso(contrato_resuelto(C, a_medias)), ambos,
      'Contrato resuelto a medias: «~w». A medias es mejor que nada, y bastante peor que todo.'-[C]).
frase(suceso(contrato_resuelto(C, fracaso)), ambos,
      'Contrato fracasado: «~w». Se queda en el tablón, por si a alguien le queda dignidad para otro intento.'-[C]).
frase(suceso(cobra(C)), ambos,
      'Cobráis por «~w». Los quesos entran en la despensa y los sueldos, como siempre, esperan su turno.'-[C]).
% Un contrato que aparece de pronto en el tablon (por ejemplo, al visitar el castillo): hay que avisarlo.
frase(suceso(contrato_nuevo(despensa_real)), ambos,
      'Corre la voz: el rey Brieto busca a los peores contra el Gran Roquefort. Nuevo contrato final en el tablón: «La Despensa Real».').
frase(suceso(contrato_nuevo(C)), ambos,
      'Hay un contrato nuevo en el tablón: «~w».'-[C]).
frase(suceso(acepta(C)), ambos,
      'Contrato aceptado: «~w». Todos asienten con convicción; nadie ha leído la letra pequeña.'-[C]).
frase(suceso(aparece(T)), ambos,
      '~w se interpone en tu camino. Nadie ha preguntado si tenía permiso.'-[T]).
frase(suceso(victoria), ambos,
      'Victoria. Nadie la esperaba, y menos que nadie la propia Banda.').
frase(suceso(sin_botin), ambos,
      'Registráis los restos con todo el cuidado de un recaudador: ni una corteza. Hoy los bolsillos de esta gente estaban de huelga.').
% --- hablar con la gente (docs/12-npcs.md): lo que dice cada personaje al abrir su escena, lo que pasa al elegir y el diario ---
frase(suceso(charla_repite(Npc)), ambos,
      'Ya habéis hablado con ~w. «Ya os lo he dicho», responde, con cara de quien no piensa repetirlo.'-[Npc]).

frase(suceso(charla_abre(mantecosa)), ambos,
      'Doña Mantecosa seca una jarra con el mismo trapo con el que limpia la mesa. «El moho. Lo huelo desde hace tres inviernos, desde que el rey me compró queso y lo devolvió "para afinarlo". Ahora sale por mis desagües. Yo no digo nada, pero la sopa ya no es de ayer: es de anteayer».').
frase(suceso(charla_elige(mantecosa, jurar_honor)), ambos,
      'Baldomero jura con la mano en el pecho. Doña Mantecosa asiente: «El honor no paga la cuenta, pero queda bien en la pared.» La Banda se siente un poco más importante.').
frase(suceso(charla_elige(mantecosa, invitar_al_caldo)), ambos,
      'Pimentina paga el caldo. Doña Mantecosa, ablandada por exactamente un queso, suelta lo que sabía: el moho empezó en la despensa del rey.').
frase(suceso(charla_elige(mantecosa, mirar_los_desagues)), ambos,
      'Tuerca vuelve de los desagües con un queso y cara de haberse equivocado de oficio. Rufino ha tenido que olerlo y su ánimo se resiente.').

frase(suceso(charla_abre(gruyere)), ambos,
      'Gruyère, un viajante con el sombrero en la mano, mira su jarra vacía. «Perdí la carreta en el Camino Real. Eran cuatro bandidos, y uno venía a caballo: ese ni lo vi, solo lo oí. Nadie me cree.» Suspira con todo el cuerpo.').
frase(suceso(charla_elige(gruyere, vengar_al_viajante)), ambos,
      'Baldomero se hincha de honor y Gruyère le cuenta con detalle lo de los jinetes del camino. A Baldomero se le va el color: acaba de enterarse de que hay caballos.').
frase(suceso(charla_elige(gruyere, consolar_con_una_balada)), ambos,
      'La balada es mala, pero larga. Gruyère llora, se suena con el sombrero y jura que ya no se siente solo. La Banda sale animada.').
frase(suceso(charla_elige(gruyere, ayudarle_a_recoger)), ambos,
      'Tuerca recoge el petate con tanta eficacia que le sobra un queso. Gruyère no se da cuenta: sigue mirando la jarra.').

frase(suceso(charla_abre(alcaldesa_nata)), ambos,
      'La alcaldesa Nata despliega una lista de quejas que llega al suelo. «Las vacas dan leche con vetas azules desde hace semanas, el rodillo del panadero se oxida y nadie me pregunta nada. ¿Les importa si empiezo por el principio?» Y empieza por el principio.').
frase(suceso(charla_elige(alcaldesa_nata, escuchar_la_lista)), ambos,
      'Baldomero escucha la lista entera. Le duele el honor a partir de la queja noventa, pero la alcaldesa se desahoga y cuenta que la leche sale azul desde que empezó el moho.').
frase(suceso(charla_elige(alcaldesa_nata, curar_las_vacas)), ambos,
      'El remedio de Pimentina no cura a las vacas, pero alegra a la alcaldesa, que deja dos quesos «para la causa». El saldo, a favor.').
frase(suceso(charla_elige(alcaldesa_nata, ojear_el_registro)), ambos,
      'Tuerca no encuentra nada valioso, pero descubre su propia queja en la lista (la 212: «el ladrón»). Se siente visto y, extrañamente, orgulloso.').

frase(suceso(charla_abre(ricota)), ambos,
      'Ricota, el tendero, os enseña su estante con una sonrisa de oferta permanente. «¡Hoy todo a mitad de precio! Bueno, hoy y siempre. Aquí no se vende queso, ya lo sabéis, pero se hace buen negocio con el aire».').
frase(suceso(charla_elige(ricota, cantar_el_anuncio)), ambos,
      'Rufino compone «Oferta eterna» en tres minutos. Ricota, emocionado, le paga con una poción «de muestra»: el primer pago por música de la historia de la aldea.').
frase(suceso(charla_elige(ricota, regatear)), ambos,
      'Tuerca regatea tan bien que Ricota le da un queso para que se vaya. Pero ahora lo miran mal en la aldea y Tuerca pierde ánimo.').
frase(suceso(charla_elige(ricota, preguntar_por_los_precios)), ambos,
      'Pimentina anota los precios con interés profesional. No saca nada, pero se siente muy informada y de buen humor.').

frase(suceso(charla_abre(penicilio)), ambos,
      'El Hermano Penicilio levanta la vista de una seta con la que discutía. «No lo llaméis plaga. El moho no es malo: tiene hambre. Viene de abajo, de las cuevas, y come lo que encuentra. Si nadie le da otra cosa...», suspira.').
frase(suceso(charla_elige(penicilio, hablar_con_el_moho)), ambos,
      'Pimentina se arrodilla junto a la seta y entiende dos palabras: «queso» y «ya». El Hermano asiente: el moho viene de las cuevas y tiene hambre de verdad.').
frase(suceso(charla_elige(penicilio, amenazar_con_fuego)), ambos,
      'Baldomero blande la espada. Penicilio no se inmuta; la seta sí: se esconde. Baldomero se siente mal por haber asustado a una seta y su ánimo baja.').
frase(suceso(charla_elige(penicilio, cantarle_al_moho)), ambos,
      'La nana de Rufino hace brotar un hongo que baila. Penicilio llora de gusto y cuenta lo del hambre. Rufino sale encantado de sí mismo.').

frase(suceso(charla_abre(ganso_recaudador)), ambos,
      'Un ganso con tricornio y libro de cuentas corta el camino. «Peaje. Un queso por Banda. Si no se paga, se discute, y se discute siempre.» Detrás, una carreta del Gremio pasa sin detenerse ni pagar.').
frase(suceso(charla_elige(ganso_recaudador, discutir_el_peaje)), ambos,
      'Baldomero discute media hora sobre el concepto de peaje. El ganso gana por cansancio. La Banda pasa, pero el honor ha sufrido.').
frase(suceso(charla_elige(ganso_recaudador, pagar_el_peaje)), ambos,
      'Pimentina paga con una sonrisa. El ganso, enternecido, murmura que el Gremio nunca paga peaje: «Ellos tienen sello».').
frase(suceso(charla_elige(ganso_recaudador, esquivar_al_ganso)), ambos,
      'Tuerca se cuela por la cuneta sin pagar y sin que el ganso mueva el cuello. Se siente un artista.').

frase(suceso(charla_abre(rey_brieto)), ambos,
      'El rey Brieto IV os recibe con las manos juntas y un pañuelo perfumado. «¡Mis queridos mercenarios! Disculpad la peste: mi despensa tiene... carácter. Todo empezó cuando firmé aquello de las cuevas. ¿Qué firmé? Pues no lo sé: la letra era pequeña».').
frase(suceso(charla_elige(rey_brieto, hacer_la_reverencia)), ambos,
      'Baldomero se inclina tanto que se oye una vértebra. El rey aplaude, los cortesanos suspiran de alivio y la Banda sale con la cabeza más alta.').
frase(suceso(charla_elige(rey_brieto, preguntar_por_la_despensa)), ambos,
      'Pimentina pregunta con mucho tacto. El rey, abochornado, confiesa que firmó el permiso para «afinar» el queso en las cuevas sin leer la letra pequeña.').
frase(suceso(charla_elige(rey_brieto, registrar_los_bolsillos_reales)), ambos,
      'Tuerca vacía dos quesos del manto real sin que nadie se dé cuenta. Baldomero sí, y le pesa en la conciencia. Su ánimo baja.').

frase(suceso(charla_abre(el_eco)), ambos,
      'En el fondo de la cueva algo repite cada una de vuestras palabras, un segundo tarde y con otra voz. «Eco... eco...», dice. Luego, más bajo y sin que nadie le haya preguntado: «...cuánto tiempo...».').
frase(suceso(charla_elige(el_eco, cantar_a_la_cueva)), ambos,
      'La cueva devuelve la canción con una armonía que Rufino no había escrito. Nadie sabe quién canta la tercera voz, pero la Banda sale con ánimo.').
frase(suceso(charla_elige(el_eco, gritarle_al_eco)), ambos,
      'Baldomero grita «¡Soy Baldomero!». La cueva responde, con calma: «...sí, ya lo sé...». No le gusta que le contesten y su ánimo baja.').
frase(suceso(charla_elige(el_eco, susurrar_una_pregunta)), ambos,
      'Tuerca susurra «¿hay tesoro?». Tras una pausa larga, la cueva contesta: «...no. Hay hambre... y alguien que lleva siglos hablando solo...».').

% El diario: una linea por cada fragmento averiguado (texto_saber/2 usa estas mismas frases).
frase(suceso(saber_nuevo(moho_en_la_despensa)), ambos,
      'Diario: el moho empezó hace tres inviernos en la despensa del rey.').
frase(suceso(saber_nuevo(moho_con_hambre)), ambos,
      'Diario: el moho no es malo: tiene hambre, y viene de las cuevas.').
frase(suceso(saber_nuevo(brieto_firmo)), ambos,
      'Diario: el rey firmó el permiso para afinar queso en las cuevas sin leer la letra pequeña.').
frase(suceso(saber_nuevo(el_eco_habla_solo)), ambos,
      'Diario: el eco de las cuevas no repite: contesta con la voz de alguien que lleva siglos hablando solo.').
frase(suceso(saber_nuevo(gremio_sin_peaje)), ambos,
      'Diario: el Gremio cruza el Camino Real sin pagar peaje: tiene sello.').
frase(suceso(saber_nuevo(vacas_azules)), ambos,
      'Diario: en la aldea la leche sale con vetas azules desde que empezó el moho.').
frase(suceso(saber_nuevo(bandidos_a_caballo)), ambos,
      'Diario: en el Camino Real hay bandidos a caballo, y a Baldomero los caballos le dan pavor.').

% --- el segundo lote de charlas: los diez personajes de los grupos A y B ---
frase(suceso(charla_abre(capitan_pecorino)), ambos,
      'El capitán Pecorino Duro os corta el paso con una armadura tan pulida que se ve a sí mismo y no le gusta. «Mercenarios. Sois como la humedad: nadie os quiere, pero siempre estáis. Un consejo gratis, que no cobro: si os topáis con un jinete, no corráis. Los caballos huelen el miedo. Y el queso».').
frase(suceso(charla_elige(capitan_pecorino, saludar_con_firmeza)), ambos,
      'Baldomero se cuadra con un taconazo que levanta polvo. Pecorino asiente, a regañadientes: «Al menos este sabe saludar». Baldomero se siente, por un momento, de la guardia real.').
frase(suceso(charla_elige(capitan_pecorino, ofrecerle_una_marcha)), ambos,
      'Rufino toca una marcha militar con el laúd. Pecorino aguanta tres compases con la barbilla en alto y al cuarto empieza a marcar el paso sin darse cuenta. Rufino sale convencido de su talento.').
frase(suceso(charla_elige(capitan_pecorino, preguntar_por_su_ronda)), ambos,
      'Pimentina pregunta por su ronda con interés sincero. Pecorino se desahoga: lleva meses esperando que el rey lo contrate a él y no a «gente de saldo». Se arrepiente a medias y se aleja marcando el paso.').

frase(suceso(charla_abre(seta_chismosa)), ambos,
      'Una seta del tamaño de una silla se inclina hacia vosotros y baja la voz, que en una seta es subir el volumen. «Psst. Yo lo sé todo de todos. De vosotros, por ejemplo, sé más de lo que me conviene. ¿Qué queréis saber?» Y se relame, que en una seta es ensancharse.').
frase(suceso(charla_elige(seta_chismosa, preguntar_por_si_mismo)), ambos,
      'La seta no se corta: «Dicen que teme a los caballos y que duerme con la armadura puesta». Baldomero se queda mudo, que es su forma de reconocerlo, y su ánimo baja.').
frase(suceso(charla_elige(seta_chismosa, pedir_una_critica_de_baladas)), ambos,
      'La seta se lo piensa un buen rato: «Las he oído desde el bosque. Los hongos aplauden». Rufino no sabe si es un cumplido, pero lo toma como tal y se anima.').
frase(suceso(charla_elige(seta_chismosa, preguntar_por_el_queso_escondido)), ambos,
      'La seta lo señala con el sombrero: «Bajo la tercera raíz». Tuerca escarba y encuentra un queso olvidado por alguien con peor memoria que él.').

frase(suceso(charla_abre(aldeano_perdido)), ambos,
      'Un aldeano con barba de tres días y cara de seis os mira con alivio. «¡Gente! Salí a buscar setas y llevo tres días buscando la salida. El bosque se ha movido. Estoy casi seguro de que se ha movido».').
frase(suceso(charla_elige(aldeano_perdido, acompanarle_a_casa)), ambos,
      'Baldomero lo lleva a su aldea con paso firme y el aldeano le da las gracias llorando. El honor de un caballero se mide en barbas rescatadas, y Baldomero se siente rico.').
frase(suceso(charla_elige(aldeano_perdido, darle_de_comer)), ambos,
      'Pimentina le da un queso y el aldeano, agradecido, rebusca en su zurrón y le regala una poción de su abuela. Dice que sabe a abuela y que cura casi todo. Pimentina decide no preguntar el «casi».').
frase(suceso(charla_elige(aldeano_perdido, seguirle_por_un_atajo)), ambos,
      'El atajo da la vuelta al mismo árbol cuatro veces. Tuerca vuelve cansado y de mal humor, con la sensación de haber pagado por algo que era gratis: perderse.').

frase(suceso(charla_abre(lord_tapanarices)), ambos,
      'Lord Tapanarices pasea por el patio con una pinza en la nariz y un pañuelo perfumado en cada mano. «Disculpad que no os dé la mano: la necesito para respirar. Esto no era así. Antes olíamos a nata y a poder. Ahora olemos a... decisiones».').
frase(suceso(charla_elige(lord_tapanarices, prestarle_un_panuelo)), ambos,
      'Baldomero le da su pañuelo, que el lord acepta como quien acepta un título. Se despide con una reverencia y Baldomero se siente un poco menos plebeyo.').
frase(suceso(charla_elige(lord_tapanarices, cantar_para_distraer_la_nariz)), ambos,
      'Rufino canta una balada sobre flores. El lord llora un poco y aplaude con el pañuelo. Es el mejor público que ha tenido Rufino desde que cantó para un fantasma.').
frase(suceso(charla_elige(lord_tapanarices, venderle_aire_perfumado)), ambos,
      'Tuerca llena un frasco con el aire del patio y lo vende como «Brisa de Alcoba Real». El lord lo paga con elogios: «¡Qué bouquet!». Tuerca no cobra nada, pero se siente un artista del comercio, que es mejor que cobrar.').

frase(suceso(charla_abre(reina_viuda)), ambos,
      'La reina viuda Nata Doble os recibe en una sala llena de retratos de su hijo, todos con la misma cara de «¿dónde firmo?». «Mi Brieto era un niño encantador. Firmaba todo lo que le ponían delante. Todo. Con letra preciosa. Y sin leer ni una línea».').
frase(suceso(charla_elige(reina_viuda, hacer_la_reverencia_de_luto)), ambos,
      'Baldomero se inclina con tanto sentimiento que la reina viuda lo confunde con un pariente lejano y le pellizca una mejilla. La Banda sale con la moral alta y el pómulo de Baldomero, no tanto.').
frase(suceso(charla_elige(reina_viuda, preguntar_por_su_hijo)), ambos,
      'La reina viuda suspira: su hijo firmó el permiso de las cuevas porque ponía «afinar» y sonaba bien. Lo cuenta como quien cuenta una travesura, sin imaginar que es una catástrofe.').
frase(suceso(charla_elige(reina_viuda, cantar_una_nana)), ambos,
      'La reina viuda cierra los ojos y sonríe: lleva años sin que nadie le cante. Rufino sale con la garganta caliente y el ánimo alto.').

frase(suceso(charla_abre(rata_exiliada)), ambos,
      'Una rata de pelaje gris, con una gorra de guía de cuevas, os saluda desde una roca. «¿Venís a matarme? Ya me mataron media familia en el granero. Yo escapé: por listo. Y ahora, por no tener otro oficio, enseño las cuevas. Gratis, que las propinas me dan un poco de vergüenza».').
frase(suceso(charla_elige(rata_exiliada, disculparse_por_el_granero)), ambos,
      'Baldomero se disculpa con la mano en el pecho y la rata asiente con dignidad: «Cosas del oficio». Baldomero se siente más noble y un poquito culpable, que es lo mismo.').
frase(suceso(charla_elige(rata_exiliada, compartir_un_queso)), ambos,
      'La rata come con delicadeza, mirando a Pimentina con respeto: «Hay quien nos echa. Hay quien nos da de comer. Os recordaré». Todos salen con la sensación de haber hecho algo bueno por casi nada.').
frase(suceso(charla_elige(rata_exiliada, preguntarle_por_las_cuevas)), ambos,
      'La rata se pone seria: «Nos fuimos del fondo porque allí abajo ya no queda nada de comer. Lo que hay, tiene hambre». Y se pone a limpiarse los bigotes para no pensarlo.').

frase(suceso(charla_abre(murcielago_azul)), ambos,
      'Un murciélago azul, colgado boca abajo, os mira con un ojo, luego con el otro, luego con ambos. Chilla algo agudo y largo. Por el tono, no parece insultar. Por la duración, parece que cuenta una historia.').
frase(suceso(charla_elige(murcielago_azul, escuchar_los_chillidos)), ambos,
      'Rufino, que sabe de agudos, traduce: el murciélago fue sumiller del príncipe Roque y catalogaba sus quesos por el olor. Hoy no queda nada que catalogar, salvo al propio príncipe.').
frase(suceso(charla_elige(murcielago_azul, espantarlo_con_la_espada)), ambos,
      'Baldomero agita la espada y el murciélago cambia de rama con gran calma. Baldomero guarda la espada con la sensación de haber perdido una discusión con alguien que no habla.').
frase(suceso(charla_elige(murcielago_azul, ofrecerle_queso_azul)), ambos,
      'El murciélago lo huele, lo mira, lo desprecia con elegancia y se lo come entero. Pimentina se siente juzgada por un murciélago y, curiosamente, mejor persona.').

frase(suceso(charla_abre(eustaquio)), ambos,
      'Un mayordomo translúcido se endereza la corbata inexistente. «Sirvo al príncipe Roque de Fort desde antes de que él supiera pronunciarlo. Un día me dijo: "Eustaquio, voy a madurar un poco". Eso fue hace trescientos años. Mi cena sigue sin llegar. ¿Querrían escuchar la historia completa? Dura tres días. Les haré una versión de tres minutos».').
frase(suceso(charla_elige(eustaquio, escuchar_la_historia_entera)), ambos,
      'Rufino escucha, toma notas y compone «La cena del príncipe» de un trago. El fantasma se emociona y cuenta cómo el príncipe se retiró a las cuevas a «madurar» y dijo que volvería cuando estuviera en su punto. La Banda sale conmovida.').
frase(suceso(charla_elige(eustaquio, exigir_que_se_vaya)), ambos,
      'Baldomero exige con voz de espada. Eustaquio se ofende tanto que se vuelve casi transparente del todo y se calla. No hay historia: solo un mayordomo muy digno que ya no habla con vosotros.').
frase(suceso(charla_elige(eustaquio, ofrecerle_una_cena)), ambos,
      'Pimentina le sirve un plato imaginario con un queso de verdad al lado. El fantasma llora de gratitud sobre el plato y confiesa lo del príncipe: se fue a «madurar» y no volvió.').

frase(suceso(charla_abre(inspectora_cuajaron)), ambos,
      'Una mujer de gafas redondas y maletín cuadrado revisa la taberna con un bolígrafo. «Inspectora Cuajarón, del Gremio de Afinadores. Una auditoría rutinaria. Rutinaria, quiero decir, para mí. Para ustedes, no sé: depende de lo que encuentre».').
frase(suceso(charla_elige(inspectora_cuajaron, firmar_sin_leer)), ambos,
      'Baldomero firma con letra de caballero y la inspectora sonríe como quien suma. Más tarde descubrirá que ha firmado una multa. El honor, a veces, se paga en quesos que aún no tiene.').
frase(suceso(charla_elige(inspectora_cuajaron, pagar_la_tasa)), ambos,
      'Pimentina paga y la inspectora, de mejor humor, deja escapar un comentario: el Gremio sabe de lo que pasa en las cuevas desde hace años, pero ha preferido callar para que no se hunda el precio del queso.').
frase(suceso(charla_elige(inspectora_cuajaron, ojear_el_maletin)), ambos,
      'Tuerca descubre un informe sobre las cuevas: «SE SABE. NO SE DICE». La inspectora lo pilla leyendo y le da un manotazo con la carpeta. Tuerca sale con el dato y el amor propio magullado.').

frase(suceso(charla_abre(bandido_arrepentido)), ambos,
      'Un bandido sin caballo, con la cara de quien no ha dormido desde el último robo, os sale al paso con las manos en alto. «No os asaltaré, lo juro. Me he vuelto honrado. Es muy aburrido, pero se duerme mejor. ¿Aceptaríais mi arrepentimiento? Es lo único que me queda».').
frase(suceso(charla_elige(bandido_arrepentido, perdonarle_en_nombre_del_honor)), ambos,
      'Baldomero lo perdona con una solemnidad que hace llorar al bandido. Es el primer perdón oficial de la Banda y le sienta tan bien a Baldomero que se queda un rato mirando el horizonte.').
frase(suceso(charla_elige(bandido_arrepentido, aceptar_el_queso_robado)), ambos,
      'El bandido devuelve un queso que robó hace semanas, un poco mohoso. Tuerca lo acepta con la profesionalidad de quien sabe dónde acaban esas cosas.').
frase(suceso(charla_elige(bandido_arrepentido, escribirle_una_balada_de_perdon)), ambos,
      'Rufino compone «El bandido que quiso ser bueno» en un cuarto de hora. El bandido llora, la Banda también y hasta un cuervo cercano aplaude con un ala.').

% Los fragmentos nuevos del diario (los dos que cierran el hilo y tres de ambientacion).
frase(suceso(saber_nuevo(principe_madura)), ambos,
      'Diario: el último príncipe de Roquefort se retiró a «madurar un poco» y no ha vuelto.').
frase(suceso(saber_nuevo(gremio_oculta)), ambos,
      'Diario: el Gremio sabe lo de las cuevas desde hace años y lo calla para no hundir el precio del queso.').
frase(suceso(saber_nuevo(pecorino_celoso)), ambos,
      'Diario: el capitán Pecorino quiere que el rey lo contrate a él y no a mercenarios.').
frase(suceso(saber_nuevo(ratas_huyen_de_abajo)), ambos,
      'Diario: las ratas huyeron de las cuevas: allí abajo ya no queda nada de comer.').
frase(suceso(saber_nuevo(sumiller_del_principe)), ambos,
      'Diario: el murciélago azul fue el sumiller del príncipe Roque y lo conoce por el olor.').

% La ultima pagina: cuando se saben las seis piezas del hilo, el narrador junta la historia.
frase(suceso(diario_completo), ambos,
      'Última página del diario: el príncipe Roque de Fort se retiró a las cuevas a «madurar»; el moho que sale de allí solo tiene hambre; el Gremio lo supo y lo calló; el rey firmó el permiso sin leerlo y su despensa se pudre. El Gran Roquefort no es un monstruo: es un príncipe al que nadie fue a buscar.').

frase(suceso(botin(1)), ambos,
      'Botín: 1 queso fresco. Lo guardaba «para emergencias». Esto lo era.').
frase(suceso(botin(N)), ambos,
      'Botín: ~w quesos frescos. Los guardaban «para emergencias». Esto lo era.'-[N]).
frase(suceso(derrota_combate), ambos,
      'Cuajados. El moho avanza. Una a una, las cuatro botas se quedan pegadas al suelo de la cueva y Doña Mantecosa añade vuestro nombre al tablón de incobrables.\nNarrador: «Intentadlo de nuevo, esta vez con más queso y menos honor.»\nFin de la partida.').
frase(suceso(aturdido(A)), ambos,
      '~w pierde el turno, aturdido de pies a cabeza. Mira las estrellas, que hoy están muy cerca.'-[A]).
frase(suceso(pasa(E)), ambos,
      '~w no sabe qué hacer y se queda mirando. Es su mejor táctica.'-[E]).
frase(suceso(usa_objeto(O, M, N)), ambos,
      'Gasto de botiquín: ~w para ~w (+~w de vida). Sabe a medicina de queso.'-[O, M, N]).
frase(suceso(se_cura(E, N)), ambos,
      '~w se bebe lo que lleva encima y recupera ~w de vida. Hasta los malos tienen botiquín.'-[E, N]).
frase(suceso(invoca_moho(E)), ambos,
      '~w murmura algo antiguo y de la pared se despega un moho saltarín, con ganas de conocer gente.'-[E]).
frase(suceso(roba_queso(E)), ambos,
      '~w se lleva un queso de la despensa mientras todos miran el combate. Roba con una técnica impecable.'-[E]).
frase(suceso(embiste(E, B, D)), ambos,
      '~w embiste a ~w con todo el peso del caballo y le quita ~w de vida. El jinete se lleva el mérito.'-[E, B, D]).
frase(suceso(carga_heroica(B)), ambos,
      'Sir Baldomero grita «¡Por mi honor!» y carga contra ~w. Hay más honor que puntería, pero llega.'-[B]).
frase(suceso(fondue(B)), ambos,
      'Madame Pimentina lanza una Fondue Flamígera contra ~w. Huele a cena y a problemas para el enemigo.'-[B]).
frase(suceso(balada), ambos,
      'Rufino entona la Balada Inspiradora. La moral sube; los oídos se despiden.').
frase(suceso(rebuscar(E, ok)), ambos,
      'Tuerca rebusca en los bolsillos de ~w y encuentra un queso. «Lo tomo prestado», dice.'-[E]).
frase(suceso(rebuscar(E, nada)), ambos,
      'Tuerca rebusca en ~w y no halla nada. Se queda con la dignidad, que no cotiza.'-[E]).
frase(suceso(golpea_a_clotilde(E, N)), ambos,
      '~w se abalanza sobre Lady Clotilde y le arranca una pluma (golpe ~w). Ella lo anota para la factura.'-[E, N]).
frase(suceso(nivel(resumido)), ambos,
      'Nivel resumido: las explicaciones salen plegadas a lo esencial. Para ver todo, nivel(detallado).').
frase(suceso(nivel(detallado)), ambos,
      'Nivel detallado: las explicaciones salen enteras, con todas las cláusulas y todas las pruebas. Para acortarlas, nivel(resumido).').
frase(suceso(golpe(A, B, D)), ambos,
      'Golpe de ~w a ~w: ~w puntos. Limpio, correcto y olvidable.'-[A, B, D]).
frase(suceso(golpe(A, B, D)), ambos,
      '~w alcanza a ~w y le quita ~w. Un testigo toma nota; otro, distancia.'-[A, B, D]).
frase(suceso(aparece(T)), ambos,
      '~w te corta el paso con la seguridad de quien no ha leído tu historial.'-[T]).
frase(suceso(aparece(gran_roquefort)), ambos,
      'Al fondo de las Cuevas, algo azul y enorme se mueve despacio. Tiene barba de moho y opiniones firmes.').
frase(suceso(cae(rata_quesera)), ambos,
      'La Rata Quesera se tumba, cierra los ojos y espera. Esta vez es en serio. Ofendida, pero en serio.').
frase(suceso(cae(moho_saltarin)), ambos,
      'El Moho Saltarín se deshace en esporas y en disculpas, por ese orden.').
frase(suceso(cae(bandido_torpe)), ambos,
      'El Bandido Torpe huye gritando «¡Esto no ha pasado!». Ha pasado, y con testigos.').
frase(suceso(cae(bandido_montado)), ambos,
      'El Bandido Montado se baja del caballo a la fuerza y le pide perdón al caballo, que no escucha.').
frase(suceso(cae(gran_roquefort)), ambos,
      'El Gran Roquefort suspira, se agrieta y murmura: «Quizá sí tenía prisa». El moho se retira.').
frase(suceso(cae(P)), ambos,
      '~w cae y decide que es un buen momento para reflexionar tumbado.'-[P]).
frase(suceso(victoria), ambos,
      'Victoria. Se recoge el botín, se cuenta el queso y se niega todo lo que haya salido mal.').
frase(suceso(victoria), ambos,
      'El combate acaba a vuestro favor. Es la clase de noticia que la Banda nunca sabe dónde guardar.').
frase(suceso(victoria), ambos,
      'Habéis ganado. Un par de testigos aplauden; el resto prefiere no mojarse.').
frase(suceso(carga_heroica(B)), ambos,
      'Carga heroica: Sir Baldomero baja la visera, cierra los ojos y avanza hacia ~w. Funciona.'-[B]).
frase(suceso(balada), ambos,
      'Rufino canta. El grupo se anima, el enemigo se desanima y los pájaros emigran.').
frase(suceso(defiende(P)), ambos,
      '~w levanta la guardia, la ceja y la moral. En ese orden.'-[P]).
frase(suceso(dia_nuevo(D, N)), ambos,
      'Día ~w. Los quesos maduran y las deudas también. La ración de hoy: ~w quesos.'-[D, N]).
frase(suceso(dia_nuevo(D, N)), ambos,
      'Amanece el día ~w. Alguien tiene hambre y alguien más, una cuenta pendiente. Ración: ~w quesos.'-[D, N]).
frase(suceso(dia_nuevo(D, N)), ambos,
      'Día ~w de la Banda Chapuza. El Registro de Compañías sigue donde estaba: abajo. Ración: ~w quesos.'-[D, N]).
frase(suceso(descanso), ambos,
      'Descansáis. La vela se consume, los ronquidos de Rufino riman y Doña Mantecosa cobra las camas con puntualidad.').
frase(suceso(descanso), ambos,
      'Una noche en el Cuajo Torcido: poco sueño, mucho ruido y el colchón de siempre.').
frase(suceso(llegada(taberna)), ambos,
      'La puerta del Cuajo Torcido cuelga de una sola bisagra. Según Doña Mantecosa, le da carácter.').
frase(suceso(llegada(aldea)), ambos,
      'En la aldea todo es tan pacífico que el arma más peligrosa del pueblo es un rodillo.').
frase(suceso(llegada(camino_real)), ambos,
      'El Camino Real está empedrado con corteza de queso viejo. Se te pega a las botas y a la conversación.').
frase(suceso(defiende(A)), ambos,
      '~w se pone a la defensiva: escudo arriba, ojos cerrados y una plegaria a medias.'-[A]).

% --- comentario de explicar: la clave es la meta que se ha demostrado ---
frase(puede_viajar(Z), ambos,
      'Hay camino hasta ~w, y tan pegajoso que cuesta un día entero. Ley de la Ruta Pegajosa.'-[Z]).
frase(puede_descansar, ambos,
      'Las camas del Cuajo Torcido aceptan clientes. Han visto cosas y siguen aceptando.').
frase(puede_pagar_sueldos, ambos,
      'Hay queso para todos los sueldos. Que conste en acta, por si alguien lo duda dentro de una semana.').

% --- explicar una regla (X01 a X19 de docs/05): la clave es la meta; con la raiz de la prueba basta una frase ---
frase(puede_atacar(baldomero, E), ambos,
      'Sir Baldomero golpea a ~w. Fue la primera vez en una semana que no le temblaron las rodillas.'-[E]).
frase(puede_atacar(pimentina, E), ambos,
      'Madame Pimentina apunta con el cucharón a ~w. Nadie sabe si es un ataque o una degustación.'-[E]).
frase(puede_atacar(rufino, E), ambos,
      'Rufino golpea a ~w y lo apunta en el cuaderno: «para la balada». Lo de rimar vendrá luego.'-[E]).
frase(puede_atacar(tuerca, E), ambos,
      'Tuerca ataca a ~w por el flanco. Nadie lo ve llegar, y tampoco lo ven irse, que es lo importante.'-[E]).
frase(puede_atacar(A, E), ambos,
      'Regla cumplida: ~w puede atacar a ~w. A veces las cosas salen como manda el reglamento.'-[A, E]).
frase(dano(A, B, D), ambos,
      '~w deja a ~w sin ~w puntos de vida. Es matemática, no rencor.'-[A, B, D]).
frase(dano(_, B, 1), ambos,
      'Daño mínimo: un punto. ~w apenas lo nota, pero el reglamento exige que cuente.'-[B]).
frase(puede_habilidad(pimentina, _, _), ambos,
      'Hay queso en la despensa, así que hay magia. La Ley del Cuajo saluda a Madame Pimentina.').
frase(puede_habilidad(rufino, balada_inspiradora, _), ambos,
      'Rufino canta y la moral sube. Que el grupo quiera que pare es materia de otra regla.').
frase(puede_habilidad(tuerca, rebuscar_bolsillos, _), ambos,
      'Tuerca rebusca en un bolsillo ajeno. Según el acta, había queso; según Tuerca, oportunidades.').
frase(puede_habilidad(baldomero, carga_heroica, _), ambos,
      'Carga heroica autorizada. Sir Baldomero embiste sin que nadie le empuje, que conste.').
frase(puede_aceptar(_), ambos,
      'Cumples todos los requisitos del contrato. Lo difícil será cumplir el contrato.').
frase(ignora_miedo(baldomero), ambos,
      'La Venda de Caballos obra el milagro: si no ve caballos, no hay miedo. Lógica impecable, salud dudosa.').
frase(en_fila_alcanzable(A, B), ambos,
      'Frente contra frente: ~w y ~w quedan a la distancia justa para arrepentirse.'-[A, B]).
frase(vivo(X), detallado,
      'Comprobado en acta: ~w sigue en pie. En esta compañía, eso no es un trámite menor.'-[X]).
frase(modificador(A, _, M), detallado,
      'Ajuste al daño de ~w: ~w. El ánimo, como el queso, también cuenta.'-[A, M]).
frase(queso_total(N), detallado,
      'La despensa cuenta ~w quesos, incluidos algunos de procedencia discutible.'-[N]).

% --- explicar el turno de un enemigo (X20 de docs/05): la clave es la decision que tomo la IA ---
frase(accion_enemigo(rata_quesera, robar_queso), ambos,
      'La Rata Quesera roba queso: la prioridad tres de su lista y, de hecho, la que le toca.').
frase(accion_enemigo(bandido_torpe, atacar(_)), ambos,
      'El Bandido Torpe elige al más débil. Torpe, sí; tonto, solo a ratos.').
frase(accion_enemigo(bandido_montado, embestir(_)), ambos,
      'El caballo embiste primero. El bandido le sigue, por cortesía.').
frase(accion_enemigo(gran_roquefort, invocar_moho), ambos,
      'El Gran Roquefort llama a su moho sin prisa. Lleva cuarenta años practicando la calma.').
frase(accion_enemigo(_, curarse), ambos,
      'El primer caso de la lista que aplica es curarse, y la regla no mira más. Eso se llama prioridad.').
frase(accion_enemigo(_, _), detallado,
      'Decide el primer caso que aplica; los demás esperan turno, como en la cola de Doña Mantecosa.').
frase(golpea_a_clotilde(_), ambos,
      'El primero de cada ronda va a por Lady Clotilde. Es la regla de la escolta, no una opinión sobre las plumas.').

% --- por_que_no: por que NO se puede (F01a a F10b de docs/05). Las claves son impide(Hecho) cuando
% algo lo prohibe (una negacion que se cumplio) y falla(Meta) cuando una regla no se cumple. ---
frase(impide(teme(baldomero, caballo)), ambos,
      'Sir Baldomero ve el caballo, recuerda su infancia, y decide revisar sus calcetines.').
frase(impide(esta_en_huelga(P)), ambos,
      'Con la moral por los suelos nadie combate, y la de ~w anda en el sótano. Ley de la Huelga Sagrada.'-[P]).
frase(impide(aturdido(P)), ambos,
      'A ~w le dan vueltas la sala, el reglamento y el desayuno. Que ataque otro día.'-[P]).
frase(falla(en_fila_alcanzable(A, B)), ambos,
      'La retaguardia queda tras el frente: ~w no llega hasta ~w mientras alguien siga delante.'-[A, B]).
frase(falla(puede_habilidad(pimentina, _)), ambos,
      'Sin queso no hay hechizo. Madame Pimentina agita el cucharón y la despensa vacía le devuelve el eco.').
frase(falla(puede_viajar(Z)), ambos,
      'No hay camino de aquí a ~w. Hay un campo, un arroyo y una filosofía, pero camino, no.'-[Z]).
frase(falla(puede_descansar), ambos,
      'Aquí fuera no hay camas, solo suelo con ganas de serlo. Descansar se hace en la taberna.').
frase(falla(puede_aceptar(_)), ambos,
      'Este contrato no se puede aceptar todavía. Los requisitos están a la vista, como una factura.').
frase(impide(rasgo(baldomero, teme_caballos)), ambos,
      'Lady Clotilde exige escolta sin miedo a los caballos. Sir Baldomero levanta la mano, muy despacio, por honestidad.').

% --- por_que_no, mas casos: el punto exacto donde falla (docs/05 F04, F10, F16, E18 y propias) ---
frase(falla(vivo(X)), ambos,
      'Para atacar hay que seguir en pie, y ~w ha decidido tumbarse a reflexionar sobre sus decisiones.'-[X]).
frase(falla(puede_descansar, hay_queso_para(_)), ambos,
      'Descansar se paga en queso, y la despensa no llega. Las camas aceptan queso, no promesas.').
frase(falla(puede_pagar_sueldos, hay_queso_para(_)), ambos,
      'No alcanza para todos los sueldos. Al que se queda sin cobrar se le promete, que es el insulto máximo.').
frase(impide(marca(sueldos_pagados)), ambos,
      'Los sueldos de hoy ya están pagados. Doña Mantecosa agradece la intención y se queda el queso.').
frase(impide(contrato_activo(_)), ambos,
      'Ese contrato ya está firmado. La Ley del Contrato Escrito no admite doble firma ni por cariño.').
frase(impide(contrato_cumplido(_)), ambos,
      'Ese contrato ya se cumplió. Repetirlo no lo hace más cumplido, solo más aburrido.').
frase(falla(puede_aceptar(_), _ < _), ambos,
      'Ya lleváis tantos contratos como la Banda aguanta. Cumplid alguno antes de firmar otro.').
frase(falla(contratos_cumplidos_min(N)), ambos,
      'El rey pide ~w contratos cumplidos antes de fiarse. Con la Banda, hasta la fe necesita referencias.'-[N]).
frase(falla(visita(Z)), ambos,
      'Antes hay que presentarse en ~w: el rey no firma con desconocidos.'-[Z]).
frase(falla(moral_media_min(N)), ambos,
      'La moral de la Banda no llega a la media de ~w que exige el rey. Un buen descanso no vendría mal.'-[N]).
frase(falla(miembros_en_pie_min(N)), ambos,
      'El rey quiere al menos ~w miembros en pie. Los demás pueden mirar, pero no cuentan.'-[N]).
frase(falla(disponible(_)), ambos,
      'Ese contrato no está al alcance: ni se ofrece aquí ni todavía. Mira el tablón y deja de soñar.').

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
nombre(ratas_del_granero, 'Ratas del Granero').
nombre(rescate_gato,       'el rescate del gato').
nombre(gato_en_el_arbol,   'El Gato en el Árbol').
nombre(gallina_noble,      'Lady Clotilde Plumífera').
nombre(despensa_real,      'La Despensa Real').
nombre(pocion,             'poción').
nombre(carga_heroica,      'la Carga Heroica').
nombre(fondue_flamigera,   'la Fondue Flamígera').
nombre(balada_inspiradora, 'la Balada Inspiradora').
nombre(rebuscar_bolsillos, 'Rebuscar Bolsillos').
nombre(venda_de_caballos,  'venda de caballos').
nombre(rata_quesera,    'la Rata Quesera').
nombre(bandido_torpe,   'el Bandido Torpe').
nombre(moho_saltarin,   'el Moho Saltarín').
nombre(bandido_montado, 'el Bandido Montado').
nombre(gran_roquefort,  'el Gran Roquefort').
nombre(mantecosa,        'Doña Mantecosa').
nombre(gruyere,          'Gruyère').
nombre(alcaldesa_nata,   'la Alcaldesa Nata').
nombre(ricota,           'Ricota').
nombre(penicilio,        'el Hermano Penicilio').
nombre(ganso_recaudador, 'el Ganso Recaudador').
nombre(rey_brieto,       'el Rey Brieto IV').
nombre(el_eco,           'el Eco').
nombre(inspectora_cuajaron, 'la Inspectora Cuajarón').
nombre(eustaquio,           'Eustaquio').
nombre(seta_chismosa,       'la Seta Chismosa').
nombre(aldeano_perdido,     'el Aldeano Perdido').
nombre(capitan_pecorino,    'el Capitán Pecorino').
nombre(bandido_arrepentido, 'el Bandido Arrepentido').
nombre(lord_tapanarices,    'Lord Tapanarices').
nombre(reina_viuda,         'la Reina Viuda Nata Doble').
nombre(rata_exiliada,       'la Rata Exiliada').
nombre(murcielago_azul,     'el Murciélago Azul').

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

% ---------------------------------------------------------------------------
% Del diagnostico de por_que_no a una frase (docs/05 7.4).
%
% El diagnostico (explicar, docs/02 6.9) dice DONDE falla algo; aqui se traduce a una lista de
% claves candidatas, de la causa mas profunda a la raiz, y se usa la primera que tenga frase:
%   neg_viola(X, Prueba)  impide(H) por cada meta de la prueba de X, en preorden
%   fallo(G, [cl(_,_,punto(F,D))|_])  las de D, luego falla(F) (si F no es una negacion), luego falla(G)
%   tras(_, D)            las de D (el fallo esta en el segundo conjuntivo)
%   ninguna(DA, DB)       las de DA y luego las de DB (una disyuncion que falla por los dos lados)
%   sin_clausula(G)       falla(G)
%   builtin_falso, limite ninguna (se salta a la clave falla(...) de la regla padre)
% Una condicion de contrato llega envuelta en condicion_cumple(C): se prueba falla(condicion_cumple(C))
% y luego falla(C). Los objetivos pueden llegar con modulo (strip_module los pela).
% ---------------------------------------------------------------------------

% claves_de_diag(+Diag, -Claves): siempre tiene exito; una forma desconocida da [].
claves_de_diag(Diag, Claves) :-
    (   nonvar(Diag), claves_diag(Diag, Cs)
    ->  Claves = Cs
    ;   Claves = []
    ).

claves_diag(neg_viola(_, Prueba), Claves) :-
    findall(impide(H),
            ( meta_en(Prueba, H0), strip_module(H0, _, H) ),
            Claves).
claves_diag(neg_doble(_, D), Claves) :-
    claves_de_diag(D, Claves).
claves_diag(tras(_, D), Claves) :-
    claves_de_diag(D, Claves).
claves_diag(ninguna(DA, DB), Claves) :-
    claves_de_diag(DA, As),
    claves_de_diag(DB, Bs),
    append(As, Bs, Claves).
claves_diag(sin_clausula(G0), Claves) :-
    strip_module(G0, _, G),
    claves_falla(G, Claves).
claves_diag(builtin_falso(_), []).
claves_diag(limite(_), []).
claves_diag(fallo(G0, Cands), Claves) :-
    strip_module(G0, _, G),
    (   Cands = [cl(_, _, punto(F0, D))|_]
    ->  claves_de_diag(D, Hondas),
        strip_module(F0, _, F),
        (   F = (\+ _) -> Propias = [] ; claves_falla(F, Propias) )
    ;   Hondas = [], Propias = []
    ),
    compuesta(G, Propias, Compuestas),
    append([Hondas, Propias, Compuestas, [falla(G)]], Claves).

% compuesta(+G, +Propias, -Claves): la meta Y el punto donde falla, para frases que dependen de los dos
% (descansar sin queso no es lo mismo que descansar fuera de la taberna). Solo con el punto de la meta.
compuesta(G, Propias, Compuestas) :-
    (   Propias = [falla(Punto)|_]
    ->  Compuestas = [falla(G, Punto)]
    ;   Compuestas = []
    ).

claves_falla(Meta, Claves) :-
    (   Meta = condicion_cumple(C)
    ->  Claves = [falla(condicion_cumple(C)), falla(C)]
    ;   Claves = [falla(Meta)]
    ).

% tiene_frase(+Clave): hay alguna frase en el banco para esa clave (a cualquier nivel).
tiene_frase(Clave) :-
    \+ \+ ( frase(K, _, _), casa(K, Clave) ).

% clave_de_diag(+Diag, -Clave): la primera clave candidata con frase; si ninguna la tiene,
% generica(impide) cuando algo lo prohibia (hubo neg_viola) y generica(fallo) en otro caso.
clave_de_diag(Diag, Clave) :-
    claves_de_diag(Diag, Claves),
    (   member(C, Claves), tiene_frase(C)
    ->  Clave = C
    ;   member(impide(_), Claves)
    ->  Clave = generica(impide)
    ;   Clave = generica(fallo)
    ).

% comentario_diag(+Diag, +Nivel, +Uso, -Texto): la frase de por_que_no. Siempre hay texto.
comentario_diag(Diag, Nivel, Uso, Texto) :-
    clave_de_diag(Diag, Clave),
    (   comentario(Clave, Nivel, Uso, T)
    ->  Texto = T
    ;   comentario(generica(fallo), Nivel, Uso, Texto)    % una frase solo de nivel detallado no sale en el resumido
    ).

% comentarios_de_nodo(+Prueba, +Nivel, +Uso, -Textos): en el nivel detallado, hasta tres frases sueltas
% sobre los nodos del arbol que tienen frase propia (no la raiz: esa cierra la explicacion). En el
% resumido no hay ninguna. Sin repetir texto.
comentarios_de_nodo(Prueba, Nivel, Uso, Textos) :-
    (   Nivel == detallado
    ->  metas_de_prueba(Prueba, Metas),
        (   Metas = [Raiz|Resto]
        ->  true
        ;   Raiz = nada, Resto = []
        ),
        (   comentario(Raiz, Nivel, Uso, TextoRaiz) -> true ; TextoRaiz = '' ),
        findall(T, ( member(M, Resto), comentario(M, Nivel, Uso, T), T \== TextoRaiz ), Todos),
        sin_repetidos(Todos, Unicos),
        primeros_n(3, Unicos, Textos)
    ;   Textos = []
    ).

sin_repetidos([], []).
sin_repetidos([X|Xs], [X|Ys]) :-
    exclude(==(X), Xs, Resto),
    sin_repetidos(Resto, Ys).

primeros_n(N, L, P) :-
    (   N > 0, L = [X|R]
    ->  N1 is N - 1, P = [X|P1], primeros_n(N1, R, P1)
    ;   P = []
    ).

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
% descripcion_evento(+E, -Texto) y descripcion_opcion(+E, +Opcion, -Texto): lo que enseña el evento.
descripcion_evento(rescate_gato, 'El Gato en el Árbol: Su Excelencia Bigotes no piensa bajar solo.').
descripcion_opcion(rescate_gato, trepar,              'Tuerca trepa a por él').
descripcion_opcion(rescate_gato, hechizo_de_raclette, 'Madame Pimentina lo atrae con un hechizo de raclette (cuesta 1 queso)').
descripcion_opcion(rescate_gato, sacudir_arbol,       'Sir Baldomero sacude el árbol con todo su honor').
descripcion_opcion(rescate_gato, cantar,              'Rufino le canta una balada (gasta un intento)').

% descripcion_contrato(+Contrato, -Texto): el chiste de cada contrato, que enseña el tablon.
descripcion_contrato(ratas_del_granero, 'Las ratas dicen tener papeles de alquiler por un queso al siglo y se hacen las muertas para cobrar el seguro.').
descripcion_contrato(gato_en_el_arbol,  'Su Excelencia Bigotes lleva tres días arriba y dice que desde allí se juzga mejor.').
descripcion_contrato(gallina_noble,     'Lady Clotilde exige palanquín, escolta y que nadie cante a su alrededor: «Si canta, picoteo».').
descripcion_contrato(despensa_real,     'El rey contrata a los peores porque los buenos no cobran en promesas de cobro.').

% descripcion_personaje(+Npc, -Texto): quien es, para la lista de `hablar.`
descripcion_personaje(mantecosa,        'La dueña del Cuajo Torcido: cobra todo y no perdona nada.').
descripcion_personaje(gruyere,          'Un viajante sin carreta, con el sombrero en la mano y la mirada en otra parte.').
descripcion_personaje(alcaldesa_nata,   'La máxima autoridad de la aldea, con una lista de quejas más larga que el pueblo.').
descripcion_personaje(ricota,           'El tendero risueño, convencido de que todo se arregla con una oferta.').
descripcion_personaje(penicilio,        'Un ex-afinador que vive en el bosque y habla con los hongos.').
descripcion_personaje(ganso_recaudador, 'Un ganso con permiso de cobro y muy pocas ganas de discutir.').
descripcion_personaje(rey_brieto,       'Brieto IV «el Mal Curado»: rey amable, ingenuo y bastante pegajoso.').
descripcion_personaje(el_eco,           'Una voz que repite lo que dices, pero no siempre con tus palabras.').

% descripcion_opcion_charla(+Npc, +Opcion, -Texto): lo que ensena cada opcion de la charla.
descripcion_opcion_charla(mantecosa, jurar_honor,        'Sir Baldomero jura por su honor que la Banda arreglará el asunto').
descripcion_opcion_charla(mantecosa, invitar_al_caldo,   'Madame Pimentina invita a una ronda de caldo (cuesta 1 queso)').
descripcion_opcion_charla(mantecosa, mirar_los_desagues, 'Tuerca se ofrece a «echar un vistazo» a los desagües').
descripcion_opcion_charla(gruyere, vengar_al_viajante,        'Sir Baldomero promete vengar su carreta (y lo del caballo, mejor no pensarlo)').
descripcion_opcion_charla(gruyere, consolar_con_una_balada,   'Rufino le canta una balada de consuelo').
descripcion_opcion_charla(gruyere, ayudarle_a_recoger,        'Tuerca le ayuda a recoger lo que se le cayó del petate').
descripcion_opcion_charla(alcaldesa_nata, escuchar_la_lista,  'Sir Baldomero escucha la lista entera, con educación').
descripcion_opcion_charla(alcaldesa_nata, curar_las_vacas,    'Madame Pimentina propone un remedio para las vacas (cuesta 1 queso)').
descripcion_opcion_charla(alcaldesa_nata, ojear_el_registro,  'Tuerca ojea el registro de quejas «por si hay algo valioso»').
descripcion_opcion_charla(ricota, cantar_el_anuncio,          'Rufino canta el anuncio de la tienda').
descripcion_opcion_charla(ricota, regatear,                   'Tuerca regatea (y se lleva lo que puede)').
descripcion_opcion_charla(ricota, preguntar_por_los_precios,  'Madame Pimentina pregunta por los precios').
descripcion_opcion_charla(penicilio, hablar_con_el_moho,      'Madame Pimentina intenta hablar con el moho').
descripcion_opcion_charla(penicilio, amenazar_con_fuego,      'Sir Baldomero amenaza con quemarlo todo').
descripcion_opcion_charla(penicilio, cantarle_al_moho,        'Rufino le canta al moho una nana').
descripcion_opcion_charla(ganso_recaudador, discutir_el_peaje, 'Sir Baldomero discute el peaje por principios').
descripcion_opcion_charla(ganso_recaudador, pagar_el_peaje,    'Madame Pimentina paga el peaje (cuesta 1 queso)').
descripcion_opcion_charla(ganso_recaudador, esquivar_al_ganso, 'Tuerca esquiva al ganso por la cuneta').
descripcion_opcion_charla(rey_brieto, hacer_la_reverencia,             'Sir Baldomero hace una reverencia impecable').
descripcion_opcion_charla(rey_brieto, preguntar_por_la_despensa,       'Madame Pimentina pregunta por la despensa y por «aquello de las cuevas»').
descripcion_opcion_charla(rey_brieto, registrar_los_bolsillos_reales,  'Tuerca registra los bolsillos reales mientras el rey habla').
descripcion_opcion_charla(el_eco, cantar_a_la_cueva,          'Rufino canta a la cueva').
descripcion_opcion_charla(el_eco, gritarle_al_eco,            'Sir Baldomero le grita al eco').
descripcion_opcion_charla(el_eco, susurrar_una_pregunta,      'Tuerca susurra una pregunta al eco').

% (el segundo lote de descripciones, mas abajo, se declara discontiguo a proposito)
:- discontiguous descripcion_personaje/2, descripcion_opcion_charla/3.
descripcion_personaje(inspectora_cuajaron, 'Inspectora del Gremio de Afinadores, con gafas redondas y un maletín cuadrado.').
descripcion_personaje(eustaquio,           'Un mayordomo fantasma que lleva trescientos años esperando su cena.').
descripcion_personaje(seta_chismosa,       'Una seta del tamaño de una silla que lo sabe todo de todos.').
descripcion_personaje(aldeano_perdido,     'Un aldeano que lleva tres días buscando la salida del bosque.').
descripcion_personaje(capitan_pecorino,    'Jefe de las Lanzas Parmesanas: todo lo que dice parece un sermón.').
descripcion_personaje(bandido_arrepentido, 'Un bandido sin caballo que se ha vuelto honrado y lo encuentra aburrido.').
descripcion_personaje(lord_tapanarices,    'Un cortesano con una pinza en la nariz y un pañuelo perfumado en cada mano.').
descripcion_personaje(reina_viuda,         'La reina viuda Nata Doble, madre de un rey que firmaba sin leer.').
descripcion_personaje(rata_exiliada,       'Una rata que escapó del granero y ahora hace de guía de cuevas.').
descripcion_personaje(murcielago_azul,     'Un murciélago azul que chilla historias largas colgado boca abajo.').

descripcion_opcion_charla(inspectora_cuajaron, firmar_sin_leer,   'Sir Baldomero firma el formulario sin leerlo').
descripcion_opcion_charla(inspectora_cuajaron, pagar_la_tasa,     'Madame Pimentina paga la tasa de inspección (cuesta 1 queso)').
descripcion_opcion_charla(inspectora_cuajaron, ojear_el_maletin,  'Tuerca ojea el maletín de la inspectora').
descripcion_opcion_charla(eustaquio, escuchar_la_historia_entera, 'Rufino escucha la historia entera (y la convierte en balada)').
descripcion_opcion_charla(eustaquio, exigir_que_se_vaya,          'Sir Baldomero exige que se marche de la aldea').
descripcion_opcion_charla(eustaquio, ofrecerle_una_cena,          'Madame Pimentina le ofrece, por fin, una cena (cuesta 1 queso)').
descripcion_opcion_charla(seta_chismosa, preguntar_por_si_mismo,           'Sir Baldomero pregunta qué dicen de él').
descripcion_opcion_charla(seta_chismosa, pedir_una_critica_de_baladas,     'Rufino le pide una crítica de sus baladas').
descripcion_opcion_charla(seta_chismosa, preguntar_por_el_queso_escondido, 'Tuerca pregunta, como quien no quiere la cosa, dónde hay queso escondido').
descripcion_opcion_charla(aldeano_perdido, acompanarle_a_casa,   'Sir Baldomero acompaña al aldeano a casa').
descripcion_opcion_charla(aldeano_perdido, darle_de_comer,       'Madame Pimentina le da de comer (cuesta 1 queso)').
descripcion_opcion_charla(aldeano_perdido, seguirle_por_un_atajo, 'Tuerca se ofrece a seguirlo por un atajo').
descripcion_opcion_charla(capitan_pecorino, saludar_con_firmeza,  'Sir Baldomero saluda con firmeza').
descripcion_opcion_charla(capitan_pecorino, ofrecerle_una_marcha, 'Rufino le ofrece una marcha militar').
descripcion_opcion_charla(capitan_pecorino, preguntar_por_su_ronda, 'Madame Pimentina le pregunta por su ronda').
descripcion_opcion_charla(bandido_arrepentido, perdonarle_en_nombre_del_honor, 'Sir Baldomero le perdona en nombre del honor').
descripcion_opcion_charla(bandido_arrepentido, aceptar_el_queso_robado,        'Tuerca acepta el queso que robó el bandido').
descripcion_opcion_charla(bandido_arrepentido, escribirle_una_balada_de_perdon, 'Rufino le escribe una balada de perdón').
descripcion_opcion_charla(lord_tapanarices, prestarle_un_panuelo,           'Sir Baldomero le presta su pañuelo').
descripcion_opcion_charla(lord_tapanarices, cantar_para_distraer_la_nariz,  'Rufino canta para que no piense en el olor').
descripcion_opcion_charla(lord_tapanarices, venderle_aire_perfumado,        'Tuerca le vende un frasco de «aire perfumado»').
descripcion_opcion_charla(reina_viuda, hacer_la_reverencia_de_luto, 'Sir Baldomero hace una reverencia de luto').
descripcion_opcion_charla(reina_viuda, preguntar_por_su_hijo,       'Madame Pimentina le pregunta por su hijo').
descripcion_opcion_charla(reina_viuda, cantar_una_nana,             'Rufino canta una nana a la reina viuda').
descripcion_opcion_charla(rata_exiliada, disculparse_por_el_granero,  'Sir Baldomero se disculpa por lo del granero').
descripcion_opcion_charla(rata_exiliada, compartir_un_queso,          'Madame Pimentina comparte un queso con ella (cuesta 1 queso)').
descripcion_opcion_charla(rata_exiliada, preguntarle_por_las_cuevas,  'Tuerca le pregunta por las cuevas').
descripcion_opcion_charla(murcielago_azul, escuchar_los_chillidos,    'Rufino intenta traducir los chillidos').
descripcion_opcion_charla(murcielago_azul, espantarlo_con_la_espada,  'Sir Baldomero lo espanta con la espada').
descripcion_opcion_charla(murcielago_azul, ofrecerle_queso_azul,      'Madame Pimentina le ofrece un trocito de queso (cuesta 1 queso)').

% texto_saber(+Marca, -Texto): la linea del diario (la misma frase con la que se anuncia al averiguarlo).
texto_saber(Marca, Texto) :-
    texto(saber_nuevo, [Marca], 0, Crudo),
    (   atom_concat('Diario: ', Resto, Crudo)
    ->  mayuscula_inicial(Resto, Texto)
    ;   Texto = Crudo
    ).

% texto_recompensa(+Premios, -Texto): "9 quesos, poción" a partir de [quesos(9), objeto(pocion)].
texto_recompensa(Premios, Texto) :-
    maplist(texto_premio, Premios, Textos),
    atomic_list_concat(Textos, ', ', Texto).

texto_premio(quesos(N), Texto) :-
    format(atom(Texto), '~w quesos', [N]).
texto_premio(queso(Tipo, _, N), Texto) :-
    format(atom(Texto), '~w ~w', [N, Tipo]).
texto_premio(objeto(Objeto), Texto) :-
    nombre_visible(Objeto, Texto).

% texto_error(+Motivo, -Texto): por que un comando no se pudo ejecutar.
% (Aun fuera del banco: sus variantes llegan con el resto del humor.)
% ---------------------------------------------------------------------------
texto_error(no_puede_viajar(Zona), Texto) :-
    (   mundo:zona(Zona, Nombre)
    ->  format(atom(Texto), 'No puedes ir a ~w desde aquí: no hay camino directo. Pregunta por_que_no(ir(~w)) para ver por qué.', [Nombre, Zona])
    ;   como_texto(Zona, Dicho),
        format(atom(Texto), 'No conozco ningún lugar llamado "~w".', [Dicho])
    ).
texto_error(no_puede_descansar, Texto) :-
    mundo:parametro(coste_descanso, Coste),
    format(atom(Texto), 'Descansar cuesta ~w quesos y la despensa no llega. Pregunta por_que_no(descansar) para ver por qué.', [Coste]).
texto_error(fuera_de_fase(Cmd, Fase), Texto) :-
    (   Fase == fin
    ->  Texto = 'La partida ha terminado.'
    ;   functor(Cmd, descansar, _)
    ->  Texto = 'Solo se puede descansar en la taberna.'
    ;   ( functor(Cmd, atacar, _) ; functor(Cmd, defender, _) ; functor(Cmd, habilidad, _) )
    ->  Texto = 'Solo se puede atacar, defender o usar una habilidad en pleno combate.'
    ;   format(atom(Texto), 'Ahora mismo no puedes hacer eso (fase: ~w).', [Fase])
    ).
texto_error(no_entiendo(Termino), Texto) :-
    como_texto(Termino, Dicho),
    format(atom(Texto), 'No entiendo "~w". Escribe ayuda. para ver los comandos.', [Dicho]).
texto_error(contrato_desconocido(C), Texto) :-
    como_texto(C, Dicho),
    format(atom(Texto), 'No hay ningún contrato llamado "~w". Escribe contratos. para ver los que hay.', [Dicho]).
texto_error(no_puede_aceptar(C), Texto) :-
    nombre_visible(C, Nombre),
    format(atom(Texto), 'El contrato «~w» os mira, mira a la Banda y decide que no. Ahora mismo no podéis aceptarlo: pregunta por_que_no(aceptar(~w)).', [Nombre, C]).
texto_error(no_se_usa(Objeto), Texto) :-
    nombre_visible(Objeto, N),
    format(atom(Texto), '~w no se puede usar: solo sirven los objetos que curan (la poción).', [N]).
texto_error(no_puede_usar(Objeto, Miembro), Texto) :-
    nombre_visible(Objeto, O), nombre_visible(Miembro, M),
    format(atom(Texto), 'No se puede usar ~w en ~w ahora mismo. Pregunta por_que_no(usar(~w, ~w)) para ver por qué.', [O, M, Objeto, Miembro]).
texto_error(no_hay_evento, 'No hay ningún evento abierto (ni charla): no hay nada que elegir.').
texto_error(personaje_desconocido(Npc), Texto) :-
    format(atom(Texto), 'No conozco a nadie que se llame ~w. hablar. enseña con quién puedes hablar aquí.', [Npc]).
texto_error(no_esta_aqui(Npc), Texto) :-
    nombre_visible(Npc, Nombre),
    format(atom(Texto), '~w no está aquí hoy. hablar. enseña con quién puedes hablar. Pregunta por_que_no(hablar(~w)) para ver por qué.', [Nombre, Npc]).
texto_error(opcion_desconocida(X), Texto) :-
    como_texto(X, Dicho),
    format(atom(Texto), 'No existe la opción "~w". Escribe mirar. para ver las que hay.', [Dicho]).
texto_error(opcion_no_disponible(Op), Texto) :-
    format(atom(Texto), 'La opción «~w» no está disponible ahora mismo: falta quien la haga o lo que necesita.', [Op]).
texto_error(no_es_tu_turno, 'Ahora no te toca a ti: espera a tu turno.').
texto_error(no_puede_atacar(Actor, Objetivo), Texto) :-
    nombre_visible(Actor, A),
    nombre_visible(Objetivo, B),
    con_a(B, ConA),
    format(atom(Texto), '~w no puede atacar ~w ahora mismo. Pregunta por_que_no(atacar(...)) con esa misma orden.', [A, ConA]).
texto_error(no_puede_habilidad(Actor, Habilidad), Texto) :-
    nombre_visible(Actor, A),
    nombre_visible(Habilidad, H),
    format(atom(Texto), '~w no puede usar ~w ahora mismo: falta lo que necesita, o el objetivo no está a su alcance. Pregunta por_que_no(habilidad(...)).', [A, H]).
texto_error(habilidad_pide_objetivo(Habilidad), Texto) :-
    nombre_visible(Habilidad, H),
    format(atom(Texto), '~w necesita un enemigo: escribe habilidad(Objetivo).', [H]).
texto_error(no_puede_defender(Actor), Texto) :-
    nombre_visible(Actor, A),
    format(atom(Texto), '~w no puede defenderse ahora mismo.', [A]).
texto_error(objetivo_desconocido(Objetivo), Texto) :-
    como_texto(Objetivo, Dicho),
    format(atom(Texto), 'No hay nada llamado "~w" a lo que atacar.', [Dicho]).
texto_error(nada_que_pagar, 'No debes nada: los sueldos ya están pagados.').
texto_error(no_puede_pagar, 'Los sueldos no se pueden pagar a medias y la despensa no llega. Pregunta por_que_no(pagar).').
texto_error(nada_que_explicar, 'Todavía no has hecho nada que explicar. Prueba con explicar(ir(aldea)).').
texto_error(no_hay_prueba(Accion), Texto) :-
    como_texto(Accion, Dicho),
    format(atom(Texto), 'Ahora mismo no se puede hacer ~w, así que no hay prueba que enseñar. Prueba con por_que_no(~w) para ver qué falla.', [Dicho, Dicho]).
texto_error(escena_desconocida(Nombre), Texto) :-
    como_texto(Nombre, Dicho),
    format(atom(Texto), 'No hay ninguna escena llamada "~w". Escribe demo. para ver las que hay.', [Dicho]).
texto_error(nivel_desconocido(Nivel), Texto) :-
    como_texto(Nivel, Dicho),
    format(atom(Texto), 'No existe el nivel "~w": usa nivel(resumido). o nivel(detallado).', [Dicho]).
texto_error(sin_fallo(Accion), Texto) :-
    como_texto(Accion, Dicho),
    comentario(generica(sin_fallo), ambos, 0, Frase),
    format(atom(Texto), '~w (~w)', [Frase, Dicho]).
texto_error(no_se_explica(Accion), Texto) :-
    como_texto(Accion, Dicho),
    format(atom(Texto), 'No sé explicar "~w". Puedo explicar ir(Zona), descansar, pagar, aceptar(Contrato), elegir(Opcion), atacar(Objetivo), defender y habilidad.', [Dicho]).
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
ayuda_de(elegir, 'elegir(Opcion). elige una opción del evento abierto (su número o su nombre)').
ayuda_de(hablar, 'hablar.        quién hay aquí hoy; hablar(Nombre). abre su escena (una sola vez) y se elige con elegir(Opcion).').
ayuda_de(usar, 'usar(Objeto, Miembro). gasta un objeto de la compañía: usar(pocion, tuerca). cura a un miembro herido (en combate gasta su turno)').
ayuda_de(diario, 'diario.        lo que ya sabéis del Gran Rancio, según lo que cuenta la gente').
ayuda_de(contratos, 'contratos.     el tablón: los contratos a la vista y si se pueden aceptar').
ayuda_de(aceptar, 'aceptar(Contrato). acepta un contrato (en la taberna o donde lo ofrecen)').
ayuda_de(atacar, 'atacar(Objetivo). solo en combate: golpea a un enemigo (un tipo o e(Tipo, N))').
ayuda_de(defender, 'defender.      solo en combate: sube tu defensa hasta tu próximo turno').
ayuda_de(habilidad, 'habilidad(Objetivo). solo en combate: usa la habilidad de tu personaje; la balada de Rufino se escribe habilidad.').
ayuda_de(por_que_no, 'por_que_no(Accion). por qué NO se puede una acción: qué regla falla y por qué (p. ej. por_que_no(aceptar(gallina_noble)).)').
ayuda_de(nivel, 'nivel(N).      cuánto detalle tienen explicar y por_que_no: nivel(resumido). o nivel(detallado).').
ayuda_de(demo, 'demo.          las escenas de la demostración (demo(Nombre). prepara una y la deja lista para jugar)').
ayuda_de(compania,'compania.      muestra a los miembros, su vida, su moral y su estado').
ayuda_de(inventario, 'inventario.    muestra la despensa (con la edad del queso) y los objetos').
ayuda_de(explicar, 'explicar.      la prueba de lo último que hiciste; explicar(Accion). la de esa acción').
ayuda_de(salir, 'salir.         termina la partida').

% texto_objetivo(+Paso, +Faltas, -Texto): el objetivo actual (contratos:objetivo_actual/2) en una o dos frases.
% Paso dice que toca ahora; Faltas, lo que aun falta para el contrato final (puede ser []).
texto_objetivo(Paso, Faltas, Texto) :-
    texto_paso(Paso, Faltas, Frase),
    (   Paso = preparar_final(_) -> Prefijo = ' Te falta: ' ; Prefijo = ' Para el contrato final te falta: ' ),
    (   Faltas == []
    ->  Crudo = Frase
    ;   maplist(texto_falta, Faltas, Textos),
        atomic_list_concat(Textos, '; ', Lista),
        atomic_list_concat([Frase, Prefijo, Lista, '.'], Crudo)
    ),
    contraer(Crudo, Texto).

texto_paso(cobrar, _, 'Objetivo: vuelve a la taberna a cobrar lo que has resuelto.').
texto_paso(cumplir(C, Zona), _, Texto) :-
    nombre_visible(C, N), nombre_visible(Zona, Z),
    format(atom(Texto), 'Objetivo: cumple «~w» en ~w.', [N, Z]).
texto_paso(aceptar_final(F, Zona), _, Texto) :-
    nombre_visible(F, N), nombre_visible(Zona, Z),
    format(atom(Texto), 'Objetivo: acepta «~w» y ve a ~w: es el contrato final.', [N, Z]).
texto_paso(aceptar, _, 'Objetivo: acepta un contrato en el tablón de la taberna.').
texto_paso(explorar(Zona), _, Texto) :-
    nombre_visible(Zona, Z),
    format(atom(Texto), 'Objetivo: explora; en ~w se oye hablar de un contrato mayor.', [Z]).
texto_paso(preparar_final(F), _, Texto) :-
    nombre_visible(F, N),
    format(atom(Texto), 'Objetivo: prepárate para «~w», el contrato final.', [N]).

texto_falta(contratos(1), 'un contrato más cumplido') :- !.
texto_falta(contratos(K), Texto) :- format(atom(Texto), '~w contratos más cumplidos', [K]).
texto_falta(moral(N), Texto) :- format(atom(Texto), 'subir la moral media a ~w', [N]).
texto_falta(en_pie(N), Texto) :- format(atom(Texto), 'tener ~w miembros en pie', [N]).
texto_falta(visita(Z), Texto) :- nombre_visible(Z, N), format(atom(Texto), 'visitar ~w', [N]).
texto_falta(rasgo(_), 'resolver un impedimento de la compañía').

% texto_riesgo(+Riesgo, -Texto): el aviso de comida (economia:riesgo_de_gasto/2). ninguno no tiene texto.
texto_riesgo(hambre_mortal, '¡Peligro! Otro día así y perderías por hambre: sin queso, sin nada por cobrar y con el ayuno que la Banda aguanta ya agotado.').
texto_riesgo(a_cero, 'Ojo: otro día así y os quedáis sin queso. Sin comida y sin nada por cobrar solo se aguantan unos días antes de perder por hambre.').
texto_riesgo(sin_queso, 'Otro día así y la despensa se queda a cero (aunque tienes algo por cobrar).').
texto_riesgo(escaso, 'Ojo: otro día así y te quedaría menos de un día de ración.').

% bienvenida(-Lineas): lo primero que ve el jugador (consola y web): quien es, el objetivo y como empezar.
bienvenida(['=== BANDA CHAPUZA ===',
            'Diriges una compañía de mercenarios incompetentes que cobran en queso.',
            'Objetivo: aceptar contratos, no quedarte sin queso y derrotar al Gran Roquefort.',
            'Para empezar: contratos.  aceptar(ratas_del_granero).  ir(aldea).  (cada comando termina con un punto)',
            'Escribe ayuda. para ver los comandos; explicar. y por_que_no(Accion). cuentan por qué pasa todo.']).

% consejo_de_ayuda(+Comandos, -Texto): un consejo segun donde estas, deducido de los comandos disponibles
% (atacar solo existe en combate, pagar solo en la taberna y mirar no existe cuando la partida ha acabado).
consejo_de_ayuda(Comandos, Texto) :-
    (   \+ memberchk(mirar, Comandos)
    ->  Texto = 'La partida ha terminado: explicar. cuenta por qué pasó lo último.'
    ;   memberchk(atacar, Comandos)
    ->  Texto = 'Estás en combate: cada miembro actúa en su turno. atacar(Tipo). golpea (p. ej. atacar(rata_quesera).), defender. sube la defensa y habilidad. usa la de tu personaje. Con explicar. ves por qué pasó lo último.'
    ;   memberchk(pagar, Comandos)
    ->  Texto = 'Estás en la taberna: contratos. enseña el tablón, aceptar(Contrato). acepta uno, pagar. paga los sueldos pendientes, descansar. cura (cuesta queso) e ir(Zona). viaja (cuesta un día y la ración de queso). Ahorra queso: cada día come toda la Banda, así que junta los contratos de una misma zona antes de volver.'
    ;   Texto = 'Estás de viaje: mirar. te dice dónde estás y las salidas, ir(Zona). viaja y aceptar(Contrato). acepta un contrato donde te lo ofrecen. Cada día come toda la Banda: no vuelvas con las manos vacías. Si algo no se puede, por_que_no(Accion). cuenta por qué.'
    ).
