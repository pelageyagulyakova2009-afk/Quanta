import * as THREE from "three";
import { EffectComposer } from "three/addons/postprocessing/EffectComposer.js";
import { RenderPass } from "three/addons/postprocessing/RenderPass.js";
import { UnrealBloomPass } from "three/addons/postprocessing/UnrealBloomPass.js";
import { OrbitControls } from "three/addons/controls/OrbitControls.js";

const RU = ["Водород","Гелий","Литий","Бериллий","Бор","Углерод","Азот","Кислород","Фтор","Неон","Натрий","Магний","Алюминий","Кремний","Фосфор","Сера","Хлор","Аргон","Калий","Кальций","Скандий","Титан","Ванадий","Хром","Марганец","Железо","Кобальт","Никель","Медь","Цинк","Галлий","Германий","Мышьяк","Селен","Бром","Криптон","Рубидий","Стронций","Иттрий","Цирконий","Ниобий","Молибден","Технеций","Рутений","Родий","Палладий","Серебро","Кадмий","Индий","Олово","Сурьма","Теллур","Иод","Ксенон","Цезий","Барий","Лантан","Церий","Празеодим","Неодим","Прометий","Самарий","Европий","Гадолиний","Тербий","Диспрозий","Гольмий","Эрбий","Тулий","Иттербий","Лютеций","Гафний","Тантал","Вольфрам","Рений","Осмий","Иридий","Платина","Золото","Ртуть","Таллий","Свинец","Висмут","Полоний","Астат","Радон","Франций","Радий","Актиний","Торий","Протактиний","Уран","Нептуний","Плутоний","Америций","Кюрий","Берклий","Калифорний","Эйнштейний","Фермий","Менделевий","Нобелий","Лоуренсий","Резерфордий","Дубний","Сиборгий","Борий","Хассий","Мейтнерий","Дармштадтий","Рентгений","Коперниций","Нихоний","Флеровий","Московий","Ливерморий","Теннессин","Оганесон"];
const YEARS = [1766,1868,1817,1798,1808,0,1772,1774,1886,1898,1807,1755,1825,1824,1669,0,1774,1894,1807,1808,1879,1791,1801,1797,1774,0,1735,1751,0,1746,1875,1886,1250,1817,1826,1898,1861,1790,1794,1789,1801,1778,1937,1844,1804,1802,0,1817,1863,0,0,1782,1811,1898,1860,1808,1839,1803,1885,1885,1945,1879,1901,1880,1843,1886,1878,1843,1879,1878,1907,1923,1802,1783,1925,1803,1803,1735,0,0,1861,0,1753,1898,1940,1899,1939,1898,1899,1829,1913,1789,1940,1940,1944,1944,1949,1950,1952,1952,1955,1966,1961,1964,1967,1974,1981,1984,1982,1994,1994,1996,2004,1999,2003,2000,2010,2002];
const OX = ["+1, −1","0","+1","+2","+3","+4, +2, −4","−3, +3, +5","−2","−1","0","+1","+2","+3","+4, −4","+5, +3, −3","+6, +4, −2","−1, +1, +5, +7","0","+1","+2","+3","+4","+5","+3, +6","+2, +4, +7","+2, +3","+2, +3","+2","+1, +2","+2","+3","+4, −4","+5, +3, −3","+6, +4, −2","−1, +1, +5","+2","+1","+2","+3","+4","+5","+4, +6","+4, +7","+3, +4","+3","+2, +4","+1","+2","+3","+2, +4","+3, +5, −3","+6, +4, −2","−1, +1, +5, +7","+2, +4, +6","+1","+2","+3","+3, +4","+3","+3","+3","+3","+2, +3","+3","+3","+3","+3","+3","+3","+2, +3","+3","+4","+5","+4, +6","+4, +7","+4","+3, +4","+2, +4","+1, +3","+1, +2","+1, +3","+2, +4","+3","+2, +4","−1, +1","+2","+1","+2","+3","+4","+5","+6","+5","+4","+3","+3","+3","+3","+3","+3","+3","+2","+3","+4","+5","+6","+7","+8"];
const LATTICE = "hhbhrxxmmcbhcdoooocbchhbbbbhcchodrxocbchhbbhhccchttrxocbbxcxxxrbhhhhhhchhbbhhcccrhcrs-cbbctoomxxxxc";
const LAT_NAME = { c:"ГЦК", b:"ОЦК", h:"ГПУ", d:"Алмазная", o:"Ромбическая", r:"Ромбоэдрическая", x:"Гексагональная", m:"Моноклинная", t:"Тетрагональная", s:"Простая кубическая", "-":"Неизвестна" };
function colorOf(e) {
  const c = e.category.toLowerCase();
  if (c.includes("unknown")) return "#6e7a62";
  if (e.group === 17 && e.number !== 117) return "#ff5a3c";
  if (c.includes("noble")) return "#3ec8d4";
  if (c.includes("alkaline")) return "#2fbf62";
  if (c.includes("alkali")) return "#3dcc6a";
  if (c.includes("lanthanide")) return "#34c46a";
  if (c.includes("actinide")) return "#2aad58";
  if (c.includes("post-transition")) return "#c6e04a";
  if (c.includes("transition")) return "#27b85c";
  if (c.includes("metalloid")) return "#d4e04a";
  if (c.includes("nonmetal")) return "#ffe14a";
  return "#6e7a62";
}
const CAT = { "alkali metal":"Щелочной металл","alkaline earth metal":"Щёлочноземельный металл","transition metal":"Переходный металл","post-transition metal":"Постпереходный металл","metalloid":"Полуметалл","diatomic nonmetal":"Неметалл","polyatomic nonmetal":"Неметалл","noble gas":"Благородный газ","lanthanide":"Лантаноид","actinide":"Актиноид" };
function catTitle(e) {
  if (e.group === 17 && e.number !== 117) return "Галоген";
  const k = Object.keys(CAT).find(c => e.category.toLowerCase().includes(c));
  return k ? CAT[k] : e.category;
}

