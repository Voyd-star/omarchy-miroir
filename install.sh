#!/usr/bin/env bash
# Miroir — Omarchy theme family + multi-app theming.
# Interactive installer: pick only the features you want. Idempotent.
#
#   bash install.sh              # interactive
#   bash install.sh --all        # yes to everything
#   bash install.sh --theme-only # just install the theme(s), nothing else
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

ALL=0; THEME_ONLY=0
case "${1:-}" in
  --all) ALL=1 ;;
  --theme-only) THEME_ONLY=1 ;;
  -h|--help) sed -n '2,8p' "$0"; exit 0 ;;
esac

say()  { printf '\n\033[1;35m==> %s\033[0m\n' "$1"; }
note() { printf '  %s\n' "$1"; }

# ask "Question" [default y|n] -> 0 = yes
ask() {
  local q="$1" def="${2:-y}" ans
  [[ $ALL -eq 1 ]] && return 0
  [[ $THEME_ONLY -eq 1 ]] && return 1
  if [[ ! -t 0 ]]; then [[ "$def" == y ]]; return; fi
  if [[ "$def" == y ]]; then
    read -rp "$(printf '\033[1;36m?\033[0m %s [Y/n] ' "$q")" ans; [[ ! "$ans" =~ ^[nN] ]]
  else
    read -rp "$(printf '\033[1;36m?\033[0m %s [y/N] ' "$q")" ans; [[ "$ans" =~ ^[yY] ]]
  fi
}

# Package helper — Omarchy first, then AUR helpers. Never fails the install.
pkg_add() {
  omarchy pkg add "$@" 2>/dev/null && return 0
  command -v omarchy-pkg-add >/dev/null 2>&1 && omarchy-pkg-add "$@" 2>/dev/null && return 0
  command -v yay  >/dev/null 2>&1 && yay  -S --needed --noconfirm "$@" && return 0
  command -v paru >/dev/null 2>&1 && paru -S --needed --noconfirm "$@" && return 0
  sudo pacman -S --needed "$@" 2>/dev/null && return 0
  note "! could not install: $* — install manually"; return 1
}
pkg_add_aur() {
  omarchy pkg aur add "$@" 2>/dev/null && return 0
  command -v omarchy-pkg-add >/dev/null 2>&1 && omarchy-pkg-add "$@" 2>/dev/null && return 0
  command -v yay  >/dev/null 2>&1 && yay  -S --needed --noconfirm "$@" && return 0
  command -v paru >/dev/null 2>&1 && paru -S --needed --noconfirm "$@" && return 0
  note "! could not install (AUR): $* — install manually"; return 1
}

omarchy_major="$(omarchy-version 2>/dev/null | grep -oE '[0-9]+' | head -1)"; : "${omarchy_major:=3}"

FEAT_HYPR=0 FEAT_ROTATE=0 FEAT_FRAMEWORK=0
FEAT_DISCORD=0 FEAT_SPOTIFY=0 FEAT_RAZER=0 FEAT_TMUX=0 FEAT_EXTRA_HOOKS=0

