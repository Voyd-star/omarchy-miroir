# Vendored: Shibumi Shell

- Upstream: https://github.com/HANCORE-linux/Shibumi-Shell (MIT)
- Pinned commit: `5e995c3` — version `0.1.1-beta.8` (vendored 2026-08-19)
- Stripped from the vendor copy (size only, no code): `docs/screenshots/`,
  `docs/audits/`, `docs/mockups/`, upstream `.git/`.

Why vendored: installs run from this audited snapshot — an upstream push can
never execute here unreviewed. Audit notes (2026-08-19): `scripts/shibumi_suite`
(Python) has no network calls, no eval/exec, no sudo; the AI plugin only probes
file existence and delegates usage collection to Omarchy's own
`omarchy-agent-usage-update`.

To update: `git clone` upstream at a newer commit, review the diff
(`git diff <old>..<new>`, focus on scripts/ and *.sh), then re-sync this dir
(keeping this file), bump the pin above, and run
`./scripts/shibumi-suite update --yes` from here.

Requires Omarchy Quattro (4.x). Install/uninstall from this directory:
`./scripts/shibumi-suite install --yes` · `./scripts/shibumi-suite uninstall --yes`
