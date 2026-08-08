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

    def fetch_current_program(self, channel_name: str) -> dict:
        search_name = str(channel_name).strip()
        current_time = int(datetime.now(timezone.utc).timestamp())
        try:
            if not self._cursor:
                return {
                    "title": "Emisión en directo",
                    "description": "",
                    "start_ts": 0,
                    "stop_ts": 0,
                }

            self._cursor.execute(
                """
                SELECT start_ts, stop_ts, title, description FROM epg_store 
                WHERE channel_name = ? AND stop_ts > ? ORDER BY start_ts ASC LIMIT 1
            """,
                (search_name, current_time),
            )
            row = self._cursor.fetchone()
            if row:
                # 🚀 SINCRO LOCAL: Convertimos el timestamp consciente a la zona horaria local de tu sistema (.astimezone())
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
            print(f"[EpgRepository] Error SQLite now en consulta principal: {sql_err}")
        return {
            "title": "Emisión en directo",
            "description": "Sin descripción detallada disponible.",
            "start_ts": 0,
            "stop_ts": 0,
        }

    def fetch_next_program(self, channel_name: str) -> dict:
        search_name = str(channel_name).strip()
        current_time = int(datetime.now(timezone.utc).timestamp())
        try:
            if not self._cursor:
                return {
                    "title": "[--:-- - --:--] Sin datos",
                    "description": "",
                    "start_ts": 0,
                    "stop_ts": 0,
                }

            self._cursor.execute(
                """
                SELECT start_ts, stop_ts, title, description FROM epg_store 
                WHERE channel_name = ? AND stop_ts > ? ORDER BY start_ts ASC LIMIT 1 OFFSET 1
            """,
                (search_name, current_time),
            )
            row = self._cursor.fetchone()
            if row:
                # 🚀 SINCRO LOCAL: Convertimos el timestamp consciente a la zona horaria local de tu sistema (.astimezone())
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
            print(f"[EpgRepository] Error SQLite next en consulta principal: {sql_err}")
        return {
            "title": "[--:-- - --:--] Sin datos de programación futura",
            "description": "No se encontraron más eventos planificados en la base de datos local.",
            "start_ts": 0,
            "stop_ts": 0,
        }

    def close(self) -> None:
        try:
            if self._conn:
                self._conn.close()
        except sqlite3.Error as sql_err:
            print(f"[EpgRepository] Error al cerrar la conexión: {sql_err}")
