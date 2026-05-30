"""Shared Postgres/PostGIS connection for LRGDM tooling.

The LRGDM source of truth is the Postgres database `lrgdm` (see db/README.md).
All scripts connect through here so the conninfo lives in one place.

    from lrgdm_db import connect, next_id
    with connect() as con:
        cur = con.cursor()
        ...

Conninfo comes from $LRGDM_PG (libpq format), default "dbname=lrgdm".
"""
from __future__ import annotations

import os

import psycopg
from psycopg.rows import dict_row

CONNINFO = os.environ.get("LRGDM_PG", "dbname=lrgdm")


def connect(*, row_factory=dict_row):
    """Open a connection (context-manager friendly). dict_row by default."""
    return psycopg.connect(CONNINFO, row_factory=row_factory)


def next_id(cur, table: str, col: str, prefix: str) -> str:
    """Next free '<prefix>NNNN' id for a table, zero-padded to 4 digits.

    e.g. next_id(cur, 'place', 'place_id', 'PL-') -> 'PL-0200'. Uses a plain
    (tuple) cursor internally so it works regardless of the caller's row_factory.
    """
    cur.execute(
        f"SELECT COALESCE(MAX(substring({col} FROM '[0-9]+$')::int), 0) + 1 "
        f"FROM {table} WHERE {col} ~ %s",
        (f"^{prefix}[0-9]+$",),
    )
    row = cur.fetchone()
    n = row[0] if isinstance(row, (tuple, list)) else next(iter(row.values()))
    return f"{prefix}{n:04d}"
