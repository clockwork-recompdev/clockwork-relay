# clockwork-relay

The Rooms server for [Clockwork](https://github.com/clockwork-recompdev/clockwork): it lets
players anywhere play the games' local wireless together (battles, trades, co-op). Everyone picks
the same relay and room on the launcher's Rooms tab, and the relay hands each player's frames to
the others in the room, as if their consoles were side by side. It holds many rooms at once (16 players each), keeps
nothing on disk, and uses a few KB/s per player. These steps set it up on a home server running
Ubuntu Server; any Linux with systemd works the same.

## 1. Install

On the server:

```sh
git clone https://github.com/clockwork-recompdev/clockwork-relay.git
cd clockwork-relay
sudo ./install.sh
```

That builds just the relay (installing `build-essential` if needed), installs it as the
`clockwork-relay` service (starts on boot, restarts if it stops, runs as an unprivileged throwaway
user), and opens UDP port 47830 in `ufw` if the firewall is on. To update later: `git pull` and
run `sudo ./install.sh` again.

Check it: `systemctl status clockwork-relay`. Watch players come and go:
`journalctl -u clockwork-relay -f`.

## 2. Make it reachable

- **Forward UDP port 47830** on your router to the server's LAN address (only UDP, only that
  port). Giving the server a fixed LAN address (a DHCP reservation) keeps the forward working.
- **Give it a name.** Home IP addresses change; a dynamic DNS name (DuckDNS, No-IP, or your
  router's own) follows them. Players enter that name, e.g. `myname.duckdns.org`.
- **Check for CGNAT.** If your router's WAN address differs from what whatismyip.com shows (or
  starts with `100.64`–`100.127`), your ISP shares one address among customers and forwarding can't
  work: ask the ISP for a public IP, or reach the server through Tailscale (friends only) or a
  small VPS that forwards UDP 47830 to it.

## 3. Play

On each player's launcher: Rooms tab → **A relay server** → your address (`name` or `name:port`),
their name, and a room (any name; the first one in may set a password). Then Play, and use the
game's local wireless menus as usual. The room list on the tab shows who's where.

## Good to know

- Everyone who connects can see the server's IP address. Fine among friends; think about it
  before posting the address publicly.
- Limits keep one client from spoiling it for everyone: 8 players per IP address, about 300
  frames a second per player, 20 room-list or join requests a second per address, 1024 players in
  all.
- Room passwords and game traffic aren't encrypted: a password keeps strangers out of a room, it
  isn't a secret from someone watching the network.
- Another port: edit `ExecStart` in `/etc/systemd/system/clockwork-relay.service`
  (`--port N`), then `sudo systemctl daemon-reload && sudo systemctl restart clockwork-relay`,
  and players add `:N` to the address.

## Building by hand

`cmake -B build && cmake --build build`, or just
`g++ -std=c++20 -O2 src/relay.cpp src/relay_main.cpp -o clockwork-relay`. Runs on Linux, macOS and
Windows (link `ws2_32`). `clockwork-relay --port N` picks another port.

## The protocol

UDP, described at the top of `src/relay.h`. The same files live in clockwork's `runtime/src/net`
(the two-window hub and the launcher's room list use them): a protocol change goes in both.
