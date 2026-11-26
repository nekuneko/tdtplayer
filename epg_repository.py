# epg_repository.py
import sqlite3
from datetime import datetime, timezone


class EpgRepository:
    def __init__(self, db_path: str):
        self.db_path = db_path
        self._conn = None
        self._cursor = None
        self._init_sqlite_db()

    def _init_sqlite_db(self) -> None:
        try:
            self._conn = sqlite3.connect(self.db_path)
            self._cursor = self._conn.cursor()
            self._cursor.execute("PRAGMA journal_mode=WAL")
            self._cursor.execute("PRAGMA synchronous=NORMAL")
            self._cursor.execute("""
                CREATE TABLE IF NOT EXISTS epg_store (
                    channel_name TEXT,
                    start_ts INTEGER,
                    stop_ts INTEGER,
                    title TEXT,
                    description TEXT,
                    PRIMARY KEY (channel_name, start_ts)
                )
            """)
            self._cursor.execute(
                "CREATE INDEX IF NOT EXISTS idx_epg_query ON epg_store (channel_name, stop_ts)"
            )
            self._conn.commit()
        except sqlite3.Error as sql_err:
            print(f"[EpgRepository] Error inicializando SQLite WAL: {sql_err}")

    def _fetch_program(
        self,
        channel_name: str,
        offset: int,
        empty_cursor_title: str,
        fallback_title: str,
        fallback_desc: str,
    ) -> dict:
        if not self._cursor:
            return {"title": empty_cursor_title, "description": "", "start_ts": 0, "stop_ts": 0}

        search_name = str(channel_name).strip()
        current_time = int(datetime.now(timezone.utc).timestamp())
        try:
            self._cursor.execute(
                """
                SELECT start_ts, stop_ts, title, description FROM epg_store
                WHERE channel_name = ? AND stop_ts > ? ORDER BY start_ts ASC LIMIT 1 OFFSET ?
                """,
                (search_name, current_time, offset),
            )
            row = self._cursor.fetchone()
            if row:
                s_dt = datetime.fromtimestamp(row[0], tz=timezone.utc).astimezone()
                e_dt = datetime.fromtimestamp(row[1], tz=timezone.utc).astimezone()
                time_str = f"[{s_dt.strftime('%H:%M')} - {e_dt.strftime('%H:%M')}]"
                return {
                    "title": f"{time_str} {row[2]}",
                    "description": row[3],
                    "start_ts": int(row[0]),
                    "stop_ts": int(row[1]),
                }
        except sqlite3.Error as sql_err:
            print(f"[EpgRepository] Error SQLite (offset={offset}): {sql_err}")

        return {"title": fallback_title, "description": fallback_desc, "start_ts": 0, "stop_ts": 0}

    def fetch_current_program(self, channel_name: str) -> dict:
        return self._fetch_program(
            channel_name,
            offset=0,
            empty_cursor_title="Emisión en directo",
            fallback_title="Emisión en directo",
            fallback_desc="Sin descripción detallada disponible.",
        )

    def fetch_next_program(self, channel_name: str) -> dict:
        return self._fetch_program(
            channel_name,
            offset=1,
            empty_cursor_title="[--:-- - --:--] Sin datos",
            fallback_title="[--:-- - --:--] Sin datos de programación futura",
            fallback_desc="No se encontraron más eventos planificados en la base de datos local.",
        )

    def close(self) -> None:
        try:
            if self._cursor is not None:
                self._cursor.close()
                self._cursor = None
            if self._conn is not None:
                self._conn.close()
                self._conn = None
        except sqlite3.Error as sql_err:
            print(f"[EpgRepository] Error al cerrar la conexión: {sql_err}")

    def __del__(self) -> None:
        self.close()