function mix(hex, k) {
  const n = parseInt(hex.slice(1), 16);
  const r = (n >> 16) & 255, g = (n >> 8) & 255, b = n & 255;
  return `rgb(${Math.round(r * k)},${Math.round(g * k)},${Math.round(b * k)})`;
}
function roundRect(g, x, y, w, h, r) {
  g.beginPath();
  g.moveTo(x + r, y);
  g.arcTo(x + w, y, x + w, y + h, r);
  g.arcTo(x + w, y + h, x, y + h, r);
  g.arcTo(x, y + h, x, y, r);
  g.arcTo(x, y, x + w, y, r);
  g.closePath();
}
const FONT = 'Orbitron, "Share Tech Mono", sans-serif';
let lang = "ru";
function cardLabel(e) {
  return lang === "ru" ? RU[e.number - 1] : e.name;
}
function cardTexture(e, hex) {
  const W = 512, H = 640;
  const c = document.createElement("canvas"); c.width = W; c.height = H;
  const g = c.getContext("2d");
  g.fillStyle = "#000";
  g.fillRect(0, 0, W, H);
  roundRect(g, 18, 18, W - 36, H - 36, 48);
  g.fillStyle = mix(hex, 0.14);
  g.fill();
  g.strokeStyle = hex;
  g.lineWidth = 6;
  g.shadowColor = hex;
  g.shadowBlur = 18;
  g.stroke();
  g.fillStyle = hex;
  g.textAlign = "left";
  g.textBaseline = "alphabetic";
  g.font = `500 34px ${FONT}`;
  g.shadowBlur = 18;
  g.fillText(String(e.number), 44, 84);
  g.textAlign = "center";
  g.font = `700 150px ${FONT}`;
  g.shadowBlur = 16;
  g.fillText(e.symbol, 256, 348);
  g.font = lang === "ru" ? `600 26px Arial, sans-serif` : `500 26px ${FONT}`;
  g.shadowBlur = 16;
  const label = cardLabel(e);
  const name = (label.length > 12 ? label.slice(0, 11) + "." : label).toUpperCase();
  g.fillText(name, 256, 500);
  g.font = `400 24px ${FONT}`;
  g.shadowBlur = 10;
  g.fillText((e.atomic_mass ?? "").toString().slice(0, 7), 256, 556);
  g.shadowBlur = 0;
  const t = new THREE.CanvasTexture(c);
  t.colorSpace = THREE.SRGBColorSpace;
  t.anisotropy = renderer.capabilities.getMaxAnisotropy();
  t.minFilter = THREE.LinearMipmapLinearFilter;
  t.magFilter = THREE.LinearFilter;
  t.generateMipmaps = true;
  t.needsUpdate = true;
  return t;
}

