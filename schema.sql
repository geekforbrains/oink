-- Oink Schema
-- SQLite database for multi-entity transaction management

PRAGMA foreign_keys = ON;

-- Entities (e.g., HoldCo, Personal)
CREATE TABLE IF NOT EXISTS entities (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Bank accounts being tracked
CREATE TABLE IF NOT EXISTS accounts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    entity_id INTEGER NOT NULL REFERENCES entities(id) ON DELETE RESTRICT,
    name TEXT NOT NULL UNIQUE,
    currency TEXT NOT NULL CHECK (currency IN ('CAD', 'USD')),
    account_type TEXT NOT NULL DEFAULT 'asset' CHECK (account_type IN ('asset', 'liability')),
    bank_account_id TEXT,  -- Account number from OFX (ACCTID)
    description TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Category taxonomy (entity_id NULL = shared category)
CREATE TABLE IF NOT EXISTS categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    entity_id INTEGER REFERENCES entities(id) ON DELETE RESTRICT,
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('income', 'expense', 'transfer')),
    description TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(entity_id, name)
);

-- Pattern matching rules for auto-categorization (entity_id NULL = global pattern)
CREATE TABLE IF NOT EXISTS transaction_patterns (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    entity_id INTEGER REFERENCES entities(id) ON DELETE RESTRICT,
    pattern TEXT NOT NULL,
    display_name TEXT NOT NULL,
    category_id INTEGER REFERENCES categories(id) ON DELETE RESTRICT,
    priority INTEGER DEFAULT 100,
    is_active INTEGER DEFAULT 1,
    notes TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Import audit trail
CREATE TABLE IF NOT EXISTS import_batches (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    account_id INTEGER NOT NULL REFERENCES accounts(id) ON DELETE RESTRICT,
    filename TEXT,
    imported_at TEXT DEFAULT CURRENT_TIMESTAMP,
    statement_start_date TEXT,
    statement_end_date TEXT,
    transaction_count INTEGER
);

-- Main transaction ledger
CREATE TABLE IF NOT EXISTS transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    account_id INTEGER NOT NULL REFERENCES accounts(id) ON DELETE RESTRICT,
    category_id INTEGER REFERENCES categories(id) ON DELETE RESTRICT,
    fitid TEXT NOT NULL,  -- Financial Institution Transaction ID (unique per bank)
    date TEXT NOT NULL,
    description TEXT NOT NULL,
    display_name TEXT,
    amount TEXT NOT NULL,  -- Stored as TEXT to preserve Decimal precision
    trntype TEXT,  -- OFX transaction type (CREDIT, DEBIT, etc.)
    reconciled INTEGER DEFAULT 0,
    import_batch_id INTEGER REFERENCES import_batches(id) ON DELETE SET NULL,
    notes TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Prevent duplicate transactions using FITID (bank's unique ID)
CREATE UNIQUE INDEX IF NOT EXISTS idx_transaction_fitid
ON transactions(account_id, fitid);

-- Speed up common queries
CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date);
CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions(category_id);
CREATE INDEX IF NOT EXISTS idx_transactions_account ON transactions(account_id);
CREATE INDEX IF NOT EXISTS idx_patterns_active ON transaction_patterns(is_active, priority DESC);
