import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_aetheris/services/knowledge_domain_service.dart';

void main() {
  group('Apicultura routing', () {
    test('apicultura routes to agronomy domain', () {
      final domain = KnowledgeDomainService.detectDomain('que es apicultura');
      expect(domain, KnowledgeDomain.agronomy);
    });

    test('miel keyword routes to agronomy domain', () {
      final domain = KnowledgeDomainService.detectDomain('como se produce la miel');
      expect(domain, KnowledgeDomain.agronomy);
    });

    test('abejas keyword routes to agronomy domain', () {
      final domain = KnowledgeDomainService.detectDomain('tipos de abejas');
      expect(domain, KnowledgeDomain.agronomy);
    });

    test('colmena keyword routes to agronomy domain', () {
      final domain = KnowledgeDomainService.detectDomain('tipos de colmena');
      expect(domain, KnowledgeDomain.agronomy);
    });

    test('polinizacion keyword routes to agronomy domain', () {
      final domain = KnowledgeDomainService.detectDomain('polinizacion de cultivos');
      expect(domain, KnowledgeDomain.agronomy);
    });

    test('Agronomy prompt mentions apicultura', () {
      final prompt = KnowledgeDomainService.systemPromptForDomain(KnowledgeDomain.agronomy);
      expect(prompt.toLowerCase().contains('apicult'), isTrue,
          reason: 'Agronomy prompt should mention apicultura');
    });
  });
}
