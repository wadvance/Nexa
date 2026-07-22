import 'aetheris_brain.dart';

/// KnowledgeDomainService — enruta consultas a los dominios especializados.
///
/// Dominios cubiertos:
///   • Sismología / Tormentas / Clima          (datos en tiempo real)
///   • Medicina / Fisiología / Biología        (orientación + FDA fallback)
///   • Medicamentos / Nuevos virus             (alertas epidemiológicas)
///   • Reparación autos / motos / cortagramas
///   • Limpieza aires acondicionados
///   • Reparación PCs / laptops / televisores
///   • Temas políticos de interés
///   • Ingenieros / Arquitectos / Abogados     (profesiones)
///   • Contabilidad / Bancaria / Empresarial
///   • Agronomía / Hidroponía / Cosechas
///   • Cocina / Recetas
///   • Vinos / Licores / Preparación de bebidas
///   • Cervezas (tipos y listado mundial)
///   • Hackers / Informática / Ciberseguridad
///   • Biblia Etíope (Libro de Enoc, Jubileos, etc.)
///   • Conversaciones IA-usuario (charla libre)
class KnowledgeDomainService {

  // ─────────────────────────────────────────────────────────────────────────
  // DETECCIÓN DE DOMINIO
  // ─────────────────────────────────────────────────────────────────────────

