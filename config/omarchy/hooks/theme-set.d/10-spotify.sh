#!/bin/bash
# miroir guard: Omarchy <4.0 runs theme-set.d twice — once via the dispatcher
# (helpers + colors exported), once bare via omarchy-hook. Skip the bare pass.
[ -n "${primary_background:-}" ] || exit 0

# ---------------------------------------------------------------------------
# Miroir · Spotify (spicetify) — thème + modes d'interface
#
# Génère 3 fichiers dans Themes/omarchy/ :
#   color.ini  — palette dérivée du thème Omarchy actif (accent = color5)
#   user.css   — base stylée + 4 personnalités (hack/grimoire/void/shinkai)
#                + 3 modes togglables (zen / ambience / vinyl)
#   theme.js   — moteur des modes : boutons playbar, raccourcis Ctrl+Alt+Z/A/V,
#                glow ambiant extrait de la pochette, persistance localStorage
#
# La personnalité est choisie par le NOM du thème (theme.name) ; les couleurs
# par sa palette. Tout est piloté par --spice-* et --miroir-*, donc un switch
# de thème Omarchy re-skinne Spotify intégralement.
#
# Test d'une autre personnalité sans changer de thème desktop :
#   MIROIR_SPOTIFY_THEME_OVERRIDE=miroir-hack (+ exports palette) bash 10-spotify.sh
# ---------------------------------------------------------------------------

THEME_DIR="$HOME/.config/spicetify/Themes/omarchy"

THEME_NAME="${MIROIR_SPOTIFY_THEME_OVERRIDE:-$(tr -d '[:space:]' < "$HOME/.config/omarchy/current/theme.name" 2>/dev/null)}"
[ -n "$THEME_NAME" ] || THEME_NAME="miroir-void"

create_dynamic_theme() {
    bg=${primary_background}          # deep base
    elevated=${normal_black}          # color0 — slightly lifted from bg
    hover=${bright_black}             # color8 — hover surface
    text=${primary_foreground}
    muted=${normal_white}             # color7 — secondary text
    accent=${normal_magenta}          # color5 — the theme accent (violet/magenta)
    danger=${normal_red}

cat > "$THEME_DIR/color.ini" << EOF
[base]
main                = ${bg}
player              = ${bg}
sidebar             = ${bg}
shadow              = ${bg}
card                = ${elevated}
main-elevated       = ${elevated}
notification        = ${elevated}
highlight           = ${hover}
highlight-elevated  = ${hover}
button              = ${accent}
button-active       = ${accent}
tab-active          = ${accent}
selected-row        = ${accent}
equalizer           = ${accent}
button-disabled     = ${hover}
misc                = ${hover}
notification-error  = ${danger}
subtext             = ${muted}
text                = ${text}
EOF
}