const dummy = new THREE.Object3D();
function layout(mode, elements) {
  const n = elements.length;
  if (mode === "table") return elements.map(e => ({
    p: new THREE.Vector3((e.xpos - 9.5) * 1.05, -(e.ypos - 5.2) * 1.22 - (e.ypos >= 9 ? 0.7 : 0), 0),
    q: new THREE.Quaternion(),
  }));
  if (mode === "sphere") {
    const R = 5, golden = Math.PI * (3 - Math.sqrt(5)), out = [];
    for (let i = 0; i < n; i++) {
      const y = 1 - 2 * (i + 0.5) / n, r = Math.sqrt(Math.max(0, 1 - y * y)), phi = i * golden;
      const p = new THREE.Vector3(Math.cos(phi) * r * R, y * R, Math.sin(phi) * r * R);
      out.push({ p, q: new THREE.Quaternion(), billboard: true });
    }
    return out;
  }
  if (mode === "helix") {
    const R = 6, per = 18, out = [];
    for (let i = 0; i < n; i++) {
      const theta = i * (Math.PI * 2 / per);
      const y = (i - n / 2) * 0.09;
      const p = new THREE.Vector3(R * Math.cos(theta), y, R * Math.sin(theta));
      dummy.position.copy(p);
      dummy.lookAt(p.x * 2, y, p.z * 2);
      out.push({ p, q: dummy.quaternion.clone() });
    }
    return out;
  }
  const gap = 1.8, out = [];
  for (let i = 0; i < n; i++) {
    const x = (i % 5) - 2, y = (Math.floor(i / 5) % 5) - 2, z = Math.floor(i / 25) - 2;
    out.push({ p: new THREE.Vector3(x * gap, y * gap, z * gap), q: new THREE.Quaternion() });
  }
  return out;
}
const CAM = {
  table:  { pos: new THREE.Vector3(0, 3.2, 19.5), look: new THREE.Vector3(0, -1.2, 0) },
  sphere: { pos: new THREE.Vector3(0, 0, 13), look: new THREE.Vector3(0, 0, 0) },
  helix:  { pos: new THREE.Vector3(14, 6, 16), look: new THREE.Vector3(0, 0, 0) },
  grid:   { pos: new THREE.Vector3(9, 7, 18), look: new THREE.Vector3(0, 0, 0) },
};

const canvas = document.getElementById("view");
const renderer = new THREE.WebGLRenderer({ canvas, antialias: true });
renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
renderer.setClearColor(0x000000, 1);
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1;
const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(48, 1, 0.1, 200);
camera.position.copy(CAM.table.pos);
camera.lookAt(CAM.table.look);
const tilt = new THREE.Group();
scene.add(tilt);
const spin = new THREE.Group();
tilt.add(spin);
const dustGeo = new THREE.BufferGeometry();
const dustPos = new Float32Array(80 * 3);
for (let i = 0; i < 80; i++) {
  dustPos[i * 3] = (Math.random() - 0.5) * 40;
  dustPos[i * 3 + 1] = (Math.random() - 0.5) * 24;
  dustPos[i * 3 + 2] = (Math.random() - 0.5) * 40;
}
dustGeo.setAttribute("position", new THREE.BufferAttribute(dustPos, 3));
const dust = new THREE.Points(dustGeo, new THREE.PointsMaterial({ color: 0x335544, size: 0.04, transparent: true, opacity: 0.45, depthWrite: false }));
scene.add(dust);
const camPos = CAM.table.pos.clone();
const camLook = CAM.table.look.clone();
const lookNow = CAM.table.look.clone();

const composer = new EffectComposer(renderer);
composer.addPass(new RenderPass(scene, camera));
const bloom = new UnrealBloomPass(new THREE.Vector2(innerWidth, innerHeight), 0.55, 0.32, 0.32);
const bloomWide = new UnrealBloomPass(new THREE.Vector2(innerWidth, innerHeight), 0.18, 0.7, 0.62);
composer.addPass(bloom);
composer.addPass(bloomWide);
const controls = new OrbitControls(camera, canvas);
controls.enableDamping = true;
controls.dampingFactor = 0.08;
controls.target.copy(CAM.table.look);
let camBlend = 1;
let tiltX = 0, tiltY = 0;
function resize() {
  camera.aspect = innerWidth / innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(innerWidth, innerHeight, false);
  composer.setSize(innerWidth, innerHeight);
}
addEventListener("resize", resize); resize();

await document.fonts.ready;
const file = await fetch("elements.json").then(r => r.json());
const COMPOUNDS = await fetch("compounds.json").then(r => r.json()).catch(() => ({}));
const elements = file.elements.filter(e => e.number <= 118).sort((a, b) => a.number - b.number);
const geo = new THREE.PlaneGeometry(0.8, 1.0);
const cards = elements.map(e => {
  const hex = colorOf(e);
  const mesh = new THREE.Mesh(geo, new THREE.MeshBasicMaterial({
    map: cardTexture(e, hex),
    side: THREE.FrontSide,
    transparent: false,
    depthTest: true,
    depthWrite: true,
  }));
  const node = new THREE.Group(); node.add(mesh);
  node.userData = { e, hex, mesh, target: new THREE.Vector3(), targetQ: new THREE.Quaternion(), dim: false, partner: false };
  spin.add(node);
  return node;
});
const cardBySymbol = new Map(cards.map(c => [c.userData.e.symbol, c]));
let activeSymbol = null;
const partnerSet = new Set();
let links = null;

