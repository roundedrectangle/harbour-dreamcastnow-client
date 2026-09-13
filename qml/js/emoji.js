/*! Copyright Twitter Inc. and other contributors. Licensed under MIT */
/*
  https://github.com/twitter/twemoji/blob/gh-pages/LICENSE

  Stripped down for usage in Dreamfish Now (originally, Fernschreiber).
*/
.pragma library

// this doesn't work from WorkerScript
//var basePath = Qt.resolvedUrl("./emoji/")

function toCodePoint(unicodeSurrogates) {
  var
    r = [],
    c = 0,
    p = 0,
    i = 0;
  while (i < unicodeSurrogates.length) {
    c = unicodeSurrogates.charCodeAt(i++);
    if (p) {
      r.push((0x10000 + ((p - 0xD800) << 10) + (c - 0xDC00)).toString(16));
      p = 0;
    } else if (0xD800 <= c && c <= 0xDBFF) {
      p = c;
    } else {
      r.push(c.toString(16));
    }
  }
  return r.join('-');
}

function getEmojiPath(str) {
  return toCodePoint(str) + '.svg'
}

function getFlagEmojiPath(code) {
  // code is the two-letter country code
  if (!code || code.length !== 2) return ''
  code = code.toUpperCase()

  var cp1 = (127397 + code.charCodeAt(0)).toString(16)
  var cp2 = (127397 + code.charCodeAt(1)).toString(16)
  return cp1 + '-' + cp2 + '.svg'
}
