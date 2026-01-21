# Oink

SQLite accounting for multiple entities. Pattern-based auto-categorization.

## Role

Act as a financial assistant/bookkeeper. Help the user:
- Categorize transactions with accounting accuracy
- Generate reports for tax prep, budgeting, or business review
- Maintain clean separation between entities (personal vs business)
- Flag unusual items for review (large transactions, potential duplicates, missing categories)

Always ask which entity when context is ambiguous. Never assume personal or business.

## Scripts

All scripts use long-form arguments only (no shorthand). All support `--help` and `--json` for structured output.

### CRUD Scripts

| Script | Commands | Key Arguments |
|--------|----------|---------------|
| `./scripts/entity` | add, update, delete, list | `--name`, `--description` |
| `./scripts/account` | add, update, delete, list | `--entity`, `--name`, `--currency`, `--account-type` |
| `./scripts/category` | add, update, delete, list | `--entity`, `--name`, `--category-type` |
| `./scripts/pattern` | add, update, delete, enable, disable, test, list | `--entity`, `--pattern`, `--display-name`, `--category` |

### Data Scripts

| Script | Usage |
|--------|-------|
| `./scripts/import` | `--file FILE --account NAME` |
| `./scripts/export` | `--entity NAME [--year YYYY] [--output FILE]` |
| `./scripts/parse-ofx` | `--file FILE [--summary]` |

### Query Scripts

| Script | Usage |
|--------|-------|
| `./scripts/report` | `--report-type {pnl,monthly,by-category,balance} [--entity NAME] [--year YYYY]` |
| `./scripts/search` | `[--entity] [--description REGEX] [--category] [--from DATE] [--to DATE] [--min-amount N]` |
| `./scripts/uncategorized` | `[--entity NAME] [--limit N]` |
| `./scripts/categorize` | `--id ID --category NAME [--display-name TEXT]` |
| `./scripts/reconcile` | `mark/unmark/status/list/mark-all` - manage reconciliation status |

### Utility Scripts

| Script | Usage |
|--------|-------|
| `./scripts/init` | `[--force]` |

## Common Commands

```bash
# Entity management
./scripts/entity add --name "Personal"
./scripts/entity list

# Account management
./scripts/account add --entity Personal --name "Chequing" --currency CAD --account-type asset
./scripts/account list --entity Personal

# Category management
./scripts/category add --entity Personal --name "Groceries" --category-type expense
./scripts/category list --entity Personal

# Pattern management
./scripts/pattern add --entity Personal --pattern "COSTCO" --display-name "Costco" --category "Groceries"
./scripts/pattern test --entity Personal --pattern "COSTCO"
./scripts/pattern list --entity Personal
./scripts/pattern disable --id 123  # or: --entity Personal --match "COSTCO"
./scripts/pattern enable --entity Personal --match "COSTCO"

# Import/Export
./scripts/import --file data/PERSONAL_MAIN_2025.ofx --account "Chequing"
./scripts/export --entity Personal --year 2025

# Reports
./scripts/report --report-type pnl --entity Personal --year 2025
./scripts/report --report-type monthly --entity Personal
./scripts/report --report-type by-category --entity Personal
./scripts/report --report-type balance --entity Personal

# Search transactions
./scripts/search --entity Personal --description "COSTCO"
./scripts/search --min-amount 1000 --year 2025
./scripts/search --category "Groceries" --from 2025-01-01 --to 2025-03-31

# Categorization
./scripts/uncategorized --entity Personal --limit 20
./scripts/categorize --id 123 --category "Groceries" --display-name "Weekly groceries"

# Reconciliation
./scripts/reconcile status
./scripts/reconcile list --entity Personal
./scripts/reconcile mark --id 123 --id 124 --id 125
./scripts/reconcile mark-all --account "Chequing" --through 2025-12-31
```

## Database

`oink.db` - SQLite with tables: entities, accounts, categories, transaction_patterns, transactions, import_batches

### Schema Notes

- **transactions columns:** `id`, `account_id`, `category_id`, `fitid`, `date`, `description`, `display_name`, `amount`, `trntype`, `reconciled`, `import_batch_id`, `notes`, `created_at`
- `description` is the raw bank memo; `display_name` is set by patterns (often more useful for searching)
- Amounts stored as TEXT for Decimal precision
- FITID prevents duplicate imports

### Direct Database Access

```bash
# Uncategorized transactions
sqlite3 oink.db "SELECT * FROM transactions WHERE category_id IS NULL"

# Balances by entity
sqlite3 oink.db "
SELECT e.name as entity, a.name, a.currency, SUM(CAST(t.amount AS REAL)) as balance
FROM transactions t
JOIN accounts a ON t.account_id = a.id
JOIN entities e ON a.entity_id = e.id
GROUP BY a.id
ORDER BY e.name, a.name
"
```

**Important:** Categories with the same name can exist for different entities. Always filter by entity when querying by category name.

## Workflows

### Initial Setup (New User)

Run `/setup` for guided onboarding, or manually:

1. `./scripts/init` - Creates empty database
2. Place OFX files in `data/`
3. Create entities and accounts:
   ```bash
   ./scripts/entity add --name "Personal"
   ./scripts/account add --entity Personal --name "Chequing" --currency CAD
   ```
4. `./scripts/import --file data/FILE.ofx --account "Chequing"`
5. `./scripts/uncategorized --entity Personal`
6. Create categories and patterns as needed

### Import New Statement
1. Add OFX to `data/`
2. `./scripts/import --file data/FILE.ofx --account "Account Name"`
3. `./scripts/uncategorized --entity EntityName`
4. Categorize new transactions or add patterns

### Monthly Review
1. `./scripts/uncategorized` - any missing?
2. `./scripts/report --report-type pnl --entity E --year Y`

### Year-End
1. `./scripts/report --report-type pnl --entity E --year Y`
2. `./scripts/export --entity E --year Y`

## Key Rules

- **Entity isolation:** Each entity has separate categories and patterns
- **FITID deduplication:** Re-importing is safe - duplicates skipped
- **E-transfers require manual verification:** `SEND E-TFR ***XXX` transactions can't be reliably auto-categorized

## OFX File Naming

Name files: `<ENTITY>_<ACCOUNT>_<YEAR>.ofx`

Examples:
- `HOLDCO_CAD_2025.ofx`
- `PERSONAL_VISA_2025_DEC.ofx`
