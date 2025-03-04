import 'dart:math' as math;
import 'dart:typed_data';

int pixelMatch(
  Uint8List img1,
  Uint8List img2, {
  required int width,
  required int height,
  Uint8List? output,
  num? threshold,
  bool? includeAA,
}) {
  if (img1.length != img2.length) {
    throw Exception('Image sizes do not match.');
  }
  assert(
    img1.length == width * height * 4,
    '${img1.length} != ${width * height * 4}',
  );

  includeAA ??= false;
  threshold ??= 0.1;

  // maximum acceptable square distance between two colors;
  // 35215 is the maximum possible value for the YIQ difference metric
  var maxDelta = 35215 * threshold * threshold;
  var diff = 0;

  // compare each pixel of one image against the other one
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      var pos = (y * width + x) * 4;

      // squared YUV distance between colors at this pixel position
      var delta = _colorDelta(img1, img2, pos, pos);

      // the color difference is above the threshold
      if (delta > maxDelta) {
        // check it's a real rendering difference or just anti-aliasing
        if (!includeAA &&
            (_antialiased(img1, x, y, width, height, img2) ||
                _antialiased(img2, x, y, width, height, img1))) {
          // one of the pixels is anti-aliasing; draw as yellow and do not count as difference
          if (output != null) _drawPixel(output, pos, 255, 255, 0);
        } else {
          // found substantial difference not caused by anti-aliasing; draw it as red
          if (output != null) _drawPixel(output, pos, 255, 0, 0);
          diff++;
        }
      } else if (output != null) {
        // pixels are similar; draw background as grayscale image blended with white
        var val = _grayPixel(img1, pos, 0.1);
        _drawPixel(output, pos, val.truncate(), val.truncate(), val.truncate());
      }
    }
  }

  // return the number of different pixels
  return diff;
}

// check if a pixel is likely a part of anti-aliasing;
// based on "Anti-aliased Pixel and Intensity Slope Detector" paper by V. Vysniauskas, 2009

bool _antialiased(
  Uint8List img,
  int x1,
  int y1,
  int width,
  int height,
  Uint8List img2,
) {
  var x0 = math.max(x1 - 1, 0);
  var y0 = math.max(y1 - 1, 0);
  var x2 = math.min(x1 + 1, width - 1);
  var y2 = math.min(y1 + 1, height - 1);
  var pos = (y1 * width + x1) * 4;
  var zeroes = x1 == x0 || x1 == x2 || y1 == y0 || y1 == y2 ? 1 : 0;
  num min = 0;
  num max = 0;
  var minX = 0, minY = 0, maxX = 0, maxY = 0;

  // go through 8 adjacent pixels
  for (var x = x0; x <= x2; x++) {
    for (var y = y0; y <= y2; y++) {
      if (x == x1 && y == y1) continue;

      // brightness delta between the center pixel and adjacent one
      var delta = _colorDelta(img, img, pos, (y * width + x) * 4, yOnly: true);

      // count the number of equal, darker and brighter adjacent pixels
      if (delta == 0) {
        zeroes++;
        // if found more than 2 equal siblings, it's definitely not anti-aliasing
        if (zeroes > 2) return false;

        // remember the darkest pixel
      } else if (delta < min) {
        min = delta;
        minX = x;
        minY = y;

        // remember the brightest pixel
      } else if (delta > max) {
        max = delta;
        maxX = x;
        maxY = y;
      }
    }
  }

  // if there are no both darker and brighter pixels among siblings, it's not anti-aliasing
  if (min == 0 || max == 0) return false;

  // if either the darkest or the brightest pixel has 3+ equal siblings in both images
  // (definitely not anti-aliased), this pixel is anti-aliased
  return (_hasManySiblings(img, minX, minY, width, height) &&
          _hasManySiblings(img2, minX, minY, width, height)) ||
      (_hasManySiblings(img, maxX, maxY, width, height) &&
          _hasManySiblings(img2, maxX, maxY, width, height));
}

// check if a pixel has 3+ adjacent pixels of the same color.
bool _hasManySiblings(Uint8List img, int x1, int y1, int width, int height) {
  var x0 = math.max(x1 - 1, 0);
  var y0 = math.max(y1 - 1, 0);
  var x2 = math.min(x1 + 1, width - 1);
  var y2 = math.min(y1 + 1, height - 1);
  var pos = (y1 * width + x1) * 4;
  var zeroes = x1 == x0 || x1 == x2 || y1 == y0 || y1 == y2 ? 1 : 0;

  // go through 8 adjacent pixels
  for (var x = x0; x <= x2; x++) {
    for (var y = y0; y <= y2; y++) {
      if (x == x1 && y == y1) continue;

      var pos2 = (y * width + x) * 4;
      if (img[pos] == img[pos2] &&
          img[pos + 1] == img[pos2 + 1] &&
          img[pos + 2] == img[pos2 + 2] &&
          img[pos + 3] == img[pos2 + 3]) {
        zeroes++;
      }

      if (zeroes > 2) return true;
    }
  }

  return false;
}

// calculate color difference according to the paper "Measuring perceived color difference
// using YIQ NTSC transmission color space in mobile applications" by Y. Kotsarenko and F. Ramos

num _colorDelta(Uint8List img1, Uint8List img2, int k, int m, {bool? yOnly}) {
  yOnly ??= false;
  num r1 = img1[k + 0];
  num g1 = img1[k + 1];
  num b1 = img1[k + 2];
  num a1 = img1[k + 3];

  num r2 = img2[m + 0];
  num g2 = img2[m + 1];
  num b2 = img2[m + 2];
  num a2 = img2[m + 3];

  if (a1 == a2 && r1 == r2 && g1 == g2 && b1 == b2) return 0;

  if (a1 < 255) {
    a1 /= 255;
    r1 = _blend(r1, a1);
    g1 = _blend(g1, a1);
    b1 = _blend(b1, a1);
  }

  if (a2 < 255) {
    a2 /= 255;
    r2 = _blend(r2, a2);
    g2 = _blend(g2, a2);
    b2 = _blend(b2, a2);
  }

  var y = _rgb2y(r1, g1, b1) - _rgb2y(r2, g2, b2);

  if (yOnly) return y; // brightness difference only

  var i = _rgb2i(r1, g1, b1) - _rgb2i(r2, g2, b2),
      q = _rgb2q(r1, g1, b1) - _rgb2q(r2, g2, b2);

  return 0.5053 * y * y + 0.299 * i * i + 0.1957 * q * q;
}

num _rgb2y(num r, num g, num b) {
  return r * 0.29889531 + g * 0.58662247 + b * 0.11448223;
}

num _rgb2i(num r, num g, num b) {
  return r * 0.59597799 - g * 0.27417610 - b * 0.32180189;
}

num _rgb2q(num r, num g, num b) {
  return r * 0.21147017 - g * 0.52261711 + b * 0.31114694;
}

// blend semi-transparent color with white
num _blend(num c, num a) {
  return 255 + (c - 255) * a;
}

void _drawPixel(Uint8List output, int pos, int r, int g, int b) {
  output[pos + 0] = r;
  output[pos + 1] = g;
  output[pos + 2] = b;
  output[pos + 3] = 255;
}

num _grayPixel(Uint8List img, int i, num alpha) {
  var r = img[i + 0];
  var g = img[i + 1];
  var b = img[i + 2];
  return _blend(_rgb2y(r, g, b), alpha * img[i + 3] / 255);
}
