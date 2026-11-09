#!/usr/bin/env python3
"""Reproductor MPRIS de mentira para capturas y pruebas (no suena nada).
Uso: demo-player.py "Título" "Artista" /ruta/caratula.png
"""
import sys, time
from gi.repository import Gio, GLib

title, artist, art = (sys.argv[1:4] + ["Nácar", "Demo", ""])[:3]
XML = """<node>
<interface name="org.mpris.MediaPlayer2">
 <property name="Identity" type="s" access="read"/>
 <property name="CanRaise" type="b" access="read"/><property name="CanQuit" type="b" access="read"/>
 <property name="HasTrackList" type="b" access="read"/>
</interface>
<interface name="org.mpris.MediaPlayer2.Player">
 <method name="PlayPause"/><method name="Play"/><method name="Pause"/><method name="Next"/><method name="Previous"/><method name="Stop"/>
 <method name="Seek"><arg type="x" direction="in"/></method>
 <method name="SetPosition"><arg type="o" direction="in"/><arg type="x" direction="in"/></method>
 <property name="PlaybackStatus" type="s" access="read"/>
 <property name="Metadata" type="a{sv}" access="read"/>
 <property name="Position" type="x" access="read"/>
 <property name="Volume" type="d" access="readwrite"/>
 <property name="Rate" type="d" access="read"/>
 <property name="CanPlay" type="b" access="read"/><property name="CanPause" type="b" access="read"/>
 <property name="CanGoNext" type="b" access="read"/><property name="CanGoPrevious" type="b" access="read"/>
 <property name="CanSeek" type="b" access="read"/><property name="CanControl" type="b" access="read"/>
</interface></node>"""
start = time.time() - 74
playing = True
LENGTH = 214_000_000

def props(iface):
    if iface == "org.mpris.MediaPlayer2":
        return {"Identity": GLib.Variant("s", "Demo"), "CanRaise": GLib.Variant("b", False),
                "CanQuit": GLib.Variant("b", False), "HasTrackList": GLib.Variant("b", False)}
    meta = {"mpris:trackid": GLib.Variant("o", "/nacar/track/1"), "xesam:title": GLib.Variant("s", title),
            "xesam:artist": GLib.Variant("as", [artist]), "mpris:length": GLib.Variant("x", LENGTH)}
    if art:
        meta["mpris:artUrl"] = GLib.Variant("s", "file://" + art)
    pos = int((time.time() - start) * 1e6) % LENGTH
    return {"PlaybackStatus": GLib.Variant("s", "Playing" if playing else "Paused"), "Metadata": GLib.Variant("a{sv}", meta),
            "Position": GLib.Variant("x", pos), "Volume": GLib.Variant("d", 1.0), "Rate": GLib.Variant("d", 1.0),
            **{k: GLib.Variant("b", True) for k in ["CanPlay", "CanPause", "CanGoNext", "CanGoPrevious", "CanSeek", "CanControl"]}}

def call(conn, sender, path, iface, method, params, inv):
    global playing
    if method in ("PlayPause",): playing = not playing
    elif method == "Play": playing = True
    elif method in ("Pause", "Stop"): playing = False
    inv.return_value(None)

def get(conn, sender, path, iface, prop):
    return props(iface)[prop]

def acquired(conn, name):
    info = Gio.DBusNodeInfo.new_for_xml(XML)
    for i in info.interfaces:
        conn.register_object("/org/mpris/MediaPlayer2", i, call, get, None)

Gio.bus_own_name(Gio.BusType.SESSION, "org.mpris.MediaPlayer2.nacardemo", 0, acquired, None, None)
GLib.MainLoop().run()
