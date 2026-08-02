# m3u_channel.py
from dataclasses import dataclass
from typing import Optional

@dataclass
class M3uChannel:
    name: str
    url: str
    logo: Optional[str] = None
    ch_no: Optional[str] = None
