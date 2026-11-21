/* app.js
   El frontend de Banda Chapuza: pinta lo que devuelve la API (src/api.pl) con el diseno de interfaz y manda lo que
   escribe el jugador. No contiene ninguna regla del juego: todo lo que sabe (que se puede hacer, por que no, que
   explica cada arbol) se lo dice el servidor. JavaScript sin dependencias ni compilacion. */
(function () {
  "use strict";

  var app = document.getElementById("app");

  // ---------------------------------------------------------------------------------------------------------
  // Estado de la interfaz (el del juego vive en el servidor)
  // ---------------------------------------------------------------------------------------------------------
  var S = {
    vista: "inicio",         // inicio | juego | final | cronica
    estado: null,            // lo ultimo que dijo /api/estado
    log: [],                 // la narracion: entradas {t, ...}
    tab: "Zona",             // pestana del panel derecho: Contratos | Zona | Explicar
    movilTab: "narracion",   // banda | narracion | panel
    drawer: false,           // movil: la explicacion como cajon
    explic: null,            // el ultimo item prueba | diag | decision
    ultimaExp: null,         // la orden que lo produjo (para repetirla al cambiar de nivel)
    abierta: 0,              // regla abierta del acordeon de la decision (indice) o -1
    escena: null,            // la escena de demostracion en curso
    textoFinal: "",
    tema: temaInicial(),
    menu: false,
    pop: null,               // familia del menu emergente de acciones
    entrada: "",
    hist: [],
    hpos: 0,
    ocupado: false,
    error: null,
    ultimoDia: null,
    sugs: false,
    inferior: "despensa",    // lo que enseña el panel de abajo a la izquierda: despensa | posiciones
    fichas: null,            // las fichas de los personajes (se piden una vez a /api/fichas)
    ficha: ""                // el personaje cuya ficha esta abierta ("" = cerrada)
  };

  function temaInicial() {
    try {
      var t = localStorage.getItem("chapuza-tema");
      if (t === "light" || t === "dark") return t;
    } catch (e) { /* sin almacenamiento */ }
    return window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
  }

  function esMovil() { return window.innerWidth <= 700; }

  // ---------------------------------------------------------------------------------------------------------
  // Utilidades
  // ---------------------------------------------------------------------------------------------------------
  var ESC = { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" };
  function esc(x) { return String(x == null ? "" : x).replace(/[&<>"']/g, function (c) { return ESC[c]; }); }
  function mayus(s) { s = String(s || ""); return s.charAt(0).toUpperCase() + s.slice(1); }
  function iniciales(nombre) {
    var m = String(nombre || "").match(/[A-ZÁÉÍÓÚÑ]/g);
    return m ? m.join("").slice(0, 2) : String(nombre || "?").charAt(0).toUpperCase();
  }

  var ICONOS = {
    cheese: '<path d="M3 10 14 4l7 6v9H3Z"/><path d="M3 10h18"/><circle cx="9" cy="15" r="1.3"/><circle cx="16" cy="17" r="1"/>',
    sword: '<path d="m14 4 6-1-1 6L9 19l-4-4Z"/><path d="m12 12 4 4M6 14l-3 3 4 4 3-3"/>',
    scroll: '<path d="M6 4h12v15H7a3 3 0 0 1 0-6h11"/><path d="M8 8h7M8 11h6"/>',
    tree: '<circle cx="12" cy="5" r="2"/><circle cx="6" cy="12" r="2"/><circle cx="18" cy="12" r="2"/><path d="M12 7v2m0 0H6v1m6-1h6v1M6 14v4m12-4v4"/><circle cx="6" cy="20" r="1.5"/><circle cx="18" cy="20" r="1.5"/>',
    moon: '<path d="M19 15.5A8 8 0 0 1 8.5 5 8 8 0 1 0 19 15.5Z"/>',
    sun: '<circle cx="12" cy="12" r="4"/><path d="M12 2v2m0 16v2M4.9 4.9l1.4 1.4m11.4 11.4 1.4 1.4M2 12h2m16 0h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>',
    bag: '<path d="M7 8h10l2 12H5Z"/><path d="M9 8c0-3 6-3 6 0"/>',
    map: '<path d="m3 6 6-3 6 3 6-3v15l-6 3-6-3-6 3Z"/><path d="M9 3v15m6-12v15"/>',
    heart: '<path d="M20 8c0 5-8 11-8 11S4 13 4 8c0-5 6-6 8-2 2-4 8-3 8 2Z"/>',
    shield: '<path d="M12 3 5 6v5c0 5 3 8 7 10 4-2 7-5 7-10V6Z"/>',
    skull: '<path d="M6 11a6 6 0 1 1 12 0c0 3-1 4-3 5v3H9v-3c-2-1-3-2-3-5Z"/><circle cx="9.5" cy="11" r="1"/><circle cx="14.5" cy="11" r="1"/><path d="M12 14v2"/>',
    crown: '<path d="m4 8 4 4 4-7 4 7 4-4-2 10H6Z"/><path d="M6 18h12"/>',
    keyboard: '<rect x="3" y="6" width="18" height="12" rx="2"/><path d="M6 10h1m3 0h1m3 0h1m3 0h1M7 14h10"/>'
  };
  function icono(nombre, tam) {
    tam = tam || 18;
    return '<svg width="' + tam + '" height="' + tam + '" viewBox="0 0 24 24" fill="none" stroke="currentColor" ' +
      'stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' + (ICONOS[nombre] || "") + "</svg>";
  }

  // ---------------------------------------------------------------------------------------------------------
  // Red
  // ---------------------------------------------------------------------------------------------------------
  function api(ruta, cuerpo) {
    var opciones = cuerpo === undefined ? {} : {
      method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(cuerpo)
    };
    return fetch(ruta, opciones).then(function (r) {
      if (!r.ok) throw new Error("El servidor respondio " + r.status);
      return r.json();
    });
  }

  function fallo(e) {
    S.ocupado = false;
    S.error = "No consigo hablar con el servidor (" + (e && e.message ? e.message : e) + "). ¿Sigue en marcha?";
    render();
  }

  // ---------------------------------------------------------------------------------------------------------
  // Procesar la respuesta de una orden: items -> narracion + paneles
  // ---------------------------------------------------------------------------------------------------------
  var CLAVES_SISTEMA = /^(dia_nuevo|nivel|llegada|impago|pago)/;

  function procesar(orden, resp, silencioso) {
    var items = resp.items || [];
    var combate = resp.estado && resp.estado.fase === "combate";
    var hayExplicacion = false;
    var textosFinal = [];
    items.forEach(function (it) {
      switch (it.tipo) {
        case "zona":
          S.log.push({ t: "zona", nombre: it.nombre, texto: it.descripcion, salidas: it.salidas });
          break;
        case "msg":
          if (silencioso) break;
          S.log.push({ t: it.clave === "contrato_nuevo" ? "nuevo" : CLAVES_SISTEMA.test(it.clave) ? "sys" : (combate ? "imp" : "msg"), texto: it.texto });
          if (it.texto.indexOf("Fin de la partida") < 0) textosFinal.push(it.texto);
          break;
        case "objetivo":
          if (silencioso) break;
          S.log.push({ t: "objetivo", texto: it.texto });
          break;
        case "aviso_comida":
          S.log.push({ t: "aviso", texto: it.texto });
          break;
        case "error":
          S.log.push({ t: "error", texto: it.texto, porQueNo: it.por_que_no, motivo: it.motivo });
          break;
        case "compania":
          S.log.push({ t: "compania", miembros: it.miembros });
          break;
        case "inventario":
          S.log.push({ t: "inventario", d: it.despensa });
          break;
        case "contratos":
          S.log.push({ t: "contratos", cs: it.contratos });
          S.tab = "Contratos";
          if (esMovil()) S.movilTab = "panel";
          break;
        case "presentes":
          S.log.push({ t: "presentes", ps: it.personajes });
          break;
        case "charla":
          S.log.push({ t: "charla", nombre: it.nombre, opciones: it.opciones });
          break;
        case "diario":
          S.log.push({ t: "diario", saberes: it.saberes });
          break;
        case "evento":
          S.log.push({ t: "evento", d: it.descripcion, opciones: it.opciones, quedan: it.quedan, zona: resp.estado ? resp.estado.zona.nombre : "" });
          break;
        case "ayuda":
          S.log.push({ t: "ayuda", comandos: it.comandos, consejo: it.consejo });
          break;
        case "escena":
          S.escena = { titulo: it.titulo, descripcion: it.descripcion, sugerencias: it.sugerencias };
          S.log.push({ t: "sys", texto: it.descripcion });
          break;
        case "escenas":
          S.log.push({ t: "escenas", escenas: it.escenas });
          break;
        case "prueba":
        case "diag":
        case "decision":
          S.explic = it;
          S.ultimaExp = orden;
          S.abierta = 0;
          hayExplicacion = true;
          break;
        default:
          if (it.tipo === "desconocido") S.log.push({ t: "msg", texto: it.texto });
      }
    });
    if (hayExplicacion && !silencioso) {
      S.tab = "Explicar";
      if (esMovil()) S.drawer = true;
    }
    if (resp.estado) {
      if (resp.estado.combate && !(S.estado && S.estado.combate)) S.inferior = "posiciones";
      S.estado = resp.estado;
      if (resp.estado.fin) {
        S.textoFinal = textosFinal.join("\n");
        S.vista = "final";
      }
      var dia = resp.estado.dia;
      if (S.ultimoDia !== null && dia !== S.ultimoDia) S.log.push({ t: "dia", dia: dia });
      S.ultimoDia = dia;
    }
    // Tras una orden de combate se ofrece explicar lo que acaba de pasar
    if (combate && !silencioso && /^(atacar|habilidad|defender)/.test(orden)) {
      S.log = S.log.filter(function (e) { return e.t !== "explicar"; });      // solo el ultimo
      S.log.push({ t: "explicar" });
    }
  }

  function enviar(texto, opciones) {
    opciones = opciones || {};
    texto = String(texto || "").trim();
    if (!texto || S.ocupado) return Promise.resolve();
    S.ocupado = true; S.error = null; S.pop = null; S.menu = false;
    if (!opciones.silencioso) {
      S.log.forEach(function (e) { if (e.t === "evento" || e.t === "charla") e.viejo = true; });     // un evento ya contestado no se vuelve a elegir
      S.log.push({ t: "cmd", texto: texto.replace(/\.$/, "") });
      if (S.hist[S.hist.length - 1] !== texto) S.hist.push(texto);
      S.hpos = S.hist.length;
    }
    return api("/api/orden", { orden: texto }).then(function (resp) {
      S.ocupado = false;
      procesar(texto.replace(/\.$/, ""), resp, opciones.silencioso);
      render({ bajar: !opciones.silencioso });
    }).catch(fallo);
  }

  function nuevaPartida() {
    S.ocupado = true; S.error = null;
    return api("/api/nueva", {}).then(function (resp) {
      S.ocupado = false;
      S.log = []; S.explic = null; S.ultimaExp = null; S.escena = null; S.drawer = false; S.menu = false; S.pop = null;
      S.tab = "Zona"; S.movilTab = "narracion"; S.ultimoDia = null; S.textoFinal = "";
      S.vista = "juego";
      // lo primero que ve el jugador (objetivo y primeros pasos): el mismo texto que la consola, sin el titulo
      (resp.bienvenida || []).slice(1).forEach(function (l) { S.log.push({ t: "sys", texto: l }); });
      procesar("mirar", resp, false);
      render({ bajar: true });
    }).catch(fallo);
  }

  function continuar() {
    S.vista = "juego";
    return enviar("mirar");
  }

  function cambiarNivel(nivel) {
    return enviar("nivel(" + nivel + ")", { silencioso: true }).then(function () {
      if (S.ultimaExp) return enviar(S.ultimaExp, { silencioso: true });
    });
  }

  // ---------------------------------------------------------------------------------------------------------
  // Piezas (devuelven HTML)
  // ---------------------------------------------------------------------------------------------------------
  function logo(tam) {
    return '<div class="game-logo">' + icono("cheese", tam) + "<span>BANDA<small>CHAPUZA</small></span></div>";
  }

  function medidor(valor, max, tipo) {
    var pct = max > 0 ? Math.max(0, Math.min(100, valor / max * 100)) : 0;
    var etiqueta = tipo === "life" ? "VIDA" : "MORAL";
    return '<div class="meter" aria-label="' + (tipo === "life" ? "Vida" : "Moral") + " " + valor + " de " + max + '">' +
      '<div class="meter-label"><span>' + etiqueta + "</span><strong>" + valor + "/" + max + "</strong></div>" +
      '<div class="meter-track ' + tipo + '"><span style="width:' + pct + '%"></span></div></div>';
  }

  function tarjetaMiembro(m, compacta) {
    var critico = m.estado !== "en_pie" || m.vida / m.vida_max < 0.3;
    var clsEstado = m.estado === "huelga" ? "strike" : (m.estado === "caido" ? "fallen" : "");
    var etiquetaEstado = m.estado === "huelga" ? "En huelga" : (m.estado === "caido" ? "Caído" : "");
    return '<article class="member-card clicable ' + (critico ? "critical" : "") + " " + clsEstado + '" data-act="ficha:' + esc(m.id) + '" title="Ver la ficha de ' + esc(m.nombre) + '" tabindex="0">' +
      '<div class="member-top"><div class="portrait">' + esc(iniciales(m.nombre)) + "</div>" +
      '<div class="member-title"><strong>' + esc(m.nombre) + "</strong><span>" + esc(mayus(m.rol)) + "</span></div>" +
      '<span class="status-dot ' + (critico || clsEstado ? "bad" : "") + '"></span></div>' +
      medidor(m.vida, m.vida_max, "life") +
      (compacta ? "" : medidor(m.moral, m.moral_max, "morale")) +
      '<div class="member-meta"><span>' + esc(mayus(m.fila)) + "</span><span>" + esc(m.rasgo_texto) + "</span>" +
      (etiquetaEstado ? '<span class="member-state">' + etiquetaEstado + "</span>" : "") + "</div></article>";
  }

  function despensa(sinTitulo) {
    var d = S.estado.despensa, c = d.categorias;
    var objetos = d.objetos.map(function (o) { return esc(o.nombre) + (o.cantidad > 1 ? " ×" + o.cantidad : ""); }).join(" · ");
    function cesta(n, txt, mudo) {
      return '<div class="' + (mudo ? "muted" : "") + '">' + icono("cheese", 22) + "<strong>" + n + "</strong><span>" + txt + "</span></div>";
    }
    return '<section class="pantry"><div class="section-heading"><span>' + (sinTitulo ? "" : "Despensa") + "</span>" +
      '<button data-cmd="inventario" aria-label="Ver despensa completa">Ver todo</button></div>' +
      '<div class="cheese-counts">' + cesta(c.fresco, "fresco", false) + cesta(c.curado, "curado", false) +
      cesta(c.rancio, "rancio", c.rancio === 0) + "</div>" +
      '<p class="objects">' + (objetos || "Sin objetos") + "</p></section>";
  }

  var ESTADOS_CONTRATO = {
    activo: ["active", "En curso"], por_cobrar: ["claim", "Por cobrar"], cumplido: ["done", "Cumplido"],
    disponible: ["open", "Disponible"], lejos: ["far", "Lejos"], bloqueado: ["locked", "Bloqueado"]
  };

  function filaContrato(c) {
    var e = ESTADOS_CONTRATO[c.estado] || ["far", c.estado];
    var cmd = c.estado === "disponible" ? "aceptar(" + c.id + ")"
      : (c.estado === "bloqueado" || c.estado === "lejos" ? "por_que_no(aceptar(" + c.id + "))" : "");
    return '<button class="contract-row ' + e[0] + '"' + (cmd ? ' data-cmd="' + esc(cmd) + '"' : "") +
      ' title="' + esc(c.descripcion) + '">' +
      '<span class="contract-seal">' + icono(e[0] === "locked" || e[0] === "far" ? "shield" : "scroll", 16) + "</span>" +
      "<span><strong>" + esc(c.nombre) + "</strong><small><b>" + e[1] + "</b> · " + esc(c.zona_nombre) + " · " + esc(c.recompensa) + (c.estado === "por_cobrar" ? " en la taberna" : "") +
      "</small></span><span class=\"arrow\">›</span></button>";
  }

  // El mapa: posiciones fijas de las seis zonas; las conexiones son las del juego.
  var POS = { taberna: [17, 17], aldea: [17, 55], bosque: [45, 80], camino_real: [52, 47], castillo: [84, 17], cuevas: [84, 76] };

  function grafoZonas() {
    var e = S.estado, aqui = e.zona.id, mapa = e.mapa;
    var salidas = {};
    e.zona.salidas.forEach(function (s) { salidas[s.id] = true; });
    var lineas = mapa.conexiones.map(function (c) {
      var a = POS[c[0]], b = POS[c[1]];
      return a && b ? "M" + a[0] + " " + a[1] + " L" + b[0] + " " + b[1] : "";
    }).join(" ");
    var nodos = mapa.zonas.map(function (z) {
      var p = POS[z.id] || [50, 50];
      var activo = z.id === aqui;
      var vecina = !!salidas[z.id];
      return '<button class="zone-node ' + (activo ? "active" : "") + '" style="left:calc(' + p[0] + "% - 46px);top:calc(" + p[1] + '% - 8px);right:auto;bottom:auto"' +
        (vecina ? ' data-cmd="ir(' + z.id + ')" title="Ir a ' + esc(z.nombre) + '"' : ' tabindex="-1"') + "><i></i><span>" + esc(z.nombre) + "</span></button>";
    }).join("");
    return '<div class="zone-graph"><svg viewBox="0 0 100 100" preserveAspectRatio="none" aria-hidden="true">' +
      '<path vector-effect="non-scaling-stroke" d="' + lineas + '"/></svg>' + nodos + "</div>";
  }

  // El objetivo actual (lo calcula el servidor con las reglas del juego). Tolera un servidor viejo sin `objetivo`.
  function bloqueObjetivo() {
    var o = S.estado && S.estado.objetivo;
    return o && o.texto ? '<p class="objetivo-actual"><b>➤</b> ' + esc(o.texto) + "</p>" : "";
  }

  function panelContratos() {
    var cs = S.estado.contratos;
    return '<p class="panel-kicker">TABLÓN DE CONTRATOS</p><h3>Asuntos pendientes</h3>' + bloqueObjetivo() +
      (cs.length ? cs.map(filaContrato).join("") : '<p class="tree-vacio">No hay contratos a la vista.</p>');
  }

  function panelZona() {
    var e = S.estado;
    return '<p class="panel-kicker">UBICACIÓN ACTUAL</p><h3>' + esc(e.zona.nombre) + "</h3>" + grafoZonas() +
      bloqueObjetivo() + '<dl class="zone-facts"><div><dt>Jornada</dt><dd>Día ' + e.dia + "</dd></div>" +
      "<div><dt>Salidas</dt><dd>" + (e.zona.salidas.map(function (s) { return esc(s.nombre); }).join(" · ") || "Ninguna") + "</dd></div></dl>";
  }

  // ---- el arbol de explicacion ----
  var TIPOS_NODO = {
    hecho: ["fact", "HECHO"], calculo: ["calc", "CÁLCULO"], negacion: ["neg", "NEGACIÓN"], corte: ["cut", "CORTE"],
    agregado: ["calc", "AGREGADO"], condicional: ["calc", "CONDICIÓN"], sin_clausula: ["neg", "SIN CLÁUSULA"], limite: ["neg", "LÍMITE"]
  };

  function nodoHTML(n) {
    var estado = n.estado === "info" ? "info" : n.estado;
    var etiqueta = "";
    if (n.tipo === "regla") etiqueta = '<span class="node-type rule">REGLA' + (n.clausula !== null ? " · CLÁUSULA " + n.clausula : "") + "</span>";
    else if (TIPOS_NODO[n.tipo]) etiqueta = '<span class="node-type ' + TIPOS_NODO[n.tipo][0] + '">' + TIPOS_NODO[n.tipo][1] + "</span>";
    var estadoTxt = n.estado === "info" ? "" : '<span class="node-status">[' + n.estado + "]</span>";
    var extra = n.tipo === "corte" ? "<small>Se descartaron las cláusulas siguientes</small>" : "";
    var texto = n.tipo === "corte" ? "corte" : (n.legible || n.texto);
    return '<div class="tree-node ' + estado + (n.tipo === "corte" ? " cut" : "") + '">' + estadoTxt + "<code>" + esc(texto) + "</code>" + etiqueta + extra + "</div>" +
      (n.plegados > 0 ? '<button class="folded" data-act="nivel:detallado">[+' + n.plegados + (n.plegados === 1 ? " nodo]" : " nodos]") + "</button>" : "");
  }

  // Los nodos llegan en lista plana con profundidad: se anidan en .branch como en el diseno.
  function arbolHTML(nodos, sinPorque) {
    // la frase "porque ..." de la raiz ya sale en su propia caja
    if (sinPorque) nodos = nodos.filter(function (n, i) { return !(n.tipo === "comentario" && n.profundidad > 0 && /^porque /.test(n.texto) && i === indicePorque(nodos)); });
    if (!nodos || !nodos.length) return '<div class="tree-scroll"><p class="tree-vacio">Sin nodos que mostrar.</p></div>';
    var html = "", abiertos = 0;
    for (var i = 0; i < nodos.length; i++) {
      var n = nodos[i], sig = nodos[i + 1];
      html += nodoHTML(n);
      if (sig && sig.profundidad > n.profundidad) { html += '<div class="branch">'; abiertos++; }
      else if (sig && sig.profundidad < n.profundidad) {
        var cierres = Math.min(abiertos, n.profundidad - sig.profundidad);
        for (var k = 0; k < cierres; k++) { html += "</div>"; abiertos--; }
      }
    }
    while (abiertos-- > 0) html += "</div>";
    return '<div class="tree-scroll">' + html + "</div>";
  }

  function indicePorque(nodos) {
    for (var i = 0; i < nodos.length; i++) if (nodos[i].tipo === "comentario" && /^porque /.test(nodos[i].texto)) return i;
    return -1;
  }

  function conmutadorNivel() {
    var n = S.estado.nivel;
    return '<div class="segmented"><button class="' + (n === "resumido" ? "active" : "") + '" data-act="nivel:resumido">Resumido</button>' +
      '<button class="' + (n === "detallado" ? "active" : "") + '" data-act="nivel:detallado">Detallado</button></div>';
  }

  function arbolConCajas(it, compacto) {
    var cajas = "";
    if (it.porque) cajas += '<div class="reason-box"><strong>Porque…</strong><p>' + esc(it.porque_legible || it.porque) + "</p></div>";
    if (it.notas && it.notas.length) {
      cajas += '<div class="reason-box"><strong>Notas</strong>' + it.notas.map(function (t) { return "<p>" + esc(t) + "</p>"; }).join("") + "</div>";
    }
    if (it.narrador) cajas += '<div class="narrator-box"><strong>Narrador:</strong><p>' + esc(it.narrador) + "</p></div>";
    return '<div class="logic-tree ' + (compacto ? "compact" : "") + " " + (S.estado.nivel === "detallado" ? "is-detailed" : "") + '">' +
      '<div class="logic-toolbar"><span class="eyebrow">' + icono("tree", 15) + " EXPLICACIÓN LÓGICA</span>" + conmutadorNivel() + "</div>" +
      '<p class="panel-kicker" style="margin:6px 0 8px">' + (it.tipo === "diag" ? "POR QUÉ NO · " : "POR QUÉ SÍ · ") + esc(it.accion || "") + "</p>" +
      arbolHTML(it.nodos, !!it.porque) + cajas + "</div>";
  }

  function decisionHTML(it) {
    var r = it.regla, resumen;
    if (r.tipo === "corte") resumen = "Eligió la regla de prioridad <strong>" + r.prioridad + " de " + r.total + "</strong> · el corte descartó las demás.";
    else if (r.tipo === "escolta") resumen = "Lady Clotilde va escoltada: el primero en actuar de cada ronda se ceba con ella.";
    else if (r.tipo === "comodin") resumen = "Eligió la última regla (<strong>prioridad " + r.prioridad + " de " + r.total + "</strong>): el comodín, cuando no hay nada mejor.";
    else resumen = "Esta decisión no sigue la lista de prioridades.";
    var raiz = it.nodos && it.nodos[0] ? (it.nodos[0].legible || it.nodos[0].texto) : "";
    var tarjeta = '<article class="winning-rule"><div><span>REGLA GANADORA</span>' + (r.tipo === "corte" ? '<b class="node-type cut">CORTE</b>' : "") + "</div>" +
      "<h3>" + esc(it.accion ? it.accion.texto : "Decisión") + "</h3><p>" + resumen + "</p>" + (raiz ? "<code>" + esc(raiz) + "</code>" : "") + "</article>";
    var filas = it.descartes.map(function (d, i) {
      var abierta = S.abierta === i;
      return '<article class="rule-row"><button data-act="regla:' + i + '"><span class="rule-number">' + d.prioridad + "</span>" +
        "<span><strong>" + esc(d.titulo) + "</strong><small>" + esc(d.motivo_legible || d.motivo || d.comentario) + "</small></span><b>" + (abierta ? "−" : "+") + "</b></button>" +
        (abierta ? '<div class="mini-rule-tree">' + arbolHTML(d.nodos) + "</div>" : "") + "</article>";
    }).join("");
    var ganadora = "", posteriores = "";
    if (r.tipo === "corte") {
      ganadora = '<article class="rule-row winner"><div><span class="rule-number">' + r.prioridad + "</span><span><strong>" +
        esc(it.accion ? it.accion.texto : "") + "</strong><small>la primera cuya condición se cumple</small></span><b>GANADORA</b></div></article>";
      for (var p = r.prioridad + 1; p <= r.total; p++) {
        posteriores += '<article class="rule-row discarded"><div><span class="rule-number">' + p + "</span><span><strong>Regla " + p +
          "</strong><small>descartada por el corte de la regla " + r.prioridad + "</small></span><b>CORTE</b></div></article>";
      }
    }
    return '<div class="enemy-decision"><div class="logic-toolbar"><p class="panel-kicker">DECISIÓN DE ' + esc(String(it.enemigo).toUpperCase()) + "</p>" + conmutadorNivel() + "</div>" +
      tarjeta + '<div class="rule-accordion"><h4>Reglas de mayor prioridad que no se aplicaron</h4>' + (filas || '<p class="tree-vacio">Ninguna: era la primera.</p>') +
      ganadora + posteriores + "</div>" +
      (it.narrador ? '<div class="narrator-box"><strong>Narrador:</strong><p>' + esc(it.narrador) + "</p></div>" : "") + "</div>";
  }

  function panelExplicar(compacto) {
    var it = S.explic;
    if (!it) {
      return '<p class="panel-kicker">EXPLICAR</p><h3>Nada que explicar todavía</h3>' +
        '<p class="tree-vacio">Haz algo y pregunta por qué. También sirven <code>explicar.</code> y <code>por_que_no(accion).</code></p>' +
        '<div class="explicar-fila" style="margin-left:0"><button data-cmd="explicar">' + icono("tree", 15) + " Explicar la última acción</button></div>";
    }
    return it.tipo === "decision" ? decisionHTML(it) : arbolConCajas(it, compacto);
  }

  function panelDerecho(explicarAbierto) {
    var tabs = ["Contratos", "Zona", "Explicar"].map(function (t) {
      return '<button data-act="tab:' + t + '" class="' + (S.tab === t ? "active" : "") + '">' + t + (t === "Explicar" && S.explic ? '<span class="tab-dot"></span>' : "") + "</button>";
    }).join("");
    var cuerpo = S.tab === "Contratos" ? panelContratos() : (S.tab === "Zona" ? panelZona() : panelExplicar(true));
    return '<aside class="right-panel"><div class="tabs">' + tabs + '</div><div class="right-content">' + cuerpo + "</div></aside>";
  }

  // ---- la ficha de un personaje (modal): cifras, rasgo, habilidad, fuerte/debil, moral y progresion ----
  function barra(valor, max, etiqueta, extra) {
    var pct = max > 0 ? Math.round(valor / max * 100) : 0;
    return '<div class="fila-stat"><span class="etq">' + etiqueta + '</span><span class="barra" aria-hidden="true"><i style="width:' + pct + '%"></i></span><strong>' + valor + (extra || "") + "</strong></div>";
  }

  function fichaHTML() {
    var F = S.fichas;
    if (!S.ficha || !F || !S.estado) return "";
    var f = F.miembros.filter(function (m) { return m.id === S.ficha; })[0] || F.miembros[0];
    var vivo = S.estado.banda.filter(function (m) { return m.id === f.id; })[0];
    var tabs = F.miembros.map(function (m) {
      return '<button class="' + (m.id === f.id ? "active" : "") + '" data-act="ficha:' + esc(m.id) + '">' + esc(String(m.nombre).replace(/^(Sir|Madame) /, "")) + "</button>";
    }).join("");
    var stats = barra(f.ataque, f.maximos.ataque, "Ataque") + barra(f.defensa, f.maximos.defensa, "Defensa") + barra(f.vida_max, f.maximos.vida, "Vida máx.") +
      '<div class="fila-stat"><span class="etq">Sueldo</span><span class="barra vacia"></span><strong>' + f.sueldo + (f.sueldo === 1 ? " queso" : " quesos") + "</strong></div>";
    var ahora = vivo ? '<p class="ahora">Ahora: vida <strong>' + vivo.vida + "/" + vivo.vida_max + "</strong> · moral <strong>" + vivo.moral + "/" + vivo.moral_max + "</strong>" +
      (vivo.estado === "huelga" ? " · <strong>en huelga</strong>" : (vivo.estado === "caido" ? " · <strong>caído</strong>" : "")) + "</p>" : "";
    function chips(lista, cls, vacio) {
      return lista.length ? lista.map(function (t) { return '<li class="' + cls + '">' + esc(t) + "</li>"; }).join("") : '<li class="neutro">' + vacio + "</li>";
    }
    var h = f.habilidad;
    var moral = F.moral.map(function (t) {
      return "<li><strong>" + esc(({ critica: "Crítica", baja: "Baja", normal: "Normal", alta: "Alta" })[t.nivel] || mayus(t.nivel)) + "</strong> (" + (t.desde === t.hasta ? t.desde : t.desde + "–" + t.hasta) + "): " +
        (t.modificador > 0 ? "+" : (t.modificador < 0 ? "−" : "")) + Math.abs(t.modificador) + " al ataque y a la iniciativa</li>";
    }).join("");
    return '<div class="menu-backdrop"><section class="ficha-modal" role="dialog" aria-modal="true" aria-label="Ficha de ' + esc(f.nombre) + '">' +
      '<header><div><p class="panel-kicker">LA BANDA · FICHAS</p><h2>' + esc(f.nombre) + '</h2><p class="sub">' + esc(mayus(f.rol)) + " · " + esc(mayus(f.fila)) + ' por defecto</p></div>' +
      '<button data-act="ficha-cerrar" aria-label="Cerrar">×</button></header>' +
      '<div class="segmented ficha-tabs" role="tablist">' + tabs + "</div>" +
      '<div class="ficha-cuerpo">' +
      '<section><h3>Cifras</h3>' + stats + ahora + '<p class="nota">' + esc(f.alcance_texto) + "</p></section>" +
      '<section><h3>Fuerte y débil</h3><ul class="chips">' + chips(f.fuertes, "fuerte", "Nada destacable") + chips(f.debiles, "debil", "Sin puntos débiles destacados") + "</ul></section>" +
      '<section><h3>Rasgo · ' + esc(f.rasgo_nombre) + "</h3><p>" + esc(f.rasgo_texto) + "</p></section>" +
      '<section><h3>Habilidad · ' + esc(h.nombre) + '</h3><p>' + esc(h.efecto) + '</p><p class="meta"><span class="coste">' + esc(h.coste) + "</span> " + esc(h.objetivo) +
      '. En el juego: <code>' + esc(h.comando) + "</code></p></section>" +
      '<section class="progresion"><h3>¿Suben de nivel?</h3><p><strong>' + (F.progresion.sube_de_nivel ? "Sí" : "No.") + "</strong> " + esc(F.progresion.texto) + "</p><p>" + esc(F.progresion.detalle) + "</p></section>" +
      '<section><h3>La moral</h3><ul class="moral">' + moral + '</ul><p class="nota">Con moral ' + F.reglas.huelga_si_moral_hasta + " o menos, el personaje se pone en <strong>huelga</strong> y no combate. Defender suma +" + F.reglas.bono_defender +
      " de defensa hasta tu próximo turno; descansar cuesta " + F.reglas.coste_descanso + " quesos.</p></section>" +
      "</div></section></div>";
  }

  function abrirFicha(id) {
    S.menu = false; S.pop = null; S.ficha = id;
    if (S.fichas) { render(); return; }
    api("/api/fichas").then(function (j) { S.fichas = j; render(); }).catch(function (e) { S.ficha = ""; fallo(e); });
  }

  // ---- el panel de abajo a la izquierda: despensa o posiciones ----
  // La formacion es una malla de fichas con las iniciales. Fuera de combate: la Banda en retaguardia y frente.
  // En combate: la Banda a un lado y los enemigos al otro, cada uno con su frente y su retaguardia. La ficha de
  // un enemigo es un atajo para atacarlo; una ficha con anillo es a quien le toca.
  function fichaHeroe(m, turno, conNombre) {
    var cls = "ficha heroe" + (m.id === turno ? " turno" : "") + (m.estado === "caido" ? " caido" : "") + (m.estado === "huelga" ? " huelga" : "");
    var nombre = String(m.nombre).replace(/^(Sir|Madame) /, "");
    return '<span class="celda-ficha"><span class="' + cls + '" title="' + esc(m.nombre + " · vida " + m.vida + "/" + m.vida_max +
      (m.estado === "huelga" ? " · en huelga" : "") + (m.estado === "caido" ? " · caído" : "")) + '">' + esc(iniciales(m.nombre)) + "</span>" +
      (conNombre ? "<small>" + esc(nombre) + "</small>" : "") + "</span>";
  }

  function fichaEnemigo(e, repetidos) {
    var n = (String(e.id).match(/(\d+)\)?$/) || [])[1];
    var etiqueta = iniciales(e.nombre) + (repetidos[e.tipo_enemigo] > 1 && n ? n : "");
    var cls = "ficha enemigo" + (e.caido ? " caido" : "");
    var titulo = e.nombre + " · vida " + e.vida + "/" + e.vida_max + (e.caido ? " · caído" : " · pulsa para atacarlo");
    var accion = e.caido ? "" : ' data-cmd="atacar(' + esc(e.id) + ')"';
    return '<span class="celda-ficha"><button class="' + cls + '"' + accion + (e.caido ? " disabled" : "") + ' title="' + esc(titulo) + '">' + esc(etiqueta) + "</button></span>";
  }

  function formacionHTML() {
    var e = S.estado, c = e.combate, turno = c ? c.turno.id : null;
    function celda(cab, fichas) { return '<div class="celda"><span class="cab">' + cab + '</span><div class="fichas">' + (fichas || '<span class="vacia">—</span>') + "</div></div>"; }
    var ret = e.banda.filter(function (m) { return m.fila === "retaguardia"; }).map(function (m) { return fichaHeroe(m, turno, !c); }).join("");
    var fre = e.banda.filter(function (m) { return m.fila === "frente"; }).map(function (m) { return fichaHeroe(m, turno, !c); }).join("");
    var nota = '<p class="nota-formacion">Los de retaguardia solo reciben golpes cuando cae el frente.</p>';
    if (!c) {
      return '<section class="formacion"><p class="panel-kicker">FORMACIÓN DE LA BANDA</p><div class="malla fuera">' + celda("Retaguardia", ret) + celda("Frente", fre) + "</div>" + nota + "</section>";
    }
    var repetidos = {};
    c.enemigos.forEach(function (x) { repetidos[x.tipo_enemigo] = (repetidos[x.tipo_enemigo] || 0) + 1; });
    var eFre = c.enemigos.filter(function (x) { return x.fila === "frente"; }).map(function (x) { return fichaEnemigo(x, repetidos); }).join("");
    var eRet = c.enemigos.filter(function (x) { return x.fila !== "frente"; }).map(function (x) { return fichaEnemigo(x, repetidos); }).join("");
    return '<section class="formacion"><p class="panel-kicker">EN COMBATE · RONDA ' + c.ronda + '</p><div class="malla combate">' +
      celda("Ret.", ret) + celda("Fte.", fre) + '<div class="vs" aria-hidden="true">' + icono("sword", 16) + "</div>" + celda("Fte.", eFre) + celda("Ret.", eRet) + "</div>" + nota + "</section>";
  }

  function panelInferior() {
    var pos = S.inferior === "posiciones";
    return '<div class="panel-inferior"><div class="segmented" role="tablist">' +
      '<button role="tab" aria-selected="' + !pos + '" class="' + (pos ? "" : "active") + '" data-act="inf:despensa">Despensa</button>' +
      '<button role="tab" aria-selected="' + pos + '" class="' + (pos ? "active" : "") + '" data-act="inf:posiciones">Posiciones</button></div>' +
      (pos ? formacionHTML() : despensa(true)) + "</div>";
  }

  // ---- la narracion ----
  var GRUPOS_AYUDA = [
    ["Movimiento", ["mirar", "ir"]], ["Banda", ["compania", "inventario", "descansar", "pagar"]],
    ["Contratos", ["contratos", "aceptar", "elegir"]], ["Combate", ["atacar", "defender", "habilidad"]],
    ["Explicar", ["explicar", "por_que_no", "nivel"]], ["Otros", ["ayuda", "salir"]]
  ];

  function ayudaHTML(comandos, consejo) {
    var grupos = GRUPOS_AYUDA.map(function (g) {
      var lista = g[1].filter(function (c) { return comandos.some(function (x) { return x.nombre === c; }); });
      if (!lista.length) return "";
      var cmds = lista.map(function (c) {
        var info = comandos.filter(function (x) { return x.nombre === c; })[0];
        return esc(info.texto);
      }).join("<br>");
      return '<div class="log-block" style="margin:0"><strong>' + g[0] + "</strong><code style=\"font-size:13px;line-height:1.55\">" + cmds + "</code></div>";
    }).join("");
    return '<section class="help-panel"><p class="panel-kicker">REFERENCIA DE COMANDOS</p><h2>¿Qué puede hacer la banda?</h2>' +
      (consejo ? '<div class="log-block" style="margin:10px 0 0"><strong>Ahora mismo</strong><span>' + esc(consejo) + "</span></div>" : "") +
      "<p>Escribe una orden o pulsa un botón. Los paréntesis son obligatorios; el dramatismo, opcional.</p>" +
      '<div style="display:grid;gap:10px;margin-top:14px">' + grupos + "</div>" +
      '<div class="help-tip"><kbd>↑</kbd><span><strong>Historial de órdenes</strong>Recupera lo último que escribiste, incluidos tus errores más creativos.</span></div></section>';
  }

  // El evento con opciones (EventChoice del diseno).
  function eventoHTML(e) {
    var opciones = e.opciones.map(function (o) {
      if (e.viejo) {
        return '<button class="disabled" disabled><kbd>' + o.numero + "</kbd><span><strong>" + esc(o.texto) + "</strong><small>" + esc(o.quien) + " · ya resuelto</small></span></button>";
      }
      var cmd = o.disponible ? "elegir(" + o.numero + ")" : "por_que_no(elegir(" + o.numero + "))";
      return '<button class="' + (o.disponible ? "" : "disabled") + '" data-cmd="' + esc(cmd) + '"><kbd>' + o.numero + "</kbd><span><strong>" + esc(o.texto) + "</strong><small>" +
        esc(o.quien) + " · " + (o.disponible ? "Disponible" : "No disponible") + "</small>" + (o.disponible ? "" : "<u>¿por qué no?</u>") + "</span></button>";
    }).join("");
    var marcas = ""; for (var i = 0; i < e.quedan; i++) marcas += "<i></i>";
    return '<section class="event-choice"><p class="panel-kicker">EVENTO · ' + esc(String(e.zona || "").toUpperCase()) + "</p><h2>¿Qué hace la banda?</h2><p>" + esc(e.d) + "</p>" +
      '<div class="event-options">' + opciones + "</div>" + (e.viejo ? "" : '<div class="attempts"><span>Intentos que quedan</span><strong>' + e.quedan + "</strong>" + marcas + "</div>") + "</section>";
  }

  // Hablar con la gente: quien hay aqui, la escena con sus opciones y el diario.
  function presentesHTML(e) {
    if (!e.ps.length) return '<div class="narration-line system"><span class="line-mark">◆</span><p>Aquí no hay nadie con quien hablar.</p></div>';
    return '<section class="event-choice"><p class="panel-kicker">GENTE</p><h2>Con quién hablar</h2><div class="event-options">' + e.ps.map(function (p) {
      var hecha = p.estado === "hecha";
      return '<button class="' + (hecha ? "disabled" : "") + '" data-cmd="hablar(' + esc(p.id) + ')"><span><strong>' + esc(mayus(p.nombre)) + "</strong><small>" + esc(p.quien) +
        (hecha ? " · ya hablado" : p.estado === "abierta" ? " · a medias" : "") + "</small></span></button>";
    }).join("") + "</div></section>";
  }

  function charlaHTML(e) {
    var opciones = e.opciones.map(function (o) {
      if (e.viejo) {
        return '<button class="disabled" disabled><kbd>' + o.numero + "</kbd><span><strong>" + esc(o.texto) + "</strong><small>" + esc(o.quien) + " · ya resuelto</small></span></button>";
      }
      var cmd = o.disponible ? "elegir(" + o.numero + ")" : "por_que_no(elegir(" + o.numero + "))";
      return '<button class="' + (o.disponible ? "" : "disabled") + '" data-cmd="' + esc(cmd) + '"><kbd>' + o.numero + "</kbd><span><strong>" + esc(o.texto) + "</strong><small>" +
        esc(o.quien) + " · " + (o.disponible ? "Disponible" : "No disponible") + "</small>" + (o.disponible ? "" : "<u>¿por qué no?</u>") + "</span></button>";
    }).join("");
    return '<section class="event-choice"><p class="panel-kicker">CHARLA · ' + esc(String(e.nombre || "").toUpperCase()) + "</p><h2>¿Qué hace la banda?</h2>" +
      '<div class="event-options">' + opciones + "</div></section>";
  }

  function diarioHTML(e) {
    if (!e.saberes.length) return '<div class="narration-line system"><span class="line-mark">◆</span><p>El diario está en blanco: todavía no sabéis nada del Gran Rancio. Hablad con la gente.</p></div>';
    return '<section class="event-choice diario"><p class="panel-kicker">DIARIO DE LA BANDA</p><h2>Lo que sabéis del Gran Rancio</h2><ul>' +
      e.saberes.map(function (s) { return "<li>" + esc(s.texto) + "</li>"; }).join("") + "</ul></section>";
  }

  // La despensa completa (PantryFull del diseno).
  function despensaCompletaHTML(d) {
    var lotes = d.lotes.map(function (l) {
      return '<article><div class="lot-icon">' + icono("cheese", 24) + "</div><div><strong>" + esc(mayus(l.tipo)) + "</strong><small>Edad " + l.edad + " días</small></div>" +
        '<span class="freshness ' + esc(l.categoria) + '">' + esc(mayus(l.categoria)) + "</span><div><small>Cantidad</small><b>" + l.cantidad + (l.cantidad === 1 ? " queso" : " quesos") + "</b></div><strong>×" + l.cantidad + "</strong></article>";
    }).join("");
    var objetos = d.objetos.map(function (o) { return "<div><span>" + esc(o.nombre) + "</span><small></small><b>×" + o.cantidad + "</b></div>"; }).join("");
    return '<section class="pantry-full"><header><div><p class="panel-kicker">INVENTARIO DE LA BANDA</p><h2>Despensa completa</h2></div><span>' + d.total + " piezas · valor total " + d.valor +
      ' quesos</span></header><div class="pantry-lots">' + (lotes || '<p class="tree-vacio">La despensa está vacía.</p>') + '</div><div class="object-list"><h3>Objetos</h3>' +
      (objetos || '<p class="tree-vacio">Sin objetos.</p>') + "</div></section>";
  }

  // La cronica: cada orden con lo que respondio el juego.
  function entradasCronica() {
    var dia = 1, lista = [], actual = null;
    S.log.forEach(function (e) {
      if (e.t === "dia") { dia = e.dia; return; }
      if (e.t === "cmd") { actual = { dia: dia, cmd: e.texto, textos: [] }; lista.push(actual); return; }
      var txt = e.t === "zona" ? e.nombre + ". " + e.texto : (e.texto || "");
      if (!txt) return;
      if (!actual) { actual = { dia: dia, cmd: "mirar", textos: [] }; lista.push(actual); }
      actual.textos.push(txt);
    });
    return lista;
  }

  function cronicaHTML() {
    var es = entradasCronica();
    return '<div class="game-frame ' + S.tema + ' desktop-game"><section class="chronicle"><header><p class="panel-kicker">HISTORIAL DE LA PARTIDA</p><h2>Crónica completa</h2><span>' +
      (S.estado ? S.estado.dia : 1) + " días · " + es.length + ' órdenes</span></header><div class="chronicle-scroll">' +
      (es.map(function (x) { return "<article><time>DÍA " + x.dia + "</time><code>&gt; " + esc(x.cmd) + "</code><p>" + esc(x.textos.join(" ")) + "</p></article>"; }).join("") || '<p class="tree-vacio">Todavía no hay nada que contar.</p>') +
      '</div><footer><button data-act="exportar">Exportar como texto</button><button class="primary" data-act="volver">Volver a la partida</button></footer></section></div>';
  }

  function exportarCronica() {
    var texto = entradasCronica().map(function (x) { return "DÍA " + x.dia + "\n> " + x.cmd + "\n" + x.textos.join("\n") + "\n"; }).join("\n");
    var a = document.createElement("a");
    a.href = URL.createObjectURL(new Blob([texto], { type: "text/plain;charset=utf-8" }));
    a.download = "cronica-banda-chapuza.txt";
    document.body.appendChild(a); a.click(); document.body.removeChild(a);
  }

  // Conexion perdida / consultando las reglas (SystemState del diseno).
  function sistemaHTML(cargando) {
    return '<div class="game-frame ' + S.tema + ' desktop-game"><section class="system-state"><div class="' + (cargando ? "loader-cheese" : "offline-icon") + '">' + (cargando ? icono("cheese", 34) : "!") + "</div>" +
      '<p class="panel-kicker">' + (cargando ? "CONSULTANDO LAS REGLAS" : "CONEXIÓN INTERRUMPIDA") + "</p><h2>" + (cargando ? "El Prolog está pensando…" : "No consigo hablar con el servidor") + "</h2><p>" +
      (cargando ? "Ordenando hechos, cláusulas y una cantidad prudente de queso." : "La banda sigue aquí. Las reglas, de momento, están detrás de una puerta cerrada.") + "</p>" +
      (cargando ? '<div class="loading-lines"><i></i><i></i><i></i></div>' : '<div class="system-actions"><button class="primary" data-act="reintentar">Reintentar</button></div>') + "</section></div>";
  }

  function entradaLog(e) {
    switch (e.t) {
      case "aviso": return '<div class="narration-line aviso-comida"><span class="line-mark">⚠</span><p>' + esc(e.texto) + "</p></div>";
      case "objetivo": return '<div class="narration-line objetivo"><span class="line-mark">➤</span><p>' + esc(e.texto) + "</p></div>";
      case "nuevo": return '<div class="narration-line objetivo nuevo"><span class="line-mark">★</span><p>' + esc(e.texto) + "</p></div>";
      case "dia": return '<div class="day-divider"><span>DÍA ' + e.dia + "</span></div>";
      case "cmd": return '<div class="command-line"><span>&gt;</span> ' + esc(e.texto) + "</div>";
      case "sys": return '<div class="narration-line system"><span class="line-mark">◆</span><p>' + esc(e.texto) + "</p></div>";
      case "msg": return '<div class="narration-line"><span class="line-mark">§</span><p>' + esc(e.texto) + "</p></div>";
      case "imp": return '<div class="narration-line important"><span class="line-mark">⚔</span><p>' + esc(e.texto) + "</p></div>";
      case "zona":
        return '<div class="narration-line"><span class="line-mark">§</span><p><span class="escena-titulo">' + esc(e.nombre) + "</span>" + esc(e.texto) +
          '<span class="salidas">Salidas: ' + (e.salidas.map(function (s) { return '<button class="text-button" style="display:inline;padding:0 3px" data-cmd="ir(' + s.id + ')">' + esc(s.nombre) + "</button>"; }).join(" · ") || "ninguna") + "</span></p></div>";
      case "error":
        return '<div class="command-line denied"><span>!</span> orden no válida</div><div class="invalid-command"><strong>No se pudo</strong><p>' + esc(e.texto) + "</p></div>" +
          (e.porQueNo ? '<button class="why-inline" data-cmd="por_que_no(' + esc(e.porQueNo) + ')">' + icono("tree", 15) + " Ver por qué no</button>"
            : (/^(no_entiendo|sintaxis|falta_argumento|comando_vacio)$/.test(e.motivo) ? '<button class="why-inline help-link" data-cmd="ayuda">' + icono("scroll", 15) + " Ver ayuda</button>" : ""));
      case "compania":
        return '<div class="log-block"><strong>La compañía</strong>' + e.miembros.map(function (m) {
          return '<div class="fila"><span>' + esc(m.nombre) + " · " + esc(mayus(m.rol)) + "</span><span>vida " + m.vida + "/" + m.vida_max + " · moral " + m.moral + "/10 · " + esc(m.fila) + "</span></div>";
        }).join("") + "</div>";
      case "inventario": return despensaCompletaHTML(e.d);
      case "contratos": return '<div class="narration-line system"><span class="line-mark">◆</span><p>El tablón de contratos está en el panel de la derecha.</p></div>';
      case "evento": return eventoHTML(e);
      case "presentes": return presentesHTML(e);
      case "charla": return charlaHTML(e);
      case "diario": return diarioHTML(e);
      case "ayuda": return ayudaHTML(e.comandos, e.consejo);
      case "escenas":
        return '<div class="log-opciones">' + e.escenas.map(function (s) {
          return '<button data-cmd="demo(' + s.nombre + ')" title="' + esc(s.descripcion) + '">' + esc(s.titulo) + "</button>";
        }).join("") + "</div>";
      case "explicar": return '<div class="explicar-fila"><button data-cmd="explicar">' + icono("tree", 15) + " Explicar lo que ha pasado</button></div>";
      default: return "";
    }
  }

  function narracion() {
    return '<div class="narrative" id="narrativa">' + S.log.map(entradaLog).join("") + "</div>";
  }

  function tiraEnemigos() {
    var c = S.estado.combate;
    if (!c) return "";
    return '<div class="enemy-strip">' + c.enemigos.map(function (e) {
      var pct = e.vida_max ? Math.max(0, e.vida / e.vida_max * 100) : 0;
      return '<article class="enemy-card"' + (e.caido ? ' style="opacity:.55"' : "") + '><div class="enemy-icon">' + icono("skull", 19) + "</div><div><strong>" + esc(e.nombre) + "</strong><span>" +
        (e.caido ? "Caído" : esc(mayus(e.fila))) + '</span><div class="enemy-life"><i style="width:' + pct + '%"></i></div></div><b>' + e.vida + "/" + e.vida_max + "</b></article>";
    }).join("") + "</div>";
  }

  function bannerCombate() {
    var c = S.estado.combate;
    if (!c) return "";
    var chips = c.orden.map(function (o, i) { return '<i title="' + esc(o.nombre) + '"' + (i === 0 ? ' style="outline:2px solid #fff"' : "") + ">" + esc(iniciales(o.nombre)) + "</i>"; }).join("");
    return '<div class="combat-banner">' + icono("sword", 23) + "<div><span>COMBATE · RONDA " + c.ronda + "</span><strong>Turno de " + esc(c.turno.nombre) + '</strong></div><div class="turn-order">' + chips + "</div></div>";
  }

  // En movil las sugerencias se pliegan: ocupan media pantalla.
  // En movil las sugerencias se pliegan (details, como en el diseno).
  function bannerEscena(movil) {
    if (!S.escena) return "";
    var botones = S.escena.sugerencias.map(function (c) { return '<button data-cmd="' + esc(c) + '">' + esc(c) + "</button>"; }).join("");
    return '<aside class="demo-banner ' + (movil ? "collapsible" : "") + '"><span>ESCENA: ' + esc(S.escena.titulo.toUpperCase()) + "</span><details" + (!movil || S.sugs ? " open" : "") +
      '><summary data-act="sugs">Para probar</summary><div>' + botones + "</div></details></aside>";
  }

  // ---- la barra de acciones y la linea de ordenes ----
  var ETIQUETAS = { mirar: "Mirar", ir: "Ir a…", inventario: "Inventario", contratos: "Contratos", compania: "Compañía", pagar: "Pagar", descansar: "Descansar", hablar: "Hablar", diario: "Diario",
    atacar: "Atacar", defender: "Defender", habilidad: "Habilidad" };

  function accionesRapidas() {
    var e = S.estado, combate = e.fase === "combate", fam = {};
    e.acciones.forEach(function (a) { (fam[a.familia] = fam[a.familia] || []).push(a); });
    var orden = combate ? ["atacar", "defender", "habilidad"] : ["mirar", "ir", "hablar", "diario", "inventario", "contratos", "compania", "pagar", "descansar"];
    var botones = orden.filter(function (f) { return fam[f]; }).map(function (f) {
      var todas = fam[f], ok = todas.filter(function (a) { return a.habilitada; });
      var etq = ETIQUETAS[f];
      if (!ok.length) {
        return '<button class="disabled-action" data-cmd="por_que_no(' + esc(todas[0].comando) + ')" title="' + esc(todas[0].motivo || "") + '">' + etq + "<small>¿por qué no?</small></button>";
      }
      if (ok.length === 1 && f !== "ir") return '<button data-cmd="' + esc(ok[0].comando) + '">' + etq + "</button>";
      return '<button data-act="pop:' + f + '" aria-haspopup="true">' + etq + "</button>";
    });
    botones.push('<button data-cmd="explicar">Explicar</button>');
    botones.push('<button data-cmd="ayuda">Ayuda</button>');
    return '<div class="quick-actions">' + botones.join("") + "</div>";
  }

  // ChoiceMenu del diseno: selector de zona, objetivo de ataque y objetivo de habilidad.
  var SELECTORES = {
    ir: ["Ir a…", "Elige una zona conectada"], hablar: ["Hablar con…", "Elige con quién"], atacar: ["Atacar a…", "Elige un objetivo"], habilidad: ["Habilidad sobre…", "Elige un objetivo"]
  };

  function nombreDe(a) { return String(a.etiqueta).replace(/^(Ir a|Atacar a|Habilidad contra|Hablar con) /, ""); }

  function razonDe(a) {
    if (!a.habilitada) return a.motivo || "No disponible";
    if (a.aviso) return "⚠ " + a.aviso;
    if (a.familia === "atacar") {
      var c = S.estado.combate, e = c && c.enemigos.filter(function (x) { return a.comando.indexOf("(" + x.tipo_enemigo + ")") >= 0 && !x.caido; })[0];
      return e ? mayus(e.fila) + " · " + e.vida + "/" + e.vida_max + " vida" : "Disponible";
    }
    return a.familia === "ir" ? "Zona conectada" : "Alcance válido";
  }

  function menuEmergente() {
    if (!S.pop || !S.estado) return "";
    var lista = S.estado.acciones.filter(function (a) { return a.familia === S.pop; });
    var t = SELECTORES[S.pop] || ["Elegir", ""];
    return '<aside class="choice-menu" role="dialog" aria-modal="true" aria-label="' + esc(t[0]) + '"><header><div><p class="panel-kicker">' + esc(t[1]) + "</p><h3>" + esc(t[0]) +
      '</h3></div><button data-act="pop-cerrar" aria-label="Cerrar">×</button></header><div>' + lista.map(function (a, i) {
        var cmd = a.habilitada ? a.comando : "por_que_no(" + a.comando + ")";
        return '<button class="' + (a.habilitada ? "" : "unavailable") + '" data-cmd="' + esc(cmd) + '"><kbd>' + (i + 1) + "</kbd><span><strong>" + esc(nombreDe(a)) + "</strong><small>" + esc(razonDe(a)) + "</small>" +
          (a.habilitada ? "" : "<u>¿por qué no?</u>") + "</span><b>›</b></button>";
      }).join("") + '</div><p class="choice-hint">↑↓ para moverte · Intro para elegir · Esc para cerrar</p></aside>';
  }

  function areaOrdenes() {
    var combate = S.estado.fase === "combate";
    return '<div class="command-area">' + accionesRapidas() +
      '<label class="command-input"><span>&gt;</span><input id="orden" autocomplete="off" autocapitalize="off" spellcheck="false" aria-label="Escribe una orden" ' +
      'placeholder="' + (combate ? "atacar(bandido_torpe)" : "Escribe una orden…") + '" value="' + esc(S.entrada) + '"><kbd>INTRO ↵</kbd></label>' +
      '<p class="hint">' + icono("keyboard", 13) + ' Prueba <button data-cmd="ayuda">ayuda()</button> · ↑ recupera órdenes anteriores</p></div>';
  }

  function menuPrincipal() {
    if (!S.menu || !S.estado) return "";
    var n = S.estado.nivel;
    var cabecera = '<header><div><p class="panel-kicker">PARTIDA · DÍA ' + S.estado.dia + '</p><h2>Menú</h2></div><button data-act="menu" aria-label="Cerrar menú">×</button></header>';
    var cuerpo;
    if (S.menu === "confirmar") {
      cuerpo = '<div class="new-game-confirm">' + icono("shield", 34) + "<h3>¿Empezar una nueva partida?</h3><p>Se perderá el progreso de esta expedición.</p>" +
        '<div><button data-act="menu-volver">Cancelar</button><button class="danger" data-act="nueva">Sí, empezar de nuevo</button></div></div>';
    } else {
      cuerpo = '<div class="menu-setting"><span><strong>Tema</strong><small>Aspecto de la interfaz</small></span><div class="segmented">' +
        '<button class="' + (S.tema === "light" ? "active" : "") + '" data-act="tema:light">Pergamino</button>' +
        '<button class="' + (S.tema === "dark" ? "active" : "") + '" data-act="tema:dark">Cueva</button></div></div>' +
        '<div class="menu-setting"><span><strong>Nivel de explicación</strong><small>Puede cambiarse también en el árbol</small></span><div class="segmented">' +
        '<button class="' + (n === "resumido" ? "active" : "") + '" data-act="nivel:resumido">Resumido</button>' +
        '<button class="' + (n === "detallado" ? "active" : "") + '" data-act="nivel:detallado">Detallado</button></div></div>' +
        '<button class="menu-row" data-act="ficha:baldomero">' + icono("heart") + "<span><strong>Personajes y habilidades</strong><small>Cifras, rasgos, habilidades y si suben de nivel</small></span><b>›</b></button>" +
        '<button class="menu-row" data-cmd="demo">' + icono("sword") + "<span><strong>Escenas de demostración</strong><small>Preparar una escena y comandos sugeridos</small></span><b>›</b></button>" +
        '<button class="menu-row" data-act="cronica">' + icono("scroll") + "<span><strong>Ver crónica</strong><small>Historial completo de la partida</small></span><b>›</b></button>" +
        '<button class="menu-row destructive" data-act="confirmar-nueva">' + icono("skull") + "<span><strong>Nueva partida</strong><small>Empezar desde la Taberna</small></span><b>›</b></button>";
    }
    return '<div class="menu-backdrop"><section class="game-menu" role="dialog" aria-modal="true" aria-label="Menú de partida">' + cabecera + cuerpo + "</section></div>";
  }

  // El queso y para cuantos dias llega; en amarillo o rojo cuando esta justo. Tolera un servidor viejo sin `comida`.
  function indicadorComida(e) {
    var c = e.comida;
    if (!c) return '<span title="Quesos en la despensa">' + icono("cheese", 17) + e.despensa.total + "</span>";
    return '<span class="comida ' + esc(c.riesgo) + '" title="' + esc("Ración: " + c.racion + " quesos al día. " + (c.aviso || "Hay margen.") + (c.ayuno ? " Ayuno: " + c.ayuno + " de " + c.ayuno_max + " días seguidos sin comer." : "")) + '">' + icono("cheese", 17) +
      e.despensa.total + " <small>" + c.dias + (c.dias === 1 ? " día" : " días") + "</small></span>";
  }

  function cabecera() {
    var e = S.estado;
    return '<header class="game-header">' + logo(28) + '<div class="location">' + icono("map", 16) + "<span>" + esc(e.zona.nombre) + "</span><i></i>Día " + e.dia + "</div>" +
      '<div class="header-stats">' + indicadorComida(e) + '<button data-act="menu" aria-haspopup="dialog">Menú</button></div></header>';
  }

  // ---------------------------------------------------------------------------------------------------------
  // Pantallas
  // ---------------------------------------------------------------------------------------------------------
  function pantallaInicio(movil) {
    var hayPartida = S.estado && (S.estado.dia > 1 || S.estado.fase === "combate") && !S.estado.fin;
    return '<div class="game-frame start-screen ' + S.tema + (movil ? " mobile" : "") + '"><header class="game-logo">' + icono("cheese", movil ? 34 : 46) +
      "<span>BANDA<small>CHAPUZA</small></span></header><main class=\"start-content\"><div class=\"crest\">" + icono("crown", movil ? 42 : 58) + '<span class="crest-cheese">◌</span></div>' +
      '<p class="overline">UN RPG DE TEXTO, DEUDAS Y LÁCTEOS</p><h1>La gloria está<br>a medio curar.</h1>' +
      '<p class="start-copy">Reúne a cuatro héroes discutibles, administra el queso y sobrevive a decisiones perfectamente justificables.</p>' +
      '<p class="start-copy" style="font-size:15px">Se juega escribiendo órdenes (<code>contratos.</code>, <code>ir(aldea).</code>) o con los botones; <code>explicar.</code> y «¿por qué no?» cuentan el porqué de todo.</p>' +
      '<button class="primary large" data-act="comenzar">Comenzar una chapuza <span>→</span></button>' +
      (hayPartida ? '<p style="margin-top:14px"><button class="text-button" data-act="continuar">Continuar · Día ' + S.estado.dia + ", " + esc(S.estado.zona.nombre) + "</button></p>" : "") +
      '</main><footer><span>Escrito en Prolog · Leche sin pasteurizar</span><button data-act="tema:' + (S.tema === "dark" ? "light" : "dark") + '">' + (S.tema === "dark" ? "Pergamino" : "Cueva") + "</button></footer></div>";
  }

  function puestoRegistro() {
    var txt = S.log.map(function (e) { return e.texto || ""; }).join("\n") + "\n" + S.textoFinal;
    var m = txt.match(/puesto (\d+)/);
    return m ? "puesto " + m[1] : "sin puesto";
  }

  function pantallaFinal(movil) {
    var e = S.estado, victoria = String(e.fin.motivo) === "victoria";
    var h1 = victoria ? "Una victoria<br>bien curada." : "Hasta aquí llegó<br>la corteza.";
    var texto = (S.textoFinal || "").split("\n").filter(function (l) { return l && l.indexOf("Narrador:") < 0; }).slice(0, 2).join(" ");
    return '<div class="game-frame final-screen ' + S.tema + (movil ? " mobile" : "") + " " + (victoria ? "victory" : "defeat") + '"><header class="game-logo">' + icono("cheese", 30) +
      "<span>BANDA<small>CHAPUZA</small></span></header><main><div class=\"final-icon\">" + icono(victoria ? "crown" : "skull", 56) + "</div>" +
      '<p class="overline">' + (victoria ? "CONTRATO CUMPLIDO · MÁS O MENOS" : "LA BANDA HA CAÍDO") + "</p><h1>" + h1 + "</h1><p>" + esc(texto) + "</p>" +
      '<div class="final-stats"><div><b>' + e.dia + "</b><span>Días</span></div><div><b>" + e.despensa.total + "</b><span>Quesos</span></div><div><b>" +
      (victoria ? puestoRegistro() : "sin puesto") + "</b><span>Puesto en el Registro</span></div></div>" +
      '<button class="primary" data-act="nueva">Nueva partida</button><button class="text-button" data-act="cronica">Ver crónica completa</button></main></div>';
  }

  function pantallaCronica() { return cronicaHTML(); }

  function juegoEscritorio() {
    var e = S.estado, combate = e.fase === "combate";
    return '<div class="game-frame ' + S.tema + " desktop-game " + (S.tab === "Explicar" ? "explain-open" : "") + (S.ocupado ? " cargando" : "") + '">' +
      cabecera() + bannerCombate() + bannerEscena() +
      '<div class="game-layout"><aside class="party-panel"><div class="section-heading"><span>La Banda</span><small>' +
      e.banda.filter(function (m) { return m.estado === "en_pie"; }).length + "/" + e.banda.length + " EN PIE</small></div>" +
      '<div class="party-list">' + e.banda.map(function (m) { return tarjetaMiembro(m, combate); }).join("") + "</div>" + panelInferior() + "</aside>" +
      '<main class="story-panel">' + tiraEnemigos() + narracion() + areaOrdenes() + "</main>" +
      panelDerecho() + "</div>" + menuEmergente() + menuPrincipal() + fichaHTML() + "</div>";
  }

  function juegoMovil() {
    var e = S.estado, combate = e.fase === "combate", cuerpo, comandos = true;
    if (S.drawer && S.explic) {
      cuerpo = '<main class="mobile-main with-drawer">' + narracion() + '<section class="mobile-explain drawer"><div class="drawer-handle"></div>' +
        '<div class="drawer-title"><span>Explicar</span><button data-act="cerrar-drawer" aria-label="Cerrar">×</button></div>' + panelExplicar(false) + "</section></main>";
      comandos = false;
    } else if (S.movilTab === "banda") {
      cuerpo = '<main class="mobile-main"><section class="mobile-party"><p class="panel-kicker">COMPAÑÍA ACTIVA</p><h2>La Banda</h2><div class="party-list">' +
        e.banda.map(function (m) { return tarjetaMiembro(m, false); }).join("") + "</div>" + panelInferior() + "</section></main>";
    } else if (S.movilTab === "panel") {
      var tabs = ["Contratos", "Zona", "Explicar"].map(function (t) {
        return '<button data-act="tab:' + t + '" class="' + (S.tab === t ? "active" : "") + '">' + t + (t === "Explicar" && S.explic ? '<span class="tab-dot"></span>' : "") + "</button>";
      }).join("");
      cuerpo = '<main class="mobile-main"><div class="tabs">' + tabs + '</div><div class="right-content">' +
        (S.tab === "Contratos" ? panelContratos() : (S.tab === "Zona" ? panelZona() : panelExplicar(false))) + "</div></main>";
    } else {
      cuerpo = '<main class="mobile-main">' + bannerEscena(true) + (combate ? tiraEnemigos() : "") + narracion() + "</main>";
    }
    var panelActivo = S.movilTab === "panel";
    return '<div class="game-frame ' + S.tema + " mobile mobile-game" + (S.ocupado ? " cargando" : "") + '"><header class="mobile-header">' + logo(23) +
      '<div class="mobile-header-actions"><div class="day-chip">Día ' + e.dia + '</div><button aria-label="Abrir menú" data-act="menu">Menú</button></div></header>' +
      bannerCombate() + cuerpo + (comandos && S.movilTab === "narracion" ? areaOrdenes() : "") +
      '<nav class="mobile-nav three-tabs"><button class="' + (S.movilTab === "banda" ? "active" : "") + '" data-act="movil:banda">' + icono("heart") + "<span>Banda</span></button>" +
      '<button class="' + (S.movilTab === "narracion" ? "active" : "") + '" data-act="movil:narracion">' + icono("scroll") + "<span>Narración</span></button>" +
      '<button class="' + (panelActivo ? "active" : "") + '" data-act="movil:panel">' + icono("tree") + "<span>Contratos · Zona · Explicar</span></button></nav>" + menuEmergente() + menuPrincipal() + fichaHTML() + "</div>";
  }

  // ---------------------------------------------------------------------------------------------------------
  // Dibujar
  // ---------------------------------------------------------------------------------------------------------
  // El elemento que desplaza la narracion: en movil es toda la columna principal, en escritorio la propia narracion.
  function zonaScroll() {
    return esMovil() ? document.querySelector(".mobile-main") : document.getElementById("narrativa");
  }

  function render(op) {
    op = op || {};
    var movil = esMovil();
    var previo = document.getElementById("orden");
    var enfocado = previo && document.activeElement === previo;
    var narr = zonaScroll();
    var scrollPrevio = narr ? narr.scrollTop : 0;
    document.body.setAttribute("data-tema", S.tema);

    var html;
    if (S.error) html = sistemaHTML(false);
    else if (!S.estado) html = sistemaHTML(true);
    else if (S.vista === "inicio") html = pantallaInicio(movil);
    else if (S.vista === "final" && S.estado.fin) html = pantallaFinal(movil);
    else if (S.vista === "cronica") html = pantallaCronica();
    else html = movil ? juegoMovil() : juegoEscritorio();
    app.innerHTML = html;

    var nuevo = document.getElementById("orden");
    if (nuevo) {
      if (enfocado || op.enfocar || (!movil && op.bajar)) { nuevo.focus(); try { nuevo.setSelectionRange(nuevo.value.length, nuevo.value.length); } catch (e) { /* nada */ } }
    }
    var primero = document.querySelector(".choice-menu > div > button");
    if (primero) primero.focus();
    var narr2 = zonaScroll();
    if (narr2) narr2.scrollTop = op.bajar ? narr2.scrollHeight : scrollPrevio;
  }

  // ---------------------------------------------------------------------------------------------------------
  // Eventos
  // ---------------------------------------------------------------------------------------------------------
  app.addEventListener("click", function (ev) {
    var b = ev.target.closest("[data-cmd],[data-act]");
    if (!b) {
      // un clic fuera del menu o del selector los cierra; dentro, no
      if ((S.pop || S.menu || S.ficha) && !ev.target.closest(".game-menu, .choice-menu, .ficha-modal")) { S.pop = null; S.menu = false; S.ficha = ""; render(); }
      return;
    }
    var cmd = b.getAttribute("data-cmd"), act = b.getAttribute("data-act");
    if (cmd) { enviar(cmd); return; }
    var partes = act.split(":"), a = partes[0], arg = partes.slice(1).join(":");
    if (a === "sugs") ev.preventDefault();             // el details se pliega con nuestro estado, no el del navegador
    switch (a) {
      case "comenzar": nuevaPartida(); break;
      case "continuar": continuar(); break;
      case "nueva": nuevaPartida(); break;
      case "confirmar-nueva": S.menu = "confirmar"; render(); break;
      case "menu-volver": S.menu = true; render(); break;
      case "pop-cerrar": S.pop = null; render({ enfocar: true }); break;
      case "exportar": exportarCronica(); break;
      case "reintentar":
        S.error = null;
        if (S.estado) render();
        else api("/api/estado").then(function (e) { S.estado = e; if (e.fin) S.vista = "final"; render(); }).catch(fallo);
        break;
      case "tab": S.tab = arg; S.pop = null; render(); break;
      case "movil": S.movilTab = arg; S.drawer = false; S.pop = null; render(); break;
      case "sugs": S.sugs = !S.sugs; render(); break;
      case "ficha": abrirFicha(arg); break;
      case "ficha-cerrar": S.ficha = ""; render({ enfocar: true }); break;
      case "inf": S.inferior = arg === "posiciones" ? "posiciones" : "despensa"; render(); break;
      case "cerrar-drawer": S.drawer = false; render({ enfocar: false }); break;
      case "menu": S.menu = S.menu ? false : true; S.pop = null; render(); break;
      case "pop": S.pop = S.pop === arg ? null : arg; S.menu = false; render(); break;
      case "tema":
        S.tema = arg; S.menu = false;
        try { localStorage.setItem("chapuza-tema", arg); } catch (e) { /* nada */ }
        render(); break;
      case "nivel": S.menu = false; cambiarNivel(arg); break;
      case "regla": S.abierta = S.abierta === Number(arg) ? -1 : Number(arg); render(); break;
      case "cronica": S.menu = false; S.vista = "cronica"; render(); break;
      case "volver": S.vista = S.estado && S.estado.fin ? "final" : "juego"; render({ bajar: true }); break;
    }
  });

  app.addEventListener("input", function (ev) { if (ev.target.id === "orden") S.entrada = ev.target.value; });

  app.addEventListener("keydown", function (ev) {
    if (ev.target.id !== "orden") return;
    if (ev.key === "Enter") {
      var t = ev.target.value; S.entrada = ""; ev.target.value = ""; enviar(t);
    } else if (ev.key === "ArrowUp") {
      if (S.hist.length) { S.hpos = Math.max(0, S.hpos - 1); ev.target.value = S.entrada = S.hist[S.hpos] || ""; ev.preventDefault(); }
    } else if (ev.key === "ArrowDown") {
      if (S.hist.length) { S.hpos = Math.min(S.hist.length, S.hpos + 1); ev.target.value = S.entrada = S.hist[S.hpos] || ""; ev.preventDefault(); }
    } else if (ev.key === "Escape") { S.pop = null; S.menu = false; render({ enfocar: true }); }
  });

  document.addEventListener("keydown", function (ev) {
    if (S.pop || S.menu || S.ficha) {
      if (ev.key === "Escape") { S.pop = null; S.menu = false; S.ficha = ""; render({ enfocar: true }); return; }
      if (S.pop) {
        var opciones = [].slice.call(document.querySelectorAll(".choice-menu > div > button"));
        if (/^[1-9]$/.test(ev.key) && opciones[Number(ev.key) - 1]) { opciones[Number(ev.key) - 1].click(); ev.preventDefault(); return; }
        if (ev.key === "ArrowDown" || ev.key === "ArrowUp") {
          var i = opciones.indexOf(document.activeElement), paso = ev.key === "ArrowDown" ? 1 : -1;
          opciones[(i + paso + opciones.length) % opciones.length].focus(); ev.preventDefault(); return;
        }
      }
    }
    var t = ev.target, escribiendo = t && (t.tagName === "INPUT" || t.tagName === "TEXTAREA");
    if (ev.key === "/" && !escribiendo) { var i = document.getElementById("orden"); if (i) { i.focus(); ev.preventDefault(); } }
  });

  var modoMovil = esMovil(), temporizador = null;
  window.addEventListener("resize", function () {
    clearTimeout(temporizador);
    temporizador = setTimeout(function () {
      if (esMovil() !== modoMovil) { modoMovil = esMovil(); S.drawer = false; render(); }
    }, 120);
  });

  // ---------------------------------------------------------------------------------------------------------
  // Arranque
  // ---------------------------------------------------------------------------------------------------------
  document.body.setAttribute("data-tema", S.tema);
  render();
  api("/api/estado").then(function (e) {
    if (S.estado) return;          // una orden ya respondio antes: su estado es mas reciente
    S.estado = e;
    if (e.fin) S.vista = "final";
    render();
  }).catch(fallo);

  // Para la depuracion y las pruebas en el navegador
  window.chapuza = { S: S, enviar: enviar, render: render };
})();