let mode = "table", hovered = null;
const MODES = ["table", "sphere", "helix", "grid"];
let switchAt = 0, idleAt = 0, demoOn = false, lastDemo = 0;
const ray = new THREE.Raycaster(), ndc = new THREE.Vector2(2, 2);
function apply(next, fromDemo) {
  mode = next;
  camBlend = 0;
  switchAt = performance.now();
  if (!fromDemo) { idleAt = switchAt; demoOn = false; }
  document.querySelectorAll("#bar button").forEach(b => b.classList.toggle("active", b.dataset.mode === next));
  const t = layout(next, elements);
  cards.forEach((n, i) => {
    n.userData.target.copy(t[i].p);
    n.userData.targetQ.copy(t[i].q);
    n.userData.billboard = !!t[i].billboard;
  });
  camPos.copy(CAM[next].pos);
  camLook.copy(CAM[next].look);
  if (next === "table" || next === "grid") spin.rotation.y = 0;
  if (activeSymbol) buildLinks();
}
document.querySelectorAll("#bar button").forEach(b => b.onclick = () => apply(b.dataset.mode));
apply("table");
cards.forEach(n => {
  n.position.copy(n.userData.target).add(new THREE.Vector3((Math.random() - 0.5) * 16, (Math.random() - 0.5) * 12, (Math.random() - 0.5) * 8));
  n.userData.mesh.scale.setScalar(0.2);
});
switchAt = performance.now();
idleAt = switchAt;

function poke() { idleAt = performance.now(); demoOn = false; }
function focusCard(n) {
  const p = n.getWorldPosition(new THREE.Vector3());
  const dir = camera.position.clone().sub(p).normalize();
  camPos.copy(p).add(dir.multiplyScalar(5.5));
  camLook.copy(p);
  camBlend = 0;
}
function restoreCam() {
  camPos.copy(CAM[mode].pos);
  camLook.copy(CAM[mode].look);
  camBlend = 0;
}
canvas.addEventListener("pointermove", ev => {
  poke();
  ndc.x = (ev.clientX / innerWidth) * 2 - 1;
  ndc.y = -(ev.clientY / innerHeight) * 2 + 1;
  tiltX = ndc.y * 0.04;
  tiltY = ndc.x * 0.04;
});
canvas.addEventListener("pointerleave", () => ndc.set(2, 2));
canvas.addEventListener("click", ev => {
  poke();
  ndc.x = (ev.clientX / innerWidth) * 2 - 1;
  ndc.y = -(ev.clientY / innerHeight) * 2 + 1;
  ray.setFromCamera(ndc, camera);
  const hits = ray.intersectObjects(cards.map(c => c.userData.mesh), false);
  if (passport.hidden && hits.length) openPassport(hits[0].object.parent.userData);
});

const passport = document.getElementById("passport");
let bohrAnim = 0;

function section(title, rows) {
  return `<section class="sec-block"><h2>${title}</h2><div class="grid">${
    rows.map(([a, b]) => `<div class="row"><span>${a}</span><b>${b}</b></div>`).join("")}</div></section>`;
}

