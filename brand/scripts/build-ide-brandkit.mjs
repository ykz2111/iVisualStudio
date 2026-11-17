#!/usr/bin/env node
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const BRAND_ROOT = path.resolve(__dirname, "..");
const REPO_ROOT = path.resolve(BRAND_ROOT, "..");
const GROOVE_KIT_ROOT = path.resolve(REPO_ROOT, "../GROOVE-LABS-BRANDKIT");

function loadSharp() {
  const req = createRequire(import.meta.url);
  try {
    return req("sharp");
  } catch {}
  const candidates = [
    process.env.SHARP_SEARCH_PATH,
    path.join(os.tmpdir(), "opencode"),
    BRAND_ROOT,
    REPO_ROOT,
    GROOVE_KIT_ROOT,
    process.cwd(),
  ].filter(Boolean);
  for (const base of candidates) {
    try {
      return req(req.resolve("sharp", { paths: [base] }));
    } catch {}
  }
  throw new Error('Could not resolve "sharp".');
}

function encodeIco(entries) {
  const count = entries.length;
  const headerSize = 6 + count * 16;
  const header = Buffer.alloc(headerSize);
  header.writeUInt16LE(0, 0);
  header.writeUInt16LE(1, 2);
  header.writeUInt16LE(count, 4);

  let offset = headerSize;
  const chunks = [header];
  entries.forEach(({ size, png }, index) => {
    const pos = 6 + index * 16;
    const encodedSize = size >= 256 ? 0 : size;
    header.writeUInt8(encodedSize, pos);
    header.writeUInt8(encodedSize, pos + 1);
    header.writeUInt8(0, pos + 2);
    header.writeUInt8(0, pos + 3);
    header.writeUInt16LE(1, pos + 4);
    header.writeUInt16LE(32, pos + 6);
    header.writeUInt32LE(png.length, pos + 8);
    header.writeUInt32LE(offset, pos + 12);
    offset += png.length;
    chunks.push(png);
  });
  return Buffer.concat(chunks);
}

const SQUIRCLE_PATH =
  "M 320 0 H 704 C 836 0, 908 12, 960 64 C 1012 116, 1024 188, 1024 320 V 704 C 1024 836, 1012 908, 960 960 C 908 1012, 836 1024, 704 1024 H 320 C 188 1024, 116 1012, 64 960 C 12 908, 0 836, 0 704 V 320 C 0 188, 12 116, 64 64 C 116 12, 188 0, 320 0 Z";

const RIM_PATH =
  "M 320 3 H 704 C 834 3, 906 15, 957.5 66.5 C 1009 118, 1021 190, 1021 320 V 704 C 1021 834, 1009 906, 957.5 957.5 C 906 1009, 834 1021, 704 1021 H 320 C 190 1021, 118 1009, 66.5 957.5 C 15 906, 3 834, 3 704 V 320 C 3 190, 15 118, 66.5 66.5 C 118 15, 190 3, 320 3 Z";

// Pure-Vector Architectural Letter Library (Cap Height = 100, Stroke = 20)
const GLYPHS = {
  i: { w: 28, d: "M 4 0 H 24 V 20 H 4 Z M 4 32 H 24 V 100 H 4 Z" },
  I: { w: 36, d: "M 0 0 H 36 V 20 H 28 V 80 H 36 V 100 H 0 V 80 H 8 V 20 H 0 Z" },
  D: { w: 74, d: "M 0 0 H 54 L 74 20 V 80 L 54 100 H 0 Z M 20 20 V 80 H 52 V 20 Z" },
  E: { w: 66, d: "M 0 0 H 66 L 56 20 H 20 V 40 H 54 V 60 H 20 V 80 H 66 V 100 H 0 Z" },
  C: { w: 68, d: "M 14 0 H 68 L 58 20 H 20 V 80 H 58 L 68 100 H 14 L 0 86 V 14 Z" },
  O: { w: 74, d: "M 14 0 H 60 L 74 14 V 86 L 60 100 H 14 L 0 86 V 14 Z M 20 20 V 80 H 54 V 20 Z" },
  N: { w: 76, d: "M 0 0 H 20 L 56 64 V 0 H 76 V 100 H 56 L 20 36 V 100 H 0 Z" },
  P: { w: 70, d: "M 0 0 H 56 L 70 14 V 50 L 56 64 H 20 V 100 H 0 Z M 20 20 V 44 H 50 V 20 Z" },
  T: { w: 72, d: "M 0 0 H 72 L 62 20 H 46 V 100 H 26 V 20 H 0 Z" },
  M: { w: 86, d: "M 0 0 H 22 L 43 44 L 64 0 H 86 V 100 H 66 V 42 L 48 76 H 38 L 20 42 V 100 H 0 Z" },
  B: { w: 72, d: "M 0 0 H 56 L 70 14 V 42 L 58 50 L 72 60 V 86 L 58 100 H 0 Z M 20 18 V 41 H 50 V 18 Z M 20 59 V 82 H 52 V 59 Z" },
  L: { w: 64, d: "M 0 0 H 20 V 80 H 64 L 54 100 H 0 Z" },
  S: { w: 72, d: "M 12 0 H 70 L 60 20 H 20 V 40 L 60 46 L 72 58 V 88 L 60 100 H 2 L 12 80 H 52 V 60 L 12 54 L 0 42 V 12 Z" },
  "_": { w: 56, d: "M 0 84 H 56 V 100 H 0 Z" },
  " ": { w: 34, d: "" },
};

function renderVectorWord(text, gap = 12) {
  let x = 0;
  const parts = [];
  for (const ch of text) {
    const g = GLYPHS[ch];
    if (!g) throw new Error(`Unsupported glyph "${ch}" in "${text}"`);
    if (g.d) {
      const fillAttr = ch === "i" || ch === "_" ? ' fill="#14F1D9"' : "";
      parts.push(`<g transform="translate(${x}, 0)"${fillAttr}><path d="${g.d}"/></g>`);
    }
    x += g.w + gap;
  }
  return { svg: parts.join("\n      "), width: Math.max(0, x - gap) };
}

