#!/usr/bin/env bash
# Merge the original package (alheekmahlib/quran_library) into this fork.
#
# Usage (from the repo root, in Git Bash):
#   tool/merge_upstream.sh              # merges upstream/main
#   tool/merge_upstream.sh <ref>        # merges another ref/commit
#
# What it does automatically (see FORK_CHANGES.md for the reasons):
#   1. fetches upstream and merges without committing
#   2. deletes the features this fork removed (audio, tasmee) again
#   3. keeps the fork's version of fork-only config, takes upstream's
#      generated example files
#   4. removes the audio packages from pubspec.yaml
#   5. lists what is left to resolve by hand, then analyzes and tests
# It never commits or pushes.

set -uo pipefail
cd "$(git rev-parse --show-toplevel)" || exit 1

REF="${1:-upstream/main}"

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "✋ Working tree has uncommitted changes. Commit or stash them first."
  exit 1
fi

if [[ "$REF" == upstream/* ]]; then
  git remote get-url upstream >/dev/null 2>&1 ||
    git remote add upstream https://github.com/alheekmahlib/quran_library.git
  git fetch upstream || exit 1
fi

echo "▶ Merging $REF ..."
git merge --no-ff --no-commit "$REF"

# ── 2. features removed in this fork ─────────────────────────────────────────
REMOVED_PATHS=(
  lib/src/audio
  lib/src/tasmee
  lib/src/pages/surah_audio_screen.dart
  lib/src/quran/core/services/word_audio_service.dart
  assets/quran_lab
  doc/superpowers
  test/fixtures
  example/integration_test
)
for p in "${REMOVED_PATHS[@]}"; do
  if [ -e "$p" ] || git ls-files --error-unmatch "$p" >/dev/null 2>&1; then
    git rm -rqf --ignore-unmatch "$p" && echo "  🗑  removed $p"
  fi
done

# tests of the removed features
for f in $(git grep -l -i -e 'tasmee' -e 'AudioCtrl' -e 'sherpa' -- 'test/*.dart' 2>/dev/null); do
  git rm -qf "$f" && echo "  🗑  removed $f"
done

# ── 3. per-file rules for conflicts ──────────────────────────────────────────
take_ours=(
  README.md
  android/src/main/AndroidManifest.xml
  example/ios/Runner/Info.plist
  example/macos/Runner/DebugProfile.entitlements
  example/macos/Runner/Release.entitlements
  FORK_CHANGES.md
  tool/merge_upstream.sh
)
take_theirs=(
  example/pubspec.lock
  example/macos/Flutter/GeneratedPluginRegistrant.swift
  example/windows/flutter/generated_plugin_registrant.cc
  example/windows/flutter/generated_plugins.cmake
  example/linux/flutter/generated_plugin_registrant.cc
  example/linux/flutter/generated_plugins.cmake
)
conflicted() { git diff --name-only --diff-filter=U | grep -qxF "$1"; }
for f in "${take_ours[@]}"; do
  if conflicted "$f"; then git checkout --ours -- "$f" && git add "$f" && echo "  ✔ ours   $f"; fi
done
for f in "${take_theirs[@]}"; do
  if conflicted "$f"; then git checkout --theirs -- "$f" && git add "$f" && echo "  ✔ theirs $f"; fi
done
# fork-owned code is never changed by upstream, keep ours if it ever collides
for f in $(git diff --name-only --diff-filter=U -- lib/src/services); do
  git checkout --ours -- "$f" && git add "$f" && echo "  ✔ ours   $f"
done

# ── 4. pubspec.yaml = upstream's version minus what this fork removes ──────
strip_pubspec() {
  sed -i -E \
    -e '/^  (audio_service|just_audio|just_audio_[a-z_]+|record|sherpa_onnx|sherpa_onnx_[a-z0-9_]+):/d' \
    -e '/^    - assets\/$/d' \
    -e '/^    - assets\/(jsons|quran_lab|fonts\/quran_fonts_qfc4)\/?$/d' \
    -e '/^    - assets\/[a-z_]+\.json(\.gz)?$/d' \
    -e '/^    - family: surahName$/,/surah_name_naskh\.ttf$/d' \
    pubspec.yaml
}
if git diff --name-only --diff-filter=U | grep -qxF pubspec.yaml; then
  git checkout --theirs -- pubspec.yaml && echo "  ✔ theirs pubspec.yaml (then stripped)"
fi
if ! grep -q '^<<<<<<<' pubspec.yaml; then
  strip_pubspec
  git add pubspec.yaml
fi

# ── 5. report ────────────────────────────────────────────────────────────────
echo
LEFT=$(git diff --name-only --diff-filter=U)
if [ -n "$LEFT" ]; then
  echo "⚠  Resolve these by hand (FORK_CHANGES.md says what the fork keeps):"
  echo "$LEFT" | sed 's/^/   - /'
  echo
fi

echo "▶ Leftover references to removed features (remove them, see FORK_CHANGES.md):"
git grep -n -E 'AudioCtrl|AyahAudioStyle|SurahAudioStyle|AyahDownloadManager|AyahsAudioWidget|WordAudioService|playWordAudio|Tasmee|isTasmee|JustAudio' -- lib example/lib || echo "   none"
echo

echo "▶ Compare upstream's QuranCtrl.loadQuranDataV3() with"
echo "  lib/src/services/quran_ctrl_fast_loading.dart (copy any new steps):"
git diff HEAD "$REF" -- lib/src/quran/presentation/controllers/quran/quran_ctrl.dart | grep -n -A3 -B3 'loadQuranDataV3\|fetchSurahs' || echo "   no upstream change around these methods"
echo

if [ -z "$LEFT" ]; then
  echo "▶ flutter pub get / analyze / test"
  flutter pub get >/dev/null
  flutter analyze --no-pub lib test
  (cd example && flutter pub get >/dev/null && flutter analyze --no-pub)
  flutter test
fi

echo
echo "When everything is green:  git commit   (then push when you are ready)"
