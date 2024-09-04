import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:image_draw/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:signature/signature.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // initialize the signature controller
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 1,
    penColor: Colors.red,
    exportBackgroundColor: Colors.transparent,
    exportPenColor: Colors.black,
    onDrawStart: () => log('onDrawStart called!'),
    onDrawEnd: () => log('onDrawEnd called!'),
  );

  @override
  void initState() {
    super.initState();
    _controller
      ..addListener(() => log('Value changed'))
      ..onDrawEnd = () => setState(
            () {
              // setState for build to update value of "empty label" in gui
            },
          );
  }

  @override
  void dispose() {
    // IMPORTANT to dispose of the controller
    _controller.dispose();
    super.dispose();
  }

  Future<void> exportToPDF(BuildContext context) async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          key: Key('snackbarPDF'),
          content: Text('No content'),
        ),
      );
      return;
    }

    final Uint8List? pngData =
        await _controller.toPngBytes(height: 1000, width: 1000);
    if (pngData == null) {
      return;
    }

    final pdf = pw.Document();
    final image = pw.MemoryImage(pngData);

    pdf.addPage(pw.Page(build: (pw.Context context) {
      return pw.Center(child: pw.Image(image));
    }));

    try {
      final output = await getExternalStorageDirectory();
      final file = File('${output?.path}/example.pdf');
      await file.writeAsBytes(await pdf.save());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved to $output'),
        ),
      );
    } catch (e) {
      print('Error saving PDF file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save PDF'),
        ),
      );
    }
  }

  Future<void> exportImage(BuildContext context) async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          key: Key('snackbarPNG'),
          content: Text('No content'),
        ),
      );
      return;
    }

    final Uint8List? data =
        await _controller.toPngBytes(height: 1000, width: 1000);
    if (data == null) {
      return;
    }

    if (!mounted) return;

    await push(
      context,
      Scaffold(
        appBar: AppBar(
          title: const Text('PNG Image'),
        ),
        body: Center(
          child: Container(
            color: Colors.grey[300],
            child: Image.memory(data),
          ),
        ),
      ),
    );
  }

  Future<void> exportSVG(BuildContext context) async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          key: Key('snackbarSVG'),
          content: Text('No content'),
        ),
      );
      return;
    }

    final SvgPicture data = _controller.toSVG()!;

    if (!mounted) return;

    await push(
      context,
      Scaffold(
        appBar: AppBar(
          title: const Text('SVG Image'),
        ),
        body: Center(
          child: Container(
            color: Colors.grey[300],
            child: data,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Desenhar sobre Imagem'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/body.jpg',
              fit: BoxFit
                  .contain, // Use BoxFit.cover para garantir que a imagem cubra todo o espaço
            ),
          ),
          Positioned.fill(
            child: Signature(
              key: const Key('signature'),
              controller: _controller,
              backgroundColor: Colors
                  .transparent, // Fundo transparente para sobrepor a imagem
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          decoration: const BoxDecoration(color: Colors.black),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              //SHOW EXPORTED IMAGE IN NEW ROUTE
              IconButton(
                key: const Key('exportPNG'),
                icon: const Icon(Icons.image),
                color: Colors.blue,
                onPressed: () => exportImage(context),
                tooltip: 'Export Image',
              ),
              IconButton(
                key: const Key('exportSVG'),
                icon: const Icon(Icons.share),
                color: Colors.blue,
                onPressed: () => exportSVG(context),
                tooltip: 'Export SVG',
              ),
              IconButton(
                icon: const Icon(Icons.undo),
                color: Colors.blue,
                onPressed: () {
                  setState(() => _controller.undo());
                },
                tooltip: 'Undo',
              ),
              IconButton(
                icon: const Icon(Icons.redo),
                color: Colors.blue,
                onPressed: () {
                  setState(() => _controller.redo());
                },
                tooltip: 'Redo',
              ),
              //CLEAR CANVAS
              IconButton(
                key: const Key('clear'),
                icon: const Icon(Icons.clear),
                color: Colors.blue,
                onPressed: () {
                  setState(() => _controller.clear());
                },
                tooltip: 'Clear',
              ),
              // STOP Edit
              IconButton(
                key: const Key('stop'),
                icon: Icon(
                  _controller.disabled ? Icons.pause : Icons.play_arrow,
                ),
                color: Colors.blue,
                onPressed: () {
                  setState(() => _controller.disabled = !_controller.disabled);
                },
                tooltip: _controller.disabled ? 'Pause' : 'Play',
              ),
              IconButton(
                key: const Key('exportPDF'),
                icon: const Icon(Icons.picture_as_pdf),
                color: Colors.blue,
                onPressed: () => exportToPDF(context),
                tooltip: 'Export PDF',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