// ============================================================================
// iDE MASTER ICON (1024x1024)
// "Pocket VS Code Ribbon + Titanium iPhone Dynamic-Island Chassis"
// ============================================================================
function buildIdeMasterSvg() {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024" role="img" aria-labelledby="ideTitle ideDesc">
  <title id="ideTitle">iDE — Mobile Codespaces &amp; Cloud IDE for iOS</title>
  <desc id="ideDesc">Titanium-Ice iPhone chassis with an active Dynamic Island tunnel pill framing a folded Electric-Azure and Phosphor-Cyan Visual Studio Code geometric ribbon and thumb-zone command bar on a machined dark obsidian superellipse.</desc>

  <defs>
    <path id="squirclePath" d="${SQUIRCLE_PATH}"/>
    <clipPath id="tileClip"><use href="#squirclePath"/></clipPath>

    <radialGradient id="chassisBg" gradientUnits="userSpaceOnUse" cx="512" cy="220" r="900">
      <stop offset="0%"   stop-color="#132030"/>
      <stop offset="52%"  stop-color="#0A0F18"/>
      <stop offset="100%" stop-color="#04060A"/>
    </radialGradient>

    <radialGradient id="ideAmbient" gradientUnits="userSpaceOnUse" cx="520" cy="512" r="410">
      <stop offset="0%"   stop-color="#007ACC" stop-opacity="0.24"/>
      <stop offset="48%"  stop-color="#14F1D9" stop-opacity="0.12"/>
      <stop offset="100%" stop-color="#8B5CF6" stop-opacity="0"/>
    </radialGradient>

    <radialGradient id="gridFade" gradientUnits="userSpaceOnUse" cx="512" cy="512" r="460">
      <stop offset="0%"   stop-color="#FFFFFF" stop-opacity="1"/>
      <stop offset="65%"  stop-color="#FFFFFF" stop-opacity="0.4"/>
      <stop offset="100%" stop-color="#FFFFFF" stop-opacity="0"/>
    </radialGradient>
    <mask id="gridMask"><rect width="1024" height="1024" fill="url(#gridFade)"/></mask>

    <pattern id="instrumentGrid" width="64" height="64" patternUnits="userSpaceOnUse">
      <path d="M 64 0 H 0 V 64" fill="none" stroke="#7DD3FC" stroke-opacity="0.05" stroke-width="1"/>
    </pattern>

    <linearGradient id="titaniumPhone" gradientUnits="userSpaceOnUse" x1="512" y1="128" x2="512" y2="896">
      <stop offset="0%"   stop-color="#F7FBFE"/>
      <stop offset="55%"  stop-color="#DCE7F2"/>
      <stop offset="100%" stop-color="#B4C6D8"/>
    </linearGradient>

    <linearGradient id="vscodeAzure" gradientUnits="userSpaceOnUse" x1="340" y1="320" x2="720" y2="690">
      <stop offset="0%"   stop-color="#38BDF8"/>
      <stop offset="52%"  stop-color="#007ACC"/>
      <stop offset="100%" stop-color="#0284C7"/>
    </linearGradient>

    <linearGradient id="vscodeCyanBlade" gradientUnits="userSpaceOnUse" x1="340" y1="660" x2="720" y2="330">
      <stop offset="0%"   stop-color="#64FAE7"/>
      <stop offset="50%"  stop-color="#14F1D9"/>
      <stop offset="100%" stop-color="#0EA5E9"/>
    </linearGradient>

    <linearGradient id="bezelRim" gradientUnits="userSpaceOnUse" x1="512" y1="0" x2="512" y2="1024">
      <stop offset="0%"   stop-color="#E2F2FA" stop-opacity="0.24"/>
      <stop offset="50%"  stop-color="#38BDF8" stop-opacity="0.10"/>
      <stop offset="100%" stop-color="#14F1D9" stop-opacity="0.22"/>
    </linearGradient>

    <filter id="glyphShadow" filterUnits="userSpaceOnUse" x="0" y="0" width="1024" height="1024">
      <feDropShadow dx="0" dy="14" stdDeviation="15" flood-color="#020408" flood-opacity="0.68"/>
    </filter>
    <filter id="ribbonGlow" filterUnits="userSpaceOnUse" x="0" y="0" width="1024" height="1024">
      <feGaussianBlur stdDeviation="22"/>
    </filter>

    <!-- Titanium iPhone Handset Frame (Split Left/Right/Top/Bottom with Kerf Aperture for the Code Ribbon) -->
    <path id="phoneShell" fill-rule="evenodd" d="
      M 332 132 H 692 C 748 132, 780 164, 780 220 V 804 C 780 860, 748 892, 692 892 H 332 C 276 892, 244 860, 244 804 V 220 C 244 164, 276 132, 332 132 Z
      M 340 184 C 308 184, 296 196, 296 228 V 796 C 296 828, 308 840, 340 840 H 684 C 716 840, 728 828, 728 796 V 228 C 728 196, 716 184, 684 184 Z
    "/>

    <!-- Folded VS Code / iDE Geometric Ribbon (Breaking out of the screen with 3D depth) -->
    <!-- Lower-right descending ribbon + right vertical pillar -->
    <path id="ribbonBack" d="M 336 392 L 404 336 L 680 576 V 324 L 764 368 V 656 L 680 700 L 336 404 Z"/>
    <!-- Upper-right ascending Phosphor-Cyan hero blade -->
    <path id="ribbonFront" d="M 336 620 L 680 324 L 764 368 L 404 680 L 336 620 Z"/>
  </defs>

  <g id="iconRoot" clip-path="url(#tileClip)">
    <rect width="1024" height="1024" fill="url(#chassisBg)"/>
    <rect width="1024" height="1024" fill="url(#ideAmbient)"/>
    <rect width="1024" height="1024" fill="url(#instrumentGrid)" mask="url(#gridMask)"/>

    <g id="foregroundMark">
      <!-- Precision corner reticles -->
      <g stroke="#38BDF8" stroke-opacity="0.26" stroke-width="2" fill="none" stroke-linecap="square">
        <path d="M 148 184 V 160 H 172"/><path d="M 876 184 V 160 H 852"/>
        <path d="M 148 840 V 864 H 172"/><path d="M 876 840 V 864 H 852"/>
      </g>

      <!-- Inner OLED Screen Well -->
      <rect x="284" y="172" width="456" height="680" rx="56" fill="#060A10"/>

      <!-- Dynamic Island Live Codespace Tunnel Pill -->
      <rect x="424" y="212" width="176" height="36" rx="18" fill="#111A27" stroke="#14F1D9" stroke-opacity="0.55" stroke-width="2"/>
      <circle cx="452" cy="230" r="7" fill="#34D399"/>
      <circle cx="476" cy="230" r="7" fill="#14F1D9"/>
      <rect x="498" y="225" width="78" height="10" rx="5" fill="#38BDF8" fill-opacity="0.75"/>

      <!-- Subtle Code Lines in Screen Background -->
      <g fill="#38BDF8" fill-opacity="0.18">
        <rect x="336" y="284" width="96" height="12" rx="4"/>
        <rect x="336" y="308" width="148" height="10" rx="4"/>
        <rect x="336" y="704" width="164" height="10" rx="4"/>
        <rect x="516" y="704" width="112" height="10" rx="4" fill="#14F1D9" fill-opacity="0.32"/>
      </g>

      <!-- Titanium iPhone Bezel -->
      <g filter="url(#glyphShadow)">
        <use href="#phoneShell" fill="url(#titaniumPhone)"/>
      </g>

      <!-- Sub-surface glow behind the VS Code / iDE Ribbon -->
      <use href="#ribbonFront" fill="#14F1D9" opacity="0.34" filter="url(#ribbonGlow)"/>

      <!-- Folded VS Code / iDE Geometric Ribbon -->
      <g filter="url(#glyphShadow)">
        <use href="#ribbonBack" fill="url(#vscodeAzure)"/>
        <use href="#ribbonFront" fill="url(#vscodeCyanBlade)"/>
      </g>

      <!-- Left Touch-Cursor Pillar ('i' in iDE) -->
      <g filter="url(#glyphShadow)">
        <rect x="192" y="388" width="68" height="248" rx="20" fill="#14F1D9"/>
        <circle cx="226" cy="328" r="34" fill="#34D399"/>
      </g>

      <!-- Thumb-Zone Coding Key Pill Bar + iOS Home Indicator -->
      <g fill="#162234" stroke="#38BDF8" stroke-opacity="0.35" stroke-width="1.5">
        <rect x="332" y="742" width="76" height="36" rx="8"/>
        <rect x="422" y="742" width="76" height="36" rx="8"/>
        <rect x="512" y="742" width="76" height="36" rx="8"/>
        <rect x="602" y="742" width="88" height="36" rx="8" fill="#0B262A" stroke="#14F1D9" stroke-opacity="0.65"/>
      </g>
      <text x="370" y="765" text-anchor="middle" fill="#9BB0C5" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="16" font-weight="700">TAB</text>
      <text x="460" y="765" text-anchor="middle" fill="#64FAE7" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="16" font-weight="700">{ }</text>
      <text x="550" y="765" text-anchor="middle" fill="#38BDF8" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="16" font-weight="700">⌘P</text>
      <text x="646" y="765" text-anchor="middle" fill="#6EE7B7" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="16" font-weight="700">RUN ▶</text>

      <!-- iOS Home Indicator Bar -->
      <rect x="432" y="806" width="160" height="10" rx="5" fill="#F7FBFE" fill-opacity="0.65"/>
    </g>

    <path id="chassisRim" d="${RIM_PATH}" fill="none" stroke="url(#bezelRim)" stroke-width="3"/>
  </g>
</svg>`;
}

function buildIdeMicroSvg() {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024" role="img" aria-labelledby="ideMicroTitle">
  <title id="ideMicroTitle">iDE Icon (Optical Micro Master 16-32px)</title>
  <defs>
    <clipPath id="microClip"><rect x="0" y="0" width="1024" height="1024" rx="192"/></clipPath>
    <linearGradient id="microBg" gradientUnits="userSpaceOnUse" x1="512" y1="0" x2="512" y2="1024">
      <stop offset="0%" stop-color="#121E2E"/>
      <stop offset="100%" stop-color="#06090F"/>
    </linearGradient>
  </defs>
  <g clip-path="url(#microClip)">
    <rect width="1024" height="1024" fill="url(#microBg)"/>
    <!-- 64-unit pixel-snapped iPhone Frame + 'i' Touch Pillar + Code Ribbon -->
    <path fill="#F6FAFE" fill-rule="evenodd" d="M 256 128 H 768 V 896 H 256 Z M 320 192 V 832 H 704 V 192 Z"/>
    <!-- Left 'i' Touch Cursor Pillar -->
    <rect x="128" y="384" width="128" height="320" fill="#1CF5DC"/>
    <rect x="128" y="192" width="128" height="128" fill="#34D399"/>
    <!-- Folded Code Ribbon Inside Screen -->
    <path d="M 384 384 L 768 640 V 320 L 832 320 V 704 L 384 448 Z" fill="#38BDF8"/>
    <path d="M 384 640 L 768 320 H 832 L 448 704 Z" fill="#1CF5DC"/>
  </g>
</svg>`;
}