create_spicetify_styling() {
    mkdir -p "$THEME_DIR"

# --- 1. Palette étendue (générée, hex réels du thème) ----------------------
cat > "$THEME_DIR/user.css" << EOF
/* Miroir — généré par 10-spotify.sh pour le thème: ${THEME_NAME} */
:root {
    --miroir-radius: 12px;
    --miroir-radius-sm: 8px;
    --miroir-gap: 8px;
    --miroir-bg: #${primary_background};
    --miroir-fg: #${primary_foreground};
    --miroir-black: #${normal_black};
    --miroir-gray: #${bright_black};
    --miroir-red: #${normal_red};
    --miroir-green: #${normal_green};
    --miroir-yellow: #${normal_yellow};
    --miroir-blue: #${normal_blue};
    --miroir-accent: #${normal_magenta};
    --miroir-cyan: #${normal_cyan};
    --miroir-bright-yellow: #${bright_yellow};
    --miroir-bright-magenta: #${bright_magenta};
    --miroir-bright-cyan: #${bright_cyan};
}
EOF

# --- 2. Feuille statique (pas d'expansion shell ici) -----------------------
cat >> "$THEME_DIR/user.css" << 'CSSEOF'

/* ===========================================================================
   BASE — surfaces, arrondis, accents (suit --spice-* quel que soit le thème)
   =========================================================================== */

.main-entityHeader-backgroundColor,
.main-actionBarBackground-background,
.main-home-homeHeader,
.main-topBar-background {
    background: transparent !important;
}
.main-entityHeader-background,
.main-entityHeader-headerDefault { background: transparent !important; }

.main-view-container__scroll-node-child,
.main-yourLibraryX-libraryRootlist,
.Root__right-sidebar > *,
.main-buddyFeed-content {
    border-radius: var(--miroir-radius);
}

.Root__nav-bar .main-yourLibraryX-libraryContainer,
.Root__right-sidebar aside {
    background-color: var(--spice-sidebar) !important;
    border: 1px solid rgba(var(--spice-rgb-button), 0.10);
    border-radius: var(--miroir-radius);
}

.main-card-card,
.main-card-cardContainer,
[data-encore-id="card"] {
    border-radius: var(--miroir-radius) !important;
    background-color: var(--spice-card) !important;
    transition: transform .18s ease, box-shadow .18s ease, background-color .18s ease;
}
.main-card-card:hover,
.main-card-cardContainer:hover,
[data-encore-id="card"]:hover {
    transform: translateY(-4px);
    background-color: var(--spice-highlight-elevated, var(--spice-card)) !important;
    box-shadow: 0 8px 24px -6px rgba(var(--spice-rgb-button), 0.45);
}

.main-image-image,
.main-cardImage-image,
.main-entityHeader-imageContainer img,
.main-trackList-rowImage,
.cover-art,
.main-nowPlayingWidget-coverArt .cover-art {
    border-radius: var(--miroir-radius-sm) !important;
}

.main-nowPlayingBar-container {
    background-color: var(--spice-card) !important;
    border-radius: var(--miroir-radius);
    border: 1px solid rgba(var(--spice-rgb-button), 0.14);
    margin: 0 var(--miroir-gap) var(--miroir-gap);
    padding: 0.35rem 0.6rem;
    box-shadow: 0 6px 20px -10px rgba(0, 0, 0, 0.6);
}

.playback-bar .progress-bar__fg,
.progress-bar__fg,
.x-progressBar-fillColor,
.volume-bar__slider-container .progress-bar__fg {
    background-color: var(--spice-button) !important;
    box-shadow: 0 0 8px -1px rgba(var(--spice-rgb-button), 0.7);
}
.progress-bar__slider,
.x-progressBar-sliderArea .progress-bar__slider {
    background-color: var(--spice-button) !important;
    box-shadow: 0 0 6px rgba(var(--spice-rgb-button), 0.9);
}

.main-playButton-PlayButton button,
.main-playPauseButton-button,
button[data-testid="control-button-playpause"] {
    background-color: var(--spice-button) !important;
    color: var(--spice-main) !important;
    transition: transform .15s ease, box-shadow .15s ease;
}
.main-playButton-PlayButton button:hover,
.main-playPauseButton-button:hover {
    transform: scale(1.06);
    box-shadow: 0 0 16px -2px rgba(var(--spice-rgb-button), 0.75);
}

.main-yourLibraryX-listItem,
.spicetify-playlist-list li a,
.main-navBar-navBarLink {
    border-radius: var(--miroir-radius-sm) !important;
}
.main-yourLibraryX-navLinkActive,
.main-navBar-navBarLinkActive {
    background-color: rgba(var(--spice-rgb-button), 0.14) !important;
}

.main-genre-chip,
.main-home-filterChip,
#main [class*="legacy-chip"] {
    border-radius: 999px !important;
}
#main button[class*="legacy-chip--selected"],
#main [class*="legacy-chip--selected"] {
    background-color: var(--spice-button) !important;
    color: var(--spice-main) !important;
}

/* Barre de recherche (global nav) en pilule, focus accentué */
.main-globalNav-searchInputContainer {
    border-radius: 999px !important;
    border: 1px solid rgba(var(--spice-rgb-button), 0.18) !important;
    transition: border-color .2s ease, box-shadow .2s ease;
}
.main-globalNav-searchInputContainer:focus-within {
    border-color: rgba(var(--spice-rgb-button), 0.6) !important;
    box-shadow: 0 0 12px -2px rgba(var(--spice-rgb-button), 0.5);
}

/* Boutons de modes miroir actifs : accent + halo */
.main-nowPlayingBar-extraControls .main-genericButton-buttonActive,
.main-nowPlayingBar-extraControls .main-genericButton-buttonActive svg {
    color: var(--spice-button) !important;
    filter: drop-shadow(0 0 6px rgba(var(--spice-rgb-button), 0.8));
}