  static KnowledgeDomain detectDomain(String query) {
    final q = query.toLowerCase();

    // ── Peligros / Desastres / Sismología ──────────────────────────────────
    if (_any(q, ['sismo', 'terremoto', 'temblor', 'sismología', 'sismologia',
        'richter', 'magnitud', 'tectónica', 'tectonica', 'placa tectónica',
        'tsunami', 'volcano', 'volcán', 'erupción', 'erupcion',
        'tormenta', 'huracán', 'huracan', 'ciclón', 'ciclon', 'tornado',
        'inundación', 'inundacion', 'alerta meteorológica', 'alerta clima',
        'peligro cerca', 'amenaza cerca', 'desastre natural'])) {
      return KnowledgeDomain.hazards;
    }

    // ── Nuevos virus / Epidemias ────────────────────────────────────────────
    if (_any(q, ['virus nuevo', 'nueva cepa', 'nueva variante', 'brote',
        'epidemia', 'pandemia', 'covid', 'gripe aviar', 'mpox', 'viruela',
        'bacteria resistente', 'alerta epidemiológica', 'alerta sanitaria',
        'enfermedad infecciosa', 'enfermedad emergente', 'zoonosis'])) {
      return KnowledgeDomain.newViruses;
    }

    // ── Fisiología / Biología ──────────────────────────────────────────────
    if (_any(q, ['fisiología', 'fisiologia', 'biología', 'biologia',
        'célula', 'celula', 'adn', 'dna', 'genética', 'genetica',
        'cromosoma', 'proteína', 'proteina', 'metabolismo', 'homeostasis',
        'sistema nervioso', 'sistema digestivo', 'sistema inmune',
        'neurona', 'sinapsis', 'mitocondria', 'fotosíntesis', 'fotosintesis',
        'evolución', 'evolucion', 'ecosistema', 'taxonomía', 'taxonomia'])) {
      return KnowledgeDomain.biology;
    }

    // ── Medicina / Salud / Medicamentos ────────────────────────────────────
    if (_any(q, ['medicamento', 'medicina', 'pastilla', 'fármaco', 'farmaco',
        'dosis', 'antibiótico', 'antibiotico', 'analgésico', 'analgésicos',
        'vacuna', 'tratamiento', 'diagnóstico', 'diagnostico',
        'enfermedad', 'síntoma', 'sintoma', 'dolor', 'fiebre', 'tos',
        'presión arterial', 'diabetes', 'cáncer', 'cancer', 'cirugía',
        'cirugia', 'emergencia médica', 'primeros auxilios', 'rcp'])) {
      return KnowledgeDomain.medicine;
    }

    // ── Reparación de automóviles ──────────────────────────────────────────
    if (_any(q, ['reparación de auto', 'reparar auto', 'reparación de carro',
        'reparar carro', 'motor del carro', 'motor del auto', 'frenos',
        'transmisión', 'transmision', 'caja de cambios', 'embrague',
        'batería del carro', 'bateria del carro', 'alternador', 'carburador',
        'inyector', 'suspensión del auto', 'suspensión del carro',
        'aceite del motor', 'filtro de aceite', 'correa de distribución',
        'correa dentada', 'radiador', 'termostato', 'bujía', 'bujia',
        'llanta', 'cauchos', 'taller mecánico', 'taller mecanico',
        'mecánico', 'mecanico', 'diagnostico obd', 'código de error auto'])) {
      return KnowledgeDomain.carRepair;
    }

    // ── Reparación de motos ────────────────────────────────────────────────
    if (_any(q, ['reparar moto', 'reparación de moto', 'moto averiada',
        'motor de moto', 'carburador de moto', 'cadena de moto',
        'freno de moto', 'batería de moto', 'bateria de moto',
        'filtro de aire moto', 'aceite de moto', 'mantenimiento moto',
        'pinchazo moto', 'pastilla de freno moto'])) {
      return KnowledgeDomain.motoRepair;
    }

    // ── Cortagramas / Jardinería ───────────────────────────────────────────
    if (_any(q, ['cortagramas', 'cortacésped', 'cortacesped', 'podadora',
        'jardinería', 'jardineria', 'cortar hierba', 'cortar pasto',
        'cortar grama', 'reparar podadora', 'hoja de corte',
        'motor de cortadora', 'mantenimiento de jardín'])) {
      return KnowledgeDomain.lawnMower;
    }

    // ── Limpieza / Mantenimiento de aires acondicionados ──────────────────
    if (_any(q, ['aire acondicionado', 'ac', 'a/c', 'limpieza de aire',
        'filtro de aire acondicionado', 'gas refrigerante', 'freon',
        'r-22', 'r-410', 'compresor de ac', 'evaporador', 'condensador',
        'limpieza de split', 'mantenimiento de ac', 'gotea el ac',
        'no enfría el ac', 'no enfria el ac', 'ruido del ac'])) {
      return KnowledgeDomain.acMaintenance;
    }

    // ── Reparación de computadoras / laptops ──────────────────────────────
    if (_any(q, ['reparar computadora', 'reparar pc', 'reparar laptop',
        'pantalla azul', 'bsod', 'formatear', 'instalar windows',
        'instalar linux', 'disco duro', 'ssd', 'ram', 'memoria ram',
        'tarjeta de video', 'gpu', 'cpu', 'placa madre', 'fuente de poder',
        'virus en pc', 'malware', 'computadora lenta', 'pc lenta',
        'sobrerecalentamiento', 'overheating', 'driver', 'controlador',
        'bios', 'uefi', 'no enciende la pc', 'no enciende el laptop'])) {
      return KnowledgeDomain.computerRepair;
    }

    // ── Reparación de televisores ──────────────────────────────────────────
    if (_any(q, ['reparar televisor', 'reparar tv', 'televisor dañado',
        'pantalla del tv', 'backlight', 'panel lcd', 'oled roto',
        'placa de tv', 'fuente de poder tv', 'tv no enciende',
        'tv sin imagen', 'tv sin sonido', 'smart tv falla',
        'parpadea el tv', 'rayada la pantalla del tv'])) {
      return KnowledgeDomain.tvRepair;
    }

    // ── Informática / Tecnología / Hackers ────────────────────────────────
    if (_any(q, ['hacker', 'hackear', 'ciberseguridad', 'pentesting',
        'vulnerabilidad', 'exploit', 'phishing', 'ransomware', 'malware',
        'firewall', 'vpn', 'cifrado', 'criptografía', 'criptografia',
        'red tor', 'dark web', 'sql injection', 'xss', 'ingeniería social',
        'kali linux', 'metasploit', 'nmap', 'wireshark',
        'programación', 'programacion', 'código fuente', 'algoritmo',
        'base de datos', 'api', 'backend', 'frontend', 'inteligencia artificial',
        'machine learning', 'red neuronal', 'python', 'javascript', 'flutter'])) {
      return KnowledgeDomain.tech;
    }

    // ── Política ──────────────────────────────────────────────────────────
    if (_any(q, ['política', 'politica', 'gobierno', 'presidente',
        'elecciones', 'partido político', 'partido politico', 'congreso',
        'parlamento', 'senado', 'ley', 'constitución', 'constitucion',
        'democracia', 'dictadura', 'geopolítica', 'geopolitica',
        'relaciones internacionales', 'tratado', 'cumbre', 'noticias politicas'])) {
      return KnowledgeDomain.politics;
    }

    // ── Ingenieros / Arquitectos ──────────────────────────────────────────
    if (_any(q, ['ingeniero', 'ingeniería', 'ingenieria', 'civil',
        'estructural', 'mecánico', 'mecanico', 'eléctrico', 'electricidad',
        'arquitecto', 'arquitectura', 'diseño estructural', 'planos',
        'norma', 'código de construcción', 'hormigón', 'concreto', 'acero',
        'carga estructural', 'proyecto de construcción', 'obra civil'])) {
      return KnowledgeDomain.engineering;
    }

    // ── Abogados / Legal ──────────────────────────────────────────────────
    if (_any(q, ['abogado', 'derecho', 'ley', 'demanda', 'contrato',
        'constitución', 'tribunal', 'juicio', 'penal', 'civil',
        'laboral', 'familia', 'herencia', 'testamento', 'divorcio',
        'sociedad anónima', 'empresa', 'registro mercantil', 'propiedad intelectual',
        'derechos de autor', 'patente', 'marca registrada', 'código penal'])) {
      return KnowledgeDomain.legal;
    }

    // ── Contabilidad / Bancaria / Empresarial ─────────────────────────────
    if (_any(q, ['contabilidad', 'contable', 'factura', 'declaración de impuestos',
        'declaracion de impuestos', 'iva', 'itbms', 'balance', 'estado financiero',
        'banco', 'bancario', 'préstamo', 'prestamo', 'hipoteca', 'interés bancario',
        'empresa', 'negocio', 'plan de negocios', 'inversión', 'inversion',
        'finanzas', 'auditoría', 'auditoria', 'flujo de caja', 'presupuesto'])) {
      return KnowledgeDomain.business;
    }

    // ── Agronomía / Hidroponía / Cosechas ─────────────────────────────────
    if (_any(q, ['agronomía', 'agronomia', 'agricultura', 'hidroponía', 'hidroponia',
        'cultivo', 'cosecha', 'siembra', 'semilla', 'fertilizante', 'abono',
        'plaga', 'fumigación', 'fumigacion', 'riego', 'ph del suelo',
        'nutrientes', 'sustrato', 'invernadero', 'tomate', 'lechuga',
        'maíz', 'maiz', 'caña', 'cana de azucar', 'café', 'cafe cultivo',
        'sistema nft', 'sistema dwc', 'aeroponía', 'aeroponia', 'ec nutrientes'])) {
      return KnowledgeDomain.agronomy;
    }

    // ── Cocina / Recetas ──────────────────────────────────────────────────
    if (_any(q, ['receta', 'cocinar', 'cocina', 'ingredientes', 'preparación de',
        'preparacion de', 'plato', 'guiso', 'sopa', 'ensalada', 'postre',
        'cómo se hace', 'como se hace', 'cómo preparo', 'como preparo',
        'hornear', 'freír', 'freir', 'hervir', 'saltear',
        'arroz con', 'pollo al', 'carne de', 'mariscos', 'pasta', 'pizza casera',
        'cocina panameña', 'cocina latina', 'cocina italiana'])) {
      return KnowledgeDomain.cooking;
    }

    // ── Vinos / Licores ───────────────────────────────────────────────────
    if (_any(q, ['vino', 'vinos', 'enología', 'enologia', 'cepa', 'uva',
        'tinto', 'blanco', 'rosado', 'espumoso', 'champagne', 'cava', 'prosecco',
        'fermentación', 'fermentacion', 'barril', 'maduración del vino',
        'licor', 'coctel', 'cóctel', 'ron', 'whisky', 'whiskey', 'vodka',
        'ginebra', 'tequila', 'mezcal', 'pisco', 'aguardiente',
        'preparar licor', 'bebida alcohólica', 'bebida alcoholica',
        'maridaje', 'sommelier', 'destilación', 'destilacion'])) {
      return KnowledgeDomain.wines;
    }

    // ── Cervezas ──────────────────────────────────────────────────────────
    if (_any(q, ['cerveza', 'cervezas', 'ale', 'lager', 'stout', 'porter',
        'ipa', 'apa', 'pilsner', 'pilsen', 'weizen', 'hefeweizen',
        'cerveza artesanal', 'craft beer', 'homebrewing', 'malta',
        'lúpulo', 'lupulo', 'levadura de cerveza', 'fermentación cerveza',
        'tipos de cerveza', 'cervezas del mundo', 'cervezas famosas',
        'heineken', 'corona', 'budweiser', 'guinness'])) {
      return KnowledgeDomain.beer;
    }

    // ── Biblia Etíope / Textos sagrados ───────────────────────────────────
    if (_any(q, ['biblia etíope', 'biblia etiope', 'libro de enoc', 'libro de henoc',
        'libro de jubileos', 'enoc', 'henoc', 'jubileos', 'baruc', 'ezra etíope',
        'canon etíope', 'canon ortodoxo', 'iglesia ortodoxa etíope',
        'testamento de adán', 'apocalipsis de ezra', 'libros apócrifos',
        'apocrifos', 'deuterocanónicos', 'deuterocanonico',
        'genesis etíope', 'ángeles caídos', 'angeles caidos', 'nefilim',
        'watchers', 'vigilantes', 'libro de los gigantes'])) {
      return KnowledgeDomain.ethiopianBible;
    }

    // ── Conversación general ──────────────────────────────────────────────
    return KnowledgeDomain.general;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // OBTENCIÓN DE RESPUESTA POR DOMINIO
  // ─────────────────────────────────────────────────────────────────────────

  /// Devuelve una respuesta experta para [query] en el [domain] detectado.
  static Future<String> answer(String query, {KnowledgeDomain? domain}) async {
    final d = domain ?? detectDomain(query);
    final systemInstruction = _systemPromptForDomain(d);
    return AetherisBrain.getExpertAdvice(query, systemInstruction);
  }

  static String _systemPromptForDomain(KnowledgeDomain d) {
    switch (d) {
      case KnowledgeDomain.hazards:
        return 'Eres un experto en geofísica, meteorología y gestión de riesgos. '
            'Da información clara y accionable sobre sismos, tormentas y alertas. '
            'Siempre indica fuentes oficiales (USGS, ONAMET, SINAPROC, etc.).';

      case KnowledgeDomain.newViruses:
        return 'Eres epidemiólogo experto. Informa sobre brotes, nuevos virus y alertas de la OMS/OPS. '
            'Sé preciso, cita fuentes, y recomienda siempre consultar autoridades sanitarias locales.';

      case KnowledgeDomain.biology:
        return 'Eres biólogo y fisiólogo PhD. Explica temas de biología celular, molecular, fisiología '
            'humana y animal con rigor académico pero lenguaje accesible.';

      case KnowledgeDomain.medicine:
        return 'Eres médico general con especialización en farmacología. Da orientación clara. '
            'Siempre añade "Esto es orientación general, no sustituye la consulta médica profesional." '
            'Nunca recetes ni diagnostiques de forma definitiva.';

      case KnowledgeDomain.carRepair:
        return 'Eres mecánico automotriz experto con 20 años de experiencia. Explica diagnósticos '
            'y reparaciones paso a paso, menciona herramientas necesarias y costos aproximados.';

      case KnowledgeDomain.motoRepair:
        return 'Eres mecánico especialista en motocicletas. Cubre todas las marcas y modelos. '
            'Da instrucciones detalladas de diagnóstico y reparación con pasos numerados.';

      case KnowledgeDomain.lawnMower:
        return 'Eres técnico especialista en equipos de jardinería, cortacéspedes y podadoras. '
            'Explica diagnóstico, mantenimiento preventivo y reparación de motores a gasolina y eléctricos.';

      case KnowledgeDomain.acMaintenance:
        return 'Eres técnico certificado en sistemas de climatización (HVAC). Explica limpieza, '
            'mantenimiento preventivo, carga de gas refrigerante y diagnóstico de fallas en '
            'sistemas split, ventana y central.';

      case KnowledgeDomain.computerRepair:
        return 'Eres técnico certificado en hardware y software. Cubre PCs, laptops, Mac. '
            'Da diagnósticos y soluciones paso a paso, desde BIOS hasta software.';

      case KnowledgeDomain.tvRepair:
        return 'Eres técnico electrónico especializado en televisores LED, OLED, QLED y plasma. '
            'Diagnostica fallas de imagen, sonido, backlight y placa. Da pasos de reparación claros.';

      case KnowledgeDomain.tech:
        return 'Eres arquitecto de software y experto en ciberseguridad. Cubre programación, '
            'redes, hacking ético, criptografía, IA y desarrollo de software. '
            'Para temas de hacking: solo ética y defensa, nunca ataques ilegales.';

      case KnowledgeDomain.politics:
        return 'Eres analista político objetivo y sin sesgo ideológico. Informa sobre eventos '
            'políticos con datos verificables, cita fuentes y presenta múltiples perspectivas.';

      case KnowledgeDomain.engineering:
        return 'Eres ingeniero senior con experiencia en civil, estructural, mecánica y eléctrica. '
            'Maneja normativas internacionales (ACI, AISC, NEC) y locales. '
            'Da cálculos y recomendaciones técnicas precisas.';

      case KnowledgeDomain.legal:
        return 'Eres abogado con experiencia en derecho civil, penal, laboral y mercantil. '
            'Orienta sobre situaciones legales comunes pero siempre indica: '
            '"Esto es orientación general, consulta a un abogado para tu caso específico."';

      case KnowledgeDomain.business:
        return 'Eres consultor empresarial senior, contador público y asesor bancario. '
            'Cubre contabilidad, impuestos, finanzas corporativas y banca. '
            'Añade "Consulta a un contador o asesor financiero certificado para decisiones importantes."';

      case KnowledgeDomain.agronomy:
        return 'Eres ingeniero agrónomo especializado en agricultura tropical, hidroponía avanzada '
            'y agricultura de precisión. Cubre cultivos, plagas, fertilización, riego y cosecha.';

      case KnowledgeDomain.cooking:
        return 'Eres chef profesional con especialización en cocina latina, panameña e internacional. '
            'Da recetas detalladas con cantidades exactas, pasos numerados y variaciones posibles.';

      case KnowledgeDomain.wines:
        return 'Eres sommelier certificado y maestro destilador. Cubre enología, cepas, regiones '
            'vinícolas, maridajes, coctelería y destilación artesanal de licores. '
            'Da información detallada sobre preparación, tipos y características.';

      case KnowledgeDomain.beer:
        return 'Eres maestro cervecero (Cicerone certificado). Conoces todos los estilos de cerveza '
            'del mundo, procesos de elaboración, ingredientes y las principales marcas globales. '
            'Da listas detalladas y explicaciones sobre cada estilo.';

      case KnowledgeDomain.ethiopianBible:
        return 'Eres teólogo y biblista especializado en el canon bíblico etíope de la Iglesia '
            'Ortodoxa Tewahedo. Conoces a fondo el Libro de Enoc, Jubileos, los apócrifos etíopes '
            'y su contexto histórico y religioso. Responde con rigor académico y respeto.';

      case KnowledgeDomain.general:
        return 'Eres AETHERIS, asistente multidisciplinario experto en todos los campos del conocimiento. '
            'Responde siempre en español con información precisa, útil y actualizada.';
    }
  }

  static bool _any(String q, List<String> keys) => keys.any(q.contains);
}

// ─────────────────────────────────────────────────────────────────────────────
// Enum de dominios
// ─────────────────────────────────────────────────────────────────────────────

enum KnowledgeDomain {
  hazards,
  newViruses,
  biology,
  medicine,
  carRepair,
  motoRepair,
  lawnMower,
  acMaintenance,
  computerRepair,
  tvRepair,
  tech,
  politics,
  engineering,
  legal,
  business,
  agronomy,
  cooking,
  wines,
  beer,
  ethiopianBible,
  general,
}
