/* stage3d.js — WebGL playfield for Rebound Tycoon.
 *
 * Drop-in replacement for REBOUND_STAGE: same draw(canvas, state, opts) plus the four fx
 * calls, so game.js needs no changes. The 2D renderer stays as the fallback for machines
 * with no WebGL, and for `?flat=1`.
 *
 * The table is the same normalised space the kernel simulates in — x,y in [0,1], y down —
 * mapped to a tilted 3D slab: X = (x-.5)*W, Z = (y-.5)*D, Y = height above the playfield.
 * Nothing here touches physics; it only reads state.
 */
import * as THREE from "three";
import { EffectComposer } from "../vendor/three/addons/postprocessing/EffectComposer.js";
import { RenderPass } from "../vendor/three/addons/postprocessing/RenderPass.js";
import { UnrealBloomPass } from "../vendor/three/addons/postprocessing/UnrealBloomPass.js";
import { OutputPass } from "../vendor/three/addons/postprocessing/OutputPass.js";

const W = 10, D = 13;                       // playfield size in world units
const X = (x) => (x - 0.5) * W;
const Z = (y) => (y - 0.5) * D;
const R = (r) => r * W;                     // normalised radius -> world

const CYAN = 0x1ec8c0, AMBER = 0xe8c36a, HOT = 0xf4d78a;

let renderer, scene, camera, composer, bloom, clock;
let ballMesh, flipL, flipR, saucerRing, plungerMesh, hintSprite;
const bumperMeshes = [], targetMeshes = [], skyline = [];
const particles = [];
let ready = false, failed = false, lastW = 0, lastH = 0;

function mat(color, opts = {}) {
  return new THREE.MeshStandardMaterial({
    color, metalness: opts.metalness ?? 0.85, roughness: opts.roughness ?? 0.28,
    emissive: opts.emissive ?? 0x000000, emissiveIntensity: opts.emissiveIntensity ?? 1,
  });
}

