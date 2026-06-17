import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../core/constants/api_keys.dart';

class GeminiService {
  late final GenerativeModel _model;
  late final ChatSession _chat;

  GeminiService({String? nombreRestaurante, required String menuContexto}) {
    String rolContexto = nombreRestaurante != null
        ? 'Eres SofIA, la mesera virtual exclusiva del restaurante "$nombreRestaurante".'
        : 'Eres SofIA, la asistente virtual global de la aplicación MeserApp. Conoces TODOS los restaurantes disponibles y sus menús.';

    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: geminiApiKey,
      systemInstruction: Content.system('''
        $rolContexto
        
        Aquí tienes la información EXACTA y actualizada de los restaurantes y sus cartas:
        $menuContexto

        REGLAS ESTRICTAS:
        1. NO inventes locales, platos, precios ni ingredientes que no estén en la información de arriba.
        2. Si te preguntan por el más barato o dónde venden un producto, busca en la lista de arriba y responde con precisión.
        3. Tienes libertad para responder preguntas sobre la comida (ej. ¿qué es más sano?, estimaciones de calorías, qué contiene alergenos) BASÁNDOTE EN TU CONOCIMIENTO GENERAL sobre esos platos, SIEMPRE Y CUANDO los platos existan en los menús de arriba.
        4. EXCEPCIÓN: Si un plato tiene un nombre único, inventado o muy especial del cual no se pueda deducir qué es (ej. "El Volcán del Chef", "Promo MeserApp"), indica que no puedes estimar su información nutricional porque es una receta secreta o exclusiva.
        5. Responde siempre en español, de forma muy amigable, útil y concisa.
      '''),
    );
    _chat = _model.startChat();
  }

  Future<String> sendMessage(String userMessage) async {
    try {
      final response = await _chat.sendMessage(Content.text(userMessage));
      return response.text ?? 'No pude generar una respuesta.';
    } catch (e) {
      return 'Error al conectar con el asistente. Verifica tu conexión.';
    }
  }
}