function buildIdeMonoSvg() {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024" role="img" aria-labelledby="ideMonoTitle">
  <title id="ideMonoTitle">iDE (Monochrome Stencil Glyph)</title>
  <g fill="currentColor" fill-rule="evenodd">
    <path d="M 332 132 H 692 C 748 132, 780 164, 780 220 V 804 C 780 860, 748 892, 692 892 H 332 C 276 892, 244 860, 244 804 V 220 C 244 164, 276 132, 332 132 Z M 340 184 C 308 184, 296 196, 296 228 V 796 C 296 828, 308 840, 340 840 H 684 C 716 840, 728 828, 728 796 V 228 C 728 196, 716 184, 684 184 Z"/>
    <rect x="424" y="212" width="176" height="36" rx="18"/>
    <rect x="192" y="388" width="68" height="248" rx="20"/>
    <circle cx="226" cy="328" r="34"/>
    <path d="M 336 620 L 680 324 L 764 368 V 656 L 680 700 L 336 404 L 404 336 L 680 576 V 420 L 404 680 Z"/>
    <rect x="432" y="806" width="160" height="12" rx="6"/>
  </g>
</svg>`;
}

const MINI_IDE_INNER = `
  <rect x="284" y="172" width="456" height="680" rx="56" fill="#060A10"/>
  <path fill="#F4F9FD" fill-rule="evenodd" d="M 332 132 H 692 C 748 132, 780 164, 780 220 V 804 C 780 860, 748 892, 692 892 H 332 C 276 892, 244 860, 244 804 V 220 C 244 164, 276 132, 332 132 Z M 340 184 C 308 184, 296 196, 296 228 V 796 C 296 828, 308 840, 340 840 H 684 C 716 840, 728 828, 728 796 V 228 C 728 196, 716 184, 684 184 Z"/>
  <rect x="424" y="212" width="176" height="36" rx="18" fill="#14F1D9"/>
  <path d="M 336 392 L 404 336 L 680 576 V 324 L 764 368 V 656 L 680 700 L 336 404 Z" fill="#007ACC"/>
  <path d="M 336 620 L 680 324 L 764 368 L 404 680 L 336 620 Z" fill="#14F1D9"/>
  <rect x="192" y="388" width="68" height="248" rx="20" fill="#14F1D9"/>
  <circle cx="226" cy="328" r="34" fill="#34D399"/>
`;

function buildWordmarkSvg({ lightMode = false, compact = false }) {
  const wm = renderVectorWord("iDE_CONCEPT", 12);
  if (compact) {
    return `<svg xmlns="http://www.w3.org/2000/svg" width="660" height="112" viewBox="0 0 660 112" role="img" aria-label="iDE Compact Navbar Lockup">
  <title>iDE — Compact Navbar Lockup</title>
  <g transform="translate(8, 8)">
    <rect width="96" height="96" rx="22" fill="#0B0F16" stroke="#38BDF8" stroke-opacity="0.36" stroke-width="1.5"/>
    <g transform="scale(0.09375)">${MINI_IDE_INNER}</g>
  </g>
  <g transform="translate(124, 28) scale(0.52)">
    <g fill="currentColor" fill-rule="evenodd">${wm.svg}</g>
  </g>
</svg>`;
  }

  const scale = 0.64;
  const ink = lightMode ? "#0B0F16" : "#F4F9FD";
  const subInk = lightMode ? "#475569" : "#8FA3B8";

  return `<svg xmlns="http://www.w3.org/2000/svg" width="960" height="220" viewBox="0 0 960 220" role="img" aria-label="iDE Brand Lockup">
  <title>iDE_CONCEPT — ${lightMode ? "Daylight" : "Dark"} Brand Lockup</title>
  <g transform="translate(24, 30)">
    <rect width="160" height="160" rx="36" fill="#0B0F16" stroke="#38BDF8" stroke-opacity="0.4" stroke-width="2"/>
    <g transform="scale(0.15625)">${MINI_IDE_INNER}</g>
  </g>
  <g transform="translate(216, 46)">
    <g transform="scale(${scale})" fill="${ink}" fill-rule="evenodd">${wm.svg}</g>
    <text x="2" y="108" fill="${subInk}" font-family="ui-monospace, SFMono-Regular, Menlo, Consolas, monospace" font-size="13.5" font-weight="600" letter-spacing="2.0">POCKET VS CODE, GITHUB CODESPACES &amp; CLOUD IDE FOR IOS // GROOVE LABS</text>
  </g>
</svg>`;
}

// ============================================================================
// OpenGraph (1200x630), Repo Banner (1280x360), Square Announcement (1080x1080)
// & App Store Vertical Poster (1080x1920)
// ============================================================================
function buildOgSvg() {
  const wm = renderVectorWord("iDE_CONCEPT", 12);
  return `<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630" viewBox="0 0 1200 630" role="img" aria-label="iDE — Visual Studio Code &amp; GitHub Codespaces on iPhone">
  <defs>
    <radialGradient id="idOgBg" gradientUnits="userSpaceOnUse" cx="380" cy="140" r="1050">
      <stop offset="0%"   stop-color="#132234"/>
      <stop offset="55%"  stop-color="#0A0F18"/>
      <stop offset="100%" stop-color="#04060A"/>
    </radialGradient>
    <radialGradient id="idOgGlow" gradientUnits="userSpaceOnUse" cx="920" cy="315" r="320">
      <stop offset="0%"   stop-color="#007ACC" stop-opacity="0.24"/>
      <stop offset="50%"  stop-color="#14F1D9" stop-opacity="0.10"/>
      <stop offset="100%" stop-color="#14F1D9" stop-opacity="0"/>
    </radialGradient>
    <pattern id="idOgGrid" width="48" height="48" patternUnits="userSpaceOnUse">
      <path d="M 48 0 H 0 V 48" fill="none" stroke="#7DD3FC" stroke-opacity="0.045" stroke-width="1"/>
    </pattern>
  </defs>

  <rect width="1200" height="630" fill="url(#idOgBg)"/>
  <rect width="1200" height="630" fill="url(#idOgGrid)"/>
  <rect width="1200" height="630" fill="url(#idOgGlow)"/>
  <rect x="36" y="36" width="1128" height="558" rx="18" fill="none" stroke="#38BDF8" stroke-opacity="0.22" stroke-width="1.5"/>

  <!-- Top Pill -->
  <g transform="translate(76, 78)">
    <rect width="412" height="34" rx="6" fill="#0E1724" stroke="#38BDF8" stroke-opacity="0.4"/>
    <circle cx="20" cy="17" r="4" fill="#34D399"/>
    <circle cx="34" cy="17" r="4" fill="#38BDF8"/>
    <circle cx="48" cy="17" r="4" fill="#FC6D26"/>
    <text x="64" y="21.5" fill="#CBD9E6" font-family="ui-monospace, SFMono-Regular, Menlo, Consolas, monospace" font-size="11.5" font-weight="600" letter-spacing="1.3">GROOVE LABS // YKZ21 · IOS HIG + THUMB-ZONE IDE</text>
  </g>

  <!-- Main Lockup -->
  <g transform="translate(76, 150)">
    <rect width="112" height="112" rx="25" fill="#080D14" stroke="#38BDF8" stroke-opacity="0.42" stroke-width="1.5"/>
    <g transform="scale(0.109375)">${MINI_IDE_INNER}</g>
    <g transform="translate(132, 14)">
      <g transform="scale(0.54)" fill="#F7FBFE" fill-rule="evenodd">${wm.svg}</g>
      <text x="2" y="84" fill="#38BDF8" font-family="ui-monospace, SFMono-Regular, Menlo, Consolas, monospace" font-size="14" font-weight="600" letter-spacing="2.2">VISUAL STUDIO CODE &amp; CODESPACES IN YOUR POCKET</text>
    </g>
  </g>

  <!-- Value Prop -->
  <text x="76" y="328" fill="#F4F9FD" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif" font-size="21.5" font-weight="600">Full Desktop IDE Power. Re-Engineered for One-Handed iOS Touch.</text>
  <text x="76" y="366" fill="#9BB0C5" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif" font-size="16.5">Connect instantaneously to GitHub Codespaces, OpenVSCode Server, SSH</text>
  <text x="76" y="392" fill="#9BB0C5" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif" font-size="16.5">DevContainers, JetBrains Gateway, and OpenCode agents with a 44pt+ thumb-zone</text>
  <text x="76" y="418" fill="#9BB0C5" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif" font-size="16.5">coding keyboard, Dynamic Island tunnel telemetry, and true-black OLED themes.</text>

  <!-- Feature Pills -->
  <g transform="translate(76, 488)" font-family="ui-monospace, SFMono-Regular, Menlo, Consolas, monospace" font-size="11" font-weight="600" letter-spacing="0.7">
    <rect x="0" y="0" width="194" height="32" rx="6" fill="#081813" stroke="#34D399" stroke-opacity="0.5"/>
    <text x="16" y="20" fill="#6EE7B7">● 44PT+ THUMB-ZONE BAR</text>

    <rect x="206" y="0" width="208" height="32" rx="6" fill="#091624" stroke="#38BDF8" stroke-opacity="0.5"/>
    <text x="222" y="20" fill="#7DD3FC">● CODESPACES + SSH + LSP</text>

    <rect x="426" y="0" width="198" height="32" rx="6" fill="#09161B" stroke="#14F1D9" stroke-opacity="0.5"/>
    <text x="442" y="20" fill="#7CF9E8">● OLED 0%-SMEAR DARK</text>
  </g>

  <!-- Right Column: iPhone 16 Pro Pocket VS Code Mockup -->
  <g transform="translate(772, 62)">
    <!-- iPhone Titanium Outer Frame -->
    <rect x="0" y="0" width="320" height="506" rx="44" fill="#1E293B" stroke="#94A3B8" stroke-opacity="0.45" stroke-width="3"/>
    <rect x="10" y="10" width="300" height="486" rx="36" fill="#05080E"/>

    <!-- Dynamic Island Live Tunnel Pill -->
    <rect x="92" y="22" width="136" height="24" rx="12" fill="#111926" stroke="#14F1D9" stroke-opacity="0.5"/>
    <circle cx="108" cy="34" r="4.5" fill="#34D399"/>
    <text x="120" y="38" fill="#64FAE7" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="9.5" font-weight="600">codespace · 14ms</text>

    <!-- File Tabs Bar -->
    <g transform="translate(18, 56)" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="10">
      <rect x="0" y="0" width="118" height="24" rx="5" fill="#0E1724" stroke="#38BDF8" stroke-opacity="0.5"/>
      <text x="10" y="15.5" fill="#F4F9FD">MobileIDE.swift</text>
      <rect x="124" y="0" width="104" height="24" rx="5" fill="#080D14"/>
      <text x="134" y="15.5" fill="#64748B">devcontainer</text>
    </g>

    <!-- Code Editor Viewport (SF Mono Syntax Highlighting) -->
    <g transform="translate(22, 96)" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="11">
      <text x="0"  y="14" fill="#475569">01</text><text x="24" y="14" fill="#C4B5FD">import</text><text x="72" y="14" fill="#7DD3FC">SwiftUI</text>
      <text x="0"  y="34" fill="#475569">02</text><text x="24" y="34" fill="#C4B5FD">import</text><text x="72" y="34" fill="#64FAE7">CodespaceKit</text>
      <text x="0"  y="58" fill="#475569">03</text><text x="24" y="58" fill="#38BDF8">struct</text><text x="72" y="58" fill="#F4F9FD">PocketWorkspace {</text>
      <text x="0"  y="78" fill="#475569">04</text><text x="38" y="78" fill="#7DD3FC">let</text><text x="66" y="78" fill="#F4F9FD">host =</text><text x="114" y="78" fill="#6EE7B7">"codespace://main"</text>
      <text x="0"  y="98" fill="#475569">05</text><text x="38" y="98" fill="#7DD3FC">let</text><text x="66" y="98" fill="#F4F9FD">hitTarget =</text><text x="148" y="98" fill="#FBBF24">48.0</text>
      <rect x="20" y="108" width="256" height="20" rx="4" fill="#007ACC" fill-opacity="0.22"/>
      <text x="0"  y="122" fill="#38BDF8">06</text><text x="38" y="122" fill="#64FAE7">func</text><text x="72" y="122" fill="#F4F9FD">attachLSP() async</text>
      <text x="0"  y="142" fill="#475569">07</text><text x="24" y="142" fill="#F4F9FD">}</text>
    </g>

    <!-- Pull-Up Integrated Terminal Mini Sheet -->
    <g transform="translate(18, 266)">
      <rect width="284" height="106" rx="10" fill="#0A101A" stroke="#94B8D0" stroke-opacity="0.22"/>
      <rect x="122" y="6" width="40" height="4" rx="2" fill="#475569"/>
      <text x="14" y="28" fill="#64FAE7" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="10" font-weight="600">TERMINAL · zsh (codespace-main)</text>
      <text x="14" y="50" fill="#9BB0C5" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="10">$ npm run typecheck &amp;&amp; pytest</text>
      <text x="14" y="68" fill="#6EE7B7" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="10">✓ 0 errors · LSP indexed in 38ms</text>
      <text x="14" y="88" fill="#38BDF8" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="10">● Port 3000 forwarded → iOS Preview</text>
    </g>

    <!-- Bottom Thumb-Zone Coding Accessory Bar (48pt Ergonomic Arc) -->
    <g transform="translate(18, 384)" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="10.5" font-weight="700">
      <rect x="0"   y="0" width="52" height="40" rx="8" fill="#131E2E" stroke="#38BDF8" stroke-opacity="0.4"/><text x="26"  y="24" text-anchor="middle" fill="#F4F9FD">TAB</text>
      <rect x="58"  y="0" width="52" height="40" rx="8" fill="#131E2E" stroke="#38BDF8" stroke-opacity="0.4"/><text x="84"  y="24" text-anchor="middle" fill="#64FAE7">{ }</text>
      <rect x="116" y="0" width="52" height="40" rx="8" fill="#131E2E" stroke="#38BDF8" stroke-opacity="0.4"/><text x="142" y="24" text-anchor="middle" fill="#C4B5FD">⌘P</text>
      <rect x="174" y="0" width="52" height="40" rx="8" fill="#131E2E" stroke="#38BDF8" stroke-opacity="0.4"/><text x="200" y="24" text-anchor="middle" fill="#FBBF24">=&gt;</text>
      <rect x="232" y="0" width="52" height="40" rx="8" fill="#092420" stroke="#34D399" stroke-opacity="0.7"/><text x="258" y="24" text-anchor="middle" fill="#6EE7B7">▶</text>
    </g>

    <!-- iOS Home Indicator -->
    <rect x="104" y="476" width="112" height="5" rx="2.5" fill="#94A3B8" fill-opacity="0.65"/>
  </g>
</svg>`;
}

function buildSquareAnnouncementSvg() {
  const wm = renderVectorWord("iDE_CONCEPT", 12);
  return `<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="1080" viewBox="0 0 1080 1080" role="img" aria-label="iDE Mobile Announcement Card (1080x1080)">
  <defs>
    <radialGradient id="sqBg" gradientUnits="userSpaceOnUse" cx="540" cy="360" r="900">
      <stop offset="0%"   stop-color="#142336"/>
      <stop offset="55%"  stop-color="#0A0F18"/>
      <stop offset="100%" stop-color="#04060A"/>
    </radialGradient>
    <pattern id="sqGrid" width="54" height="54" patternUnits="userSpaceOnUse">
      <path d="M 54 0 H 0 V 54" fill="none" stroke="#7DD3FC" stroke-opacity="0.045" stroke-width="1"/>
    </pattern>
  </defs>
  <rect width="1080" height="1080" fill="url(#sqBg)"/>
  <rect width="1080" height="1080" fill="url(#sqGrid)"/>
  <rect x="44" y="44" width="992" height="992" rx="28" fill="none" stroke="#38BDF8" stroke-opacity="0.25" stroke-width="2"/>

  <text x="540" y="114" text-anchor="middle" fill="#38BDF8" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="15" font-weight="600" letter-spacing="3.2">GROOVE LABS // YKZ21 · MOBILE CLOUD IDE FOR IOS</text>

  <!-- Center 340x340 Master Emblem -->
  <g transform="translate(370, 156)">
    <rect width="340" height="340" rx="76" fill="#080C12" stroke="#38BDF8" stroke-opacity="0.45" stroke-width="2.5"/>
    <g transform="scale(0.33203125)">${MINI_IDE_INNER}</g>
  </g>

  <g transform="translate(158, 548) scale(0.84)" fill="#F7FBFE" fill-rule="evenodd">
    ${wm.svg}
  </g>

  <text x="540" y="688" text-anchor="middle" fill="#DCE7F2" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif" font-size="27" font-weight="600">Visual Studio Code &amp; Codespaces in Your Thumb Zone.</text>

  <g transform="translate(110, 742)" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="14" font-weight="600">
    <rect x="0"   y="0" width="268" height="72" rx="10" fill="#0D1624" stroke="#38BDF8" stroke-opacity="0.5"/>
    <circle cx="28" cy="36" r="6" fill="#38BDF8"/><text x="48" y="41" fill="#F4F9FD">GitHub Codespaces</text>

    <rect x="296" y="0" width="268" height="72" rx="10" fill="#0D1624" stroke="#14F1D9" stroke-opacity="0.5"/>
    <circle cx="324" cy="36" r="6" fill="#14F1D9"/><text x="344" y="41" fill="#F4F9FD">OpenVSCode Server</text>

    <rect x="592" y="0" width="268" height="72" rx="10" fill="#0D1624" stroke="#A855F7" stroke-opacity="0.5"/>
    <circle cx="620" cy="36" r="6" fill="#A855F7"/><text x="640" y="41" fill="#F4F9FD">JetBrains Gateway</text>

    <rect x="0"   y="92" width="268" height="72" rx="10" fill="#0D1624" stroke="#34D399" stroke-opacity="0.5"/>
    <circle cx="28" cy="128" r="6" fill="#34D399"/><text x="48" y="133" fill="#F4F9FD">44pt+ Thumb Bar</text>

    <rect x="296" y="92" width="268" height="72" rx="10" fill="#0D1624" stroke="#FC6D26" stroke-opacity="0.5"/>
    <circle cx="324" cy="128" r="6" fill="#FC6D26"/><text x="344" y="133" fill="#F4F9FD">SSH DevContainers</text>

    <rect x="592" y="92" width="268" height="72" rx="10" fill="#0D1624" stroke="#FBBF24" stroke-opacity="0.5"/>
    <circle cx="620" cy="128" r="6" fill="#FBBF24"/><text x="640" y="133" fill="#F4F9FD">OLED True-Black</text>
  </g>

  <text x="540" y="982" text-anchor="middle" fill="#8FA3B8" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="14" letter-spacing="2">GITLAB.COM/YKZ2111/IDE_CONCEPT // GROOVE LABS</text>
</svg>`;
}

function buildRepoBannerSvg(lightMode = false) {
  const wm = renderVectorWord("iDE_CONCEPT", 12);
  const bg = lightMode ? "#F4F7FA" : "#0A0F18";
  const fg = lightMode ? "#0B0F16" : "#F4F9FD";
  const sub = lightMode ? "#334155" : "#9BB0C5";
  const border = lightMode ? "rgba(15,23,42,0.14)" : "rgba(56,189,248,0.22)";
  return `<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="360" viewBox="0 0 1280 360" role="img" aria-label="iDE_CONCEPT Repository Banner">
  <rect width="1280" height="360" rx="18" fill="${bg}"/>
  <rect x="1" y="1" width="1278" height="358" rx="17" fill="none" stroke="${border}" stroke-width="2"/>

  <g transform="translate(56, 54)">
    <rect width="108" height="108" rx="24" fill="#080D14" stroke="#38BDF8" stroke-opacity="0.45" stroke-width="1.5"/>
    <g transform="scale(0.10546875)">${MINI_IDE_INNER}</g>
    <g transform="translate(132, 12)">
      <g transform="scale(0.52)" fill="${fg}" fill-rule="evenodd">${wm.svg}</g>
      <text x="2" y="82" fill="${lightMode ? "#0284C7" : "#38BDF8"}" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="13.5" font-weight="600" letter-spacing="2.1">POCKET VS CODE, GITHUB CODESPACES &amp; CLOUD IDE FOR IOS // GROOVE LABS</text>
    </g>
  </g>

  <text x="56" y="216" fill="${fg}" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif" font-size="19.5" font-weight="600">Full Visual Studio Code &amp; Remote DevContainers Re-Engineered for iPhone Touch</text>
  <text x="56" y="246" fill="${sub}" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif" font-size="15.5">44pt+ thumb-zone coding keyboard, Dynamic Island live tunnel status, SF Mono Dynamic Type, and OLED true-black themes.</text>

  <g transform="translate(56, 284)" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="11.5" font-weight="600" fill="${sub}">
    <circle cx="6" cy="-4" r="4" fill="#38BDF8"/><text x="18" y="0">CODESPACES</text>
    <circle cx="136" cy="-4" r="4" fill="#14F1D9"/><text x="148" y="0">OPENVSCODE</text>
    <circle cx="272" cy="-4" r="4" fill="#A855F7"/><text x="284" y="0">SSH + DEVCONTAINERS</text>
    <circle cx="468" cy="-4" r="4" fill="#34D399"/><text x="480" y="0">44PT+ THUMB ZONE</text>
    <circle cx="644" cy="-4" r="4" fill="#FC6D26"/><text x="656" y="0">OLED 0% SMEAR</text>
  </g>

  <!-- Right Mini Handset Telemetry Card -->
  <g transform="translate(932, 42)">
    <rect width="292" height="276" rx="18" fill="#080D14" stroke="#38BDF8" stroke-opacity="0.36" stroke-width="1.5"/>
    <rect x="86" y="14" width="120" height="20" rx="10" fill="#111A27" stroke="#14F1D9" stroke-opacity="0.5"/>
    <circle cx="100" cy="24" r="4" fill="#34D399"/>
    <text x="112" y="28" fill="#64FAE7" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="9" font-weight="600">codespace · 14ms</text>
    <g transform="translate(22, 52)" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="10.5">
      <text x="0" y="16" fill="#C4B5FD">await</text><text x="42" y="16" fill="#64FAE7">codespace.connect</text><text x="164" y="16" fill="#F4F9FD">()</text>
      <text x="0" y="36" fill="#7DD3FC">lsp.attach</text><text x="72" y="36" fill="#6EE7B7">("typescript, swift")</text>
      <text x="0" y="56" fill="#38BDF8">ui.thumbBar</text><text x="82" y="56" fill="#FBBF24">(minHitPt: 48)</text>
    </g>
    <g transform="translate(20, 148)" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="10" font-weight="700">
      <rect x="0"   y="0" width="56" height="36" rx="6" fill="#131E2E" stroke="#38BDF8" stroke-opacity="0.4"/><text x="28"  y="22" text-anchor="middle" fill="#F4F9FD">TAB</text>
      <rect x="64"  y="0" width="56" height="36" rx="6" fill="#131E2E" stroke="#38BDF8" stroke-opacity="0.4"/><text x="92"  y="22" text-anchor="middle" fill="#64FAE7">{ }</text>
      <rect x="128" y="0" width="56" height="36" rx="6" fill="#131E2E" stroke="#38BDF8" stroke-opacity="0.4"/><text x="156" y="22" text-anchor="middle" fill="#C4B5FD">⌘P</text>
      <rect x="192" y="0" width="60" height="36" rx="6" fill="#092420" stroke="#34D399" stroke-opacity="0.6"/><text x="222" y="22" text-anchor="middle" fill="#6EE7B7">RUN</text>
    </g>
    <text x="22" y="218" fill="#6EE7B7" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="11" font-weight="600">● IOS 18+ HIG · DYNAMIC TYPE</text>
    <text x="22" y="242" fill="#8FA3B8" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="10.5">GITLAB.COM/YKZ2111/IDE_CONCEPT</text>
  </g>
</svg>`;
}

function buildWorkspaceBgSvg() {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="3840" height="2160" viewBox="0 0 3840 2160" role="img" aria-label="iDE 4K Workspace &amp; Codespace Wallpaper">
  <defs>
    <radialGradient id="wsBg" gradientUnits="userSpaceOnUse" cx="1920" cy="960" r="2400">
      <stop offset="0%"   stop-color="#111E2E"/>
      <stop offset="52%"  stop-color="#090E17"/>
      <stop offset="100%" stop-color="#030508"/>
    </radialGradient>
    <radialGradient id="wsAura" gradientUnits="userSpaceOnUse" cx="1920" cy="1080" r="1100">
      <stop offset="0%"   stop-color="#007ACC" stop-opacity="0.14"/>
      <stop offset="50%"  stop-color="#14F1D9" stop-opacity="0.05"/>
      <stop offset="100%" stop-color="#14F1D9" stop-opacity="0"/>
    </radialGradient>
    <pattern id="wsMinor" width="64" height="64" patternUnits="userSpaceOnUse">
      <path d="M 64 0 H 0 V 64" fill="none" stroke="#7DD3FC" stroke-opacity="0.032" stroke-width="1"/>
    </pattern>
    <pattern id="wsMajor" width="320" height="320" patternUnits="userSpaceOnUse">
      <path d="M 320 0 H 0 V 320" fill="none" stroke="#7DD3FC" stroke-opacity="0.065" stroke-width="1.5"/>
      <circle cx="320" cy="320" r="2.5" fill="#38BDF8" fill-opacity="0.24"/>
    </pattern>
  </defs>
  <rect width="3840" height="2160" fill="url(#wsBg)"/>
  <rect width="3840" height="2160" fill="url(#wsAura)"/>
  <rect width="3840" height="2160" fill="url(#wsMinor)"/>
  <rect width="3840" height="2160" fill="url(#wsMajor)"/>
  <g transform="translate(2620, 480) scale(1.1)" opacity="0.04">${MINI_IDE_INNER}</g>
  <g stroke="#38BDF8" stroke-opacity="0.26" stroke-width="3" fill="none" stroke-linecap="square">
    <path d="M 128 176 V 128 H 176"/><path d="M 3712 176 V 128 H 3664"/>
    <path d="M 128 1984 V 2032 H 176"/><path d="M 3712 1984 V 2032 H 3664"/>
  </g>
  <g fill="#697E94" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="18" letter-spacing="2.4">
    <text x="200" y="156">GROOVE LABS // iDE_CONCEPT · POCKET VS CODE &amp; CODESPACES FOR IOS</text>
    <text x="3100" y="156">44PT THUMB ZONE · OLED TRUE-BLACK</text>
    <text x="200" y="2018">YKZ21 · GITLAB.COM/YKZ2111/IDE_CONCEPT</text>
    <text x="3390" y="2018">3840 × 2160 · 4K</text>
  </g>
</svg>`;
}

