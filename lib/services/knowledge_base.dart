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

    // ── COCINA PANAMEÑA ──────────────────────────────────────────────────────
    _Entry(['sao', 'sao de patitas', 'sao de puerco', 'sofrito panameño'], 'El sao es la base de muchos guisos panameños. Se prepara sofriendo cebolla, ají, ajo, tomate y culantro en aceite. Para hacer sao de patitas de puerco: hierve las patitas con sal y ajo hasta que estén tiernas. En una olla aparte, haz un sao con cebolla, ají, ajo, tomate y culantro rallado. Agrega las patitas cocidas, un poco del caldo, sal, pimienta y orégano. Cocina a fuego bajo por 20 minutos. Se sirve con arroz blanco y rodajas de limón.'),
    _Entry(['patitas de puerco', 'patitas de cerdo', 'manos de cerdo'], 'Las patitas de puerco se cocinan primero en agua con sal, ajo y cebolla hasta que ablanden (unos 40 minutos). Luego se guisan en sao (sofrito panameño con cebolla, ají, tomate, ajo y culantro). Se sirven con arroz blanco y limón. Es un plato tradicional panameño lleno de colágeno.'),
    _Entry(['arroz con guandú', 'arroz con guandu', 'guandú panameño'], 'El arroz con guandú es un plato típico panameño. Se cocina arroz con gandules (guandú), coco, sal y ajo. Se sirve con carne de cerdo, chorizo o pescado frito. Es tradicional en las fiestas patrias de noviembre.'),
    _Entry(['sancocho panameño', 'sancocho', 'sancocho de gallina'], 'El sancocho panameño es una sopa espesa hecha con gallina o pollo, ñame, yuca, otoe, mazorca, plátano verde y culantro. Se sazona con ajo, cebolla y sal. Se sirve con arroz blanco y rodajas de ají.'),
    _Entry(['tamal panameño', 'tamal de olla', 'tamal panameño'], 'Los tamales panameños se hacen con masa de maíz rellena de pollo o cerdo, aceitunas, alcaparras y pasas, envueltos en hojas de bijao y cocidos en agua. La masa se prepara con maíz molido, manteca de cerdo, sal y achiote para el color.'),
    _Entry(['carimañola', 'carimañola panameña'], 'La carimañola es una fritura panameña de yuca rellena de carne molida guisada, queso o pollo. Se amasa la yuca cocida y triturada, se rellena, se forman croquetas alargadas y se fríen hasta dorar.'),
    _Entry(['ropa vieja', 'ropa vieja panameña'], 'La ropa vieja es carne de res desmechada guisada en un sao de cebolla, ají, tomate, ajo y culantro. Se cocina a fuego bajo hasta que la carne absorba los sabores. Se sirve con arroz blanco, tajadas de plátano maduro frito y frijoles.'),
    _Entry(['ceviche panameño', 'ceviche de corvina', 'ceviche panameño'], 'El ceviche panameño se hace con corvina fresca cortada en cubos, cocida en jugo de limón con cebolla morada en rodajas finas, ají, culantro picado, sal y pimienta. Se sirve frío con galletas de soda.'),
    _Entry(['chicheme', 'chicheme panameño'], 'El chicheme es una bebida tradicional panameña hecha de maíz tierno molido, cocido con leche, canela, azúcar y vainilla. Se sirve fría, espesa y dulce.'),
    _Entry(['raspadilla', 'raspadilla panameña', 'raspao', 'raspado'], 'La raspadilla es hielo raspado bañado en jarabes de colores, leche condensada y sirope de chocolate. Es un postre y refresco callejero panameño.'),
    _Entry(['tortilla de maíz', 'tortilla panameña', 'tortilla de maíz nuevo'], 'Las tortillas panameñas se hacen con maíz nuevo molido, amasado con sal y agua. Se forman discos delgados y se cocinan en budare o sartén. Se comen con queso blanco, crema o como acompañante.'),
    _Entry(['arroz con coco', 'arroz con coco panameño'], 'El arroz con coco se prepara friendo coco rallado para extraer la leche, luego se cocina arroz con esa leche, sal y azúcar. Es típico de la costa caribeña de Panamá.'),
    _Entry(['pescado frito', 'pescado frito panameño', 'pescado entero frito'], 'El pescado frito panameño se hace con pescado entero (corvina, pargo o mojarra) marinado con ajo, sal y limón, luego frito en aceite caliente hasta dorar y crujiente. Se sirve con arroz, patacones y ensalada de repollo.'),
    _Entry(['patacones', 'patacones panameños', 'tostones'], 'Los patacones se hacen con plátano verde cortado en rodajas gruesas, fritas primero, luego aplastadas y fritas de nuevo hasta dorar. Se salan al gusto y se sirven como acompañante o con ceviche.'),
    _Entry(['cerveza panamá', 'cerveza panameña', 'panamá cerveza'], 'En Panamá hay varias cervezas locales: Panamá (la más tradicional), Atlas, Balboa, Soberana y otras artesanales. La Cerveza Panamá, fundada en 1909, es la más emblemática.'),
    _Entry(['seco panameño', 'seco', 'aguardiente panameño'], 'El seco es el aguardiente nacional de Panamá, destilado de caña de azúcar. Se usa en cócteles como el seco con leche condensada, hielo y canela. También se toma solo o con refresco de limón.'),
    _Entry(['locro panameño', 'locro', 'sopa panameña'], 'El locro es una sopa espesa panameña hecha con zapallo (calabaza), maíz, carne de cerdo o res, y verduras. Se sazona con ajo, cebolla y culantro.'),
    _Entry(['bollo panameño', 'bollo de maíz', 'bollo de maíz nuevo'], 'Los bollos panameños son masas de maíz envueltas en hojas de maíz o bijao y cocidas al vapor. Pueden ser de maíz nuevo (dulce) o de maíz viejo (salado), rellenos de queso o carne.'),

    // ── MÚSICA ───────────────────────────────────────────────────────────────
    _Entry(['música clásica', 'musica clasica', 'compositores clásicos', 'sinfonía', 'sinfonia'], 'La música clásica abarca desde el período barroco (Bach, Vivaldi), clásico (Mozart, Haydn), romántico (Beethoven, Chopin, Tchaikovsky) hasta el moderno (Stravinski, Debussy). La orquesta sinfónica típica tiene cuerdas, maderas, metales y percusión.'),
    _Entry(['música salsa', 'salsa', 'salsa dura', 'salsa romántica'], 'La salsa nació en Nueva York de la mezcla de ritmos afrocubanos con jazz. Grandes exponentes: Héctor Lavoe, Celia Cruz, Rubén Blades, Willie Colón, Marc Anthony. La salsa dura tiene más percusión; la romántica, más énfasis en las letras'),
    _Entry(['música reggae', 'reggae', 'bob marley'], 'El reggae originario de Jamaica en los 60. Bob Marley es su máximo exponente. Se caracteriza por el ritmo acentuado en el segundo y cuarto tiempo, y letras sobre justicia social, amor y espiritualidad rastafari.'),
    _Entry(['música rock', 'rock and roll', 'rock clásico', 'rock'], 'El rock nació en los 50 con Chuck Berry y Elvis Presley. En los 60 llegaron The Beatles y The Rolling Stones. Los 70 trajeron el rock progresivo (Pink Floyd) y el heavy metal (Led Zeppelin). Los 80 el punk y rock alternativo.'),
    _Entry(['música pop', 'pop música', 'música popular'], 'El pop es música popular comercial. Grandes artistas: Michael Jackson (el rey del pop), Madonna, Britney Spears, Taylor Swift, Shakira, Luis Fonsi. Se caracteriza por melodías pegajosas, estribillos repetitivos y producción pulida.'),
    _Entry(['música reguetón', 'reguetón', 'reggaeton', 'perreo'], 'El reguetón nació en Puerto Rico en los 90 combinando reggae jamaiquino, hip hop y ritmos latinos. Artistas clave: Daddy Yankee, Bad Bunny, J Balvin, Karol G, Don Omar. El dembow es su ritmo base característico.'),
    _Entry(['música jazz', 'jazz', 'música de jazz'], 'El jazz nació en Nueva Orleans a principios del siglo XX. Combina blues, ragtime y música africana. Grandes: Louis Armstrong, Miles Davis, John Coltrane, Ella Fitzgerald. El jazz se caracteriza por la improvisación.'),
    _Entry(['música vallenato', 'vallenato', 'acordeón vallenato'], 'El vallenato es un género musical colombiano de la región caribeña. Usa acordeón, caja y guacharaca. Grandes: Carlos Vives, Diomedes Díaz, Los Hermanos Zuleta.'),
    _Entry(['instrumentos musicales', 'instrumentos de música', 'tipos de instrumentos'], 'Los instrumentos musicales se clasifican en cuerdas (guitarra, violín, piano), viento (flauta, saxofón, trompeta), percusión (batería, maracas, tambores) y electrónicos (sintetizador, theremín).'),

    // ── CINE Y TEATRO ────────────────────────────────────────────────────────
    _Entry(['cine', 'películas', 'historia del cine', 'mejores películas'], 'El cine nació en 1895 con los hermanos Lumière. Grandes películas: El Padrino, Ciudadano Kane, Casablanca, Lo que el viento se llevó. Los géneros incluyen drama, comedia, acción, terror, ciencia ficción y documental.'),
    _Entry(['actor famoso', 'actor de cine', 'actores famosos'], 'Actores legendarios: Marlon Brando, Robert De Niro, Al Pacino, Meryl Streep, Tom Hanks, Leonardo DiCaprio. Actores latinos: Antonio Banderas, Gael García Bernal, Salma Hayek, Penélope Cruz.'),
    _Entry(['director de cine', 'directores famosos', 'mejores directores'], 'Directores icónicos: Steven Spielberg, Martin Scorsese, Alfred Hitchcock, Stanley Kubrick, Quentin Tarantino, Christopher Nolan. Latinoamericanos: Guillermo del Toro, Alejandro González Iñárritu, Alfonso Cuarón.'),
    _Entry(['teatro', 'historia del teatro', 'obras de teatro'], 'El teatro nació en la Antigua Grecia con las tragedias de Sófocles y Eurípides y las comedias de Aristófanes. Grandes dramaturgos: Shakespeare, Molière, Lorca, Ibsen, Chéjov. El teatro incluye drama, comedia, musical y experimental.'),
    _Entry(['oscar', 'premios oscar', 'premios de la academia'], 'Los Premios Óscar son los premios cinematográficos más importantes del mundo, otorgados por la Academia de Hollywood desde 1929. Categorías principales: Mejor Película, Mejor Director, Mejor Actor y Mejor Actriz.'),
    _Entry(['película panameña', 'cine panameño', 'películas panameñas'], 'El cine panameño ha crecido en los últimos años. Películas destacadas: "La Yuma" (2010), "Salsipuedes" (2016), "Ruben Blades Is Not My Name" (2018), "Encuentros" (2021). El IFF Panamá es el festival internacional de cine.'),

    // ── PLAYAS, RÍOS, MONTAÑAS ──────────────────────────────────────────────
    _Entry(['playas de panamá', 'playas panameñas', 'mejores playas panamá'], 'Panamá tiene playas en ambos océanos. Caribe: Bocas del Toro (Isla Colón, Red Frog), Portobelo, Isla Grande. Pacífico: Santa Catalina (surf), Pedasí, Isla Contadora (archipiélago de las Perlas), Cambutal.'),
    _Entry(['ríos de panamá', 'ríos panameños', 'rios panamá'], 'Panamá tiene numerosos ríos. El más largo es el Río Chucunaque (231 km). Otros: Río Tuira, Río Bayano, Río Santa María, Río Chagres (vital para el Canal), Río Indio, Río La Villa.'),
    _Entry(['montañas de panamá', 'montañas panameñas', 'cerros panamá'], 'Panamá tiene montañas volcánicas. El punto más alto es el Volcán Barú (3,475 m) en Chiriquí. Otras: Cerro Fabrega, Cerro Itamut, Cerro Santiago. La cordillera Central divide el país en vertientes Caribe y Pacífica.'),
    _Entry(['volcán barú', 'volcan baru', 'cerro punta', 'boquete'], 'El Volcán Barú es la montaña más alta de Panamá con 3,475 m. Está en Chiriquí, cerca de Boquete. Es un volcán inactivo desde el siglo XVI. Desde la cima se ven ambos océanos en días despejados.'),
    _Entry(['bocas del toro', 'bocas del toro panamá', 'isla colon'], 'Bocas del Toro es un archipiélago en el Caribe panameño. Capital: Isla Colón. Conocido por playas de arena blanca, arrecifes de coral, surf, vida nocturna y biodiversidad.'),
    _Entry(['san blas', 'guna yala', 'islas san blas', 'comarca guna'], 'San Blas (Guna Yala) es un archipiélago de 365 islas en el Caribe panameño, territorio autónomo del pueblo Guna. Playas vírgenes, aguas cristalinas, cultura ancestral. Sin electricidad ni hoteles grandes.'),
    _Entry(['playa santa catalina', 'santa catalina panamá', 'surf panamá'], 'Santa Catalina es un pueblo playero en Veraguas, Pacífico panameño. Famoso por surf de clase mundial (punto de rompiente "La Punta"). También es puerta de entrada a la Isla Coiba.'),
    _Entry(['isla coiba', 'coiba panamá', 'parque nacional coiba'], 'La Isla Coiba es la isla más grande de Panamá, en el Pacífico. Fue colonia penal hasta 2004. Hoy es Parque Nacional y Patrimonio de la Humanidad UNESCO, con arrecifes y fauna marina increíbles.'),
    _Entry(['boquete', 'boquete chiriquí', 'valle de boquete'], 'Boquete es un pueblo en las tierras altas de Chiriquí, Panamá. Clima fresco (15-25°C), famoso por su café geisha (uno de los más caros del mundo), paisajes de montaña, flores y senderismo.'),

    // ── CAMPING ──────────────────────────────────────────────────────────────
    _Entry(['camping', 'acampar', 'campamento', 'equipo de camping'], 'Para acampar necesitas: carpa (tienda de campaña), bolsa de dormir (sleeping bag), aislante, linterna, cocinilla portátil, repelente de insectos, kit de primeros auxilios, agua potable y comida no perecedera. Lugares en Panamá: Parque Nacional Soberanía, playas de Bocas, Boquete, Altos de Campana.'),
    _Entry(['tienda de campaña', 'carpa para acampar', 'como elegir carpa'], 'Elige carpa según capacidad (1-2, 3-4 personas), estación (3 estaciones para clima normal, 4 para invierno), peso (para mochilear busca menos de 2.5 kg). Marcas: Coleman, Quechua, The North Face, Marmot.'),
    _Entry(['supervivencia', 'técnicas de supervivencia', 'supervivencia al aire libre'], 'Técnicas básicas de supervivencia: 1) Busca o construye refugio. 2) Encuentra agua potable (hierve o purifica). 3) Haz fuego. 4) Señaliza para rescate (3 de todo: silbatos, fogatas). 5) No entres en pánico.'),

    // ── SEXOLOGÍA ────────────────────────────────────────────────────────────
    _Entry(['sexología', 'sexualidad humana', 'educación sexual'], 'La sexología estudia la sexualidad humana: biología, psicología, cultura y relaciones. Aborda temas como orientación sexual, identidad de género, salud sexual, consentimiento, disfunciones y educación sexual integral.'),
    _Entry(['anticonceptivos', 'métodos anticonceptivos', 'planificación familiar'], 'Métodos anticonceptivos: condón (barrera), píldora anticonceptiva (hormonal), DIU (dispositivo intrauterino), implante, inyección, parche, anillo vaginal, ligadura de trompas, vasectomía. Solo el condón protege de ETS.'),
    _Entry(['ets', 'enfermedades de transmisión sexual', 'its'], 'Enfermedades de transmisión sexual comunes: VIH/SIDA, clamidia, gonorrea, sífilis, herpes genital, VPH (virus del papiloma humano), hepatitis B. Se previenen con uso correcto del condón y vacunación (VPH, hepatitis B).'),
    _Entry(['consentimiento sexual', 'consentimiento', 'relaciones consentidas'], 'El consentimiento sexual debe ser: voluntario, informado, entusiasta, específico y reversible. Solo "sí" significa sí. El silencio, la coerción o estar intoxicado no es consentimiento.'),
    _Entry(['orientación sexual', 'lgbtq', 'identidad de género'], 'La orientación sexual (heterosexual, homosexual, bisexual, asexual) es la atracción hacia otros. La identidad de género (cisgénero, transgénero, no binario) es cómo te identificas. Son conceptos distintos. La diversidad sexual es natural.'),

    // ── AUTOS Y MOTOS ────────────────────────────────────────────────────────
    _Entry(['marcas de autos', 'marcas de carros', 'fabricantes de autos'], 'Fabricantes de autos: Toyota, Honda, Ford, Chevrolet, Volkswagen, BMW, Mercedes-Benz, Audi, Hyundai, Kia, Nissan, Mazda, Subaru, Tesla. Toyota es el mayor fabricante mundial por volumen.'),
    _Entry(['cambio de aceite', 'aceite de motor', 'cuando cambiar aceite'], 'El aceite de motor se cambia cada 5,000-10,000 km o según manual. Usa la viscosidad recomendada (ej. 5W-30). Cambia también el filtro de aceite. El aceite lubrica, limpia y enfría el motor.'),
    _Entry(['tipos de motos', 'motos deportivas', 'motos cruiser', 'motos touring'], 'Tipos de motos: deportivas (alta velocidad), cruiser (estilo chopper), touring (viajes largos), naked (calles), dual sport (calle/tierra), motocross (off-road), scooter (ciudad). Marcas: Harley-Davidson, Honda, Yamaha, Kawasaki, Ducati, BMW.'),
    _Entry(['cómo funciona un motor', 'motor 4 tiempos', 'motor de combustión'], 'Un motor de 4 tiempos funciona en cuatro fases: admisión (entra aire+combustible), compresión (pistón sube), explosión (bujía enciende), escape (gases salen). La potencia se mide en caballos de fuerza (HP) o kilovatios (kW).'),

    // ── MUEBLES HOGAR ────────────────────────────────────────────────────────
    _Entry(['muebles de casa', 'mueblerías', 'tiendas de muebles'], 'Las tiendas de muebles ofrecen: salas, comedores, recámaras, cocinas, muebles de jardín y oficina. Marcas: IKEA, Ashley Furniture, Rooms To Go. En Panamá: Confort Plaza, Doral, Súper Muebles, El Mueble.'),
    _Entry(['tipos de madera', 'muebles de madera', 'madera para muebles'], 'Maderas comunes para muebles: caoba (lujosa, duradera), cedro (aromática, resistente a plagas), pino (económica, versátil), roble (fuerte, clásica), teca (para exteriores). Cada una tiene diferentes propiedades de dureza y grano.'),

    // ── HOSPITALES Y SALUD ────────────────────────────────────────────────────
    _Entry(['hospitales en panamá', 'hospitales panameños', 'clínicas panamá'], 'Principales hospitales en Panamá: Hospital Santo Tomás (público, más grande), Hospital Punta Pacífica, Hospital Nacional, Clínica Hospital San Fernando, Hospital Paitilla, Hospital Chiriquí (David). Todos ofrecen servicios de emergencia 24h.'),
    _Entry(['medicamentos comunes', 'farmacia', 'medicinas básicas'], 'Medicamentos comunes de venta libre: paracetamol (fiebre/dolor), ibuprofeno (antiinflamatorio), loratadina (alergias), omeprazol (acidez), ibuprofeno (dolor muscular), antidiarreicos (loperamida). Siempre consulta al médico o farmacéutico.'),
    _Entry(['presión arterial', 'presion arterial alta', 'hipertensión'], 'La presión arterial normal es menos de 120/80 mmHg. La hipertensión (alta) es mayor de 130/80. Se controla con dieta baja en sodio, ejercicio, peso saludable y medicación si es necesario.'),
    _Entry(['diabetes', 'diabetes tipo 2', 'azúcar en la sangre'], 'La diabetes es una enfermedad donde el cuerpo no produce o usa bien la insulina. Síntomas: sed excesiva, orinar mucho, cansancio. Se controla con dieta, ejercicio, medicación oral o insulina y monitoreo de glucosa.'),
    _Entry(['primeros auxilios básicos', 'botiquín', 'kit de emergencia'], 'Un botiquín debe incluir: vendas, gasas, esparadrapo, antiséptico (alcohol/yodo), tijeras, pinzas, guantes desechables, analgésico, antidiarreico, antihistamínico y números de emergencia.'),

    // ── ARQUITECTURA E INGENIERÍA ────────────────────────────────────────────
    _Entry(['arquitectura', 'estilos arquitectónicos', 'historia de la arquitectura'], 'La arquitectura ha evolucionado desde las pirámides egipcias, el estilo clásico griego y romano, el gótico, renacimiento, barroco, hasta el moderno (Le Corbusier, Frank Lloyd Wright) y contemporáneo.'),
    _Entry(['arquitectura panameña', 'edificios panamá', 'arquitectura en panamá'], 'Panamá tiene una mezcla arquitectónica: Casco Viejo (colonial español), Art Decó (Edificio Lefevre), rascacielos modernos (JW Marriott), y el Canal de Panamá (ingeniería).'),
    _Entry(['ingeniería civil', 'ingenieria civil', 'ramas de la ingeniería'], 'La ingeniería civil diseña y construye infraestructura: puentes, carreteras, edificios, presas, túneles. Subramas: estructural, geotécnica, hidráulica, transporte y construcción.'),
    _Entry(['canal de panamá', 'historia del canal', 'funcionamiento del canal'], 'El Canal de Panamá conecta el Atlántico y Pacífico. Inaugurado en 1914, usa esclusas que elevan barcos 26 metros sobre el nivel del mar. En 2016 se amplió con un tercer juego de esclusas (Neopanamax). Ahorra 13,000 km de viaje.'),
    _Entry(['puentes', 'tipos de puentes', 'ingeniería de puentes'], 'Tipos de puentes: viga (el más simple), arco (distribuye carga), colgante (Golden Gate), atirantado (Puente de las Américas), voladizo. El más largo del mundo es el Puente Danyang-Kunshan en China (164.8 km).'),

    // ── INFORMÁTICA Y REDES ──────────────────────────────────────────────────
    _Entry(['programación', 'lenguajes de programación', 'código'], 'Lenguajes de programación: Python (versátil, IA), JavaScript (web), Java (empresarial), C++ (alto rendimiento), C# (.NET), Kotlin (Android), Swift (iOS), Dart/Flutter (multi-plataforma). Python es el más recomendado para empezar.'),
    _Entry(['redes de computadoras', 'redes informáticas', 'internet funcionamiento'], 'Internet es una red global de redes. Protocolos: TCP/IP (base de internet), HTTP/HTTPS (web), DNS (traduce nombres a IPs), FTP (transferencia de archivos), SMTP (email). Las redes se clasifican en LAN, WAN, MAN y PAN.'),
    _Entry(['qué es una ip', 'dirección ip', 'ip público privado'], 'Una dirección IP identifica un dispositivo en una red. IPv4 (ej. 192.168.1.1) tiene 4 mil millones de direcciones. IPv6 (ej. 2001:db8::1) tiene direcciones virtualmente ilimitadas. Las IPs públicas son visibles en internet; las privadas, en redes locales.'),
    _Entry(['wifi', 'wi-fi', 'red inalámbrica'], 'Wi-Fi es tecnología de red inalámbrica que usa ondas de radio (2.4 GHz y 5 GHz). Estándares: Wi-Fi 4 (802.11n), Wi-Fi 5 (802.11ac), Wi-Fi 6, Wi-Fi 7. La seguridad WPA3 es la más reciente.'),
    _Entry(['ciberseguridad', 'seguridad informática', 'hacking ético'], 'La ciberseguridad protege sistemas y datos. Ramas: seguridad de redes, seguridad en aplicaciones, criptografía, análisis de malware, hacking ético (penetration testing). Amenazas comunes: phishing, ransomware, malware, ingeniería social.'),
    _Entry(['qué es la nube', 'cloud computing', 'servicios en la nube'], 'La nube ofrece recursos informáticos por internet. Modelos: IaaS (infraestructura), PaaS (plataforma), SaaS (software). Proveedores: AWS (Amazon), Azure (Microsoft), Google Cloud, DigitalOcean. Beneficios: escalabilidad, pago por uso.'),

    // ── REDES SOCIALES ───────────────────────────────────────────────────────
    _Entry(['facebook', 'facebook red social', 'meta'], 'Facebook, fundado por Mark Zuckerberg en 2004, es la red social más grande del mundo con más de 3,000 millones de usuarios. Permite compartir publicaciones, fotos, videos, eventos y mensajes. Su empresa matriz es Meta.'),
    _Entry(['instagram', 'instagram red social', 'insta'], 'Instagram, fundado en 2010 por Kevin Systrom, comprado por Meta en 2012. Red social enfocada en fotos y videos, Reels (videos cortos), Stories (contenido temporal), IGTV. Tiene más de 2,000 millones de usuarios.'),
    _Entry(['x red social', 'twitter red social', 'x antes twitter'], 'X (antes Twitter), fundado por Jack Dorsey en 2006. Red de microblogging con publicaciones de hasta 280 caracteres. Comprado por Elon Musk en 2022 y renombrado X. Se usa para noticias en tiempo real.'),
    _Entry(['tiktok', 'tik tok', 'tiktok red social'], 'TikTok, lanzado por ByteDance en 2016, es la red social de videos cortos de más rápido crecimiento. Su algoritmo recomienda contenido basado en preferencias del usuario. Tiene más de 1,500 millones de usuarios.'),
    _Entry(['youtube', 'youtube red social', 'youtube videos'], 'YouTube, fundado en 2005 por Chad Hurley, Steve Chen y Jawed Karim, comprado por Google en 2006. Es la plataforma de videos más grande del mundo, con más de 2,500 millones de usuarios y 500 horas de video subidas por minuto.'),
    _Entry(['whatsapp', 'whatsapp mensajería', 'whatsapp meta'], 'WhatsApp, fundado por Jan Koum en 2009, comprado por Meta en 2014. Es la aplicación de mensajería más usada del mundo con cifrado de extremo a extremo. Tiene más de 2,000 millones de usuarios.'),

    // ── CONTABILIDAD ─────────────────────────────────────────────────────────
    _Entry(['contabilidad básica', 'que es contabilidad', 'contabilidad definición'], 'La contabilidad registra, clasifica y resume las transacciones financieras de una empresa. Principios: partida doble (cada transacción afecta al menos dos cuentas), debe y haber, activo = pasivo + patrimonio.'),
    _Entry(['iva', 'impuesto al valor agregado', 'itbms panamá'], 'El IVA (ITBMS en Panamá) es un impuesto al consumo. En Panamá es del 7% general, 0% en alimentos básicos y medicinas. Las empresas deben recolectarlo y pagarlo al fisco mensual o trimestralmente.'),
    _Entry(['declaración de impuestos', 'declaración de renta', 'impuesto sobre la renta'], 'El impuesto sobre la renta (ISR) se paga sobre las ganancias. Las personas naturales declaran anualmente. En Panamá, el sistema es territorial: solo se grava la renta de fuente panameña.'),
    _Entry(['balance general', 'estados financieros', 'estado de resultados'], 'El balance general muestra activos (lo que tiene), pasivos (lo que debe) y patrimonio (capital). El estado de resultados muestra ingresos, gastos y utilidad o pérdida en un período. Son los estados financieros básicos.'),
    _Entry(['facturación', 'factura electrónica', 'requisitos de factura'], 'Una factura debe tener: número secuencial, fecha, datos del emisor y receptor, descripción de bienes/servicios, monto, impuestos (ITBMS). En Panamá la factura electrónica es obligatoria desde 2023.'),

    // ── SISMOS Y MAREAS ──────────────────────────────────────────────────────
    _Entry(['mareas', 'cómo funcionan las mareas', 'subida del mar'], 'Las mareas son causadas por la atracción gravitacional de la Luna y el Sol sobre los océanos. Hay dos mareas altas y dos bajas cada día (ciclo de 12.4 horas). Las mareas vivas (spring tides) ocurren en luna llena y nueva.'),
    _Entry(['sismología', 'terremotos causas', 'placas tectónicas'], 'Los terremotos son causados por el movimiento de las placas tectónicas. La escala de Richter mide la magnitud (energía liberada). La escala de Mercalli mide la intensidad (efectos). El Anillo de Fuego del Pacífico concentra el 90% de los sismos.'),
    _Entry(['escala richter', 'magnitud terremoto', 'medir sismos'], 'La escala de Richter es logarítmica: cada número entero representa 10 veces más amplitud y 31.6 veces más energía. Un sismo de magnitud 6 libera tanta energía como la bomba atómica de Hiroshima.'),
    _Entry(['panamá sismos', 'terremotos en panamá', 'actividad sísmica panamá'], 'Panamá está en el cinturón de fuego del Pacífico, con actividad sísmica moderada. Las zonas más activas son Chiriquí (cerca del Volcán Barú), el Golfo de Chiriquí y la frontera con Costa Rica. Los sismos de magnitud 5-6 ocurren ocasionalmente.'),

    // ── SEGURIDAD INDUSTRIAL ─────────────────────────────────────────────────
    _Entry(['seguridad industrial', 'seguridad en el trabajo', 'prevención de riesgos'], 'La seguridad industrial previene accidentes laborales. Elementos: EPP (equipo de protección personal: casco, guantes, lentes, arnés), señalización, extintores, planes de emergencia, capacitación. Norma OSHA en USA, normas locales en cada país.'),
    _Entry(['extintores', 'tipos de extintores', 'clases de fuego'], 'Clases de fuego: A (materiales sólidos: madera, papel), B (líquidos inflamables), C (eléctricos), D (metales combustibles), K (aceites de cocina). Extintores: agua (A), CO2 (B/C), polvo químico seco (ABC), espuma (A/B).'),
    _Entry(['epp', 'equipo de protección personal', 'cascos seguridad', 'guantes seguridad'], 'Equipo de protección personal: casco (protección craneana), lentes de seguridad (impactos/químicos), guantes (mecánicos, químicos, eléctricos), botas con puntera de acero, arnés (trabajo en altura), protectores auditivos, mascarillas respiratorias.'),

    // ── POLÍTICA Y GOBIERNO ──────────────────────────────────────────────────
    _Entry(['política', 'sistemas políticos', 'tipos de gobierno'], 'Sistemas políticos: democracia (el pueblo elige), monarquía (rey/reina), república (jefe de estado electo), dictadura (poder concentrado en uno), socialismo (estado controla medios de producción), capitalismo (mercado libre).'),
    _Entry(['gobierno de panamá', 'política panameña', 'presidentes de panamá'], 'Panamá es una república democrática con tres poderes: Ejecutivo (presidente), Legislativo (Asamblea Nacional), Judicial (Corte Suprema). El presidente se elige cada 5 años. El actual presidente es José Raúl Mulino (2024).'),
    _Entry(['democracia', 'que es democracia', 'sistema democrático'], 'La democracia (del griego "poder del pueblo") es un sistema donde los ciudadanos eligen a sus representantes mediante votaciones libres. Características: separación de poderes, estado de derecho, derechos humanos, pluralismo político.'),
    _Entry(['onu', 'organización de las naciones unidas', 'naciones unidas'], 'La ONU fue fundada en 1945 tras la Segunda Guerra Mundial. Tiene 193 estados miembros. Propósitos: mantener paz y seguridad, promover derechos humanos, cooperación internacional. Sede en Nueva York.'),
    _Entry(['derechos humanos', 'declaración derechos humanos', 'ddhh'], 'La Declaración Universal de Derechos Humanos (1948) establece derechos básicos: vida, libertad, igualdad, educación, trabajo, salud, libre expresión. Son universales, inalienables e interdependientes.'),

    // ── AVANCES TECNOLÓGICOS ─────────────────────────────────────────────────
    _Entry(['inteligencia artificial generativa', 'ia generativa', 'modelos de lenguaje'], 'La IA generativa crea contenido nuevo: texto (ChatGPT, Gemini), imágenes (DALL-E, Midjourney), música, código. Usa modelos de lenguaje grandes entrenados con billones de parámetros. Avances recientes: GPT-4, Gemini, Claude, Llama.'),
    _Entry(['realidad virtual', 'vr', 'realidad aumentada', 'ar'], 'Realidad virtual (VR): sumerge al usuario en un mundo digital (Meta Quest, PlayStation VR). Realidad aumentada (AR): superpone objetos digitales al mundo real (Pokémon GO, filtros Instagram). Realidad mixta (MR): combina ambas.'),
    _Entry(['vehículos eléctricos', 'autos eléctricos', 'tesla', 'ev'], 'Los vehículos eléctricos (EV) usan baterías recargables en vez de combustible. Tesla es el líder mundial. Otras marcas: Nissan Leaf, Chevrolet Bolt, Hyundai Ioniq, BYD. Ventajas: cero emisiones, menor costo operativo.'),
    _Entry(['energía solar', 'paneles solares', 'energía fotovoltaica'], 'La energía solar convierte la luz del sol en electricidad mediante paneles fotovoltaicos. Los paneles modernos tienen 20-23% de eficiencia. La energía solar es la fuente renovable de más rápido crecimiento en el mundo.'),
    _Entry(['robótica', 'robots', 'automatización'], 'La robótica combina ingeniería, informática y electrónica para crear robots. Tipos: industriales (fábricas), de servicio (aspiradoras Roomba), médicos (Da Vinci para cirugía), humanoides (Tesla Optimus, Boston Dynamics).'),
    _Entry(['5g', 'tecnología 5g', 'red 5g'], 'El 5G es la quinta generación de redes móviles. Ofrece velocidades hasta 10 Gbps (100x más que 4G), latencia de 1 ms, y capacidad para conectar 1 millón de dispositivos por km². Permite IoT, autos autónomos, telemedicina.'),

    // ── INFORMÁTICA ──────────────────────────────────────────────────────────
    _Entry(['sistema operativo', 'windows', 'mac os', 'linux', 'android', 'ios'], 'Sistemas operativos: Windows (Microsoft, escritorio), macOS (Apple, escritorio), Linux (código abierto, servidores), Android (Google, móviles), iOS (Apple, móviles). Gestionan recursos, archivos, procesos y memoria.'),
    _Entry(['base de datos', 'sql', 'bases de datos relacionales', 'nosql'], 'Bases de datos almacenan y organizan datos. SQL (relacionales): MySQL, PostgreSQL, SQL Server. NoSQL (no relacionales): MongoDB, Firebase. SQL usa tablas con filas y columnas. NoSQL usa documentos, grafos o clave-valor.'),
    _Entry(['ciberseguridad prevención', 'protegerse de hackers', 'contraseña segura'], 'Para protegerte: usa contraseñas únicas de 12+ caracteres con mayúsculas, minúsculas, números y símbolos. Activa autenticación de dos factores (2FA). No hagas clic en enlaces sospechosos. Mantén software actualizado. Usa VPN en redes públicas.'),
  ];

}

class _Entry {
  final List<String> keywords;
  final String response;
  const _Entry(this.keywords, this.response);
}
