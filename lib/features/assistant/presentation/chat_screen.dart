import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../estado/app_state.dart';
import '../data/gemini_service.dart';
import '../data/chat_repository.dart';
import '../domain/chat_message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _repo = ChatRepository();
  final _uuid = const Uuid();
  
  GeminiService? _gemini;
  List<ChatMessage> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _inicializarChat();
  }

  Future<void> _inicializarChat() async {
    final history = await _repo.loadHistory();
    setState(() => _messages = history);
    _scrollToBottom();

    final restId = appState.restauranteId;
    String contextoFinal = '';
    String? nombreRest;

    try {
      if (restId != null) {
        final docRest = await FirebaseFirestore.instance.collection('restaurantes').doc(restId).get();
        nombreRest = docRest.data()?['nombre'] ?? 'nuestro local';

        final snapshotMenu = await FirebaseFirestore.instance.collection('restaurantes').doc(restId).collection('platos').get();
        String menuString = '';
        for (var doc in snapshotMenu.docs) {
          final plato = doc.data();
          final agotado = plato['agotado'] == true ? ' [AGOTADO]' : '';
          menuString += "- ${plato['nombre']}: \$${plato['precio']}. ${plato['descripcion']} (Espera: ${plato['tiempo']} min)$agotado\n";
        }
        contextoFinal = "Menú de $nombreRest:\n${menuString.isEmpty ? 'Vacío' : menuString}";
      } else {
        final snapshotRestaurantes = await FirebaseFirestore.instance.collection('restaurantes').get();
        
        for (var docRest in snapshotRestaurantes.docs) {
          final restData = docRest.data();
          if (restData['configurado'] == true) {
            final nombreLocal = restData['nombre'] ?? 'Restaurante';
            contextoFinal += "--- Restaurante: $nombreLocal ---\n";
            
            final snapshotMenu = await FirebaseFirestore.instance.collection('restaurantes').doc(docRest.id).collection('platos').get();
            if (snapshotMenu.docs.isEmpty) {
              contextoFinal += "Menú vacío por ahora.\n\n";
            } else {
              for (var docPlato in snapshotMenu.docs) {
                final plato = docPlato.data();
                final agotado = plato['agotado'] == true ? ' [AGOTADO]' : '';
                contextoFinal += "- ${plato['nombre']}: \$${plato['precio']}. ${plato['descripcion']}$agotado\n";
              }
              contextoFinal += "\n";
            }
          }
        }
        if (contextoFinal.isEmpty) contextoFinal = "No hay restaurantes disponibles aún.";
      }
      
      _gemini = GeminiService(
        nombreRestaurante: nombreRest, 
        menuContexto: contextoFinal,
      );
      
    } catch (e) {
      debugPrint("Error cargando contexto: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading || _gemini == null) return;

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      text: text,
      isFromUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();
    await _repo.saveMessage(userMsg);

    final responseText = await _gemini!.sendMessage(text);
    
    final botMsg = ChatMessage(
      id: _uuid.v4(),
      text: responseText,
      isFromUser: false,
      timestamp: DateTime.now(),
    );

    await _repo.saveMessage(botMsg);
    setState(() {
      _messages.add(botMsg);
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: Image.asset('assets/images/sofia.png', fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'SofIA - Tu mesera virtual',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Borrar historial',
            onPressed: () async {
              await _repo.clearHistory();
              setState(() => _messages = []);
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_isLoading && _gemini != null ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          SizedBox(width: 12),
                          SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('SofIA está pensando...'),
                        ],
                      ),
                    ),
                  );
                }
                final msg = _messages[index];
                return _MessageBubble(message: msg);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: _gemini != null, 
                    decoration: InputDecoration(
                      hintText: _gemini == null 
                        ? 'Cargando carta del restaurante...' 
                        : '¿Preguntas sobre el menú?',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.send),
                  onPressed: _isLoading || _gemini == null ? null : _sendMessage,
                  style: IconButton.styleFrom(backgroundColor: Colors.indigo),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isFromUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? Colors.indigo : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}