function buildIosWallpaperSvg() {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="1179" height="2556" viewBox="0 0 1179 2556" role="img" aria-label="iDE iPhone OLED Lock Screen Wallpaper (1179x2556)">
  <defs>
    <radialGradient id="ipBg" gradientUnits="userSpaceOnUse" cx="590" cy="1278" r="1400">
      <stop offset="0%"   stop-color="#0E1B2A"/>
      <stop offset="50%"  stop-color="#05080E"/>
      <stop offset="100%" stop-color="#000000"/>
    </radialGradient>
    <pattern id="ipGrid" width="64" height="64" patternUnits="userSpaceOnUse">
      <path d="M 64 0 H 0 V 64" fill="none" stroke="#38BDF8" stroke-opacity="0.04" stroke-width="1"/>
    </pattern>
  </defs>
  <rect width="1179" height="2556" fill="url(#ipBg)"/>
  <rect width="1179" height="2556" fill="url(#ipGrid)"/>
  <g transform="translate(282, 970) scale(0.6)" opacity="0.16">${MINI_IDE_INNER}</g>
  <text x="590" y="2420" text-anchor="middle" fill="#38BDF8" fill-opacity="0.45" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="18" letter-spacing="4">GROOVE LABS // iDE MOBILE</text>
</svg>`;
}

async function main() {
  const sharp = loadSharp();

  const masterSvg = buildIdeMasterSvg();
  const microSvg = buildIdeMicroSvg();
  const monoSvg = buildIdeMonoSvg();
  const wmDark = buildWordmarkSvg({ lightMode: false });
  const wmLight = buildWordmarkSvg({ lightMode: true });
  const wmCompact = buildWordmarkSvg({ compact: true });
  const ogSvg = buildOgSvg();
  const sqSvg = buildSquareAnnouncementSvg();
  const bannerDark = buildRepoBannerSvg(false);
  const bannerLight = buildRepoBannerSvg(true);
  const wsBg = buildWorkspaceBgSvg();
  const iosWall = buildIosWallpaperSvg();

  const unclipped = masterSvg.replace(' clip-path="url(#tileClip)"', "");
  const fullBleedSvg = unclipped.replace(/<path\s+id="chassisRim"[\s\S]*?\/>/, "");
  const maskableSvg = fullBleedSvg.replace(
    '<g id="foregroundMark">',
    '<g id="foregroundMark" transform="translate(512 512) scale(0.76) translate(-512 -512)">',
  );

  const dirs = [BRAND_ROOT, path.join(GROOVE_KIT_ROOT, "ide-concept")];
  for (const outDir of dirs) {
    fs.mkdirSync(path.join(outDir, "backgrounds"), { recursive: true });
    fs.mkdirSync(path.join(outDir, "badges"), { recursive: true });
    fs.mkdirSync(path.join(outDir, "ios", "AppIcon.appiconset"), { recursive: true });

    fs.writeFileSync(path.join(outDir, "ide-icon.svg"), masterSvg);
    fs.writeFileSync(path.join(outDir, "ide-icon-micro.svg"), microSvg);
    fs.writeFileSync(path.join(outDir, "ide-icon-mono.svg"), monoSvg);
    fs.writeFileSync(path.join(outDir, "ide-wordmark-dark.svg"), wmDark);
    fs.writeFileSync(path.join(outDir, "ide-wordmark-light.svg"), wmLight);
    fs.writeFileSync(path.join(outDir, "ide-wordmark-compact.svg"), wmCompact);
    fs.writeFileSync(path.join(outDir, "og-image.svg"), ogSvg);
    fs.writeFileSync(path.join(outDir, "social-announcement-square.svg"), sqSvg);
    fs.writeFileSync(path.join(outDir, "repo-banner-dark.svg"), bannerDark);
    fs.writeFileSync(path.join(outDir, "repo-banner-light.svg"), bannerLight);
    fs.writeFileSync(path.join(outDir, "backgrounds", "ide-workspace-bg-dark.svg"), wsBg);
    fs.writeFileSync(path.join(outDir, "backgrounds", "ide-ios-wallpaper.svg"), iosWall);

    // Squircle PNGs 1024..64
    for (const s of [1024, 512, 256, 128, 64]) {
      await sharp(Buffer.from(masterSvg), { density: 300 })
        .resize(s, s, { kernel: sharp.kernel.lanczos3 })
        .png({ compressionLevel: 9 })
        .toFile(path.join(outDir, `ide-icon-${s}.png`));
    }

    // Micro PNGs 32 & 16 + favicon.ico
    const icoFrames = [];
    for (const s of [32, 16]) {
      const sized = microSvg.replace('width="1024" height="1024"', `width="${s}" height="${s}"`);
      const png = await sharp(Buffer.from(sized), { density: 72 }).png({ compressionLevel: 9 }).toBuffer();
      fs.writeFileSync(path.join(outDir, `ide-icon-${s}.png`), png);
      icoFrames.push({ size: s, png });
    }
    fs.writeFileSync(path.join(outDir, "favicon.ico"), encodeIco(icoFrames.sort((a, b) => a.size - b.size)));

    // Full-bleed & Maskable 24-bit RGB PNGs (for iOS AppIcon.appiconset & PWA)
    for (const { file, size, svg } of [
      { file: "apple-touch-icon.png", size: 180, svg: fullBleedSvg },
      { file: "icon-192.png", size: 192, svg: fullBleedSvg },
      { file: "icon-512.png", size: 512, svg: fullBleedSvg },
      { file: "icon-512-maskable.png", size: 512, svg: maskableSvg },
    ]) {
      await sharp(Buffer.from(svg), { density: 300 })
        .resize(size, size, { kernel: sharp.kernel.lanczos3 })
        .flatten({ background: "#04060A" })
        .png({ compressionLevel: 9 })
        .toFile(path.join(outDir, file));
    }

    // Complete Xcode iOS AppIcon.appiconset (24-bit RGB opaque PNGs per Apple HIG)
    const iosSizes = [1024, 180, 167, 152, 120, 87, 80, 60, 58, 40];
    for (const s of iosSizes) {
      await sharp(Buffer.from(fullBleedSvg), { density: 300 })
        .resize(s, s, { kernel: sharp.kernel.lanczos3 })
        .flatten({ background: "#04060A" })
        .png({ compressionLevel: 9 })
        .toFile(path.join(outDir, "ios", "AppIcon.appiconset", `AppIcon-${s}.png`));
    }
    fs.writeFileSync(
      path.join(outDir, "ios", "AppIcon.appiconset", "Contents.json"),
      JSON.stringify(
        {
          images: [
            { idiom: "universal", platform: "ios", size: "1024x1024", filename: "AppIcon-1024.png" },
            { idiom: "iphone", scale: "3x", size: "60x60", filename: "AppIcon-180.png" },
            { idiom: "iphone", scale: "2x", size: "60x60", filename: "AppIcon-120.png" },
            { idiom: "ipad", scale: "2x", size: "83.5x83.5", filename: "AppIcon-167.png" },
            { idiom: "ipad", scale: "2x", size: "76x76", filename: "AppIcon-152.png" },
          ],
          info: { author: "xcode", version: 1 },
        },
        null,
        2,
      ) + "\n",
    );

    // Social, Repo & Background PNGs
    await sharp(Buffer.from(ogSvg), { density: 192 })
      .resize(1200, 630, { kernel: sharp.kernel.lanczos3 })
      .flatten({ background: "#04060A" })
      .png({ compressionLevel: 9 })
      .toFile(path.join(outDir, "og-image.png"));

    await sharp(Buffer.from(sqSvg), { density: 192 })
      .resize(1080, 1080, { kernel: sharp.kernel.lanczos3 })
      .flatten({ background: "#04060A" })
      .png({ compressionLevel: 9 })
      .toFile(path.join(outDir, "social-announcement-square.png"));

    await sharp(Buffer.from(bannerDark), { density: 192 })
      .resize(1280, 360, { kernel: sharp.kernel.lanczos3 })
      .png({ compressionLevel: 9 })
      .toFile(path.join(outDir, "repo-banner.png"));

    await sharp(Buffer.from(wsBg), { density: 144 })
      .resize(1920, 1080, { kernel: sharp.kernel.lanczos3 })
      .flatten({ background: "#030508" })
      .png({ compressionLevel: 9 })
      .toFile(path.join(outDir, "backgrounds", "ide-workspace-bg-fhd.png"));

    await sharp(Buffer.from(wsBg), { density: 144 })
      .resize(3840, 2160, { kernel: sharp.kernel.lanczos3 })
      .flatten({ background: "#030508" })
      .png({ compressionLevel: 9 })
      .toFile(path.join(outDir, "backgrounds", "ide-workspace-bg-4k.png"));

    await sharp(Buffer.from(iosWall), { density: 144 })
      .resize(1179, 2556, { kernel: sharp.kernel.lanczos3 })
      .flatten({ background: "#000000" })
      .png({ compressionLevel: 9 })
      .toFile(path.join(outDir, "backgrounds", "ide-ios-wallpaper.png"));

    // Badges
    const badges = [
      { file: "ios-testflight.svg", w: 198, bg: "#091524", stroke: "#38BDF8", fg: "#7DD3FC", label: "iOS 18+ · HIG NATIVE" },
      { file: "codespaces-ready.svg", w: 224, bg: "#091519", stroke: "#14F1D9", fg: "#7CF9E8", label: "CODESPACES + OPENVSCODE" },
      { file: "thumb-zone-ergonomics.svg", w: 214, bg: "#081611", stroke: "#34D399", fg: "#6EE7B7", label: "44PT+ THUMB-ZONE UX" },
      { file: "oled-zero-smear.svg", w: 204, bg: "#101324", stroke: "#8B5CF6", fg: "#C4B5FD", label: "OLED TRUE-BLACK · 60FPS" },
    ];
    for (const b of badges) {
      fs.writeFileSync(
        path.join(outDir, "badges", b.file),
        `<svg xmlns="http://www.w3.org/2000/svg" width="${b.w}" height="26" viewBox="0 0 ${b.w} 26" role="img" aria-label="${b.label}">
  <rect x="0.5" y="0.5" width="${b.w - 1}" height="25" rx="5" fill="${b.bg}" stroke="${b.stroke}" stroke-opacity="0.48"/>
  <circle cx="14" cy="13" r="3.5" fill="${b.stroke}"/>
  <text x="25" y="16.8" fill="${b.fg}" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="11" font-weight="600" letter-spacing="0.7">${b.label}</text>
</svg>\n`,
      );
    }

    // @ui-design-system & @mobile-design Tokens (CSS + DTCG JSON)
    fs.writeFileSync(
      path.join(outDir, "tokens.css"),
      `/**
 * iDE (ide_concept) — @ui-design-system & @mobile-design Tokens
 * Built for iOS OLED displays, 44pt/48pt Fitts' Law touch targets, and SF Pro / SF Mono Dynamic Type.
 */
:root {
  /* OLED & Machined Obsidian Surfaces (Battery-Conscious Dark Default) */
  --ide-bg-oled-true: #000000;
  --ide-bg-canvas: #05080E;
  --ide-bg-chassis: #0A0F18;
  --ide-bg-elevated: #111926;
  --ide-bg-thumb-bar: #131E2E;

  /* Semantic Inks (WCAG AAA > 11:1 on #05080E) */
  --ide-ink-primary: #F4F9FD;
  --ide-ink-secondary: #9BB0C5;
  --ide-ink-muted: #64748B;

  /* Brand & IDE Signals */
  --ide-signal-azure: #38BDF8;
  --ide-signal-vscode: #007ACC;
  --ide-signal-cyan: #14F1D9;
  --ide-signal-emerald: #34D399;
  --ide-signal-violet: #A855F7;
  --ide-signal-amber: #FBBF24;
  --ide-signal-coral: #FC6D26;

  /* iOS HIG Touch & Safe-Area Ergonomics (@mobile-design) */
  --ide-hit-min-ios: 44px;
  --ide-hit-recommended: 48px;
  --ide-hit-gap-min: 8px;
  --ide-safe-top-island: 59px;
  --ide-safe-bottom-home: 34px;

  /* 8pt Spatial Grid (@ui-design-system) */
  --ide-space-1: 4px;
  --ide-space-2: 8px;
  --ide-space-3: 12px;
  --ide-space-4: 16px;
  --ide-space-6: 24px;
  --ide-space-8: 32px;

  /* iOS Dynamic Type Scale (SF Pro & SF Mono) */
  --ide-font-sans: "SF Pro Text", "SF Pro Display", -apple-system, BlinkMacSystemFont, sans-serif;
  --ide-font-mono: "SF Mono", "JetBrains Mono", ui-monospace, Menlo, monospace;
  --ide-type-large-title: 34px;
  --ide-type-title-1: 28px;
  --ide-type-title-2: 22px;
  --ide-type-headline: 17px;
  --ide-type-body: 17px;
  --ide-type-code: 13.5px;
  --ide-type-caption: 12px;
}\n`,
    );

    fs.writeFileSync(
      path.join(outDir, "design-tokens.json"),
      JSON.stringify(
        {
          $schema: "https://tr.designtokens.org/format/",
          meta: {
            project: "iDE (ide_concept)",
            organization: "Groove Labs // YkZ21",
            platform: "iOS 18+ (iPhone & iPad)",
            skillsApplied: ["ui-design-system", "mobile-design", "claude-design"],
          },
          ergonomics: {
            minTouchTargetPt: 44,
            recommendedTouchTargetPt: 48,
            minTargetGapPt: 8,
            primaryThumbZone: "bottom-arc-35-percent",
            haptics: {
              keyTap: "UIImpactFeedbackGenerator(.light)",
              commandRun: "UIImpactFeedbackGenerator(.medium)",
              buildSuccess: "UINotificationFeedbackGenerator(.success)",
            },
          },
          color: {
            oledTrueBlack: "#000000",
            obsidianCanvas: "#05080E",
            elevatedSurface: "#111926",
            vscodeAzure: "#007ACC",
            electricSky: "#38BDF8",
            phosphorCyan: "#14F1D9",
            safeEmerald: "#34D399",
            irisViolet: "#A855F7",
          },
        },
        null,
        2,
      ) + "\n",
    );

    fs.writeFileSync(
      path.join(outDir, "site.webmanifest"),
      JSON.stringify(
        {
          name: "iDE — Pocket VS Code & Codespaces for iOS",
          short_name: "iDE",
          description: "Mobile iOS IDE for GitHub Codespaces, OpenVSCode Server, SSH DevContainers, and OpenCode agents.",
          start_url: "./",
          scope: "./",
          display: "standalone",
          background_color: "#05080E",
          theme_color: "#05080E",
          icons: [
            { src: "./icon-192.png", sizes: "192x192", type: "image/png", purpose: "any" },
            { src: "./icon-512.png", sizes: "512x512", type: "image/png", purpose: "any" },
            { src: "./icon-512-maskable.png", sizes: "512x512", type: "image/png", purpose: "maskable" },
          ],
        },
        null,
        2,
      ) + "\n",
    );
  }

  console.log("Built iDE_CONCEPT full identity pack in", BRAND_ROOT);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
