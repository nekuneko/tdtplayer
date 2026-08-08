# m3u_channel.py
from dataclasses import dataclass


@dataclass
class M3uChannel:
    name: str
    url: str
    logo: str | None = None
    ch_no: str | None = None
