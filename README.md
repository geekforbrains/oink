```
╭─────────────────╮
│ ░█▀█░█░█▄░█░█▄▀ │
│ ░█▄█░█░█░▀█░█░█ │
╰─────────────────╯
```

# Oink

AI accounting powered by Claude Code. Import bank statements, auto-categorize transactions, generate reports—all through natural conversation.

## Quick Start

```bash
git clone https://github.com/yourusername/oink.git
cd oink
claude
```

Then just say: `/setup`

Claude will guide you through importing your first bank statement.

## How It Works

Oink is designed to be operated entirely through [Claude Code](https://docs.anthropic.com/en/docs/claude-code). You don't run scripts manually—you just talk to Claude:

- *"Import my new bank statement"*
- *"Show me uncategorized transactions"*
- *"What did I spend on software this year?"*
- *"Generate a P&L report for 2025"*

Claude reads the instructions in `CLAUDE.md` and handles everything: creating entities, importing transactions, categorizing expenses, and generating reports.

## Adding Bank Statements

Drop your OFX files into the `data/` folder:

```
data/PERSONAL_CHEQUING_2025.ofx
data/BUSINESS_VISA_2025.ofx
```

Don't worry, Oink tracks transaction ID's and will ignore duplicates on re-import.

**Why OFX, not CSV?** OFX files contain unique transaction IDs (FITIDs) assigned by your bank. This prevents duplicate imports—you can re-import the same statement safely and Oink will skip transactions it's already seen. CSV exports lack these IDs, making accurate bookkeeping unreliable.

### Getting OFX Files

Most banks offer OFX downloads:
1. Log into online banking
2. Go to Account Activity → Download/Export
3. Select "Microsoft Money", "Quicken", or "OFX" format
4. Save to the `data/` folder

Name files descriptively: `<ENTITY>_<ACCOUNT>_<YEAR>.ofx`

## Core Concepts

**Entities** — Separate books for different purposes (Personal, Business, Rental Property). Each entity has its own categories and patterns.

**Categories** — How you classify transactions (Groceries, Software, Revenue). Categories are typed as income, expense, or transfer.

**Patterns** — Rules that auto-categorize transactions. When Claude sees "NETFLIX" in a bank memo, it can automatically categorize it as "Subscriptions" and display it as "Netflix" instead of "NETFLIX.COM NETFLIX.COM CA".

**Uncategorized** — New transactions that don't match any pattern. Claude helps you review these and create patterns for recurring ones.

## Example Session

```
You: import the new visa statement
Claude: Found data/PERSONAL_VISA_2025_JAN.ofx. Importing...
        Imported 47 transactions, 12 uncategorized.

You: show uncategorized
Claude: Here are 12 uncategorized transactions...
        I notice 5 are from UBER EATS. Want me to create a pattern?

You: yes, categorize as dining
Claude: Created pattern: UBER EATS → "Uber Eats" (Dining)
        Applied to 5 transactions.
```

## Requirements

- Python 3.8+
- Claude Code CLI
- No other dependencies (uses only Python stdlib)
