import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:supabase/supabase.dart';

late HttpServer server;
final _router = Router()
  ..get('/v1/health', healthCheck)
  ..post('/v1/board/<boardId>/task/reorder', reorderTasks);

// Initialize Supabase client
final supabase = SupabaseClient(
  'YOUR_SUPABASE_URL',
  'YOUR_SUPABASE_ANON_KEY',
  realtimeClientOptions: const RealtimeClientOptions(
    eventsPerSecond: 10,
  ),
);

Future<void> main() async {
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsMiddleware())
      .addHandler(_router.call);

  server = await serve(handler, InternetAddress.anyIPv4, 8080);

  print('Serving at http://${server.address.host}:${server.port}');
}

Middleware corsMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok(
          '',
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods':
                'GET, POST, PUT, PATCH, DELETE, OPTIONS',
            'Access-Control-Allow-Headers':
                'Origin, Content-Type, Accept, Authorization',
          },
        );
      }

      final Response response = await innerHandler(request);
      return response.change(
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods':
              'GET, POST, PUT, PATCH, DELETE, OPTIONS',
          'Access-Control-Allow-Headers':
              'Origin, Content-Type, Accept, Authorization',
        },
        context: response.context,
      );
    };
  };
}

Future<Response> healthCheck(Request req) async {
  return Response.ok(
    jsonEncode({'status': 'ok'}),
    headers: {'Cache-Control': 'no-store', 'Content-Type': 'application/json'},
  );
}

Future<Response> reorderTasks(Request request, String boardId) async {
  try {
    final payload = await request.readAsString();
    final data = jsonDecode(payload);
    
    final tasks = List<Map<String, dynamic>>.from(data['tasks']);
    
    // Process task positions
    for (final task in tasks) {
      await supabase
          .from('tasks')
          .update({
            'position': task['position'],
            'status': task['status'],
            'category': task['category'],
          })
          .eq('id', task['id']);
    }
    
    return Response.ok(
      jsonEncode({'success': true}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response(
      500,
      body: jsonEncode({'error': e.toString()}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}