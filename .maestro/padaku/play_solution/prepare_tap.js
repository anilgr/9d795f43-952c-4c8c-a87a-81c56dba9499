const idx = parseInt((output.get ? output.get("counter") : null) || output.counter || "1", 10);
const total = parseInt((output.get ? output.get("totalTaps") : null) || output.totalTaps || "0", 10);

let charStr = "Enter";
let shiftStr = "false";
let hasChar = "false";

if (idx <= total) {
  charStr = String((output.get ? output.get("char" + idx) : null) || output["char" + idx] || "Enter").trim();
  shiftStr = String((output.get ? output.get("shift" + idx) : null) || output["shift" + idx] || "false").trim();
  if (charStr !== "" && charStr !== "undefined" && charStr !== "Enter") {
    hasChar = "true";
  }
}

function setOut(k, v) {
  if (output.put) { output.put(k, v); }
  output[k] = v;
}

setOut("currentChar", charStr);
setOut("currentShift", shiftStr);
setOut("hasChar", hasChar);
setOut("counter", String(idx + 1));

console.log("[prepare_tap.js] Step #" + idx + "/12 (totalTaps=" + total + ") -> char='" + charStr + "', shift=" + shiftStr + ", hasChar=" + hasChar);