const L = {
  ru: {
    general: "ОБЗОР", num: "Атомный номер", sym: "Символ", name: "Название", other: "Английское название",
    cat: "Категория", year: "Открыт", by: "Кем открыт", named: "Кем назван",
    phys: "ФИЗИЧЕСКИЕ СВОЙСТВА", mass: "Атомная масса", period: "Период", group: "Группа", block: "Блок",
    phase: "Агрегатное состояние (20 °C)", dens: "Плотность", melt: "Температура плавления", boil: "Температура кипения",
    lat: "Тип решётки", look: "Внешний вид", elec: "ЭЛЕКТРОНЫ", cfg: "Электронная конфигурация",
    cfgS: "Конфигурация (кратко)", shells: "Оболочки", eneg: "Электроотрицательность", aff: "Сродство к электрону",
    ion: "Энергии ионизации", rad: "Радиус, пм", ox: "Степени окисления", bond: "СВЯЗИ / СОЕДИНЕНИЯ",
    none: "нет устойчивых соединений", empty: "значимых соединений нет", src: "источник", ancient: "Древность",
    solid: "Твёрдое", liquid: "Жидкое", gas: "Газообразное",
    unitDens: "г/см³", unitK: "К", unitC: "°C", unitAff: "кДж/моль",
  },
  en: {
    general: "OVERVIEW", num: "Atomic number", sym: "Symbol", name: "Name", other: "Russian name",
    cat: "Category", year: "Discovered", by: "Discovered by", named: "Named by",
    phys: "PHYSICAL", mass: "Atomic mass", period: "Period", group: "Group", block: "Block",
    phase: "Phase at 20 °C", dens: "Density", melt: "Melting point", boil: "Boiling point",
    lat: "Lattice", look: "Appearance", elec: "ELECTRONS", cfg: "Electron configuration",
    cfgS: "Configuration (short)", shells: "Shells", eneg: "Electronegativity", aff: "Electron affinity",
    ion: "Ionization energies", rad: "Radius, pm", ox: "Oxidation states", bond: "BONDS / COMPOUNDS",
    none: "no common compounds", empty: "no notable compounds", src: "source", ancient: "Antiquity",
    solid: "Solid", liquid: "Liquid", gas: "Gas",
    unitDens: "g/cm³", unitK: "K", unitC: "°C", unitAff: "kJ/mol",
  },
};
const tr = k => L[lang][k];
const LAT = {
  b: { ru: "ОЦК", en: "body-centred cubic" },
  c: { ru: "ГЦК", en: "face-centred cubic" },
  h: { ru: "ГПУ", en: "hexagonal close-packed" },
  s: { ru: "ПК", en: "simple cubic" },
  r: { ru: "ромбоэдрическая", en: "rhombohedral" },
  o: { ru: "ромбическая", en: "orthorhombic" },
  t: { ru: "тетрагональная", en: "tetragonal" },
  m: { ru: "моноклинная", en: "monoclinic" },
  d: { ru: "алмазная", en: "diamond cubic" },
  x: { ru: "гексагональная", en: "hexagonal" },
  "-": { ru: "неизвестна", en: "unknown" },
};
const CATS = [
  ["alkaline", { en: "alkaline earth metal", ru: "щёлочноземельный металл" }],
  ["alkali", { en: "alkali metal", ru: "щелочной металл" }],
  ["lanthanide", { en: "lanthanide", ru: "лантаноид" }],
  ["actinide", { en: "actinide", ru: "актиноид" }],
  ["post-transition", { en: "post-transition metal", ru: "постпереходный металл" }],
  ["transition", { en: "transition metal", ru: "переходный металл" }],
  ["metalloid", { en: "metalloid", ru: "металлоид" }],
  ["diatomic", { en: "diatomic nonmetal", ru: "двухатомный неметалл" }],
  ["polyatomic", { en: "polyatomic nonmetal", ru: "многоатомный неметалл" }],
  ["noble", { en: "noble gas", ru: "благородный газ" }],
  ["nonmetal", { en: "nonmetal", ru: "неметалл" }],
];
const BOND_EN = {
  "ковалентные связи с неметаллами; гидриды с металлами": "covalent bonds with nonmetals; hydrides with metals",
  "инертен, устойчивых соединений не образует": "inert, forms no stable compounds",
  "ионные связи с неметаллами": "ionic bonds with nonmetals",
  "преимущественно ковалентно-полярные связи": "mostly polar covalent bonds",
  "ковалентные связи": "covalent bonds",
  "ковалентные связи, основа органики": "covalent bonds, basis of organic chemistry",
  "ковалентные связи; тройная связь в N2": "covalent bonds; triple bond in N2",
  "образует оксиды почти со всеми элементами": "forms oxides with nearly every element",
  "самый сильный окислитель, ионные и ковалентные связи": "strongest oxidizer, ionic and covalent bonds",
  "ковалентно-ионные связи, амфотерные оксиды": "covalent-ionic bonds, amphoteric oxides",
  "ковалентные связи с неметаллами, сульфиды с металлами": "covalent bonds with nonmetals, sulfides with metals",
  "ионные связи с металлами, ковалентные с неметаллами": "ionic bonds with metals, covalent with nonmetals",
  "преимущественно ионные связи с неметаллами (выведено по электроотрицательности)": "mostly ionic bonds with nonmetals (from electronegativity)",
  "ковалентно-ионные связи": "covalent-ionic bonds",
  "ковалентно-ионные связи, окраска соединений": "covalent-ionic bonds, colored compounds",
  "ионные связи, амфотерный оксид": "ionic bonds, amphoteric oxide",
  "ковалентно-ионные связи с неметаллами (выведено по электроотрицательности)": "covalent-ionic bonds with nonmetals (from electronegativity)",
  "ковалентные связи с неметаллами, ионные с активными металлами (выведено по электроотрицательности)": "covalent bonds with nonmetals, ionic with active metals (from electronegativity)",
  "инертен, устойчивых соединений практически не образует": "inert, almost no stable compounds",
  "ионные связи": "ionic bonds",
  "ковалентные комплексы": "covalent complexes",
  "ковалентные связи, химически инертно": "covalent bonds, chemically inert",
  "ковалентно-ионные связи, ядовитые соединения": "covalent-ionic bonds, toxic compounds",
};
function catLabel(e) {
  const c = (e.category || "").toLowerCase();
  if (e.group === 17 && e.number !== 117) return lang === "ru" ? "галоген" : "halogen";
  if (c.includes("unknown")) {
    const tail = e.category.replace(/unknown/i, "").replace(/^,\s*/, "").trim();
    if (lang === "ru") return tail ? `неизвестно, предположительно ${tail}` : "неизвестно";
    return e.category;
  }
  const hit = CATS.find(([k]) => c.includes(k));
  if (!hit) return e.category || "—";
  return hit[1][lang];
}
function latticeLabel(i) {
  const code = LATTICE[i];
  const row = LAT[code];
  return row ? row[lang] : (code || "—");
}
function bondLabel(text) {
  if (!text) return "—";
  if (lang === "ru") return text;
  return BOND_EN[text] || text.replace(/[а-яё]/gi, "").trim() || text;
}
// TODO: elements.json has no ru_summary / ru_appearance / ru discovered_by
function freeText(s) {
  if (!s) return "—";
  return lang === "ru" ? `${s} (EN)` : s;
}
function openPassport(u) {
  const e = u.e, i = e.number - 1, hex = u.hex;
  const year = YEARS[i] === 0 ? tr("ancient") : (YEARS[i] ?? "—");
  const phaseMap = { Solid: tr("solid"), Liquid: tr("liquid"), Gas: tr("gas") };
  const phase = phaseMap[e.phase] || e.phase || "—";
  const k = v => v == null ? "—" : `${Number(v).toFixed(1)} ${tr("unitK")} (${(v - 273.15).toFixed(1)} ${tr("unitC")})`;
  const radius = e.atomic_radii?.empirical?.[0] ?? e.atomic_radii?.calculated?.[0] ?? e.atomic_radii?.covalent_single?.[0];
  const comp = COMPOUNDS[e.symbol] || { partners: [], bond_character: "—", compounds: [], sources: [] };

  const cat = catLabel(e);
  const A = section(tr("general"), [
    [tr("num"), e.number], [tr("sym"), e.symbol], [tr("name"), lang === "ru" ? RU[i] : e.name], [tr("other"), lang === "ru" ? e.name : RU[i]],
    [tr("cat"), cat], [tr("year"), year], [tr("by"), freeText(e.discovered_by)],
    [tr("named"), freeText(e.named_by)],
  ]);
  const B = section(tr("phys"), [
    [tr("mass"), e.atomic_mass?.toFixed?.(4) ?? e.atomic_mass], [tr("period"), e.period], [tr("group"), e.group],
    [tr("block"), e.block || "—"], [tr("phase"), phase], [tr("dens"), e.density != null ? e.density + " " + tr("unitDens") : "—"],
    [tr("melt"), k(e.melt)], [tr("boil"), k(e.boil)],
    [tr("lat"), latticeLabel(i)], [tr("look"), freeText(e.appearance)],
  ]);
  const C = section(tr("elec"), [
    [tr("cfg"), e.electron_configuration || "—"],
    [tr("cfgS"), e.electron_configuration_semantic || "—"],
    [tr("shells"), (e.shells || []).join(" · ") || "—"],
    [tr("eneg"), e.electronegativity_pauling ?? "—"],
    [tr("aff"), e.electron_affinity != null ? e.electron_affinity + " " + tr("unitAff") : "—"],
    [tr("ion"), (e.ionization_energies || []).slice(0, 3).map(n => n.toFixed?.(1) ?? n).join(", ") || "—"],
    [tr("rad"), radius ?? "—"], [tr("ox"), OX[i] || "—"],
  ]);

  const partnersHtml = comp.partners.length
    ? comp.partners.map(s => `<button class="chip" data-sym="${s}">${s}</button>`).join("")
    : `<span class='muted'>${tr("none")}</span>`;
  const compHtml = comp.compounds.length
    ? comp.compounds.map(x => `<div class="compound"><b class="formula">${x.formula}</b>
        <span>${lang === "ru" ? (x.name_ru || x.name_en) : (x.name_en || x.name_ru)}</span>
        ${lang === "ru" && x.note ? `<em>${x.note}</em>` : ""}</div>`).join("")
    : `<span class='muted'>${tr("empty")}</span>`;
  const srcHtml = (comp.sources || []).map((s, n) =>
    `<a href="${s}" target="_blank" rel="noopener">${tr("src")} ${n + 1}</a>`).join(" · ");
  const F = `<section class="sec-block"><h2>${tr("bond")}</h2>
    <div class="bond">${bondLabel(comp.bond_character)}</div>
    <div class="partners">${partnersHtml}</div>
    <div class="compounds">${compHtml}</div>
    ${srcHtml ? `<div class="sources">${srcHtml}</div>` : ""}</section>`;

  passport.innerHTML = `<div id="sheet" style="--accent:${hex}">
    <button class="close" id="x">✕</button>
    <div class="head">
      <div>
        <h1 style="text-shadow:0 0 18px ${hex}">${e.symbol}</h1>
        <div class="sub">${lang === "ru" ? RU[i] : e.name} · ${lang === "ru" ? e.name : RU[i]} · ${cat}</div>
      </div>
      <canvas id="bohr" width="260" height="260"></canvas>
    </div>
    <p class="summary">${e.summary ? freeText(e.summary) : ""}</p>
    ${A}${B}${C}${F}
  </div>`;
  passport.hidden = false;
  requestAnimationFrame(() => passport.classList.add("open"));
  focusCard(cardBySymbol.get(e.symbol));
  document.getElementById("x").onclick = closePassport;
  passport.querySelectorAll(".chip").forEach(btn => btn.onclick = () => {
    const card = cardBySymbol.get(btn.dataset.sym);
    if (card) openPassport(card.userData);
  });
  startBohr(e, hex);
  setHighlight(e.symbol, comp.partners);
}