# ── 1. Themes ────────────────────────────────────────────────────────────────
say "Thèmes / Themes"
mkdir -p ~/.config/omarchy/themes
installed_themes=()
for t in "$HERE"/config/omarchy/themes/*/; do
  name="$(basename "$t")"
  if [[ $THEME_ONLY -eq 1 ]] || ask "Install theme '$name'?" y; then
    cp -r "$t" ~/.config/omarchy/themes/
    installed_themes+=("$name")
    note "installed -> ~/.config/omarchy/themes/$name"
  fi
done
[[ ${#installed_themes[@]} -eq 0 && $THEME_ONLY -eq 0 ]] && note "(no theme selected — continuing with extras only)"

if [[ $THEME_ONLY -eq 1 ]]; then
  echo; echo "Done. Apply with:  omarchy-theme-set \"Miroir Hack\""; exit 0
fi

# ── 2. Hyprland look-n-feel ─────────────────────────────────────────────────
if ask "Hyprland look-n-feel (window motions/deco + border/shadow that follow the theme accent)? Backs up your current looknfeel." y; then
  FEAT_HYPR=1
  mkdir -p ~/.config/hypr
  if [[ "$omarchy_major" -ge 4 ]]; then
    [[ -f ~/.config/hypr/looknfeel.lua ]] && cp ~/.config/hypr/looknfeel.lua ~/.config/hypr/looknfeel.lua.bak."$(date +%s)"
    cp "$HERE"/config/hypr/looknfeel.lua ~/.config/hypr/looknfeel.lua
    note "looknfeel.lua deployed (Omarchy 4.x, backup kept)"
  else
    [[ -f ~/.config/hypr/looknfeel.conf ]] && cp ~/.config/hypr/looknfeel.conf ~/.config/hypr/looknfeel.conf.bak."$(date +%s)"
    cp "$HERE"/config/hypr/looknfeel.conf ~/.config/hypr/looknfeel.conf
    note "looknfeel.conf deployed (Omarchy 3.x, backup kept)"
  fi
fi

# ── 3. Hourly background rotation ───────────────────────────────────────────
if ask "Hourly wallpaper rotation (systemd user timer)?" y; then
  FEAT_ROTATE=1
fi

# ── 4. Multi-app theming framework ──────────────────────────────────────────
if ask "Multi-app theming framework (re-themes apps automatically on every theme change)?" y; then
  FEAT_FRAMEWORK=1
  ask "  ├─ Discord via Vesktop (installs vesktop-bin, base16 theme follows the palette)?" y && FEAT_DISCORD=1
  ask "  ├─ Spotify via spicetify (per-theme skin + Zen/Ambience/Vinyl modes)?" y && FEAT_SPOTIFY=1
  ask "  ├─ Razer keyboard LED = theme accent (installs openrazer + polychromatic)?" n && FEAT_RAZER=1
  ask "  ├─ tmux statusbar colors from the palette?" y && FEAT_TMUX=1
  ask "  └─ Extra app hooks: GTK, Qt6, fish, fzf, firefox, zen, qutebrowser, zed, cava, typora, superfile, vicinae, heroic, nwg-dock (each no-ops if the app isn't installed)?" y && FEAT_EXTRA_HOOKS=1
fi

# ── Deploy ──────────────────────────────────────────────────────────────────
say "Deploying files"
mkdir -p ~/.config/systemd/user ~/.local/bin ~/.config/miroir

if [[ $FEAT_FRAMEWORK -eq 1 ]]; then
  mkdir -p ~/.config/omarchy/hooks/theme-set.d ~/.config/omarchy/themed
  install -m755 "$HERE"/config/omarchy/hooks/theme-set ~/.config/omarchy/hooks/theme-set
  cp "$HERE"/config/omarchy/themed/*.tpl ~/.config/omarchy/themed/
  # Hook dispatcher runs whatever is present & executable — copy only what was chosen.
  hooks=()
  [[ $FEAT_EXTRA_HOOKS -eq 1 ]] && hooks+=(00-fish.sh 00-fzf.sh 10-gtk.sh 10-qt6ct.sh 10-superfile.sh 10-vicinae.sh 15-typora.sh 20-nwg-dock-hyprland.sh 20-zed.sh 40-cava.sh 40-firefox.sh 40-qutebrowser.sh 40-zen.sh 50-heroic.sh)
  [[ $FEAT_DISCORD -eq 1 ]] && hooks+=(10-discord.sh)
  [[ $FEAT_SPOTIFY -eq 1 ]] && hooks+=(10-spotify.sh)
  for h in "${hooks[@]}"; do
    install -m755 "$HERE/config/omarchy/hooks/theme-set.d/$h" ~/.config/omarchy/hooks/theme-set.d/
  done
  # Optional hooks kept disabled (vscode/cursor/windsurf — see README)
  cp "$HERE"/config/omarchy/hooks/theme-set.d/*.disabled ~/.config/omarchy/hooks/theme-set.d/ 2>/dev/null || true
  install -m755 "$HERE"/local/bin/miroir-theme-apply ~/.local/bin/
  cp "$HERE"/config/systemd/user/miroir-theme-apply.path "$HERE"/config/systemd/user/miroir-theme-apply.service ~/.config/systemd/user/
  pkg_add imagemagick jq
fi

if [[ $FEAT_ROTATE -eq 1 ]]; then
  cp "$HERE"/config/systemd/user/omarchy-bg-rotate.service "$HERE"/config/systemd/user/omarchy-bg-rotate.timer ~/.config/systemd/user/
fi

# Feature toggles read by miroir-theme-apply
cat > ~/.config/miroir/features.conf <<EOF
# Generated by omarchy-miroir install.sh — 1 = on, 0 = off
MIROIR_RAZER=$FEAT_RAZER
MIROIR_TMUX=$FEAT_TMUX
MIROIR_HYPR=$FEAT_HYPR
EOF

# ── Per-feature setup ───────────────────────────────────────────────────────
if [[ $FEAT_DISCORD -eq 1 ]]; then
  say "Discord (Vesktop)"
  pkg_add_aur vesktop-bin
  mkdir -p ~/.config/vesktop/themes ~/.local/share/applications
  cp "$HERE"/local/share/applications/vesktop.desktop ~/.local/share/applications/
  S="$HOME/.config/vesktop/settings/settings.json"
  if [[ -f "$S" ]] && command -v jq >/dev/null; then
    tmp=$(mktemp); jq '.enabledThemes = ["vencord.theme.css"]' "$S" > "$tmp" && mv "$tmp" "$S" && note "enabledThemes -> vencord.theme.css"
  else
    note "(launch Vesktop once, re-run install.sh — or tick 'vencord.theme.css' in Vencord > Themes)"
  fi
  if ask "  Point SUPER+D at Vesktop (patches your Hyprland bindings)?" y; then
    BL="$HOME/.config/hypr/bindings.lua"
    [[ -f "$BL" ]] && sed -i 's/or-focus discord/or-focus vesktop/g' "$BL" && note "bindings.lua patched"
    BC="$HOME/.config/hypr/bindings.conf"
    if [[ -f "$BC" ]]; then
      if grep -qE '^bindd? = SUPER, D,' "$BC"; then
        sed -i -E 's|^(bindd? = SUPER, D, [^,]*, exec,).*|\1 omarchy-launch-or-focus vesktop|' "$BC" && note "bindings.conf: SUPER+D -> vesktop"
      else
        echo 'bindd = SUPER, D, Discord, exec, omarchy-launch-or-focus vesktop' >> "$BC" && note "bindings.conf: SUPER+D added"
      fi
    fi
  fi
  ask "  Remove vanilla Discord package (Vesktop replaces it)?" n && { omarchy pkg drop discord 2>/dev/null || sudo pacman -Rns --noconfirm discord 2>/dev/null || true; }
fi

if [[ $FEAT_SPOTIFY -eq 1 ]]; then
  say "Spotify (spicetify)"
  pkg_add_aur spicetify-cli
  if [[ -d /opt/spotify ]]; then
    sudo chown -R "$USER":"$USER" /opt/spotify 2>/dev/null || sudo chmod -R a+wr /opt/spotify 2>/dev/null || true
    # Bundled spicetify extensions (no downloads): fullAppDisplay (F), popupLyrics,
    # shuffle+ (true random), keyboardShortcut (vim keys)
    for ext in fullAppDisplay.js popupLyrics.js shuffle+.js keyboardShortcut.js; do
      spicetify config extensions "$ext" 2>/dev/null || true
    done
    spicetify backup apply 2>/dev/null || note "(run 'spicetify backup apply' after launching Spotify once)"
  else
    note "(Spotify not found in /opt/spotify — install it, then re-run install.sh)"
  fi
fi

if [[ $FEAT_RAZER -eq 1 ]]; then
  say "Razer keyboard"
  pkg_add_aur openrazer-meta
  pkg_add polychromatic
  sudo gpasswd -a "$USER" plugdev 2>/dev/null || true
  systemctl --user enable --now openrazer-daemon 2>/dev/null || true
  note "(if the LED doesn't react: reboot once for the dkms module, then switch theme)"
fi

# ── Services ────────────────────────────────────────────────────────────────
say "systemd user services"
systemctl --user daemon-reload
[[ $FEAT_FRAMEWORK -eq 1 ]] && systemctl --user enable --now miroir-theme-apply.path 2>/dev/null && note "miroir-theme-apply.path enabled"
[[ $FEAT_ROTATE   -eq 1 ]] && systemctl --user enable --now omarchy-bg-rotate.timer 2>/dev/null && note "omarchy-bg-rotate.timer enabled"

# Apply everything to the current theme once
[[ $FEAT_FRAMEWORK -eq 1 ]] && "$HOME/.local/bin/miroir-theme-apply" 2>/dev/null || true

cat <<'EOF'

✓ Done. Pick a theme:   omarchy-theme-set "Miroir Hack"

  • Discord : Ctrl+R inside Vesktop reloads the theme.
  • Spotify : reopen it. After EVERY Spotify update /opt/spotify goes back to root:
                sudo chown -R "$USER" /opt/spotify && spicetify backup apply
  • Modes   : Zen Ctrl+Alt+Z · Ambience Ctrl+Alt+A · Vinyl Ctrl+Alt+V (in Spotify)
EOF