function build() {
  const K = globalThis;                      // kernel exports live on globalThis
  scene = new THREE.Scene();
  scene.background = new THREE.Color(0x05080c);
  scene.fog = new THREE.Fog(0x05080c, 26, 46);

  camera = new THREE.PerspectiveCamera(38, 1, 0.1, 100);
  camera.position.set(0, 17.5, 9.4);
  camera.lookAt(0, 0, 0.2);

  // --- lighting: one cool key, one warm rim, plus the neon fills the bloom picks up
  scene.add(new THREE.AmbientLight(0x1e3a45, 0.75));
  const key = new THREE.DirectionalLight(0xdff2ff, 3.0);
  key.position.set(-7, 16, 7);
  key.castShadow = true;
  key.shadow.mapSize.set(1024, 1024);
  key.shadow.camera.left = -9; key.shadow.camera.right = 9;
  key.shadow.camera.top = 11; key.shadow.camera.bottom = -11;
  key.shadow.bias = -0.0012;
  scene.add(key);
  const rim = new THREE.DirectionalLight(0xffc98a, 1.1);
  rim.position.set(7, 6, -8);
  scene.add(rim);
  [[-3.2, 0x1ec8c0], [3.2, 0xe8c36a]].forEach(([x, c]) => {
    const p = new THREE.PointLight(c, 26, 16, 2);
    p.position.set(x, 2.4, 0);
    scene.add(p);
  });

  // --- playfield slab
  const slab = new THREE.Mesh(
    new THREE.BoxGeometry(W + 1.6, 0.5, D + 1.2),
    mat(0x0a1a20, { metalness: 0.35, roughness: 0.62 })
  );
  slab.position.y = -0.3;
  scene.add(slab);

  const feltTex = (() => {
    const c = document.createElement("canvas"); c.width = c.height = 256;
    const g2 = c.getContext("2d");
    const rg = g2.createRadialGradient(128, 110, 10, 128, 128, 170);
    rg.addColorStop(0, "#19434f"); rg.addColorStop(0.55, "#0d2732"); rg.addColorStop(1, "#061219");
    g2.fillStyle = rg; g2.fillRect(0, 0, 256, 256);
    g2.strokeStyle = "rgba(30,200,192,.16)"; g2.lineWidth = 2;
    for (let i = 1; i < 5; i++) { g2.beginPath(); g2.arc(128, 132, i * 26, 0, Math.PI * 2); g2.stroke(); }
    return new THREE.CanvasTexture(c);
  })();
  const felt = new THREE.Mesh(
    new THREE.PlaneGeometry(W, D),
    new THREE.MeshStandardMaterial({ map: feltTex, color: 0xffffff, metalness: 0.25, roughness: 0.78 })
  );
  felt.rotation.x = -Math.PI / 2;
  felt.position.y = -0.045;
  felt.receiveShadow = true;
  scene.add(felt);

  // --- walls: each kernel segment becomes an extruded rail
  const railMat = mat(0xcfe8f0, { metalness: 1, roughness: 0.14, emissive: 0x1a5e6a, emissiveIntensity: 0.35 });
  (K.WALLS || []).forEach((w) => {
    const a = new THREE.Vector3(X(w[0]), 0, Z(w[1]));
    const b = new THREE.Vector3(X(w[2]), 0, Z(w[3]));
    const len = a.distanceTo(b);
    const rail = new THREE.Mesh(new THREE.BoxGeometry(len, 0.42, 0.11), railMat);
    rail.position.copy(a.clone().add(b).multiplyScalar(0.5));
    rail.position.y = 0.26;
    rail.rotation.y = -Math.atan2(b.z - a.z, b.x - a.x);
    rail.castShadow = true;
    scene.add(rail);
  });

  // --- bumpers: emissive caps that flare on hit
  (K.BUMPERS || []).forEach((b) => {
    const g = new THREE.Group();
    const base = new THREE.Mesh(new THREE.CylinderGeometry(R(b.r), R(b.r) * 1.08, 0.34, 28), mat(0x123840));
    base.position.y = 0.17;
    const cap = new THREE.Mesh(
      new THREE.CylinderGeometry(R(b.r) * 0.82, R(b.r) * 0.86, 0.22, 28),
      mat(CYAN, { emissive: CYAN, emissiveIntensity: 0.55, metalness: 0.5, roughness: 0.3 })
    );
    cap.position.y = 0.44;
    base.castShadow = true; cap.castShadow = true;
    g.add(base, cap);
    g.position.set(X(b.x), 0, Z(b.y));
    g.userData.cap = cap;
    scene.add(g);
    bumperMeshes.push(g);
  });

  // --- drop targets
  (K.TARGETS || []).forEach((t) => {
    const m = new THREE.Mesh(
      new THREE.BoxGeometry(R(t.w), 0.46, R(t.h) * 1.6),
      mat(AMBER, { emissive: AMBER, emissiveIntensity: 0.45 })
    );
    m.position.set(X(t.x + t.w / 2), 0.23, Z(t.y + t.h / 2));
    m.castShadow = true;
    scene.add(m);
    targetMeshes.push(m);
  });

  // --- saucer
  const S = K.SAUCER || { x: 0.46, y: 0.58, r: 0.028 };
  saucerRing = new THREE.Mesh(
    new THREE.TorusGeometry(R(S.r) * 1.25, 0.07, 12, 36),
    mat(HOT, { emissive: HOT, emissiveIntensity: 0.7 })
  );
  saucerRing.rotation.x = -Math.PI / 2;
  saucerRing.position.set(X(S.x), 0.08, Z(S.y));
  scene.add(saucerRing);

  // --- flippers
  const flipMat = mat(0xeaf6f3, { metalness: 0.9, roughness: 0.2, emissive: 0x0a4a48, emissiveIntensity: 0.5 });
  const mkFlip = (pivot) => {
    const g = new THREE.Group();
    const len = R(K.REBOUND?.FLIP_LEN ?? 0.115);
    const bat = new THREE.Mesh(new THREE.BoxGeometry(len, 0.3, 0.42), flipMat);
    bat.position.x = len / 2;
    bat.castShadow = true;
    g.add(bat);
    g.position.set(X(pivot.x), 0.22, Z(pivot.y));
    scene.add(g);
    return g;
  };
  flipL = mkFlip(K.LEFT_PIVOT || { x: 0.255, y: 0.865 });
  flipR = mkFlip(K.RIGHT_PIVOT || { x: 0.675, y: 0.865 });

  // --- ball: a real chrome sphere is most of the "expensive" look
  ballMesh = new THREE.Mesh(
    new THREE.SphereGeometry(R(K.REBOUND?.BALL_R ?? 0.018), 32, 24),
    new THREE.MeshStandardMaterial({ color: 0xdff6ff, metalness: 1, roughness: 0.08 })
  );
  ballMesh.castShadow = true;
  scene.add(ballMesh);

  // --- plunger
  plungerMesh = new THREE.Mesh(
    new THREE.CylinderGeometry(0.16, 0.16, 1.1, 16),
    mat(CYAN, { emissive: CYAN, emissiveIntensity: 0.6 })
  );
  plungerMesh.position.set(X(0.915), 0.3, Z(0.88));
  scene.add(plungerMesh);

  clock = new THREE.Clock();
}

function ensure(canvas) {
  if (ready || failed) return ready;
  try {
    renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: false, powerPreference: "high-performance" });
    renderer.setPixelRatio(Math.min(devicePixelRatio || 1, 2));
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    renderer.toneMapping = THREE.ACESFilmicToneMapping;
    renderer.toneMappingExposure = 0.95;
    build();
    composer = new EffectComposer(renderer);
    composer.addPass(new RenderPass(scene, camera));
    bloom = new UnrealBloomPass(new THREE.Vector2(1, 1), 0.34, 0.42, 0.62);
    composer.addPass(bloom);
    composer.addPass(new OutputPass());
    ready = true;
  } catch (e) {
    failed = true;                      // fall back to the 2D renderer, never a black screen
  }
  return ready;
}

