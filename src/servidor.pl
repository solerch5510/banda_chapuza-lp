% servidor.pl
% Servidor HTTP minimo para el frontend web (extra opcional): un envoltorio fino sobre api.pl. No contiene reglas
% del juego; solo recibe una orden escrita, la pasa por api:ejecutar_orden/2 y devuelve el JSON.
%
%   swipl -q -s src/servidor -g "servidor(8080)" -t halt        (queda escuchando; Ctrl+C para parar)
%
% Rutas:
%   GET  /api/estado            el estado completo (banda, despensa, zona, mapa, contratos, combate, acciones)
%   POST /api/orden             cuerpo {"orden": "ir(aldea)."}  ->  {orden, items, estado}
%   GET  /api/orden?orden=...   lo mismo, para probar con el navegador o curl
%   POST /api/nueva             empieza una partida nueva y devuelve lo mismo que mirar.
%   GET  /api/escenas           las escenas de demostracion
%   GET  /...                   archivos estaticos de web/ (index.html por omision)
%
% Hay UNA partida por servidor (el estado del juego es global); las peticiones se atienden de una en una con
% un cerrojo, para que dos peticiones a la vez no se pisen.

:- module(servidor, [servidor/0, servidor/1, parar/1]).
:- encoding(utf8).

:- use_module(library('http/thread_httpd')).
:- use_module(library('http/http_dispatch')).
:- use_module(library('http/http_json')).
:- use_module(library('http/http_parameters')).
:- use_module(library('http/json')).
:- use_module(library(lists)).
:- use_module(api).
:- use_module(estado).

% La carpeta web/ esta junto a src/: se deduce de donde esta este archivo (sin escribir en la base de datos).
carpeta_web(Web) :-
    module_property(servidor, file(Archivo)),
    file_directory_name(Archivo, Src),
    file_directory_name(Src, Raiz),
    atomic_list_concat([Raiz, '/web'], Web).

:- http_handler(root('api/estado'),  manejar_estado,  []).
:- http_handler(root('api/orden'),   manejar_orden,   []).
:- http_handler(root('api/nueva'),   manejar_nueva,   []).
:- http_handler(root('api/escenas'), manejar_escenas, []).
:- http_handler(root('api/fichas'),  manejar_fichas,  []).
:- http_handler(root(.),             servir_web,      [prefix]).

servidor :- servidor(8080).

servidor(Puerto) :-
    estado:nueva_partida,
    http_server(http_dispatch, [port(Puerto), workers(2)]),
    format(user_error, "Banda Chapuza en http://localhost:~w/  (Ctrl+C para parar)~n", [Puerto]),
    thread_get_message(parar_servidor).

parar(Puerto) :- http_stop_server(Puerto, []).

% todo acceso al estado del juego, de uno en uno
:- meta_predicate con_cerrojo(0).
con_cerrojo(Meta) :- with_mutex(banda_chapuza, Meta).

sin_cache :- format("Cache-Control: no-store~n").

% La respuesta declara UTF-8 (sin eso un cliente que no sea un navegador no sabe como decodificar las tildes).
responder(Json) :- reply_json(Json, [content_type('application/json; charset=UTF-8')]).

manejar_estado(_Peticion) :-
    con_cerrojo(api:estado_json(Json)),
    sin_cache,
    responder(Json).

manejar_orden(Peticion) :-
    orden_de_la_peticion(Peticion, Texto),
    con_cerrojo(api:ejecutar_orden(Texto, Json)),
    sin_cache,
    responder(Json).

% La orden llega en el cuerpo (POST, JSON) o en el parametro ?orden= (GET).
orden_de_la_peticion(Peticion, Texto) :-
    (   memberchk(method(post), Peticion)
    ->  catch(http_read_json(Peticion, json(Campos)), _, Campos = []),
        (   memberchk(orden=T0, Campos) -> Texto = T0 ; Texto = '' )
    ;   catch(http_parameters(Peticion, [orden(T1, [default(''), atom])]), _, T1 = ''),
        Texto = T1
    ).

manejar_nueva(Peticion) :-
    consumir_cuerpo(Peticion),
    con_cerrojo(api:nueva_partida_json(Json)),
    sin_cache,
    responder(Json).

% Un POST cuyo cuerpo no se lee deja esos bytes en la conexion (que el navegador reutiliza): la peticion siguiente
% llega precedida de basura y el servidor da 500 ("Syntax error: http_request"). Se lee siempre.
consumir_cuerpo(Peticion) :-
    (   memberchk(method(post), Peticion)
    ->  catch(http_read_json(Peticion, _), _, true)
    ;   true
    ).

manejar_fichas(_Peticion) :-
    con_cerrojo(api:fichas_json(Json)),
    responder(Json).

manejar_escenas(_Peticion) :-
    api:escenas_json(Js),
    sin_cache,
    responder(json([escenas=Js])).

% Archivos estaticos de web/; nunca fuera de esa carpeta.
servir_web(Peticion) :-
    (   memberchk(path_info(Info0), Peticion), Info0 \== '' -> Info = Info0 ; Info = 'index.html' ),
    carpeta_web(Web),
    (   \+ sub_atom(Info, _, _, _, '..'),
        atomic_list_concat([Web, '/', Info], Ruta),
        exists_file(Ruta)
    ->  tipo_mime(Ruta, Mime),
        throw(http_reply(file(Mime, Ruta)))
    ;   throw(http_reply(not_found(Info)))
    ).

% tipo_mime(+Ruta, -Mime): por la extension (los archivos que usa el frontend).
tipo_mime(Ruta, Mime) :-
    file_name_extension(_, Ext0, Ruta),
    downcase_atom(Ext0, Ext),
    (   mime(Ext, M) -> Mime = M ; Mime = 'application/octet-stream' ).

mime(html, 'text/html; charset=UTF-8').
mime(css,  'text/css; charset=UTF-8').
mime(js,   'application/javascript; charset=UTF-8').
mime(json, 'application/json; charset=UTF-8').
mime(txt,  'text/plain; charset=UTF-8').
mime(svg,  'image/svg+xml').
mime(png,  'image/png').
mime(ico,  'image/x-icon').
mime(woff2, 'font/woff2').
