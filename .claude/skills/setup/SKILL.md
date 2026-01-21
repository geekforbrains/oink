---
name: setup
description: Guide new users through initial Oink setup - database creation, OFX import, and categorization
allowed-tools: Bash, Read, Glob, Grep, Write, Edit, AskUserQuestion
---

# Oink Setup Wizard

You are guiding a new user through setting up Oink for the first time. Be conversational and helpful.

## Step 1: Check for OFX Files

First, check if there are any OFX files in the `data/` directory:

```bash
ls -la data/*.ofx 2>/dev/null || echo "No OFX files found"
```

**If OFX files exist:** List them and proceed to Step 2.

**If no OFX files:** Explain to the user:
- They need to download OFX files from their bank's online banking
- Look for "Download" or "Export" options, choose "Microsoft Money", "Quicken", or "OFX" format
- Save files to the `data/` folder (create it if needed: `mkdir -p data`)
- Naming convention: `<ENTITY>_<ACCOUNT>_<YEAR>.ofx` (e.g., `PERSONAL_CHEQUING_2025.ofx`)
- OFX is required because it contains unique transaction IDs (FITIDs) that prevent duplicate imports

Ask the user to add their OFX files and run `/setup` again when ready.

## Step 2: Initialize Database

Check if `oink.db` exists:

```bash
test -f oink.db && echo "Database exists" || echo "No database"
```

**If no database:** Run `./scripts/init` to create it.

**If database exists:** Ask if this is a fresh start or adding to existing data.

## Step 3: Plan Import Strategy

For each OFX file found, parse the filename to suggest:
- **Entity name** (first part before underscore, e.g., "Personal" from `PERSONAL_CHEQUING_2025.ofx`)
- **Account name** (second part, e.g., "Chequing")

Show the user what you found and ask them to confirm or adjust:
- Entity names (they may want "Personal" vs "PERSONAL")
- Account names and currencies (default CAD, ask if different)

## Step 4: Create Entities and Accounts

For each unique entity/account combination:

1. Check if entity exists: `./scripts/entity list --json`
2. Create if needed: `./scripts/entity add --name "EntityName"`
3. Check if account exists: `./scripts/account list --json`
4. Create if needed: `./scripts/account add --entity EntityName --name "AccountName" --currency CAD`

## Step 5: Import Transactions

For each OFX file:

```bash
./scripts/import --file data/FILENAME.ofx --account "AccountName"
```

Report results: how many transactions imported, how many duplicates skipped.

## Step 6: Review Uncategorized

After all imports, show uncategorized transactions:

```bash
./scripts/uncategorized --entity EntityName
```

Offer to help create categories and patterns:
- Look for obvious recurring transactions (subscriptions, regular vendors)
- Suggest pattern creation for common merchants
- Guide through `./scripts/category add` and `./scripts/pattern add`

## Step 7: Summary

Summarize what was set up:
- Entities created
- Accounts created
- Transactions imported
- Categories/patterns created

Suggest next steps:
- Run `./scripts/uncategorized` periodically to categorize new transactions
- Use `./scripts/report --type pnl --entity E --year Y` for P&L reports
- Import new statements with `./scripts/import`

## Important Notes

- Be patient and explain each step clearly
- Ask before creating anything - confirm entity/account names
- If the user seems confused about OFX files, offer to explain in more detail
- The goal is a working setup, not perfection - they can refine categories later