function startBohr(e, hex) {
  cancelAnimationFrame(bohrAnim);
  const cv = document.getElementById("bohr");
  if (!cv) return;
  const g = cv.getContext("2d"), W = cv.width, H = cv.height, cx = W / 2, cy = H / 2;
  const shells = e.shells || [];
  const maxR = W / 2 - 16;
  const step = shells.length ? maxR / (shells.length + 0.5) : maxR;
  const t0 = performance.now();
  function draw(now) {
    const t = (now - t0) / 1000;
    g.clearRect(0, 0, W, H);
    g.fillStyle = hex; g.shadowColor = hex; g.shadowBlur = 18;
    g.beginPath(); g.arc(cx, cy, 12, 0, 7); g.fill();
    g.shadowBlur = 0;
    g.fillStyle = "#fff"; g.font = "600 13px ui-monospace, Menlo"; g.textAlign = "center"; g.textBaseline = "middle";
    g.fillText(e.symbol, cx, cy);
    shells.forEach((count, s) => {
      const R = step * (s + 1);
      g.strokeStyle = "rgba(255,255,255,0.18)"; g.lineWidth = 1;
      g.beginPath(); g.arc(cx, cy, R, 0, 7); g.stroke();
      const speed = 0.9 / (s + 1);
      for (let k = 0; k < count; k++) {
        const a = t * speed + (k / count) * Math.PI * 2;
        const x = cx + R * Math.cos(a), y = cy + R * Math.sin(a);
        g.fillStyle = hex; g.shadowColor = hex; g.shadowBlur = 8;
        g.beginPath(); g.arc(x, y, 4, 0, 7); g.fill(); g.shadowBlur = 0;
      }
    });
    bohrAnim = requestAnimationFrame(draw);
  }
  bohrAnim = requestAnimationFrame(draw);
}