.os-scrollbar-handle,
::-webkit-scrollbar-thumb {
    background-color: rgba(var(--spice-rgb-button), 0.45) !important;
    border-radius: 999px !important;
}
::-webkit-scrollbar { width: 8px; height: 8px; }
::-webkit-scrollbar-thumb:hover {
    background-color: rgba(var(--spice-rgb-button), 0.75) !important;
}

.main-trackList-selected .main-trackList-rowTitle,
.main-nowPlayingWidget-trackName a {
    color: var(--spice-button) !important;
}

/* Titres — la police d'affichage est définie par la personnalité du thème */
.main-entityHeader-title h1,
.main-view-container h1,
.main-shelf-title,
.main-type-alto {
    font-family: var(--miroir-font-display, inherit);
}

/* ===========================================================================
   MODE ZEN (Ctrl+Alt+Z) — chrome effacé, musique plein cadre
   =========================================================================== */
body.miroir-zen .Root__nav-bar,
body.miroir-zen .Root__right-sidebar {
    display: none !important;
}
body.miroir-zen .Root__top-container {
    --left-sidebar-width: 0px !important;
    --right-sidebar-width: 0px !important;
    --panel-width: 0px !important;
}
body.miroir-zen .Root__main-view {
    grid-column: 1 / -1 !important;
}
body.miroir-zen .Root__globalNav {
    opacity: 0.30;
    transition: opacity .25s ease;
}
body.miroir-zen .Root__globalNav:hover { opacity: 1; }
body.miroir-zen .main-view-container__scroll-node-child {
    padding: 0 32px;
}

/* ===========================================================================
   MODE AMBIENCE (Ctrl+Alt+A) — glow extrait de la pochette, verre dépoli
   =========================================================================== */
#miroir-ambience {
    position: fixed;
    inset: -15%;
    z-index: 0;
    pointer-events: none;
    opacity: 0;
    transition: opacity 1.4s ease;
    filter: blur(70px) saturate(1.6);
}
body.miroir-ambience-on #miroir-ambience { opacity: 0.85; }
#miroir-ambience .blob {
    position: absolute;
    width: 65vw;
    height: 65vw;
    border-radius: 50%;
}
#miroir-ambience .b1 {
    top: -8%;
    left: -6%;
    background: radial-gradient(circle at 40% 40%, var(--miroir-amb-1, var(--spice-button)), transparent 65%);
    animation: miroir-drift-a 46s ease-in-out infinite alternate;
}
#miroir-ambience .b2 {
    bottom: -12%;
    right: -8%;
    background: radial-gradient(circle at 60% 60%, var(--miroir-amb-2, var(--miroir-cyan)), transparent 65%);
    animation: miroir-drift-b 58s ease-in-out infinite alternate;
}
@keyframes miroir-drift-a {
    from { transform: translate(0, 0) scale(1); }
    to   { transform: translate(14vw, 10vh) scale(1.25); }
}
@keyframes miroir-drift-b {
    from { transform: translate(0, 0) scale(1.2); }
    to   { transform: translate(-12vw, -8vh) scale(0.95); }
}
body.miroir-ambience-on { background: var(--spice-main); }
body.miroir-ambience-on .Root,
body.miroir-ambience-on .Root__top-container {
    background: transparent !important;
}
body.miroir-ambience-on .Root__main-view {
    background: rgba(var(--spice-rgb-main), 0.45) !important;
}
body.miroir-ambience-on .Root__nav-bar .main-yourLibraryX-libraryContainer,
body.miroir-ambience-on .Root__right-sidebar aside {
    background: rgba(var(--spice-rgb-main), 0.45) !important;
    backdrop-filter: blur(18px) saturate(1.2);
}
body.miroir-ambience-on .main-nowPlayingBar-container {
    background: rgba(var(--spice-rgb-card), 0.60) !important;
    backdrop-filter: blur(20px) saturate(1.3);
}

/* ===========================================================================
   MODE VINYLE (Ctrl+Alt+V) — la pochette devient un disque qui tourne
   =========================================================================== */
body.miroir-vinyl .main-nowPlayingWidget-coverArt .cover-art,
body.miroir-vinyl .main-nowPlayingWidget-coverArt .cover-art img {
    border-radius: 50% !important;
}
body.miroir-vinyl .main-nowPlayingWidget-coverArt .cover-art {
    animation: miroir-spin 9s linear infinite;
    box-shadow:
        inset 0 0 0 3px rgba(255, 255, 255, 0.10),
        inset 0 0 0 11px rgba(0, 0, 0, 0.38),
        0 0 14px rgba(var(--spice-rgb-button), 0.40);
}
body.miroir-vinyl.miroir-paused .main-nowPlayingWidget-coverArt .cover-art {
    animation-play-state: paused;
}
@keyframes miroir-spin { to { transform: rotate(360deg); } }

