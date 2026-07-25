import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_aetheris/services/aetheris_brain.dart';
import 'package:nexa_aetheris/services/knowledge_domain_service.dart';

void main() {
  group('Service domains routing', () {
    test('servicios de salud → healthServices', () {
      expect(
        KnowledgeDomainService.detectDomain(
            '¿dónde queda una clínica privada confiable?'),
        KnowledgeDomain.healthServices,
      );
    });

    test('consultoría empresarial → corporateServices', () {
      expect(
        KnowledgeDomainService.detectDomain(
            '¿qué consultora financiera me recomiendas?'),
        KnowledgeDomain.corporateServices,
      );
    });

    test('banca y seguros → financialServices', () {
      expect(
        KnowledgeDomainService.detectDomain(
            '¿qué tarjeta de crédito tiene mejor seguro de auto?'),
        KnowledgeDomain.financialServices,
      );
    });

    test('educación y universidades → educationServices', () {
      expect(
        KnowledgeDomainService.detectDomain(
            'mejores universidades con cursos en línea'),
        KnowledgeDomain.educationServices,
      );
    });

    test('proveedor de internet → telecomServices', () {
      expect(
        KnowledgeDomainService.detectDomain(
            'mejor ISP con fibra óptica en panamá'),
        KnowledgeDomain.telecomServices,
      );
    });

    test('logística y mensajería → logisticsServices', () {
      expect(
        KnowledgeDomainService.detectDomain(
            'servicio de mudanza nacional e internacional'),
        KnowledgeDomain.logisticsServices,
      );
    });

    test('turismo y hoteles → tourismServices', () {
      expect(
        KnowledgeDomainService.detectDomain(
            'agencia de viajes con paquetes turísticos baratos'),
        KnowledgeDomain.tourismServices,
      );
    });

    test('comercio y reparación → retailrepairServices', () {
      expect(
        KnowledgeDomainService.detectDomain(
            'taller de reparación de lavadora y refrigerador'),
        KnowledgeDomain.retailrepairServices,
      );
    });

    test('inmuebles y construcción → realestateServices', () {
      expect(
        KnowledgeDomainService.detectDomain(
            'alquiler y compraventa de propiedad'),
        KnowledgeDomain.realestateServices,
      );
    });

    test('servicios del hogar → personalServices', () {
      expect(
        KnowledgeDomainService.detectDomain(
            'necesito servicio de limpieza doméstica mensual'),
        KnowledgeDomain.personalServices,
      );
    });

    test('servicios públicos → publicServices', () {
      expect(
        KnowledgeDomainService.detectDomain(
            'trámite de cédula y pasaporte'),
        KnowledgeDomain.publicServices,
      );
    });

    test('hostelería y eventos → hospitalityBusiness', () {
      expect(
        KnowledgeDomainService.detectDomain(
            'catering para evento corporativo y salón de fiestas'),
        KnowledgeDomain.hospitalityBusiness,
      );
    });

    test('medicina ancestral → ancestralMedicine', () {
      expect(
        KnowledgeDomainService.detectDomain(
            '¿cómo se prepara un té de fitoterapia para la ansiedad?'),
        KnowledgeDomain.ancestralMedicine,
      );
    });

    test('música y cantantes → musicAndArts', () {
      expect(
        KnowledgeDomainService.detectDomain(
            'cuéntame sobre el último álbum de ese cantante pop'),
        KnowledgeDomain.musicAndArts,
      );
      expect(
        KnowledgeDomainService.detectDomain(
            'qué bandas de rock latino me recomiendas'),
        KnowledgeDomain.musicAndArts,
      );
    });
  });

  group('System prompts for new domains', () {
    test('prompt mention appropriate expertise', () {
      final p1 = KnowledgeDomainService.systemPromptForDomain(
          KnowledgeDomain.financialServices);
      expect(p1.toLowerCase().contains('banca'), isTrue);

      final p2 = KnowledgeDomainService.systemPromptForDomain(
          KnowledgeDomain.musicAndArts);
      expect(p2.toLowerCase().contains('música'), isTrue);

      final p3 = KnowledgeDomainService.systemPromptForDomain(
          KnowledgeDomain.ancestralMedicine);
      expect(p3.toLowerCase().contains('fitoterapia'), isTrue);
    });
  });

  group('Language detection', () {
    test('detecta español', () {
      final lang = AetherisBrain.detectUserLanguage(
          'Necesito ayuda con mi declaración de impuestos');
      expect(lang, 'español');
    });

    test('detecta inglés', () {
      final lang = AetherisBrain.detectUserLanguage(
          'Can you help me with my tax declaration and what should I know');
      expect(lang, 'inglés');
    });

    test('detecta portugués (palabra acentos)', () {
      final lang = AetherisBrain.detectUserLanguage(
          'Como você está com os seus negócios financeiros');
      expect(lang, 'portugués');
    });

    test('detecta francés', () {
      final lang = AetherisBrain.detectUserLanguage(
          'Comment ça va avec votre comptabilité fiscale des impôts');
      expect(lang, 'francés');
    });

    test('texto vacío → español (default)', () {
      final lang = AetherisBrain.detectUserLanguage('');
      expect(lang, 'español');
    });

    test('texto muy corto → español (no hay confianza)', () {
      final lang = AetherisBrain.detectUserLanguage('hola');
      expect(lang, 'español');
    });
  });

  group('Comprehensive routing (multi-facético compatible)', () {
    test('politica + música pueden combinarse en una consulta', () {
      // Notamos que el motor principal decide; verificamos que ambas
      // palabras clave activan el dominio correcto cuando se prueban
      // por separado.
      final domainPolitical =
          KnowledgeDomainService.detectDomain('elecciones en mi país');
      expect(domainPolitical, KnowledgeDomain.politics);

      final domainMusical =
          KnowledgeDomainService.detectDomain('cantante de música');
      expect(domainMusical, KnowledgeDomain.musicAndArts);
    });

    test('economía y gastronomía siguen funcionando', () {
      final domainBiz =
          KnowledgeDomainService.detectDomain('consulta con mi contador');
      // business o financialServices según palabra clave
      expect(
        domainBiz == KnowledgeDomain.business ||
            domainBiz == KnowledgeDomain.financialServices,
        isTrue,
      );

      final domainFood =
          KnowledgeDomainService.detectDomain('receta de arroz con pollo');
      expect(domainFood, KnowledgeDomain.cooking);
    });

    test('referencia a medicamentos se enruta a medicine', () {
      final d = KnowledgeDomainService.detectDomain(
          '¿qué dosis de paracetamol es segura para adultos?');
      expect(d, KnowledgeDomain.medicine);
    });
  });
}