function closePassport() {
  passport.classList.remove("open");
  cancelAnimationFrame(bohrAnim);
  clearHighlight();
  restoreCam();
  setTimeout(() => { if (!passport.classList.contains("open")) passport.hidden = true; }, 260);
}
function repaintCards() {
  for (const n of cards) {
    const prev = n.userData.mesh.material.map;
    n.userData.mesh.material.map = cardTexture(n.userData.e, n.userData.hex);
    n.userData.mesh.material.needsUpdate = true;
    prev.dispose();
  }
  if (!passport.hidden && activeSymbol) openPassport(cardBySymbol.get(activeSymbol).userData);
}
document.getElementById("lang").onclick = () => {
  poke();
  lang = lang === "ru" ? "en" : "ru";
  document.getElementById("lang").textContent = lang.toUpperCase();
  repaintCards();
};
addEventListener("keydown", ev => { if (ev.key === "Escape") closePassport(); });
passport.addEventListener("click", ev => { if (ev.target === passport) closePassport(); });

const linkMat = new THREE.LineBasicMaterial({ transparent: true, opacity: 0.6 });

function setHighlight(symbol, partners) {
  activeSymbol = symbol;
  partnerSet.clear();
  partners.forEach(s => partnerSet.add(s));
  for (const n of cards) {
    const sym = n.userData.e.symbol;
    n.userData.partner = partnerSet.has(sym);
    n.userData.dim = !(sym === symbol || partnerSet.has(sym));
  }
  buildLinks();
}

