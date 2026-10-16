// Escala x4 con ESRGAN (npm i @tensorflow/tfjs @tensorflow/tfjs-backend-wasm @upscalerjs/esrgan-thick pngjs).
// Uso: node upscale.js esrgan-thick a.png b.png ... -> a_x4rgb.png; luego merge_alpha.py pega el alfa.
const fs = require('fs'), path = require('path');
const tf = require('@tensorflow/tfjs');
require('@tensorflow/tfjs-backend-wasm');
const { PNG } = require('pngjs');
const pkg = process.argv[2] || 'esrgan-thick';
async function main() {
  await tf.setBackend('wasm'); await tf.ready();
  const def = require(`@upscalerjs/${pkg}`).x4;
  if (def.setup) await def.setup(tf);
  const dir = path.join(__dirname, 'node_modules/@upscalerjs', pkg, 'models/x4');
  const mj = JSON.parse(fs.readFileSync(path.join(dir, 'model.json')));
  const specs = [], bufs = [];
  for (const g of mj.weightsManifest) { specs.push(...g.weights); for (const p of g.paths) bufs.push(fs.readFileSync(path.join(dir, p))); }
  const all = Buffer.concat(bufs);
  const model = await tf.loadLayersModel({ load: async () => ({ modelTopology: mj.modelTopology, weightSpecs: specs, weightData: all.buffer.slice(all.byteOffset, all.byteOffset + all.byteLength) }) });
  const files = process.argv.slice(3);
  for (const f of files) {
    const png = PNG.sync.read(fs.readFileSync(f));
    const { width: w, height: h, data } = png;
    const rgb = new Float32Array(w * h * 3);
    for (let i = 0; i < w * h; i++) { const a = data[i*4+3] / 255; for (let c = 0; c < 3; c++) rgb[i*3+c] = data[i*4+c] * (a > 0.02 ? 1 : 0) + (a > 0.02 ? 0 : 0); }
    const t0 = Date.now();
    const out = tf.tidy(() => model.predict(tf.tensor4d(rgb, [1, h, w, 3])).clipByValue(0, 255).round().toInt());
    const arr = await out.data(); out.dispose();
    const W = w * 4, H = h * 4, o = new PNG({ width: W, height: H });
    for (let i = 0; i < W * H; i++) { o.data[i*4] = arr[i*3]; o.data[i*4+1] = arr[i*3+1]; o.data[i*4+2] = arr[i*3+2]; o.data[i*4+3] = 255; }
    const dst = f.replace(/\.png$/, '_x4rgb.png');
    fs.writeFileSync(dst, PNG.sync.write(o));
    console.log(dst, W, H, (Date.now() - t0) + 'ms');
  }
}
main().catch(e => { console.error(e); process.exit(1); });
