#!/bin/bash
set -euo pipefail

SUDOERS_FILE="/etc/sudoers.d/sleepless"
CURRENT_USER="$(whoami)"

RULE="$CURRENT_USER ALL=(root) NOPASSWD: /usr/bin/pmset disablesleep 0, /usr/bin/pmset disablesleep 1"

if [ -f "$SUDOERS_FILE" ]; then
    echo "Sudoers rule already installed at $SUDOERS_FILE"
    exit 0
fi

echo "=== Sleepless Sudoers Setup ==="
echo ""
echo "This will create $SUDOERS_FILE with the following rule:"
echo ""
echo "  $RULE"
echo ""
echo "This allows Sleepless to toggle sleep without a password prompt."
echo "You will be asked for your password by sudo."
echo ""
read -p "Continue? [y/N] " answer

if [[ "$answer" != [yY] ]]; then
    echo "Aborted."
    exit 1
fi

# Write to temp file, validate with visudo, then install
TMPFILE=$(mktemp)
echo "$RULE" > "$TMPFILE"

if ! sudo visudo -cf "$TMPFILE" >/dev/null 2>&1; then
    echo "Error: generated sudoers rule failed validation."
    rm -f "$TMPFILE"
    exit 1
fi

sudo cp "$TMPFILE" "$SUDOERS_FILE"
sudo chmod 0440 "$SUDOERS_FILE"
sudo chown root:wheel "$SUDOERS_FILE"
rm -f "$TMPFILE"

echo ""
echo "Done. Sudoers rule installed at $SUDOERS_FILE"
