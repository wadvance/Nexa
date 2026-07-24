class KnowledgeBase {
  static String fallback(String q) {
    return _find(q) ?? _genericFallback(q);
  }

  static String? _find(String q) {
    for (final entry in _entries) {
      for (final kw in entry.keywords) {
        if (q.contains(kw)) return entry.response;
      }
    }
    return null;
  }

  static String _genericFallback(String q) {
    final length = q.length;
    if (length < 8) {
      const replies = [
        'Dime más, estoy aquí.',
        'Cuéntame con más detalle.',
        'Explícame un poco más.',
      ];
      return replies[q.hashCode % replies.length];
    }
    if (q.contains('cómo') || q.contains('como')) {
      return 'Buena pregunta. La respuesta exacta requiere análisis, pero en términos generales: '
          'investiga fuentes confiables, compara perspectivas y saca tus propias conclusiones. '
          'Si quieres profundizar, pregúntame con más detalle.';
    }
    if (q.contains('qué') || q.contains('que')) {
      return 'Es un tema amplio. Depende del contexto específico. '
          'Dame más detalles y te daré una respuesta más precisa y útil.';
    }
    if (q.contains('por qué') || q.contains('por que') || q.contains('razón')) {
      return 'Normalmente hay múltiples factores. Te recomiendo empezar por '
          'identificar la causa raíz más probable y luego ir descartando. '
          'Cuéntame más contexto para ayudarte mejor.';
    }
    return 'Es un tema interesante. Tengo información general al respecto, '
        'pero dime exactamente qué aspecto te interesa y te daré una respuesta más concreta.';
  }

  static const _entries = <_Entry>[
    // ── GEOGRAFÍA ────────────────────────────────────────────────────────────
    _Entry(['capital de francia', 'francia capital'], 'La capital de Francia es París, conocida como la Ciudad de la Luz.'),
    _Entry(['capital de españa', 'españa capital'], 'La capital de España es Madrid, ubicada en el centro del país.'),
    _Entry(['capital de méxico', 'mexico capital', 'capital de mexico'], 'La capital de México es la Ciudad de México, antes llamada Distrito Federal.'),
    _Entry(['capital de argentina', 'argentina capital'], 'La capital de Argentina es Buenos Aires.'),
    _Entry(['capital de colombia', 'colombia capital'], 'La capital de Colombia es Bogotá.'),
    _Entry(['capital de chile', 'chile capital'], 'La capital de Chile es Santiago.'),
    _Entry(['capital de perú', 'peru capital', 'capital de peru'], 'La capital de Perú es Lima.'),
    _Entry(['capital de venezuela', 'venezuela capital'], 'La capital de Venezuela es Caracas.'),
    _Entry(['capital de ecuador', 'ecuador capital'], 'La capital de Ecuador es Quito.'),
    _Entry(['capital de bolivia', 'bolivia capital', 'capital de bolivia'], 'La capital de Bolivia es Sucre, aunque La Paz es la sede de gobierno.'),
    _Entry(['capital de uruguay', 'uruguay capital'], 'La capital de Uruguay es Montevideo.'),
    _Entry(['capital de paraguay', 'paraguay capital'], 'La capital de Paraguay es Asunción.'),
    _Entry(['capital de costa rica', 'capital de costa rica'], 'La capital de Costa Rica es San José.'),
    _Entry(['capital de panamá', 'capital de panama'], 'La capital de Panamá es la Ciudad de Panamá.'),
    _Entry(['capital de guatemala', 'guatemala capital'], 'La capital de Guatemala es la Ciudad de Guatemala.'),
    _Entry(['capital de honduras', 'honduras capital'], 'La capital de Honduras es Tegucigalpa.'),
    _Entry(['capital de el salvador', 'capital de el salvador'], 'La capital de El Salvador es San Salvador.'),
    _Entry(['capital de nicaragua', 'nicaragua capital'], 'La capital de Nicaragua es Managua.'),
    _Entry(['capital de cuba', 'cuba capital'], 'La capital de Cuba es La Habana.'),
    _Entry(['capital de república dominicana', 'capital de republica dominicana'], 'La capital de República Dominicana es Santo Domingo.'),
    _Entry(['capital de puerto rico', 'puerto rico capital'], 'La capital de Puerto Rico es San Juan.'),
    _Entry(['capital de estados unidos', 'capital de ee.uu', 'eeuu capital'], 'La capital de Estados Unidos es Washington D.C.'),
    _Entry(['capital de canadá', 'canada capital', 'capital de canada'], 'La capital de Canadá es Ottawa.'),
    _Entry(['capital de reino unido', 'reino unido capital', 'capital de inglaterra'], 'La capital del Reino Unido es Londres.'),
    _Entry(['capital de alemania', 'alemania capital'], 'La capital de Alemania es Berlín.'),
    _Entry(['capital de italia', 'italia capital'], 'La capital de Italia es Roma.'),
    _Entry(['capital de portugal', 'portugal capital'], 'La capital de Portugal es Lisboa.'),
    _Entry(['capital de brasil', 'brasil capital'], 'La capital de Brasil es Brasilia.'),
    _Entry(['capital de japón', 'japon capital', 'capital de japon'], 'La capital de Japón es Tokio.'),
    _Entry(['capital de china', 'china capital'], 'La capital de China es Pekín.'),
    _Entry(['capital de rusia', 'rusia capital'], 'La capital de Rusia es Moscú.'),
    _Entry(['capital de australia', 'australia capital'], 'La capital de Australia es Canberra.'),
    _Entry(['capital de egipto', 'egipto capital'], 'La capital de Egipto es El Cairo.'),
    _Entry(['océano más grande', 'oceano mas grande', 'océano pacífico', 'oceano pacifico'], 'El océano más grande del mundo es el Pacífico, que cubre aproximadamente 165 millones de km².'),
    _Entry(['océano atlántico', 'oceano atlantico'], 'El océano Atlántico es el segundo más grande y separa América de Europa y África.'),
    _Entry(['río más largo', 'rio mas largo', 'río amazonas', 'rio amazonas'], 'El río más largo del mundo es el Amazonas, con aproximadamente 7,062 km de longitud.'),
    _Entry(['montaña más alta', 'monte everest', 'everest'], 'La montaña más alta del mundo es el Monte Everest, con 8,849 metros sobre el nivel del mar.'),
    _Entry(['desierto más grande', 'desierto del sahara', 'sahara'], 'El desierto cálido más grande del mundo es el Sahara, en África, con 9.2 millones de km².'),
    _Entry(['continente más grande', 'mayor continente', 'asia continente'], 'El continente más grande y poblado del mundo es Asia, con 44.5 millones de km² y más de 4,700 millones de habitantes.'),
    _Entry(['continente más pequeño', 'menor continente', 'oceania continente'], 'El continente más pequeño es Oceanía, que incluye Australia y las islas del Pacífico.'),
    _Entry(['países de américa', 'cuantos países hay en américa', 'paises de america'], 'América tiene 35 países reconocidos, desde Canadá hasta Argentina.'),
    _Entry(['países de europa', 'cuantos países hay en europa', 'paises de europa'], 'Europa tiene 50 países reconocidos, siendo Rusia el más grande y Ciudad del Vaticano el más pequeño.'),

    // ── HISTORIA ─────────────────────────────────────────────────────────────
    _Entry(['primera guerra mundial', 'primera guerra', 'i guerra mundial', '1914'], 'La Primera Guerra Mundial (1914-1918) enfrentó a las potencias aliadas contra los imperios centrales. Terminó con la firma del Tratado de Versalles en 1919.'),
    _Entry(['segunda guerra mundial', 'segunda guerra', 'ii guerra mundial'], 'La Segunda Guerra Mundial (1939-1945) fue el conflicto más grande de la historia. Enfrentó a los Aliados contra las potencias del Eje. Finalizó con la rendición de Alemania y Japón.'),
    _Entry(['imperio romano', 'roma antigua', 'romanos'], 'El Imperio Romano duró desde el 27 a.C. hasta el 476 d.C. en Occidente. Su legado incluye el derecho romano, el latín y grandes obras de ingeniería como acueductos.'),
    _Entry(['cristóbal colón', 'cristobal colon', 'descubrimiento de américa'], 'Cristóbal Colón llegó a América el 12 de octubre de 1492, bajo el patrocinio de los Reyes Católicos de España.'),
    _Entry(['revolución francesa', 'revolucion francesa', '1789'], 'La Revolución Francesa (1789-1799) derrocó la monarquía absoluta y estableció los principios de libertad, igualdad y fraternidad.'),
    _Entry(['revolución industrial', 'revolucion industrial', 'revolucion industrial'], 'La Revolución Industrial comenzó en Inglaterra a mediados del siglo XVIII, transformando la producción con máquinas a vapor.'),
    _Entry(['independencia de méxico', 'independencia de mexico', 'mexico independencia', '1810 méxico'], 'La Independencia de México inició el 16 de septiembre de 1810 con el Grito de Dolores de Miguel Hidalgo.'),
    _Entry(['independencia de panamá', 'independencia de panama', 'panamá independencia'], 'Panamá se independizó de España el 28 de noviembre de 1821 y se unió a la Gran Colombia. Se separó de Colombia el 3 de noviembre de 1903.'),
    _Entry(['muro de berlín', 'muro de berlin', 'caida del muro'], 'El Muro de Berlín cayó el 9 de noviembre de 1989, marcando el fin de la Guerra Fría y la reunificación alemana.'),
    _Entry(['llegada del hombre a la luna', 'apolo 11', 'llegada a la luna'], 'El 20 de julio de 1969, la misión Apolo 11 de la NASA llevó a Neil Armstrong y Buzz Aldrin a la Luna. Armstrong fue el primer humano en pisarla.'),
    _Entry(['antiguo egipto', 'egipto antiguo', 'pirámides de egipto', 'faraones'], 'El Antiguo Egipto floreció a lo largo del Nilo hace más de 5,000 años. Construyeron las pirámides de Giza y desarrollaron la escritura jeroglífica.'),
    _Entry(['civilización maya', 'mayas', 'cultura maya'], 'Los mayas fueron una civilización mesoamericana que destacó en astronomía, matemáticas y escritura jeroglífica. Su período clásico fue del 250 al 900 d.C.'),

    // ── CIENCIA ──────────────────────────────────────────────────────────────
    _Entry(['teoría de la relatividad', 'relatividad de einstein', 'einstein'], 'La teoría de la relatividad fue desarrollada por Albert Einstein. La relatividad especial (1905) y la general (1915) revolucionaron nuestra comprensión del espacio, el tiempo y la gravedad.'),
    _Entry(['evolución de las especies', 'darwin', 'teoría de la evolución', 'origen de las especies'], 'La teoría de la evolución por selección natural fue propuesta por Charles Darwin en "El origen de las especies" (1859).'),
    _Entry(['célula', 'células', 'la célula'], 'La célula es la unidad básica de la vida. Hay dos tipos principales: procariotas (sin núcleo) y eucariotas (con núcleo).'),
    _Entry(['sistema solar', 'planetas del sistema solar', 'sistema solar planetas'], 'El Sistema Solar tiene 8 planetas: Mercurio, Venus, Tierra, Marte, Júpiter, Saturno, Urano y Neptuno. Júpiter es el más grande.'),
    _Entry(['agujero negro', 'agujeros negros', 'black hole'], 'Un agujero negro es una región del espacio con gravedad tan intensa que ni la luz puede escapar. Se forman cuando estrellas masivas colapsan.'),
    _Entry(['energía renovable', 'energias renovables', 'energía solar', 'energía eólica'], 'Las energías renovables incluyen solar, eólica, hidroeléctrica y geotérmica. Son limpias y cada vez más accesibles económicamente.'),
    _Entry(['calentamiento global', 'cambio climático', 'cambio climatico'], 'El calentamiento global es el aumento de la temperatura media de la Tierra debido a los gases de efecto invernadero. Las principales causas son la quema de combustibles fósiles y la deforestación.'),
    _Entry(['gravedad', 'ley de gravedad', 'newton gravedad'], 'La gravedad es la fuerza que atrae los objetos con masa. Isaac Newton formuló la ley de gravitación universal en 1687.'),
    _Entry(['átomo', 'atomos', 'estructura del átomo'], 'El átomo es la unidad más pequeña de la materia. Tiene un núcleo con protones y neutrones, rodeado por electrones en órbita.'),
    _Entry(['adn', 'dna', 'ácido desoxirribonucleico'], 'El ADN contiene la información genética de todos los seres vivos. Tiene estructura de doble hélice, descubierta por Watson y Crick en 1953.'),
    _Entry(['tabla periódica', 'elementos químicos', 'elementos de la tabla periódica'], 'La tabla periódica organiza los 118 elementos químicos conocidos. Fue creada por Dmitri Mendeléyev en 1869.'),
    _Entry(['fotosíntesis', 'fotosintesis', 'las plantas producen oxígeno'], 'La fotosíntesis es el proceso donde las plantas convierten luz solar, CO₂ y agua en glucosa y oxígeno. Ocurre en los cloroplastos.'),

    // ── TECNOLOGÍA ───────────────────────────────────────────────────────────
    _Entry(['qué es la inteligencia artificial', 'que es la inteligencia artificial', 'definición de ia', 'qué es ia'], 'La Inteligencia Artificial es la capacidad de las máquinas para realizar tareas que requieren inteligencia humana, como aprender, razonar y tomar decisiones.'),
    _Entry(['qué es chatgpt', 'que es chatgpt', 'openai chatgpt'], 'ChatGPT es un asistente de IA desarrollado por OpenAI. Usa modelos de lenguaje avanzados para mantener conversaciones naturales.'),
    _Entry(['qué es internet', 'que es internet', 'como funciona internet'], 'Internet es una red global de computadoras interconectadas que permite compartir información. Nació en 1969 como ARPANET.'),
    _Entry(['qué es blockchain', 'que es blockchain', 'blockchain explicado'], 'Blockchain es una tecnología de registro distribuido donde los datos se almacenan en bloques encadenados y no se pueden modificar. Es la base de las criptomonedas.'),
    _Entry(['qué es bitcoin', 'que es bitcoin', 'bitcoin criptomoneda'], 'Bitcoin es la primera criptomoneda descentralizada, creada en 2009 por una persona o grupo bajo el seudónimo Satoshi Nakamoto.'),
    _Entry(['cómo funciona un motor', 'motor de combustión', 'como funciona un motor'], 'Un motor de combustión interna convierte la energía química del combustible en movimiento mecánico mediante explosiones controladas en los cilindros.'),
    _Entry(['cómo funciona un celular', 'como funciona un celular', 'teléfono inteligente'], 'Un smartphone funciona con un procesador, memoria y sistema operativo. Se comunica mediante ondas de radio con torres celulares y WiFi.'),
    _Entry(['qué es la nube', 'que es la nube', 'cloud computing'], 'La nube (cloud computing) permite almacenar y procesar datos en servidores remotos a través de internet, sin necesidad de tenerlos localmente.'),
    _Entry(['qué es una red social', 'redes sociales', 'facebook', 'instagram', 'tiktok'], 'Las redes sociales son plataformas digitales donde los usuarios crean y comparten contenido e interactúan. Las más populares incluyen Facebook, Instagram, TikTok y X.'),

    // ── SALUD ────────────────────────────────────────────────────────────────
    _Entry(['primeros auxilios', 'que hacer en una emergencia', 'rcp', 'reanimación'], 'En una emergencia: 1) Evalúa la seguridad de la escena. 2) Llama a emergencias. 3) Verifica si la persona responde. 4) Si no respira, inicia RCP: 30 compresiones por cada 2 respiraciones.'),
    _Entry(['como reducir el estrés', 'reducir estres', 'manejar ansiedad'], 'Para reducir el estrés: respira profundamente, haz ejercicio regular, duerme bien, organiza tu tiempo y habla con alguien de confianza.'),
    _Entry(['alimentación saludable', 'comida saludable', 'dieta balanceada', 'nutrición'], 'Una alimentación saludable incluye frutas, verduras, proteínas magras, granos enteros y grasas saludables. Limita el azúcar añadido y los alimentos ultraprocesados.'),
    _Entry(['cuánto ejercicio hacer', 'cuanto ejercicio', 'ejercicio semanal'], 'La OMS recomienda al menos 150 minutos de ejercicio moderado a la semana, o 75 minutos de ejercicio vigoroso.'),
    _Entry(['beneficios del agua', 'tomar agua', 'hidratación'], 'Tomar suficiente agua (unos 2 litros al día) ayuda a la digestión, regula la temperatura corporal, lubrica las articulaciones y mejora la concentración.'),
    _Entry(['sueño saludable', 'dormir bien', 'horas de sueño', 'insomnio'], 'Los adultos necesitan 7 a 9 horas de sueño por noche. Para dormir mejor: mantén un horario regular, limita pantallas antes de dormir y evita cafeína por la tarde.'),
    _Entry(['dejar de fumar', 'dejar el tabaco', 'dejar el cigarro'], 'Dejar de fumar es lo mejor para tu salud. Busca apoyo profesional, usa terapias de reemplazo de nicotina si es necesario y recuerda que los beneficios comienzan desde el primer día.'),

    // ── NATURALEZA ────────────────────────────────────────────────────────────
    _Entry(['animal más rápido', 'animal mas rapido', 'guepardo velocidad'], 'El animal terrestre más rápido es el guepardo, que alcanza velocidades de hasta 120 km/h en sprints cortos.'),
    _Entry(['animal más grande', 'ballena azul', 'animal mas grande'], 'El animal más grande del mundo es la ballena azul, que puede medir hasta 30 metros y pesar hasta 200 toneladas.'),
    _Entry(['animal más inteligente', 'animal mas inteligente', 'delfín inteligencia'], 'Entre los animales más inteligentes están los delfines, los chimpancés, los elefantes y los pulpos.'),
    _Entry(['perro razas', 'razas de perros', 'mejor raza de perro'], 'Hay más de 340 razas de perros reconocidas. Las más populares incluyen Labrador, Pastor Alemán, Golden Retriever y Bulldog.'),
    _Entry(['gato razas', 'razas de gatos', 'mejor raza de gato'], 'Hay alrededor de 70 razas de gatos. Las más populares incluyen Persa, Maine Coon, Siamés y Bengalí.'),
    _Entry(['árbol más alto', 'arbol mas alto', 'sequoia'], 'El árbol más alto del mundo es una secuoya roja llamada Hyperion, que mide 115.92 metros, en California.'),
    _Entry(['flor más grande', 'flor mas grande', 'rafflesia'], 'La flor más grande del mundo es la Rafflesia arnoldii, que puede medir hasta 1 metro de diámetro y pesar 11 kg.'),

    // ── ARTE Y CULTURA ───────────────────────────────────────────────────────
    _Entry(['mona lisa', 'gioconda', 'leonardo da vinci'], 'La Mona Lisa, pintada por Leonardo da Vinci entre 1503 y 1519, se encuentra en el Museo del Louvre en París. Es famosa por su enigmática sonrisa.'),
    _Entry(['la última cena', 'ultima cena da vinci'], '"La Última Cena" de Leonardo da Vinci es un mural del siglo XV que representa la cena de Jesús con sus apóstoles. Está en Milán, Italia.'),
    _Entry(['noche estrellada', 'van gogh', 'vincent van gogh'], 'Vincent van Gogh pintó "La noche estrellada" en 1889 mientras estaba en un hospital psiquiátrico. Es una de las obras más reconocidas del postimpresionismo.'),
    _Entry(['shakespeare', 'william shakespeare', 'romeo y julieta', 'hamlet'], 'William Shakespeare es el dramaturgo más importante de la literatura inglesa. Escribió obras como Romeo y Julieta, Hamlet y Macbeth.'),
    _Entry(['miguel de cervantes', 'cervantes', 'don quijote'], 'Miguel de Cervantes escribió "Don Quijote de la Mancha" (1605-1615), considerada la primera novela moderna y una de las mejores obras de la literatura universal.'),
    _Entry(['gabriel garcía márquez', 'garcia marquez', 'cien años de soledad'], 'Gabriel García Márquez, premio Nobel de Literatura, escribió "Cien años de soledad" (1967), obra maestra del realismo mágico.'),
    _Entry(['música clásica', 'beethoven', 'mozart', 'bach', 'compositores clásicos'], 'Los grandes compositores clásicos incluyen a Bach, Mozart, Beethoven, Chopin y Tchaikovsky. Beethoven compuso 9 sinfonías a pesar de quedarse sordo.'),

    // ── DEPORTES ─────────────────────────────────────────────────────────────
    _Entry(['reglas del fútbol', 'futbol reglas', 'como se juega al fútbol'], 'El fútbol se juega entre dos equipos de 11 jugadores. El objetivo es meter gol en la portería contraria. El partido dura 90 minutos en dos tiempos de 45.'),
    _Entry(['pelé', 'pele futbol', 'rey del fútbol'], 'Pelé (Edson Arantes do Nascimento) es considerado uno de los mejores futbolistas de la historia. Ganó tres Copas del Mundo con Brasil.'),
    _Entry(['messi', 'lionel messi', 'messi futbol'], 'Lionel Messi es considerado uno de los mejores futbolistas de la historia. Ha ganado múltiples Balones de Oro y una Copa del Mundo con Argentina en 2022.'),
    _Entry(['cristiano ronaldo', 'ronaldo futbol', 'cr7'], 'Cristiano Ronaldo es uno de los futbolistas más completos de la historia. Es conocido por su físico, su determinación y su increíble capacidad goleadora.'),
    _Entry(['juegos olímpicos', 'olimpiadas', 'juegos olímpicos'], 'Los Juegos Olímpicos modernos comenzaron en 1896 en Atenas, inspirándose en los juegos de la antigua Grecia. Se celebran cada 4 años.'),

    // ── FILOSOFÍA ─────────────────────────────────────────────────────────────
    _Entry(['sócrates', 'socrates filosofo', 'filosofía griega'], 'Sócrates (470-399 a.C.) fue un filósofo griego, maestro de Platón. Su método de enseñanza se basaba en preguntas para hacer reflexionar.'),
    _Entry(['platón', 'platon filosofia', 'república de platón'], 'Platón (427-347 a.C.) fundó la Academia en Atenas. Escribió "La República", donde describe su visión de una sociedad ideal.'),
    _Entry(['aristóteles', 'aristoteles filosofia', 'aristoteles'], 'Aristóteles (384-322 a.C.) fue discípulo de Platón y tutor de Alejandro Magno. Escribió sobre ética, lógica, política, biología y metafísica.'),
    _Entry(['estoicismo', 'estoico', 'marco aurelio', 'séneca'], 'El estoicismo es una filosofía que enseña a centrarse en lo que podemos controlar y aceptar lo que no. Sus principales exponentes fueron Marco Aurelio, Séneca y Epicteto.'),

    // ── MATEMÁTICAS ──────────────────────────────────────────────────────────
    _Entry(['teorema de pitágoras', 'pitagoras', 'pitágoras'], 'El teorema de Pitágoras dice que en un triángulo rectángulo, el cuadrado de la hipotenusa es igual a la suma de los cuadrados de los catetos.'),
    _Entry(['número pi', 'pi matemático', '3.1416'], 'Pi (π) es la constante matemática que representa la relación entre la circunferencia de un círculo y su diámetro. Aproximadamente 3.14159.'),
    _Entry(['infinito', 'infinito matemático', 'símbolo de infinito'], 'El infinito es un concepto que representa una cantidad sin límite. En matemáticas, se usa el símbolo ∞.'),
    _Entry(['qué es el álgebra', 'que es algebra', 'algebra definición'], 'El álgebra es la rama de las matemáticas que usa letras y símbolos para representar números y relaciones. Permite resolver ecuaciones y modelar problemas.'),

    // ── ASTRONOMÍA ────────────────────────────────────────────────────────────
    _Entry(['cuántas estrellas hay', 'cuantas estrellas hay', 'número de estrellas'], 'Se estima que hay alrededor de 100 mil millones de estrellas en nuestra galaxia, la Vía Láctea, y hay billones de galaxias en el universo observable.'),
    _Entry(['vía láctea', 'via lactea', 'nuestra galaxia'], 'La Vía Láctea es una galaxia espiral que contiene nuestro Sistema Solar. Tiene un diámetro de aproximadamente 100,000 años luz.'),
    _Entry(['agujero negro supermasivo', 'sagitario a', 'centro de la galaxia'], 'En el centro de la Vía Láctea hay un agujero negro supermasivo llamado Sagitario A*, con una masa de 4 millones de soles.'),
    _Entry(['cuánto tarda la luz del sol', 'luz del sol en llegar', 'distancia sol tierra'], 'La luz del Sol tarda aproximadamente 8 minutos y 20 segundos en llegar a la Tierra.'),
    _Entry(['eclipse solar', 'eclipse de sol', 'eclipse total'], 'Un eclipse solar ocurre cuando la Luna se interpone entre el Sol y la Tierra, bloqueando total o parcialmente la luz solar.'),

    // ── IDIOMAS ──────────────────────────────────────────────────────────────
    _Entry(['idioma más hablado', 'lengua más hablada', 'idioma mas hablado'], 'El idioma más hablado del mundo por número de hablantes nativos es el chino mandarín. El inglés es el más hablado si se incluyen hablantes no nativos.'),
    _Entry(['cuántos idiomas hay', 'cuantos idiomas existen', 'lenguas del mundo'], 'Se estima que existen entre 6,000 y 7,000 idiomas en el mundo. Papua Nueva Guinea tiene la mayor diversidad lingüística.'),
    _Entry(['origen del español', 'español idioma', 'lengua española'], 'El español proviene del latín vulgar y se desarrolló en la península ibérica. Es el segundo idioma más hablado del mundo por hablantes nativos.'),
  ];
}

class _Entry {
  final List<String> keywords;
  final String response;
  const _Entry(this.keywords, this.response);
}
