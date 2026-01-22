#!/bin/bash

# SessionStart hook to load Oink entities and accounts into context
# This runs automatically at the start of each Claude Code session

cd "$CLAUDE_PROJECT_DIR" || exit 1

# Check if database exists
if [ ! -f "oink.db" ]; then
  echo "Note: oink.db not found. Run ./scripts/init to create the database."
  exit 0
fi

# Get entities with their accounts
entities_json=$(./scripts/entity list --json 2>/dev/null)

entity_count=$(echo "$entities_json" | jq '.entities | length' 2>/dev/null || echo "0")
if [ "$entity_count" -eq 0 ]; then
  echo "Oink database ready. No entities configured yet. Run /setup to get started."
  exit 0
fi

# Parse and display entity information
echo "=== Oink Entities & Accounts ==="
echo ""

echo "$entities_json" | jq -r '.entities[] | .name' | while read -r entity_name; do
  # Get accounts for this entity
  accounts_json=$(./scripts/account list --entity "$entity_name" --json 2>/dev/null)
  account_count=$(echo "$accounts_json" | jq '.accounts | length')

  echo "Entity: $entity_name"

  if [ "$account_count" -gt 0 ]; then
    echo "$accounts_json" | jq -r '.accounts[] | "  - \(.name) (\(.currency), \(.account_type))"'
  else
    echo "  (no accounts)"
  fi
  echo ""
done

echo "Use exact entity names (case-sensitive) in commands:"
echo "  ./scripts/report --report-type pnl --entity \"EntityName\" --year 2025"
echo ""

exit 0
