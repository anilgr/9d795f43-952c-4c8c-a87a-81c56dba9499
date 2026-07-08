const d = new Date();
const y = d.getFullYear();
const m = String(d.getMonth() + 1).padStart(2, '0');
const day = String(d.getDate()).padStart(2, '0');
const dateStr = `${y}/${m}/${day}`;

const url = `https://anilgr.github.io/a37a5b74-fd5e-49e9-b07e-7f4a53ba239b/api/padaku/${dateStr}.json`;
const response = http.request(url, { method: 'GET' });

const res = JSON.parse(response.body);
const solution = (res.solution || "").trim();

const diacriticMap = {
  'ಾ': 'ಆ', 'ಿ': 'ಇ', 'ೀ': 'ಈ', 'ು': 'ಉ', 'ೂ': 'ಊ',
  'ೃ': 'ಋ', 'ೆ': 'ಎ', 'ೇ': 'ಏ', 'ೈ': 'ಐ', 'ೊ': 'ಒ',
  'ೋ': 'ಓ', 'ೌ': 'ಔ', 'ಂ': 'ಂ', 'ಃ': 'ಃ', '್': '್'
};

const shiftChars = new Set([
  'ಠ', 'ಢ', 'ಏ', 'ಋ', 'ಥ', 'ಐ', 'ಊ', 'ಈ', 'ಓ', 'ಫ',
  'ಆ', 'ಶ', 'ಧ', 'ಘ', 'ಃ', 'ಝ', 'ಖ', 'ಳ', 'ಙ', 'ಷ',
  'ಛ', 'ಔ', 'ಭ', 'ಣ', 'ಂ'
]);

const keyTaps = [];
for (let i = 0; i < solution.length; i++) {
  const ch = solution[i];
  if (ch && ch.trim() !== '') {
    keyTaps.push(diacriticMap[ch] || ch);
  }
}

function setOut(k, v) {
  if (output.put) { output.put(k, v); }
  output[k] = v;
}

// Pre-initialize char1 to char12 with a valid dummy key to prevent Maestro pre-evaluation crashes
for (let idx = 1; idx <= 12; idx++) {
  setOut("char" + idx, "Enter");
  setOut("shift" + idx, "false");
}

keyTaps.forEach((char, idx) => {
  setOut("char" + (idx + 1), char);
  setOut("shift" + (idx + 1), shiftChars.has(char) ? "true" : "false");
});

setOut("totalTaps", String(keyTaps.length));
setOut("counter", "1");
setOut("loopActive", keyTaps.length > 0 ? "true" : "false");

console.log("[Maestro JS Engine] Fetched Solution (" + dateStr + "): \"" + solution + "\"");
console.log("[Maestro JS Engine] Decomposed Key Taps (" + keyTaps.length + "): " + JSON.stringify(keyTaps));