function resize(canvas) {
  const w = canvas.clientWidth || 600, h = canvas.clientHeight || 420;
  if (w === lastW && h === lastH) return;
  lastW = w; lastH = h;
  renderer.setSize(w, h, false);
  composer.setSize(w, h);
  bloom.setSize(w, h);
  camera.aspect = w / h;
  camera.updateProjectionMatrix();
}

// --- fx: same signatures as the 2D stage, but spawned in world space ------------------
function addParticle(nx, ny, color, kind) {
  particles.push({
    x: X(nx), y: 0.5 + Math.random() * 0.4, z: Z(ny),
    vx: (Math.random() - 0.5) * 4, vy: 2 + Math.random() * 3, vz: (Math.random() - 0.5) * 4,
    age: 0, life: kind === "coin" ? 0.75 : 0.4, color, kind,
  });
}
let sparkGroup = null;
function drainParticles(dt) {
  if (!sparkGroup) { sparkGroup = new THREE.Group(); scene.add(sparkGroup); }
  for (let i = particles.length - 1; i >= 0; i--) {
    const p = particles[i];
    p.age += dt;
    if (p.age >= p.life) {
      if (p.mesh) { sparkGroup.remove(p.mesh); p.mesh.geometry.dispose(); }
      particles.splice(i, 1);
      continue;
    }
    if (!p.mesh) {
      const geo = p.kind === "coin"
        ? new THREE.CylinderGeometry(0.16, 0.16, 0.05, 12)
        : new THREE.SphereGeometry(0.07, 8, 6);
      p.mesh = new THREE.Mesh(geo, new THREE.MeshStandardMaterial({
        color: p.color, emissive: p.color, emissiveIntensity: 1.4, metalness: 0.7, roughness: 0.3,
      }));
      sparkGroup.add(p.mesh);
    }
    p.vy -= 9 * dt;
    p.x += p.vx * dt; p.y += p.vy * dt; p.z += p.vz * dt;
    p.mesh.position.set(p.x, Math.max(0.05, p.y), p.z);
    p.mesh.rotation.x += dt * 6;
    p.mesh.material.opacity = 1 - p.age / p.life;
  }
}

function draw(canvas, state, opts) {
  if (!ensure(canvas)) return false;
  resize(canvas);
  const dt = Math.min(opts.dt || 0.016, 0.05);
  const K = globalThis;

  if (state.ball) {
    ballMesh.visible = true;
    ballMesh.position.set(X(state.ball.x), R(K.REBOUND?.BALL_R ?? 0.018) + 0.05, Z(state.ball.y));
  } else {
    ballMesh.visible = false;
  }

  bumperMeshes.forEach((g, i) => {
    const flash = (state.bumperFlash && state.bumperFlash[i]) || 0;
    const cap = g.userData.cap;
    cap.material.emissiveIntensity = 0.55 + flash * 7;
    cap.material.color.setHex(flash > 0 ? HOT : CYAN);
    g.scale.setScalar(1 + Math.min(flash, 0.12) * 1.2);
  });

  targetMeshes.forEach((m, i) => {
    const down = state.targetDown && state.targetDown[i];
    m.rotation.x = down ? -Math.PI / 2.4 : 0;
    m.position.y = down ? 0.06 : 0.23;
    m.material.emissiveIntensity = down ? 0.05 : 0.45;
  });

  if (flipL) flipL.rotation.y = -(state.flipL || 0);
  if (flipR) flipR.rotation.y = -(state.flipR || 0);
  if (saucerRing) saucerRing.material.emissiveIntensity = 0.7 + Math.sin(performance.now() / 320) * 0.22;
  if (plungerMesh && state.mode === "plunge") plungerMesh.position.z = Z(0.88 + (state.plunge || 0) * 0.05);

  if (!opts.reduce) drainParticles(dt); else particles.length = 0;
  composer.render();
  return true;
}

const api = {
  draw,
  spark: (x, y, color) => { for (let i = 0; i < 8; i++) addParticle(x, y, color || HOT, "spark"); },
  burstCoins: (x, y, n) => { for (let i = 0; i < (n || 6); i++) addParticle(x, y, HOT, "coin"); },
  spray: (x, y, n) => { for (let i = 0; i < (n || 8); i++) addParticle(x, y, 0x9ff6ef, "spark"); },
  floatText: () => {},                   // the DOM layer already shows the score popups
  available: () => !failed,
};
globalThis.REBOUND_STAGE_3D = api;
export default api;