function clearHighlight() {
  activeSymbol = null;
  partnerSet.clear();
  for (const n of cards) { n.userData.partner = false; n.userData.dim = false; }
  if (links) { spin.remove(links); links.geometry.dispose(); links = null; }
}

function buildLinks() {
  if (links) { spin.remove(links); links.geometry.dispose(); links = null; }
  if (mode !== "table" || !activeSymbol) return;
  const from = cardBySymbol.get(activeSymbol);
  if (!from || !partnerSet.size) return;
  const pts = [];
  for (const s of partnerSet) {
    const to = cardBySymbol.get(s);
    if (to) { pts.push(from.userData.target.clone(), to.userData.target.clone()); }
  }
  if (!pts.length) return;
  const geo = new THREE.BufferGeometry().setFromPoints(pts);
  linkMat.color = new THREE.Color(from.userData.hex);
  links = new THREE.LineSegments(geo, linkMat);
  spin.add(links);
}

const DIM = new THREE.Color(0x333333);
const FULL = new THREE.Color(0xffffff);
const HOT = new THREE.Color(1.35, 1.35, 1.35);
function frame() {
  requestAnimationFrame(frame);
  const now = performance.now();
  if (!demoOn && now - idleAt > 45000) demoOn = true;
  if (demoOn && passport.hidden && now - lastDemo > 8000) {
    lastDemo = now;
    apply(MODES[(MODES.indexOf(mode) + 1) % MODES.length], true);
  }
  ray.setFromCamera(ndc, camera);
  const hits = ray.intersectObjects(cards.map(c => c.userData.mesh), false);
  const next = passport.hidden && hits.length ? hits[0].object.parent : null;
  if (next !== hovered) {
    hovered = next;
    canvas.style.cursor = next ? "pointer" : "default";
  }
  if (mode !== "table") spin.rotation.y += 0.0022;
  tilt.rotation.x += (tiltX - tilt.rotation.x) * 0.04;
  tilt.rotation.z += (tiltY * 0.6 - tilt.rotation.z) * 0.04;
  dust.rotation.y += 0.0004;
  if (camBlend < 1) {
    camBlend = Math.min(1, camBlend + 0.035);
    camera.position.lerp(camPos, 0.08);
    controls.target.lerp(camLook, 0.08);
  }
  controls.update();
  bloom.strength = 0.55 + Math.sin(now / 900) * 0.05;
  const focused = hovered != null;
  cards.forEach((n, i) => {
    const t = Math.min(1, Math.max(0, (now - switchAt - i * 12) / 900));
    const ease = 1 - (1 - t) ** 3;
    const k = 0.02 + 0.1 * ease;
    const goal = n.userData.target.clone();
    if (t < 0.4) goal.multiplyScalar(0.15 + (t / 0.4) * 0.85);
    n.position.lerp(goal, k);
    const amp = mode === "table" ? 0.008 : 0.02;
    n.position.y += Math.sin(now / 900 + i) * amp * k;
    if (n.userData.billboard) n.lookAt(camera.position);
    else n.quaternion.slerp(n.userData.targetQ, k);
    const mesh = n.userData.mesh;
    const over = t > 0.82 ? 1 + 0.04 * Math.sin((t - 0.82) * 18) : 1;
    let s = over;
    if (n === hovered) s = 1.08 * over;
    else if (n.userData.e.symbol === activeSymbol) s = (1.06 + Math.sin(now / 220) * 0.05) * over;
    else if (n.userData.partner) s = (1.04 + Math.sin(now / 240) * 0.03) * over;
    mesh.scale.x += (s - mesh.scale.x) * 0.15;
    mesh.scale.y = mesh.scale.x;
    mesh.scale.z = mesh.scale.x;
    const zWant = n === hovered ? 0.35 : 0;
    mesh.position.z += (zWant - mesh.position.z) * 0.15;
    let col = FULL;
    if (n.userData.dim) col = DIM;
    else if (focused && n !== hovered) col = new THREE.Color(0.55, 0.55, 0.55);
    else if (n === hovered || n.userData.e.symbol === activeSymbol) col = HOT;
    if (Math.random() < 0.002 && !n.userData.dim) n.userData.flick = now + 90;
    mesh.material.color.lerp(col, 0.15);
    if (n.userData.flick > now) mesh.material.color.setScalar(1.6);
    else if (n.userData.e.symbol === activeSymbol && !n.userData.dim) {
      mesh.material.color.setScalar(1.05 + Math.sin(now / 220) * 0.3);
    }
  });
  composer.render();
}
frame();
