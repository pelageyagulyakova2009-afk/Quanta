#!/usr/bin/env node
// Строит web/compounds.json из выверенной вручную таблицы CURATED.
// Для элементов без ручных данных партнёры и характер связи выводятся эвристикой
// по электроотрицательности (Δχ > 1.7 → ионная) из web/elements.json.
// Рантайм остаётся офлайн: сайт читает готовый compounds.json.
//
// Источники, по которым выверены формулы и названия (справочные, не fetch в рантайме):
//   PubChem PUG REST  — https://pubchem.ncbi.nlm.nih.gov/rest/pug
//   Wikidata SPARQL   — https://query.wikidata.org/
//   RSC Periodic Table — https://periodic-table.rsc.org/
//   Wikipedia «Compounds of <element>» — https://en.wikipedia.org/
//   Bowserinator JSON — https://github.com/Bowserinator/Periodic-Table-JSON

import { readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const WEB = join(__dirname, "..", "web");

const SRC = {
  pubchem: "https://pubchem.ncbi.nlm.nih.gov/rest/pug",
  wikidata: "https://query.wikidata.org/",
  rsc: "https://periodic-table.rsc.org/",
  wiki: (el) => `https://en.wikipedia.org/wiki/Compounds_of_${el}`,
};

function c(formula, name_ru, name_en, note) {
  return { formula, name_ru, name_en, note };
}

// Выверенные данные. bond_character — краткое словесное описание типа связи.
const CURATED = {
  H: { partners: ["O", "C", "N", "Cl", "F", "S"], bond_character: "ковалентные связи с неметаллами; гидриды с металлами",
    compounds: [c("H2O", "вода", "water", "основа жизни"), c("H2O2", "пероксид водорода", "hydrogen peroxide", "окислитель"),
      c("HCl", "хлороводород", "hydrogen chloride", "соляная кислота в растворе"), c("NH3", "аммиак", "ammonia", "в составе с азотом"),
      c("CH4", "метан", "methane", "простейший углеводород"), c("H2SO4", "серная кислота", "sulfuric acid", "сильная кислота")],
    sources: [SRC.rsc + "element/1/hydrogen", SRC.wiki("hydrogen")] },
  He: { partners: [], bond_character: "инертен, устойчивых соединений не образует", compounds: [], sources: [SRC.rsc + "element/2/helium"] },
  Li: { partners: ["O", "Cl", "F", "H", "C", "N"], bond_character: "ионные связи с неметаллами",
    compounds: [c("Li2O", "оксид лития", "lithium oxide", ""), c("LiCl", "хлорид лития", "lithium chloride", ""),
      c("LiH", "гидрид лития", "lithium hydride", ""), c("Li2CO3", "карбонат лития", "lithium carbonate", "в медицине и батареях"),
      c("LiOH", "гидроксид лития", "lithium hydroxide", "щёлочь")],
    sources: [SRC.rsc + "element/3/lithium", SRC.wiki("lithium")] },
  Be: { partners: ["O", "Cl", "F"], bond_character: "преимущественно ковалентно-полярные связи",
    compounds: [c("BeO", "оксид бериллия", "beryllium oxide", "тугоплавкая керамика"), c("BeCl2", "хлорид бериллия", "beryllium chloride", ""),
      c("BeF2", "фторид бериллия", "beryllium fluoride", "")],
    sources: [SRC.rsc + "element/4/beryllium"] },
  B: { partners: ["O", "H", "N", "F", "Cl"], bond_character: "ковалентные связи",
    compounds: [c("B2O3", "оксид бора", "boron trioxide", ""), c("H3BO3", "борная кислота", "boric acid", "антисептик"),
      c("BN", "нитрид бора", "boron nitride", "сверхтвёрдый материал"), c("BF3", "трифторид бора", "boron trifluoride", "кислота Льюиса"),
      c("Na2B4O7", "бура", "borax", "")],
    sources: [SRC.rsc + "element/5/boron", SRC.wiki("boron")] },
  C: { partners: ["H", "O", "N", "Cl", "S", "Si"], bond_character: "ковалентные связи, основа органики",
    compounds: [c("CO2", "углекислый газ", "carbon dioxide", ""), c("CO", "угарный газ", "carbon monoxide", "ядовит"),
      c("CH4", "метан", "methane", ""), c("CaCO3", "карбонат кальция", "calcium carbonate", "мел, известняк"),
      c("C6H12O6", "глюкоза", "glucose", "сахар"), c("SiC", "карбид кремния", "silicon carbide", "абразив")],
    sources: [SRC.rsc + "element/6/carbon", SRC.wiki("carbon")] },
  N: { partners: ["H", "O", "C"], bond_character: "ковалентные связи; тройная связь в N2",
    compounds: [c("NH3", "аммиак", "ammonia", ""), c("HNO3", "азотная кислота", "nitric acid", "сильная кислота"),
      c("NO2", "диоксид азота", "nitrogen dioxide", "бурый газ"), c("N2O", "закись азота", "nitrous oxide", "веселящий газ"),
      c("NH4NO3", "нитрат аммония", "ammonium nitrate", "удобрение")],
    sources: [SRC.rsc + "element/7/nitrogen", SRC.wiki("nitrogen")] },
  O: { partners: ["H", "C", "N", "S", "Fe", "Si"], bond_character: "образует оксиды почти со всеми элементами",
    compounds: [c("H2O", "вода", "water", ""), c("CO2", "углекислый газ", "carbon dioxide", ""),
      c("SiO2", "кремнезём", "silicon dioxide", "кварц, песок"), c("Fe2O3", "оксид железа(III)", "iron(III) oxide", "ржавчина"),
      c("SO2", "диоксид серы", "sulfur dioxide", ""), c("O3", "озон", "ozone", "защитный слой")],
    sources: [SRC.rsc + "element/8/oxygen", SRC.wiki("oxygen")] },
  F: { partners: ["H", "C", "Na", "Ca", "S", "U"], bond_character: "самый сильный окислитель, ионные и ковалентные связи",
    compounds: [c("HF", "фтороводород", "hydrogen fluoride", "плавиковая кислота"), c("NaF", "фторид натрия", "sodium fluoride", "в зубной пасте"),
      c("CaF2", "флюорит", "calcium fluoride", ""), c("SF6", "гексафторид серы", "sulfur hexafluoride", "изолятор"),
      c("UF6", "гексафторид урана", "uranium hexafluoride", "обогащение урана")],
    sources: [SRC.rsc + "element/9/fluorine", SRC.wiki("fluorine")] },
  Ne: { partners: [], bond_character: "инертен, устойчивых соединений не образует", compounds: [], sources: [SRC.rsc + "element/10/neon"] },
  Na: { partners: ["Cl", "O", "F", "S", "H", "C"], bond_character: "ионные связи с неметаллами",
    compounds: [c("NaCl", "хлорид натрия", "sodium chloride", "поваренная соль"), c("NaOH", "гидроксид натрия", "sodium hydroxide", "едкий натр"),
      c("Na2CO3", "карбонат натрия", "sodium carbonate", "сода"), c("NaHCO3", "гидрокарбонат натрия", "sodium bicarbonate", "пищевая сода"),
      c("Na2SO4", "сульфат натрия", "sodium sulfate", "")],
    sources: [SRC.rsc + "element/11/sodium", SRC.wiki("sodium")] },
  Mg: { partners: ["O", "Cl", "S", "C", "H"], bond_character: "ионные связи с неметаллами",
    compounds: [c("MgO", "оксид магния", "magnesium oxide", "жжёная магнезия"), c("MgCl2", "хлорид магния", "magnesium chloride", ""),
      c("Mg(OH)2", "гидроксид магния", "magnesium hydroxide", "магнезиальное молоко"), c("MgSO4", "сульфат магния", "magnesium sulfate", "английская соль"),
      c("MgCO3", "карбонат магния", "magnesium carbonate", "")],
    sources: [SRC.rsc + "element/12/magnesium", SRC.wiki("magnesium")] },
  Al: { partners: ["O", "Cl", "F", "S"], bond_character: "ковалентно-ионные связи, амфотерные оксиды",
    compounds: [c("Al2O3", "оксид алюминия", "aluminium oxide", "корунд"), c("AlCl3", "хлорид алюминия", "aluminium chloride", "катализатор"),
      c("Al(OH)3", "гидроксид алюминия", "aluminium hydroxide", ""), c("Al2(SO4)3", "сульфат алюминия", "aluminium sulfate", "")],
    sources: [SRC.rsc + "element/13/aluminium", SRC.wiki("aluminium")] },
  Si: { partners: ["O", "C", "H", "F", "Cl"], bond_character: "ковалентные связи",
    compounds: [c("SiO2", "диоксид кремния", "silicon dioxide", "кварц"), c("SiC", "карбид кремния", "silicon carbide", "карборунд"),
      c("SiH4", "силан", "silane", ""), c("SiCl4", "тетрахлорид кремния", "silicon tetrachloride", "")],
    sources: [SRC.rsc + "element/14/silicon", SRC.wiki("silicon")] },
  P: { partners: ["O", "H", "Cl", "Ca"], bond_character: "ковалентные связи",
    compounds: [c("P2O5", "оксид фосфора(V)", "phosphorus pentoxide", "осушитель"), c("H3PO4", "фосфорная кислота", "phosphoric acid", ""),
      c("PCl3", "трихлорид фосфора", "phosphorus trichloride", ""), c("Ca3(PO4)2", "фосфат кальция", "calcium phosphate", "кости, апатит")],
    sources: [SRC.rsc + "element/15/phosphorus", SRC.wiki("phosphorus")] },
  S: { partners: ["O", "H", "Fe", "Cu", "Na"], bond_character: "ковалентные связи с неметаллами, сульфиды с металлами",
    compounds: [c("H2SO4", "серная кислота", "sulfuric acid", ""), c("SO2", "диоксид серы", "sulfur dioxide", ""),
      c("H2S", "сероводород", "hydrogen sulfide", "запах тухлых яиц"), c("FeS2", "пирит", "iron pyrite", "«золото дураков»"),
      c("Na2SO4", "сульфат натрия", "sodium sulfate", "")],
    sources: [SRC.rsc + "element/16/sulfur", SRC.wiki("sulfur")] },
  Cl: { partners: ["Na", "H", "K", "Ca", "Fe", "O"], bond_character: "ионные связи с металлами, ковалентные с неметаллами",
    compounds: [c("NaCl", "хлорид натрия", "sodium chloride", "соль"), c("HCl", "хлороводород", "hydrogen chloride", "соляная кислота"),
      c("KCl", "хлорид калия", "potassium chloride", "удобрение"), c("CaCl2", "хлорид кальция", "calcium chloride", "осушитель"),
      c("FeCl3", "хлорид железа(III)", "iron(III) chloride", "")],
    sources: [SRC.rsc + "element/17/chlorine", SRC.wiki("chlorine")] },
  Ar: { partners: [], bond_character: "инертен, устойчивых соединений не образует", compounds: [], sources: [SRC.rsc + "element/18/argon"] },
  K: { partners: ["Cl", "O", "N", "S", "C"], bond_character: "ионные связи с неметаллами",
    compounds: [c("KCl", "хлорид калия", "potassium chloride", "удобрение"), c("KOH", "гидроксид калия", "potassium hydroxide", "едкое кали"),
      c("KNO3", "нитрат калия", "potassium nitrate", "селитра"), c("K2CO3", "карбонат калия", "potassium carbonate", "поташ"),
      c("KMnO4", "перманганат калия", "potassium permanganate", "марганцовка")],
    sources: [SRC.rsc + "element/19/potassium", SRC.wiki("potassium")] },
  Ca: { partners: ["O", "C", "Cl", "F", "P", "S"], bond_character: "ионные связи с неметаллами",
    compounds: [c("CaCO3", "карбонат кальция", "calcium carbonate", "мел, известняк"), c("CaO", "оксид кальция", "calcium oxide", "негашёная известь"),
      c("Ca(OH)2", "гидроксид кальция", "calcium hydroxide", "гашёная известь"), c("CaSO4", "сульфат кальция", "calcium sulfate", "гипс"),
      c("CaCl2", "хлорид кальция", "calcium chloride", "")],
    sources: [SRC.rsc + "element/20/calcium", SRC.wiki("calcium")] },
  Ti: { partners: ["O", "Cl", "N"], bond_character: "ковалентно-ионные связи",
    compounds: [c("TiO2", "диоксид титана", "titanium dioxide", "белый пигмент"), c("TiCl4", "тетрахлорид титана", "titanium tetrachloride", ""),
      c("TiN", "нитрид титана", "titanium nitride", "твёрдое покрытие")],
    sources: [SRC.rsc + "element/22/titanium"] },
  Cr: { partners: ["O", "Cl", "K"], bond_character: "ковалентно-ионные связи, окраска соединений",
    compounds: [c("Cr2O3", "оксид хрома(III)", "chromium(III) oxide", "зелёный пигмент"), c("K2Cr2O7", "дихромат калия", "potassium dichromate", "окислитель"),
      c("CrCl3", "хлорид хрома(III)", "chromium(III) chloride", "")],
    sources: [SRC.rsc + "element/24/chromium"] },
  Mn: { partners: ["O", "Cl", "K"], bond_character: "ковалентно-ионные связи",
    compounds: [c("MnO2", "диоксид марганца", "manganese dioxide", "в батарейках"), c("KMnO4", "перманганат калия", "potassium permanganate", "марганцовка"),
      c("MnCl2", "хлорид марганца(II)", "manganese(II) chloride", "")],
    sources: [SRC.rsc + "element/25/manganese"] },
  Fe: { partners: ["O", "S", "Cl", "C"], bond_character: "ковалентно-ионные связи",
    compounds: [c("Fe2O3", "оксид железа(III)", "iron(III) oxide", "ржавчина"), c("Fe3O4", "магнетит", "magnetite", ""),
      c("FeS2", "пирит", "iron pyrite", ""), c("FeCl3", "хлорид железа(III)", "iron(III) chloride", ""),
      c("FeSO4", "сульфат железа(II)", "iron(II) sulfate", "железный купорос")],
    sources: [SRC.rsc + "element/26/iron", SRC.wiki("iron")] },
  Co: { partners: ["O", "Cl"], bond_character: "ковалентно-ионные связи",
    compounds: [c("CoO", "оксид кобальта(II)", "cobalt(II) oxide", ""), c("CoCl2", "хлорид кобальта(II)", "cobalt(II) chloride", "индикатор влаги")],
    sources: [SRC.rsc + "element/27/cobalt"] },
  Ni: { partners: ["O", "Cl", "S"], bond_character: "ковалентно-ионные связи",
    compounds: [c("NiO", "оксид никеля(II)", "nickel(II) oxide", ""), c("NiCl2", "хлорид никеля(II)", "nickel(II) chloride", ""),
      c("NiSO4", "сульфат никеля(II)", "nickel(II) sulfate", "гальваника")],
    sources: [SRC.rsc + "element/28/nickel"] },
  Cu: { partners: ["O", "S", "Cl", "N"], bond_character: "ковалентно-ионные связи",
    compounds: [c("CuO", "оксид меди(II)", "copper(II) oxide", ""), c("CuSO4", "сульфат меди(II)", "copper(II) sulfate", "медный купорос"),
      c("Cu2O", "оксид меди(I)", "copper(I) oxide", "красный"), c("CuCl2", "хлорид меди(II)", "copper(II) chloride", "")],
    sources: [SRC.rsc + "element/29/copper", SRC.wiki("copper")] },
  Zn: { partners: ["O", "S", "Cl"], bond_character: "ионные связи, амфотерный оксид",
    compounds: [c("ZnO", "оксид цинка", "zinc oxide", "в мазях и красках"), c("ZnS", "сульфид цинка", "zinc sulfide", "люминофор"),
      c("ZnCl2", "хлорид цинка", "zinc chloride", ""), c("ZnSO4", "сульфат цинка", "zinc sulfate", "")],
    sources: [SRC.rsc + "element/30/zinc"] },
  Br: { partners: ["Na", "K", "H", "Ag"], bond_character: "ионные связи с металлами, ковалентные с неметаллами",
    compounds: [c("HBr", "бромоводород", "hydrogen bromide", ""), c("NaBr", "бромид натрия", "sodium bromide", ""),
      c("KBr", "бромид калия", "potassium bromide", ""), c("AgBr", "бромид серебра", "silver bromide", "фотоплёнка")],
    sources: [SRC.rsc + "element/35/bromine"] },
  Ag: { partners: ["Cl", "Br", "O", "N", "S"], bond_character: "ковалентно-ионные связи",
    compounds: [c("AgNO3", "нитрат серебра", "silver nitrate", "ляпис"), c("AgCl", "хлорид серебра", "silver chloride", "светочувствителен"),
      c("AgBr", "бромид серебра", "silver bromide", "фотография"), c("Ag2O", "оксид серебра", "silver oxide", "")],
    sources: [SRC.rsc + "element/47/silver"] },
  Sn: { partners: ["O", "Cl", "S"], bond_character: "ковалентно-ионные связи",
    compounds: [c("SnO2", "диоксид олова", "tin dioxide", ""), c("SnCl2", "хлорид олова(II)", "tin(II) chloride", "восстановитель"),
      c("SnCl4", "хлорид олова(IV)", "tin(IV) chloride", "")],
    sources: [SRC.rsc + "element/50/tin"] },
  I: { partners: ["K", "Na", "H", "Ag"], bond_character: "ионные связи с металлами, ковалентные с неметаллами",
    compounds: [c("KI", "иодид калия", "potassium iodide", "в иодированной соли"), c("HI", "иодоводород", "hydrogen iodide", ""),
      c("NaI", "иодид натрия", "sodium iodide", ""), c("AgI", "иодид серебра", "silver iodide", "засев облаков")],
    sources: [SRC.rsc + "element/53/iodine"] },
  Ba: { partners: ["O", "S", "Cl", "C"], bond_character: "ионные связи",
    compounds: [c("BaSO4", "сульфат бария", "barium sulfate", "рентгеноконтраст"), c("BaO", "оксид бария", "barium oxide", ""),
      c("BaCl2", "хлорид бария", "barium chloride", "ядовит"), c("BaCO3", "карбонат бария", "barium carbonate", "")],
    sources: [SRC.rsc + "element/56/barium"] },
  Pt: { partners: ["Cl", "O", "N"], bond_character: "ковалентные комплексы",
    compounds: [c("PtCl2", "хлорид платины(II)", "platinum(II) chloride", ""), c("H2PtCl6", "гексахлорплатиновая кислота", "chloroplatinic acid", ""),
      c("PtO2", "оксид платины(IV)", "platinum(IV) oxide", "катализатор Адамса")],
    sources: [SRC.rsc + "element/78/platinum"] },
  Au: { partners: ["Cl", "O"], bond_character: "ковалентные связи, химически инертно",
    compounds: [c("AuCl3", "хлорид золота(III)", "gold(III) chloride", ""), c("HAuCl4", "золотохлористоводородная кислота", "chloroauric acid", ""),
      c("Au2O3", "оксид золота(III)", "gold(III) oxide", "")],
    sources: [SRC.rsc + "element/79/gold", SRC.wiki("gold")] },
  Hg: { partners: ["O", "S", "Cl"], bond_character: "ковалентно-ионные связи, ядовитые соединения",
    compounds: [c("HgO", "оксид ртути(II)", "mercury(II) oxide", ""), c("HgS", "киноварь", "cinnabar", "руда ртути"),
      c("HgCl2", "хлорид ртути(II)", "mercury(II) chloride", "сулема, яд")],
    sources: [SRC.rsc + "element/80/mercury"] },
  Pb: { partners: ["O", "S", "Cl"], bond_character: "ковалентно-ионные связи",
    compounds: [c("PbO", "оксид свинца(II)", "lead(II) oxide", "глёт"), c("PbO2", "диоксид свинца", "lead(IV) oxide", "в аккумуляторах"),
      c("PbS", "галенит", "galena", "свинцовая руда"), c("PbSO4", "сульфат свинца", "lead(II) sulfate", "")],
    sources: [SRC.rsc + "element/82/lead"] },
  U: { partners: ["O", "F"], bond_character: "ковалентно-ионные связи",
    compounds: [c("UO2", "диоксид урана", "uranium dioxide", "ядерное топливо"), c("UF6", "гексафторид урана", "uranium hexafluoride", "обогащение"),
      c("U3O8", "оксид урана", "triuranium octoxide", "жёлтый кек")],
    sources: [SRC.rsc + "element/92/uranium"] },
};

// --- Загрузка базовых данных для эвристики ---
const elements = JSON.parse(readFileSync(join(WEB, "elements.json"), "utf8")).elements
  .filter(e => e.number <= 118).sort((a, b) => a.number - b.number);
const chi = new Map(elements.map(e => [e.symbol, e.electronegativity_pauling]));

// Типичные неметаллы-партнёры для эвристического fallback у металлов.
const COMMON_NONMETALS = ["O", "Cl", "F", "S", "N"];

function fallback(e) {
  const myChi = chi.get(e.symbol);
  const cat = e.category.toLowerCase();
  if (cat.includes("noble")) {
    return { partners: [], bond_character: "инертен, устойчивых соединений практически не образует", compounds: [], sources: [SRC.rsc] };
  }
  const isMetal = !/nonmetal|metalloid|halogen/.test(cat) && !(e.group === 17);
  let partners = [], bond;
  if (isMetal) {
    partners = COMMON_NONMETALS.slice();
    // Разница электроотрицательностей с кислородом как индикатор ионности.
    const dChi = myChi != null ? Math.abs(3.44 - myChi) : 2;
    bond = dChi > 1.7 ? "преимущественно ионные связи с неметаллами" : "ковалентно-ионные связи с неметаллами";
  } else {
    partners = ["H", "O", "Na", "K", "Ca"].filter(s => s !== e.symbol);
    bond = "ковалентные связи с неметаллами, ионные с активными металлами";
  }
  return { partners, bond_character: bond + " (выведено по электроотрицательности)", compounds: [], sources: [SRC.rsc, SRC.wiki(e.name.toLowerCase())] };
}

// --- Сборка и валидация ---
const symbols = new Set(elements.map(e => e.symbol));
const out = {};
let curatedCount = 0, fallbackCount = 0;

for (const e of elements) {
  let rec = CURATED[e.symbol];
  if (rec) curatedCount++; else { rec = fallback(e); fallbackCount++; }

  const partners = (rec.partners || []).filter(s => symbols.has(s) && s !== e.symbol);
  const compounds = (rec.compounds || []).filter(x => x.formula && x.formula.length).slice(0, 6);
  if (compounds.length > 6) throw new Error(`${e.symbol}: более 6 соединений`);

  out[e.symbol] = {
    partners,
    bond_character: rec.bond_character || "—",
    compounds,
    sources: rec.sources || [],
  };
}

writeFileSync(join(WEB, "compounds.json"), JSON.stringify(out, null, 2));
console.log(`compounds.json: ${Object.keys(out).length} элементов (вручную: ${curatedCount}, эвристика: ${fallbackCount}).`);