/* ===========================================================================
   PERSONNALITÉ · miroir-hack — terminal néon, scanlines, mono
   =========================================================================== */
body.miroir-hack {
    --miroir-font-display: "CaskaydiaMono Nerd Font", "JetBrainsMono Nerd Font",
        "JetBrains Mono", ui-monospace, monospace;
    --miroir-radius: 6px;
    --miroir-radius-sm: 4px;
}
body.miroir-hack::after {
    content: "";
    position: fixed;
    inset: 0;
    z-index: 9997;
    pointer-events: none;
    background: repeating-linear-gradient(
        to bottom,
        rgba(0, 0, 0, 0.16) 0px,
        rgba(0, 0, 0, 0.16) 1px,
        transparent 1px,
        transparent 3px
    );
    opacity: 0.35;
    mix-blend-mode: multiply;
}
body.miroir-hack .main-entityHeader-title h1 {
    text-transform: uppercase;
    letter-spacing: 0.04em;
    text-shadow:
        0 0 12px rgba(var(--spice-rgb-button), 0.85),
        0 0 32px rgba(var(--spice-rgb-button), 0.35);
    animation: miroir-neon 3.2s ease-in-out infinite;
}
@keyframes miroir-neon {
    0%, 100% { text-shadow: 0 0 12px rgba(var(--spice-rgb-button), 0.85), 0 0 32px rgba(var(--spice-rgb-button), 0.35); }
    50%      { text-shadow: 0 0 18px rgba(var(--spice-rgb-button), 1),    0 0 48px rgba(var(--spice-rgb-button), 0.55); }
}
body.miroir-hack .main-shelf-title {
    text-transform: uppercase;
    letter-spacing: 0.08em;
    font-size: 1.05rem;
}
body.miroir-hack .main-shelf-title::before {
    content: "▸ ";
    color: var(--miroir-cyan);
}
body.miroir-hack .main-nowPlayingBar-container {
    border: 1px solid rgba(var(--spice-rgb-button), 0.35);
    box-shadow:
        0 0 18px -6px rgba(var(--spice-rgb-button), 0.55),
        0 6px 20px -10px rgba(0, 0, 0, 0.6);
}
body.miroir-hack .main-card-card:hover {
    box-shadow:
        -2px 0 0 0 var(--miroir-cyan),
        2px 0 0 0 var(--spice-button),
        0 8px 24px -6px rgba(var(--spice-rgb-button), 0.5);
}
body.miroir-hack .main-nowPlayingWidget-trackName a {
    text-shadow: 0 0 10px rgba(var(--spice-rgb-button), 0.8);
}

/* ===========================================================================
   PERSONNALITÉ · miroir-grimoire — vieux grimoire, serif, vignette, or
   =========================================================================== */
body.miroir-grimoire {
    --miroir-font-display: "Iowan Old Style", "Palatino Linotype", "URW Palladio L",
        P052, Palatino, Georgia, serif;
    --miroir-radius: 14px;
    --miroir-radius-sm: 10px;
}
body.miroir-grimoire::after {
    content: "";
    position: fixed;
    inset: 0;
    z-index: 9997;
    pointer-events: none;
    background: radial-gradient(ellipse at 50% 38%, transparent 52%, rgba(20, 12, 4, 0.42) 100%);
    mix-blend-mode: multiply;
}
body.miroir-grimoire .main-entityHeader-title h1 {
    font-weight: 500;
    letter-spacing: 0.01em;
    text-shadow: 0 2px 18px rgba(0, 0, 0, 0.55);
}
body.miroir-grimoire .main-shelf-title {
    font-size: 1.35rem;
    font-weight: 500;
}
body.miroir-grimoire .main-shelf-title::after {
    content: "";
    display: block;
    width: 64px;
    height: 1px;
    margin-top: 6px;
    background: linear-gradient(90deg, var(--miroir-yellow), transparent);
}
body.miroir-grimoire .main-nowPlayingBar-container,
body.miroir-grimoire .Root__nav-bar .main-yourLibraryX-libraryContainer,
body.miroir-grimoire .Root__right-sidebar aside {
    border: 1px solid rgba(216, 162, 74, 0.22);
}
body.miroir-grimoire .main-card-card:hover {
    box-shadow:
        0 0 0 1px rgba(216, 162, 74, 0.35),
        0 10px 28px -8px rgba(0, 0, 0, 0.65);
}
body.miroir-grimoire .main-playButton-PlayButton button:hover {
    box-shadow: 0 0 16px -2px rgba(216, 162, 74, 0.6);
}

