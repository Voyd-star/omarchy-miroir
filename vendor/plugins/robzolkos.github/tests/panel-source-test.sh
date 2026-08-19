#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PANEL_SOURCE=$(<"$ROOT/Panel.qml")

fail() { echo "FAIL: $*" >&2; exit 1; }
assert_contains() {
  [[ $PANEL_SOURCE == *"$1"* ]] || fail "$2"
}

assert_contains 'glyph: broken ? "󰅖" : (running ? "󰑮" : (checks === "SUCCESS" ? "󰄬" : ""))' \
  "authored pull requests without checks do not use the pull request glyph"
assert_contains $'text: linkRow.title\n          textFormat: Text.PlainText' \
  "row titles are not forced to plain text"
assert_contains $'text: linkRow.detail\n          textFormat: Text.PlainText' \
  "row details are not forced to plain text"
assert_contains $'text: github.notificationActionStatus\n            textFormat: Text.PlainText' \
  "notification action status is not forced to plain text"
assert_contains $'return summary\n              }\n              textFormat: Text.PlainText' \
  "dashboard warning text is not forced to plain text"
assert_contains $'actionText: "Mark all read"\n            actionBusyText: "Marking…"\n            actionEnabled: github.state === "ready" && !github.loading\n            actionBusy: github.marking\n            actionRevision: github.notificationsRevision\n            actionPrepare: function() { return github.prepareMarkAllNotificationsRead() }\n            onActionTriggered: function(prepared) { github.markAllNotificationsRead(prepared) }' \
  "notification bulk action is not bound to the prepared displayed snapshot"
assert_contains $'onActionBusyChanged: if (section.actionBusy) section.disarmAction()\n    onActionEnabledChanged: if (!section.actionEnabled) section.disarmAction()\n    onActionRevisionChanged: if (section.actionArmed) section.disarmAction()' \
  "bulk confirmation is not invalidated when notification state changes"
assert_contains $'var confirmed = section.preparedAction\n          section.disarmAction()\n          section.actionTriggered(confirmed)' \
  "bulk action does not submit the originally prepared snapshot"
assert_contains $'function markSelectedRead() {\n    if (github.loading || github.marking) return' \
  "keyboard notification marking is enabled during refresh"
assert_contains $'PanelActionButton {\n        visible: linkRow.showReadAction\n        enabled: !github.loading && !github.marking' \
  "notification row marking is enabled during refresh"

assert_contains 'github.fetchedRepositoryScope === "owned" ? "OWNED REPOSITORIES  " : "REPOSITORIES  "' \
  "the repository heading does not follow the fetched scope"
assert_contains '"No repositories loaded."' \
  "the repository empty state still claims a scope"

echo "panel source tests passed"
