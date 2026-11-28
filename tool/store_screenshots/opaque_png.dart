import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Encodes an opaque [ui.Image] (or a horizontal slice `[cropX, cropX + cropWidth)`)
/// as a 24-bit RGB PNG (`colorType = 2`, no alpha channel) so Google Play Console
/// never rejects it for transparency.
Future<Uint8List> encodeOpaqueRgbPng(
  ui.Image image, {
  int cropX = 0,
  int? cropWidth,
}) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (byteData == null) {
    throw StateError('Failed to extract raw RGBA bytes from rendered image.');
  }

  final srcWidth = image.width;
  final height = image.height;
  final outWidth = cropWidth ?? srcWidth;
  if (cropX < 0 || outWidth <= 0 || cropX + outWidth > srcWidth) {
    throw RangeError(
      'Invalid horizontal crop [$cropX, ${cropX + outWidth}) for image width $srcWidth.',
    );
  }
  final rgba = byteData.buffer.asUint8List();

  // Each PNG scanline starts with filter type byte `0` (None) followed by RGB.
  final rowStride = 1 + outWidth * 3;
  final rawScanlines = Uint8List(height * rowStride);
  for (var y = 0; y < height; y++) {
    final dstRow = y * rowStride;
    rawScanlines[dstRow] = 0;
    final srcRow = y * srcWidth * 4;
    for (var x = 0; x < outWidth; x++) {
      final src = srcRow + (cropX + x) * 4;
      final dst = dstRow + 1 + x * 3;
      rawScanlines[dst] = rgba[src];
      rawScanlines[dst + 1] = rgba[src + 1];
      rawScanlines[dst + 2] = rgba[src + 2];
    }
  }

  final compressed = ZLibCodec(level: 6).encode(rawScanlines);

  final out = BytesBuilder(copy: false)
    ..add(const [137, 80, 78, 71, 13, 10, 26, 10]); // PNG signature

  // IHDR: width, height, bitDepth=8, colorType=2 (RGB), compression=0, filter=0, interlace=0.
  final ihdr = ByteData(13)
    ..setUint32(0, outWidth)
    ..setUint32(4, height)
    ..setUint8(8, 8)
    ..setUint8(9, 2)
    ..setUint8(10, 0)
    ..setUint8(11, 0)
    ..setUint8(12, 0);
  _writeChunk(out, 'IHDR', ihdr.buffer.asUint8List());
  _writeChunk(out, 'IDAT', compressed);
  _writeChunk(out, 'IEND', const []);

  return out.takeBytes();
}

/// Writes an opaque 24-bit RGB PNG encoded by [encodeOpaqueRgbPng] to [destination].
Future<void> writeOpaqueRgbPng(
  File destination,
  ui.Image image, {
  int cropX = 0,
  int? cropWidth,
}) async {
  final bytes = await encodeOpaqueRgbPng(
    image,
    cropX: cropX,
    cropWidth: cropWidth,
  );
  await destination.parent.create(recursive: true);
  await destination.writeAsBytes(bytes, flush: true);
}

void _writeChunk(BytesBuilder out, String type, List<int> data) {
  final lengthBytes = ByteData(4)..setUint32(0, data.length);
  final typeBytes = type.codeUnits;
  final crc = _crc32(typeBytes, data);
  final crcBytes = ByteData(4)..setUint32(0, crc);

  out
    ..add(lengthBytes.buffer.asUint8List())
    ..add(typeBytes)
    ..add(data)
    ..add(crcBytes.buffer.asUint8List());
}

final List<int> _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? (0xedb88320 ^ (c >>> 1)) : (c >>> 1);
  }
  return c;
});

int _crc32(List<int> typeBytes, List<int> data) {
  var c = 0xffffffff;
  for (final b in typeBytes) {
    c = _crcTable[(c ^ b) & 0xff] ^ (c >>> 8);
  }
  for (final b in data) {
    c = _crcTable[(c ^ b) & 0xff] ^ (c >>> 8);
  }
  return c ^ 0xffffffff;
}