/* ===========================================================================
   PERSONNALITÉ · miroir-void — cosmos, étoiles qui scintillent, verre
   =========================================================================== */
body.miroir-void {
    --miroir-radius: 16px;
    --miroir-radius-sm: 12px;
}
body.miroir-void::before,
body.miroir-void::after {
    content: "";
    position: fixed;
    inset: 0;
    z-index: 9996;
    pointer-events: none;
    mix-blend-mode: screen;
    background-repeat: repeat;
}
body.miroir-void::before {
    background-image:
        radial-gradient(1px 1px at 18% 22%, rgba(230, 226, 245, 0.9), transparent 100%),
        radial-gradient(1px 1px at 64% 8%,  rgba(196, 155, 255, 0.8), transparent 100%),
        radial-gradient(1px 1px at 41% 63%, rgba(230, 226, 245, 0.7), transparent 100%),
        radial-gradient(1px 1px at 86% 47%, rgba(116, 230, 240, 0.7), transparent 100%);
    background-size: 420px 420px;
    opacity: 0.5;
    animation: miroir-twinkle 7s ease-in-out infinite alternate;
}
body.miroir-void::after {
    background-image:
        radial-gradient(1.5px 1.5px at 32% 84%, rgba(230, 226, 245, 0.9), transparent 100%),
        radial-gradient(1px 1px at 74% 71%,     rgba(150, 164, 255, 0.8), transparent 100%),
        radial-gradient(1px 1px at 8% 52%,      rgba(230, 226, 245, 0.6), transparent 100%);
    background-size: 560px 560px;
    opacity: 0.35;
    animation: miroir-twinkle 9s ease-in-out infinite alternate-reverse;
}
@keyframes miroir-twinkle {
    from { opacity: 0.18; }
    to   { opacity: 0.55; }
}
body.miroir-void .main-nowPlayingBar-container {
    background: rgba(var(--spice-rgb-card), 0.72) !important;
    backdrop-filter: blur(16px) saturate(1.25);
}
body.miroir-void .main-entityHeader-title h1 {
    text-shadow: 0 0 24px rgba(169, 123, 240, 0.55);
}

/* ===========================================================================
   PERSONNALITÉ · miroir-shinkai — ciel crépusculaire animé, verre doux
   =========================================================================== */
body.miroir-shinkai {
    --miroir-radius: 16px;
    --miroir-radius-sm: 12px;
}
body.miroir-shinkai::before {
    content: "";
    position: fixed;
    inset: 0;
    z-index: 9996;
    pointer-events: none;
    mix-blend-mode: screen;
    background: linear-gradient(
        180deg,
        rgba(111, 168, 240, 0.14) 0%,
        rgba(157, 142, 240, 0.06) 38%,
        transparent 60%,
        rgba(242, 122, 144, 0.07) 100%
    );
    animation: miroir-sky 40s ease-in-out infinite alternate;
}
@keyframes miroir-sky {
    from { filter: hue-rotate(0deg);   opacity: 0.8; }
    to   { filter: hue-rotate(-24deg); opacity: 1; }
}
body.miroir-shinkai .main-nowPlayingBar-container {
    background: rgba(var(--spice-rgb-card), 0.70) !important;
    backdrop-filter: blur(18px) saturate(1.3);
}
body.miroir-shinkai .main-card-card:hover {
    box-shadow: 0 12px 32px -8px rgba(157, 142, 240, 0.5);
}
body.miroir-shinkai .main-entityHeader-title h1 {
    text-shadow: 0 4px 28px rgba(111, 168, 240, 0.5);
}
CSSEOF
}

