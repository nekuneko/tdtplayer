# m3u_channel.py

class M3uChannel:
    def __init__(self, name: str, url: str, logo: str = None, ch_no: str = None):
        self.name = name
        self.url = url
        self.logo = logo
        self.ch_no = ch_no
