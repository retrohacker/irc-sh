A pure bash implementation of an irc client.

Directories are created for each network and channel.
Write to the `input` file to write to a network/channel
or send a command. The log captures all received
messages.

You probably shouldn't actually use this. But the bash
file is fun to read ;-)

```
./
├── irc.freenode.net
│   ├── kisslinux.input
│   └── kisslinux.log
├── irc.freenode.net.input
└── irc.freenode.net.log
```