create_theme_js() {
# --- 1. Constante générée : nom du thème actif -----------------------------
cat > "$THEME_DIR/theme.js" << EOF
// Miroir — généré par 10-spotify.sh
const MIROIR_THEME = "${THEME_NAME}";
EOF

# --- 2. Moteur statique (pas d'expansion shell ici) ------------------------
cat >> "$THEME_DIR/theme.js" << 'JSEOF'

(function miroir() {
    if (!window.Spicetify || !Spicetify.Player || !Spicetify.Platform || !document.body) {
        setTimeout(miroir, 300);
        return;
    }

    const MODES = {
        zen:      { cls: "miroir-zen",          label: "Zen",      key: "z", default: false },
        ambience: { cls: "miroir-ambience-on",  label: "Ambience", key: "a", default: true  },
        vinyl:    { cls: "miroir-vinyl",        label: "Vinyle",   key: "v", default: false },
    };
    const LS = (k) => `miroir:${k}`;
    const state = {};

    // Personnalité du thème actif (cible des blocs body.miroir-* du CSS)
    document.body.classList.add(MIROIR_THEME.startsWith("miroir-") ? MIROIR_THEME : "miroir-base");

    // ------------------------------------------------------------------ ambience
    let amb = document.getElementById("miroir-ambience");
    if (!amb) {
        amb = document.createElement("div");
        amb.id = "miroir-ambience";
        amb.innerHTML = '<div class="blob b1"></div><div class="blob b2"></div>';
        document.body.prepend(amb);
    }

    function coverUrl() {
        const m = Spicetify.Player.data?.item?.metadata || {};
        const uri = m.image_xlarge_url || m.image_large_url || m.image_url || "";
        if (uri.startsWith("spotify:image:")) return "https://i.scdn.co/image/" + uri.split(":").pop();
        return uri.startsWith("http") ? uri : null;
    }

    function extractColors(url) {
        return new Promise((resolve) => {
            try {
                const img = new Image();
                img.crossOrigin = "anonymous";
                img.onload = () => {
                    try {
                        const S = 24, cv = document.createElement("canvas");
                        cv.width = cv.height = S;
                        const cx = cv.getContext("2d");
                        cx.drawImage(img, 0, 0, S, S);
                        const d = cx.getImageData(0, 0, S, S).data;
                        let best = null, bestScore = -1, r2 = 0, g2 = 0, b2 = 0, n = 0;
                        for (let i = 0; i < d.length; i += 4) {
                            const r = d[i], g = d[i + 1], b = d[i + 2];
                            const mx = Math.max(r, g, b), mn = Math.min(r, g, b);
                            const sat = mx - mn, lum = (mx + mn) / 2;
                            const score = sat * (lum > 30 && lum < 225 ? 1 : 0.2);
                            if (score > bestScore) { bestScore = score; best = [r, g, b]; }
                            r2 += r; g2 += g; b2 += b; n++;
                        }
                        const avg = [r2 / n | 0, g2 / n | 0, b2 / n | 0];
                        resolve([`rgb(${best.join(",")})`, `rgb(${avg.join(",")})`]);
                    } catch (e) { resolve(null); }
                };
                img.onerror = () => resolve(null);
                img.src = url;
            } catch (e) { resolve(null); }
        });
    }

    async function refreshAmbience() {
        if (!state.ambience) return;
        const url = coverUrl();
        const fallback = getComputedStyle(document.documentElement)
            .getPropertyValue("--spice-button").trim() || "#a97bf0";
        let c = url ? await extractColors(url) : null;
        if (!c) c = [fallback, fallback];
        amb.style.setProperty("--miroir-amb-1", c[0]);
        amb.style.setProperty("--miroir-amb-2", c[1]);
    }

    // ------------------------------------------------------------------ modes
    const buttons = {};

    function setMode(name, on, silent) {
        state[name] = on;
        document.body.classList.toggle(MODES[name].cls, on);
        try { Spicetify.LocalStorage.set(LS(name), on ? "1" : "0"); } catch (e) {}
        if (buttons[name]) buttons[name].active = on;
        if (name === "ambience" && on) refreshAmbience();
        if (!silent) Spicetify.showNotification(`Miroir · ${MODES[name].label} ${on ? "ON" : "OFF"}`);
    }
    const toggle = (name) => setMode(name, !state[name]);

    // état initial depuis localStorage (défauts sinon)
    for (const name of Object.keys(MODES)) {
        let saved = null;
        try { saved = Spicetify.LocalStorage.get(LS(name)); } catch (e) {}
        state[name] = saved === null ? MODES[name].default : saved === "1";
    }

    // ------------------------------------------------------------------ playbar
    const ICONS = {
        zen: '<path d="M13.9 10.6A6.1 6.1 0 0 1 5.4 2.1a.5.5 0 0 0-.62-.62A7.1 7.1 0 1 0 14.5 11.2a.5.5 0 0 0-.6-.6z"/>',
        ambience: '<path d="M8 .8l1.5 3.9 3.9 1.5-3.9 1.5L8 11.6 6.5 7.7 2.6 6.2l3.9-1.5L8 .8zm5.2 8.4l.9 2.3 2.3.9-2.3.9-.9 2.3-.9-2.3-2.3-.9 2.3-.9.9-2.3z"/>',
        vinyl: '<path d="M8 1a7 7 0 1 0 0 14A7 7 0 0 0 8 1zm0 9.3A2.3 2.3 0 1 1 8 5.7a2.3 2.3 0 0 1 0 4.6zM8 7.2a.8.8 0 1 0 0 1.6.8.8 0 0 0 0-1.6z"/>',
    };
    try {
        if (Spicetify.Playbar && Spicetify.Playbar.Button) {
            for (const name of Object.keys(MODES)) {
                const label = `Miroir · ${MODES[name].label} (Ctrl+Alt+${MODES[name].key.toUpperCase()})`;
                buttons[name] = new Spicetify.Playbar.Button(
                    label, ICONS[name], () => toggle(name), false, state[name]
                );
                // Spotify 1.2.9x : l'API ne rend pas l'icône → injection manuelle
                const el = buttons[name].element;
                if (el && !el.querySelector("svg")) {
                    el.innerHTML = `<svg role="img" height="16" width="16" viewBox="0 0 16 16" fill="currentColor">${ICONS[name]}</svg>`;
                    el.setAttribute("aria-label", label);
                }
            }
        }
    } catch (e) { /* playbar API absente : raccourcis clavier seuls */ }

    // ------------------------------------------------------------------ clavier
    document.addEventListener("keydown", (ev) => {
        if (!ev.ctrlKey || !ev.altKey || ev.shiftKey || ev.metaKey) return;
        const k = ev.key.toLowerCase();
        for (const name of Object.keys(MODES)) {
            if (MODES[name].key === k) {
                ev.preventDefault();
                toggle(name);
                return;
            }
        }
    });

    // ------------------------------------------------------------------ player
    const syncPaused = () => {
        let paused = true;
        try { paused = !Spicetify.Player.isPlaying(); } catch (e) {}
        document.body.classList.toggle("miroir-paused", paused);
    };
    Spicetify.Player.addEventListener("onplaypause", syncPaused);
    Spicetify.Player.addEventListener("songchange", () => refreshAmbience());
    syncPaused();

    // appliquer l'état initial (sans toast)
    for (const name of Object.keys(MODES)) setMode(name, state[name], true);

    // au boot, Player.data n'est pas encore chargé → retry l'extraction pochette
    let tries = 0;
    const bootAmb = setInterval(() => {
        if (++tries > 12) return clearInterval(bootAmb);
        if (state.ambience && coverUrl()) { refreshAmbience(); clearInterval(bootAmb); }
    }, 1500);

    // petit hello la toute première fois
    try {
        if (!Spicetify.LocalStorage.get(LS("hello"))) {
            Spicetify.LocalStorage.set(LS("hello"), "1");
            setTimeout(() => Spicetify.showNotification(
                "Miroir · Ctrl+Alt+Z zen — Ctrl+Alt+A ambience — Ctrl+Alt+V vinyle"), 2500);
        }
    } catch (e) {}
})();
JSEOF
}

change_spicetify_theme() {
    spicetify config current_theme omarchy > /dev/null
    spicetify config color_scheme base > /dev/null
    spicetify config inject_theme_js 1 > /dev/null
}

if ! command -v spicetify >/dev/null 2>&1; then
    skipped "Spicetify"
fi

spotify_was_running=false
if pgrep -x "spotify" > /dev/null 2>&1; then
    spotify_was_running=true
fi

create_spicetify_styling
create_dynamic_theme
create_theme_js
change_spicetify_theme

if [ "$spotify_was_running" = true ]; then
       spicetify apply > /dev/null 2>&1 &
else
    setsid bash -c '
        spicetify apply > /dev/null 2>&1 &

        for i in {1..250}; do
            if pgrep -x "spotify" > /dev/null 2>&1; then
                sleep 0.2
                killall -9 spotify > /dev/null 2>&1
                exit 0
            fi
            sleep 0.1
        done
    ' > /dev/null 2>&1 < /dev/null &
fi

success "Spotify theme updated!"
exit 0
