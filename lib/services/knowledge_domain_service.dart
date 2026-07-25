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
    if (_any(q, ['aire acondicionado', 'limpieza de aire',
        'filtro de aire acondicionado', 'gas refrigerante', 'freon',
        'r-22', 'r-410', 'compresor de aire', 'evaporador', 'condensador',
        'limpieza de split', 'mantenimiento de aire', 'gotea el aire',
        'no enfría el aire', 'no enfria el aire', 'ruido del aire',
        'aire split'])) {
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
        'base de datos', 'api rest', 'backend', 'frontend', 'inteligencia artificial',
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

    // ── Agronomía / Hidroponía / Cosechas / Apicultura ────────────────────
    if (_any(q, ['agronomía', 'agronomia', 'agricultura', 'hidroponía', 'hidroponia',
        'cultivo', 'cosecha', 'siembra', 'semilla', 'fertilizante', 'abono',
        'plaga', 'fumigación', 'fumigacion', 'riego', 'ph del suelo',
        'nutrientes', 'sustrato', 'invernadero', 'tomate', 'lechuga',
        'maíz', 'maiz', 'caña', 'cana de azucar', 'café', 'cafe cultivo',
        'sistema nft', 'sistema dwc', 'aeroponía', 'aeroponia', 'ec nutrientes',
        'apicultura', 'apícola', 'apicola', 'abeja', 'abejas', 'miel',
        'colmena', 'colmenas', 'panal', 'panales', 'apicultor', 'enjambre',
        'enjambres', 'polinización', 'polinizacion', 'propóleo', 'propoleo',
        'jalea real', 'cera de abeja', 'abeja reina', 'zángano', 'zangano'])) {
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

    // ── Música y Artes ────────────────────────────────────────────────────
    if (_any(q, ['música', 'musica', 'cantante', 'cantantes', 'banda',
        'canción', 'cancion', 'álbum', 'album', 'género musical', 'genero musical',
        'rock', 'pop', 'reggaetón', 'reggaeton', 'salsa', 'merengue',
        'tango', 'jazz', 'blues', 'cumbia', 'vallenato', 'bolero',
        'balada', 'ópera', 'opera', 'hip hop', 'rap', 'electrónica',
        'electronica', 'mariachi', 'corrido', 'salsa', 'vallenato',
        'letra de', 'letra canción', 'disco', 'álbum', 'album', 'cd',
        'concierto', 'tour', 'presentación', 'presentacion',
        'teatro', 'película', 'pelicula', 'cine', 'actor', 'actriz',
        'director de cine', 'musical', 'ópera', 'opera'])) {
      return KnowledgeDomain.musicAndArts;
    }

    // ── Servicios Públicos / Gubernamentales ──────────────────────────────
    if (_any(q, ['bomberos', 'policía nacional', 'policia nacional',
        'seguridad ciudadana', 'recolección de basura', 'recoleccion de basura',
        'suministro de agua', 'suministro eléctrico', 'suministro electrico',
        'trámite', 'tramite', 'trámites', 'tramites', 'identidad',
        'documento nacional', 'pasaporte', 'cédula', 'cedula',
        'registro civil', 'matrimonio civil', 'defensoría', 'defensoria'])) {
      return KnowledgeDomain.publicServices;
    }

    // ── Servicios Personales y del Hogar ──────────────────────────────────
    if (_any(q, ['lavandería', 'lavanderia', 'peluquería', 'peluqueria',
        'salón de belleza', 'salon de belleza', 'cuidado de adultos mayores',
        'cuidado de niños', 'cuidado de ninos', 'niñera', 'ninera',
        'jardinería del hogar', 'jardineria del hogar', 'limpieza doméstica',
        'limpieza domestica', 'servicio doméstico', 'servicio domestico',
        'mantenimiento del hogar', 'reparaciones del hogar'])) {
      return KnowledgeDomain.personalServices;
    }

    // ── Inmobiliarios y Construcción ──────────────────────────────────────
    if (_any(q, ['compraventa', 'alquiler de propiedad', 'alquiler de casa',
        'alquiler de apartamento', 'alquiler de local', 'administración de edificio',
        'administracion de edificio', 'remodelar casa', 'remodelación',
        'remodelacion', 'mantenimiento de propiedad',
        'inmobiliaria', 'bienes raíces', 'bienes raices'])) {
      return KnowledgeDomain.realestateServices;
    }

    // ── Comercio y Reparación ──────────────────────────────────────────────
    if (_any(q, ['venta al por menor', 'venta al por mayor',
        'tienda minorista', 'tienda mayorista', 'retail',
        'reparación de electrodoméstico', 'reparacion de electrodomestico',
        'reparación de refrigerador', 'reparacion de refrigerador',
        'reparación de lavadora', 'reparacion de lavadora',
        'reparación de aire', 'reparacion de aire',
        'taller de reparación', 'taller de reparacion'])) {
      return KnowledgeDomain.retailrepairServices;
    }

    // ── Hotelería y Gastronomía (subset turismo) ───────────────────────────
    if (_any(q, ['hostal', 'hostales', 'catering', 'organización de eventos',
        'organizacion de eventos', 'evento corporativo',
        'menú para evento', 'menu para evento', 'salón de fiestas',
        'salon de fiestas', 'banquete', 'banquetes'])) {
      return KnowledgeDomain.hospitalityBusiness;
    }

    // ── Turismo, Hotelería y Gastronomía ──────────────────────────────────
    if (_any(q, ['turismo', 'viaje', 'viajar', 'agencia de viajes',
        'agencia de turismo', 'paquete turístico', 'paquete turistico',
        'reservar hotel', 'reservar vuelo', 'reservar vuelo',
        'destino turístico', 'destino turistico', 'atracción turística',
        'atraccion turistica', 'tour guiado', 'guía turística',
        'guia turistica', 'vuelo', 'aerolínea', 'aerolinea',
        'pasaporte', 'visa', 'equipaje'])) {
      return KnowledgeDomain.tourismServices;
    }

    // ── Logística, Transporte y Almacenaje ────────────────────────────────
    if (_any(q, ['mensajería', 'mensajeria', 'envío express', 'envio express',
        'transporte de carga', 'logística', 'logistica', 'mudanza',
        'mudanzas', 'gestión de flota', 'gestion de flota',
        'almacenamiento', 'bodegaje', 'bodega', 'depósito', 'deposito',
        'cadena de suministro', 'distribución', 'distribucion',
        'camión de carga', 'camion de carga', 'furgón', 'furgon'])) {
      return KnowledgeDomain.logisticsServices;
    }

    // ── Tecnología y Telecomunicaciones (TIC) ─────────────────────────────
    if (_any(q, ['proveedor de internet', 'isp', 'isp Panamá',
        'telefonía', 'telefonia', 'fibra óptica', 'fibra optica',
        '5g', '4g', 'servicio de internet', 'soporte técnico', 'soporte tecnico',
        'servicio técnico', 'servicio tecnico', 'computación en la nube',
        'computacion en la nube', 'cloud computing', 'aws', 'azure',
        'google cloud', 'paas', 'saas', 'iaas'])) {
      return KnowledgeDomain.telecomServices;
    }

    // ── Educación y Formación ──────────────────────────────────────────────
    if (_any(q, ['colegio', 'universidad', 'instituto educativo',
        'capacitación técnica', 'capacitacion tecnica', 'capacitación corporativa',
        'capacitacion corporativa', 'capacitación online', 'capacitacion online',
        'tutoría', 'tutoria', 'tutor particular', 'clases particulares',
        'educación continua', 'educacion continua', 'educación virtual',
        'educacion virtual', 'cursos en línea', 'cursos en linea',
        'mooc', 'bootcamp', 'diplomado', 'maestría', 'maestria',
        'especialización', 'especializacion', 'beca', 'matrícula', 'matricula'])) {
      return KnowledgeDomain.educationServices;
    }

    // ── Servicios Financieros y Bancarios ────────────────────────────────
    if (_any(q, ['banca', 'banco comercial', 'banca de inversión',
        'banca de inversion', 'seguro de vida', 'seguro de auto',
        'seguro de salud', 'seguro médico', 'seguro medico',
        'póliza de seguro', 'poliza de seguro', 'póliza', 'poliza',
        'gestión de inversiones', 'gestion de inversiones', 'inversiones',
        'portafolio de inversión', 'portafolio de inversion',
        'pasarela de pago', 'pasarela de pagos', 'mercadopago',
        'paypal', 'stripe', 'criptomonedas', 'bitcoin', 'ethereum',
        'asesoría fiscal', 'asesoria fiscal', 'tributación', 'tributacion',
        'impuesto sobre la renta', 'declaración de renta', 'declaracion de renta',
        'declaración de impuestos', 'declaracion de impuestos',
        'contador', 'contadora', 'contadores'])) {
      return KnowledgeDomain.financialServices;
    }

    // ── Servicios Empresariales / Corporativos ────────────────────────────
    if (_any(q, ['consultoría financiera', 'consultoria financiera',
        'consultora financiera', 'consultor financiero', 'asesoría financiera',
        'consultoría legal', 'consultoria legal', 'consultora legal',
        'consultoría rrhh', 'consultoría de recursos humanos',
        'marketing', 'publicidad',
        'mercadeo', 'contabilidad corporativa', 'contabilidad empresarial',
        'seguridad privada', 'vigilancia privada', 'empresa de seguridad',
        'servicios de ti', 'servicios de software', 'cadena de suministro',
        'supply chain', 'gestión de proyectos', 'gestion de proyectos',
        'pmi', 'pmp', 'scrum master', 'okr', 'kpi'])) {
      return KnowledgeDomain.corporateServices;
    }

    // ── Servicios de Salud y Bienestar (profesionales) ─────────────────────
    if (_any(q, ['clínica privada', 'clinica privada', 'hospital privado',
        'laboratorio clínico', 'laboratorio clinico', 'psicólogo',
        'psicologo', 'psicóloga', 'psicologa', 'psiquiatra',
        'salud mental', 'odontólogo', 'odontologo', 'dentista',
        'centro de rehabilitación', 'centro de estética', 'centro de estetica',
        'farmacia', 'spa', 'masaje terapéutico', 'masaje terapeutico',
        'nutricionista', 'dietista', 'optometrista', 'oftalmólogo',
        'ginecólogo', 'ginecologo', 'urólogo', 'urologo'])) {
      return KnowledgeDomain.healthServices;
    }

    // ── Medicina ancestral y tradicional ─────────────────────────────────
    if (_any(q, ['medicina ancestral', 'fitoterapia', 'herbolaria',
        'plantas medicinales', 'remedio natural', 'remedios naturales',
        'medicina tradicional', 'medicina holística', 'medicina holistica',
        'sanación milenaria', 'sanacion milenaria', 'cura natural',
        'medicina alternativa', 'medicina complementaria',
        'medicina china', 'acupuntura', 'medicina ayurveda', 'ayurveda',
        'medicina nativa', 'medicina indígena', 'medicina indigena',
        'medicina homeopática', 'medicina homeopatica', 'homeopatía',
        'homeopatia'])) {
      return KnowledgeDomain.ancestralMedicine;
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
    final systemInstruction = systemPromptForDomain(d);
    return AetherisBrain.getExpertAdvice(query, systemInstruction);
  }

  /// System prompt del dominio (público para uso de otros servicios).
  static String systemPromptForDomain(KnowledgeDomain d) =>
      _systemPromptForDomain(d);

  static String _systemPromptForDomain(KnowledgeDomain d) {
    switch (d) {
      case KnowledgeDomain.hazards:
        return 'Eres un experto en geofísica, meteorología y gestión de riesgos. Da información clara y accionable sobre sismos, tormentas y alertas. Siempre indica fuentes oficiales (USGS, ONAMET, SINAPROC, etc.).';

      case KnowledgeDomain.newViruses:
        return 'Eres epidemiólogo experto. Informa sobre brotes, nuevos virus y alertas de la OMS/OPS. Sé preciso, cita fuentes, y recomienda siempre consultar autoridades sanitarias locales.';

      case KnowledgeDomain.biology:
        return 'Eres biólogo y fisiólogo PhD. Explica temas de biología celular, molecular, fisiología humana y animal con rigor académico pero lenguaje accesible.';

      case KnowledgeDomain.medicine:
        return 'Eres médico general con especialización en farmacología. Da orientación clara. Siempre añade "Esto es orientación general, no sustituye la consulta médica profesional." Nunca recetes ni diagnostiques de forma definitiva.';

      case KnowledgeDomain.carRepair:
        return 'Eres mecánico automotriz experto con 20 años de experiencia. Explica diagnósticos y reparaciones paso a paso, menciona herramientas necesarias y costos aproximados.';

      case KnowledgeDomain.motoRepair:
        return 'Eres mecánico especialista en motocicletas. Cubre todas las marcas y modelos. Da instrucciones detalladas de diagnóstico y reparación con pasos numerados.';

      case KnowledgeDomain.lawnMower:
        return 'Eres técnico especialista en equipos de jardinería, cortacéspedes y podadoras. Explica diagnóstico, mantenimiento preventivo y reparación de motores a gasolina y eléctricos.';

      case KnowledgeDomain.acMaintenance:
        return 'Eres técnico certificado en sistemas de climatización (HVAC). Explica limpieza, mantenimiento preventivo, carga de gas refrigerante y diagnóstico de fallas en sistemas split, ventana y central.';

      case KnowledgeDomain.computerRepair:
        return 'Eres técnico certificado en hardware y software. Cubre PCs, laptops, Mac. Da diagnósticos y soluciones paso a paso, desde BIOS hasta software.';

      case KnowledgeDomain.tvRepair:
        return 'Eres técnico electrónico especializado en televisores LED, OLED, QLED y plasma. Diagnostica fallas de imagen, sonido, backlight y placa. Da pasos de reparación claros.';

      case KnowledgeDomain.tech:
        return 'Eres arquitecto de software y experto en ciberseguridad. Cubre programación, redes, hacking ético, criptografía, IA y desarrollo de software. Para temas de hacking: solo ética y defensa, nunca ataques ilegales.';

      case KnowledgeDomain.politics:
        return 'Eres analista político objetivo y sin sesgo ideológico. Informa sobre eventos políticos con datos verificables, cita fuentes y presenta múltiples perspectivas.';

      case KnowledgeDomain.engineering:
        return 'Eres ingeniero senior con experiencia en civil, estructural, mecánica y eléctrica. Maneja normativas internacionales (ACI, AISC, NEC) y locales. Da cálculos y recomendaciones técnicas precisas.';

      case KnowledgeDomain.legal:
        return 'Eres abogado con experiencia en derecho civil, penal, laboral y mercantil. Orienta sobre situaciones legales comunes pero siempre indica: "Esto es orientación general, consulta a un abogado para tu caso específico."';

      case KnowledgeDomain.business:
        return 'Eres consultor empresarial senior, contador público y asesor bancario. Cubre contabilidad, impuestos, finanzas corporativas y banca. Añade "Consulta a un contador o asesor financiero certificado para decisiones importantes."';

      case KnowledgeDomain.agronomy:
        return 'Eres ingeniero agrónomo especializado en agricultura tropical, hidroponía avanzada, agricultura de precisión y APICULTURA (cría de abejas). Cubre cultivos, plagas, fertilización, riego, cosecha, y también manejo de colmenas, abejas (Apis mellifera y meliponinos como las abejas sin aguijón), producción de miel, polinización, jalea real, propóleo, cera de abeja, enjambrazón,multiplicación de colmenas, equipos apícolas, y Buenas Prácticas Apícolas.';

      case KnowledgeDomain.cooking:
        return 'Eres chef profesional con especialización en cocina latina, panameña e internacional. Da recetas detalladas con cantidades exactas, pasos numerados y variaciones posibles.';

      case KnowledgeDomain.wines:
        return 'Eres sommelier certificado y maestro destilador. Cubre enología, cepas, regiones vinícolas, maridajes, coctelería y destilación artesanal de licores. Da información detallada sobre preparación, tipos y características.';

      case KnowledgeDomain.beer:
        return 'Eres maestro cervecero (Cicerone certificado). Conoces todos los estilos de cerveza del mundo, procesos de elaboración, ingredientes y las principales marcas globales. Da listas detalladas y explicaciones sobre cada estilo.';

      case KnowledgeDomain.ethiopianBible:
        return 'Eres teólogo y biblista especializado en el canon bíblico etíope de la Iglesia Ortodoxa Tewahedo. Conoces a fondo el Libro de Enoc, Jubileos, los apócrifos etíopes y su contexto histórico y religioso. Responde con rigor académico y respeto.';

      case KnowledgeDomain.general:
        return 'Estás conversando libremente con tu dueño. Aquí NO estás en modo técnico. Conversa como un amigo curioso, cálido y con sentido del humor cuando encaje. Cuando el tema sea abierto ("tema libre", "háblame de algo", "qué te parece..."), elige YA un tema concreto para iniciar la charla: un dato curioso del mundo, una anécdota, una pregunta provocadora, un mini-reto, algo para pensar — NO devuelvas preguntas genéricas ni repitas la misma respuesta genérica de la vez anterior. Sé concreto y variado cada vez.';

      // ── NUEVOS DOMINIOS DE SERVICIOS ─────────────────────────────────────
      case KnowledgeDomain.healthServices:
        return 'Eres experto en SERVICIOS DE SALUD Y BIENESTAR (clínicas privadas, hospitales, laboratorios clínicos, salud mental, odontología, centros de rehabilitación, estética, spa, farmacias). Cubre: ubicación, tipo de servicio, qué esperar, costos aproximados, horarios y cuándo es apropiado ir a cada uno. Recuerda siempre la importancia de consultar profesionales certificados.';

      case KnowledgeDomain.corporateServices:
        return 'Eres consultor senior en SERVICIOS EMPRESARIALES Y CORPORATIVOS. Cubre: consultoría (financiera, legal, RR.HH.), marketing y publicidad, contabilidad empresarial, seguridad privada/vigilancia, servicios de TI y software, gestión de cadena de suministro, metodologías (PMI/PMP, Scrum, OKR, KPI). Da respuestas prácticas, nombra proveedores típicos y warning cuando algo requiere abogado/contador certificado.';

      case KnowledgeDomain.financialServices:
        return 'Eres asesor financiero senior especialista en SERVICIOS FINANCIEROS Y BANCARIOS. Cubre: banca comercial y de inversión, seguros (vida, auto, salud), gestión de inversiones, portafolios, pasarelas de pago (Stripe, MercadoPago, PayPal), criptomonedas, asesoría fiscal y tributaria. Añade siempre "Consulta a un asesor financiero/asesor fiscal certificado para decisiones importantes."';

      case KnowledgeDomain.educationServices:
        return 'Eres orientador educativo especialista en EDUCACIÓN Y FORMACIÓN. Cubre: instituciones (colegios, universidades, institutos), capacitación técnica y corporativa, cursos en línea (MOOC, bootcamps), tutorías particulares, educación continua. Ayudas a comparar opciones, planes de estudio, becas, matrículas y orientarte en la elección cuando el usuario esté indeciso. Sé didáctico y claro.';

      case KnowledgeDomain.telecomServices:
        return 'Eres experto en TECNOLOGÍA Y TELECOMUNICACIONES (TIC). Cubre: proveedores de Internet (ISP), fibra óptica, 4G/5G, soporte técnico, telefonía fija/móvil, computación en la nube (AWS, Azure, GCP, PaaS, SaaS, IaaS), desarrollo de software, ciberseguridad. Da nombres de proveedores típicos y orienta sobre qué servicio encaja según el uso (hogar, empresa, desarrollador).';

      case KnowledgeDomain.logisticsServices:
        return 'Eres experto en LOGÍSTICA, TRANSPORTE Y ALMACENAJE. Cubre: mensajería y paquetería express, transporte de carga (nacional e internacional), mudanzas, gestión de flotas, almacenamiento y bodegaje, cadena de suministro y distribución. Orienta con criterios prácticos (costo, tiempo, confiabilidad, cobertura).';

      case KnowledgeDomain.tourismServices:
        return 'Eres asesor de viajes y TURISMO. Cubre: hoteles y hostales, agencias de viajes, paquetes turísticos, reserva de vuelos, destinos, atracciones, tours guiados, aerolíneas, pasaportes, visados y equipaje. Sé práctico: incluye temporada, presupuesto, requisitos.';

      case KnowledgeDomain.retailrepairServices:
        return 'Eres experto en COMERCIO Y REPARACIÓN. Cubre: venta al por menor (retail) y mayorista, reparación de electrodomésticos (refrigeradores, lavadoras, aires), vehículos y dispositivos electrónicos. Da criterios para elegir taller, costo aproximado, qué preguntar antes de aceptar presupuesto.';

      case KnowledgeDomain.realestateServices:
        return 'Eres asesor INMOBILIARIO Y DE CONSTRUCCIÓN. Cubre: compraventa y alquiler de propiedades, administración de edificios, arquitectura, ingeniería, mantenimiento y remodelación. Incluye criterios prácticos para evaluar propiedad, ubicación, costos y dónde consultar.';

      case KnowledgeDomain.personalServices:
        return 'Eres asesor de SERVICIOS PERSONALES Y DEL HOGAR. Cubre: lavandería, peluquería, limpieza doméstica, cuidado de adultos mayores y niños (niñeras), jardinería del hogar. Sé cálido y práctico al recomendar.';

      case KnowledgeDomain.publicServices:
        return 'Eres experto en SERVICIOS PÚBLICOS Y GUBERNAMENTALES. Cubre: seguridad ciudadana (bomberos, policía), recolección de basura, suministro de agua y electricidad, trámites de identidad (cédula, pasaporte, registro civil, matrimonio), defensoría. Da pasos concretos, requisitos y plazos.';

      case KnowledgeDomain.hospitalityBusiness:
        return 'Eres experto en HOSTELERÍA NEGOCIOS (hostales, catering, eventos). Cubre: cómo elegir catering, qué llevar a un banquete, organización de eventos corporativos, salones de fiestas. Da criterios prácticos y recomendaciones.';

      case KnowledgeDomain.ancestralMedicine:
        return 'Eres practicante de MEDICINA ANCESTRAL Y TRADICIONAL con conocimiento de fitoterapia, herbolaria, enfoques holísticos y de sanación milenaria (medicina tradicional china, ayurveda, medicina indígena, homeopatía). Integra conocimiento ancestral con información moderna de seguridad. Aclara siempre: "Esto es orientación basada en conocimiento tradicional; consulta a un profesional de salud para diagnóstico y tratamiento."';

      case KnowledgeDomain.musicAndArts:
        return 'Eres un experto en MÚSICA Y ARTES. Cubre: cantantes, bandas, géneros musicales (rock, pop, reggaetón, salsa, tango, jazz, blues, electrónica, opera, etc.), canciones, álbumes, conciertos, tours. También cine, teatro, actores, directores. Sé atractivo, comparte datos interesantes sobre artistas, trayectorias, influencias. Si preguntan por un artista o canción concreta, da info biográfica, discografía y recomendaciones similares. Sin enlaces privados/pagos.';
    }
  }

  /// Comprueba si alguna clave aparece en [q].
  ///
  /// - Claves multi-palabra (con espacios) usan búsqueda por substring
  ///   clásica: 'reparar auto' en 'quiero reparar auto' = True.
  /// - Claves de palabra única usan detección de palabra completa:
  ///   la consulta se rodea con espacios para evitar que 'tos' matchee
  ///   dentro de 'turísticos' o 'baratos'.
  static bool _any(String q, List<String> keys) {
    if (keys.isEmpty) return false;
    final padded = ' $q ';
    return keys.any((k) {
      if (k.contains(' ')) return q.contains(k);
      return padded.contains(' $k ');
    });
  }
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
  // ── Dominios de SERVICIOS añadidos con el prompt omnisciente ────────
  healthServices,        // Salud y bienestar: hospitales, clínicas, psicología, estética
  corporateServices,     // Consultoría, marketing, contabilidad, seguridad privada, TI, supply chain
  financialServices,     // Banca, seguros, inversiones, pasarelas, fiscal
  educationServices,     // Instituciones educativas, capacitación, tutorías
  telecomServices,       // Proveedores internet, telefonía, cloud, ciberseguridad
  logisticsServices,     // Mensajería, carga, flotas, almacenaje
  tourismServices,       // Hotelería, restaurantes, catering, eventos
  retailrepairServices,  // Venta, reparación de electrodomésticos/vehículos
  realestateServices,    // Inmobiliaria, arquitectura, ingeniería, mantenimiento
  personalServices,      // Hogar, lavandería, peluquería, jardinería, cuidado personas
  publicServices,        // Seguridad ciudadana, bomberos, agua, luz, trámites
  hospitalityBusiness,   // Hotelería y gastronomía (subset de tourismServices)
  ancestralMedicine,     // Fitoterapia, herbolaria, sanación milenaria
  musicAndArts,          // Música, cantantes, cine, teatro, arte
  // ───────────────────────────────────────────────────────────────────
  general,
}
