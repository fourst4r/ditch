module ditch.tmi;

import std.conv : to;
import std.socket;
import std.string;
import std.algorithm.mutation : remove;
import std.range;
import std.algorithm.searching : canFind, any;
import std.stdio;

class Connect {}

class Disconnect
{
	Exception e;
}

class RawMessage
{
	// should these be protected? 🤔
	const string[string] tags;
	const string nick;
	const string user;
	const string host;
	const string command;
	const string[] params;

	this(RawMessage raw)
	{
		this.tags = raw.tags;
		this.nick = raw.nick;
		this.user = raw.user;
		this.host = raw.host;
		this.command = raw.command;
		this.params = raw.params;
	}

	this(string[string] tags, string nick, string user, string host, string command, string[] params)
	{
		this.tags = tags;
		this.nick = nick;
		this.user = user;
		this.host = host;
		this.command = command;
		this.params = params;
	}
}

/// Join a channel.
class Join : RawMessage
{
	@property string channel() { return params[0][1..$]; }

	this(RawMessage raw)
	{
		super(raw);
	}
}

/// Depart from a channel.
class Part : RawMessage
{
	@property string channel() { return params[0][1..$]; }

	this(RawMessage raw)
	{
		super(raw);
	}
}

/// List current chatters in a channel.
class Names : RawMessage
{
	@property string channel() { return params[2][1..$]; }
	@property string[] users() { return params[3].split(' '); }

	this(RawMessage raw)
	{
		super(raw);
	}
}

/// Gain/lose moderator (operator) status in a channel.
class Mode : RawMessage
{
	@property string channel() { return params[0][1..$]; }
	@property bool isPromotion() { return params[1] == "+o"; }
	@property string user() { return params[2]; }

	this(RawMessage raw)
	{
		super(raw);
	}
}

/// Sends a message to a channel.
class PrivMsg : RawMessage
{
	@property string badgeInfo() { return tags["badge-info"]; }
	@property string badges() { return tags["badges"]; }
	@property string color() { return tags["color"]; }
	@property string displayName() { return tags["display-name"]; }
	@property string emotes() { return tags["emotes"]; }
	@property string flags() { return tags["flags"]; }
	@property string id() { return tags["id"]; }
	@property bool mod() { return to!bool(tags["mod"]); }
	@property string roomID() { return tags["room-id"]; }
	@property bool subscriber() { return to!bool(tags["subscriber"]); }
	@property string tmiSentTs() { return tags["tmi-sent-ts"]; }
	@property bool turbo() { return to!bool(tags["turbo"]); }
	@property string userID() { return tags["user-id"]; }
	@property string userType() { return tags["user-type"]; }
	@property string author() { return nick; };
	@property string channel() { return params[0][1..$]; };
	@property string message() { return params[1]; }

	this(RawMessage raw)
	{
		super(raw);
	}
}

class Whisper : RawMessage
{
	@property string author() { return params[0]; };
	@property string message() { return params[1]; }

	this(RawMessage raw)
	{
		super(raw);
	}
}

/// General notices from the server.
class Notice : RawMessage
{
	@property string msgID() { return tags["msg-id"]; }
	@property string channel() { return params[0][1..$]; };
	@property string message() { return params[1]; }

	this(RawMessage raw)
	{
		super(raw);
	}
}

class Ping : RawMessage
{
	this(RawMessage raw)
	{
		super(raw);
	}
}

/// Purge a user’s message(s), typically after a user is banned from chat or timed out.
class ClearChat : RawMessage
{
	@property string channel() { return params[0][1..$]; };
	@property string user() { return params.length == 2 ? params[1] : null; }

	this(RawMessage raw)
	{
		super(raw);
	}
}

/// Single message removal on a channel. This is triggered via /delete <target-msg-id> on IRC.
class ClearMsg : RawMessage
{
	/// Name of the user who sent the message.
	@property string login() { return tags["login"]; }
	/// UUID of the message.
	@property string targetMsgID() { return tags["target-msg-id"]; }
	@property string channel() { return params[0][1..$]; }
	@property string message() { return params[1]; }

	this(RawMessage raw)
	{
		super(raw);
	}
}

/// Channel starts or stops host mode.
class HostTarget : RawMessage
{
	@property string hoster() { return params[0][1..$]; }
	@property string hosted() { return params[1][0..$-2]; } // trim the " -"... why is that on the end???
	@property int viewers() { return params.length == 3 ? to!int(params[2]) : 0; }
	@property bool isUnhost() { return hosted == "-"; }

	this(RawMessage raw)
	{
		super(raw);
	}
}

/// On successful login, provides data about the current logged-in user through IRC tags. 
/// It is sent after successfully authenticating (sending a PASS/NICK command).
class GlobalUserState : RawMessage
{
	@property string badgeInfo() { return tags["badge-info"]; }
	@property string badges() { return tags["badges"]; }
	@property string color() { return tags["color"]; }
	@property string displayName() { return tags["display-name"]; }
	@property string emoteSets() { return tags["emote-sets"]; }
	@property string userID() { return tags["user-id"]; }
	@property string userType() { return tags["user-type"]; }

	this(RawMessage raw)
	{
		super(raw);
	}
}

/// Announces Twitch-specific events to the channel (e.g., a user’s subscription notification).
class UserNotice : RawMessage
{
	@property string badgeInfo() { return tags["badge-info"]; }
	@property string badges() { return tags["badges"]; }
	@property string color() { return tags["color"]; }
	@property string displayName() { return tags["display-name"]; }
	@property string emotes() { return tags["emotes"]; }
	@property string id() { return tags["id"]; }
	@property string login() { return tags["login"]; }
	@property bool mod() { return to!bool(tags["mod"]); }
	@property string msgID() { return tags["msg-id"]; }
	@property string roomID() { return tags["room-id"]; }
	deprecated("use badges instead") @property string subscriber() { return tags["subscriber"]; }
	@property string systemMsg() { return tags["system-msg"]; }
	@property string tmiSentTs() { return tags["tmi-sent-ts"]; }
	deprecated("use badges instead") @property bool turbo() { return to!bool(tags["turbo"]); }
	@property string userID() { return tags["user-id"]; }
	deprecated("use badges instead") @property string userType() { return tags["user-type"]; }
	@property string channel() { return params[0][1..$]; }
	@property string message() { return params[1]; }

	this(RawMessage raw)
	{
		super(raw);
	}
}

/// Identifies a user’s chat settings or properties (e.g., chat color).
class UserState : RawMessage
{
	@property string badgeInfo() { return tags["badge-info"]; }
	@property string badges() { return tags["badges"]; }
	@property string color() { return tags["color"]; }
	@property string displayName() { return tags["display-name"]; }
	@property string emoteSets() { return tags["emote-sets"]; }
	@property bool mod() { return to!bool(tags["mod"]); }
	deprecated("use badges instead") @property bool subscriber() { return to!bool(tags["subscriber"]); }
	deprecated("use badges instead") @property bool turbo() { return to!bool(tags["turbo"]); }
	deprecated("use badges instead") @property string userType() { return tags["user-type"]; }
	@property string channel() { return params[0][1..$]; }

	this(RawMessage raw)
	{
		super(raw);
	}
}

/// Identifies the channel’s chat settings (e.g., slow mode duration).
class RoomState : RawMessage
{
	@property bool emoteOnly() { return to!bool(tags["emote-only"]); }
	@property int followersOnly() { return to!int(tags["followers-only"]); }
	@property bool r9k() { return to!bool(tags["r9k"]); }
	@property bool rituals() { return to!bool(tags["rituals"]); }
	@property string id() { return tags["room-id"]; }
	@property int slow() { return to!int(tags["slow"]); }
	@property bool subsOnly() { return to!bool(tags["subs-only"]); }
	@property string channel() { return params[0][1..$]; };

	this(RawMessage raw)
	{
		super(raw);
	}
}

class Channel
{
	@property string name()
	{
		return _name;
	}

	@property string[] users()
	{
		return _users;
	}

	this(const string name)
	{
		_name = name;
	}

	void addUser(const string user)
	{
		_users ~= user;
	}

	void removeUser(const string user)
	{
		_users = _users.remove!(u => u == user);
	}

private:
	string _name;
	string[] _users;
}


class TMIClient
{
	import std.experimental.logger;
	import std.experimental.logger.filelogger;
	import std.stdio : stdout;
	import std.concurrency : Tid, spawn, concurrencySend = send;
	//import concurrencySend = std.concurrency : send;

	void delegate(PrivMsg) onPrivMsg;
	void delegate(Whisper) onWhisper;
	void delegate(HostTarget) onHostTarget;
	void delegate(GlobalUserState) onGlobalUserState;
	void delegate(UserState) onUserState;
	void delegate(UserNotice) onUserNotice;
	void delegate(RoomState) onRoomState;
	void delegate(Join) onJoin;
	void delegate(Part) onPart;
	void delegate(Mode) onMode;
	void delegate(Names) onNames;
	void delegate(Ping) onPing;
	void delegate(Notice) onNotice;

	//@property Channel[] channels()
	//{
	//    return _channels.values;
	//}

	this(string nick, string oauth, Logger logger)
	{
		
		_nick = nick.toLower();
		_oauth = oauth;
		_logger = logger;
	}
	
	//this(string nick, string oauth)
	//{
	//    this(nick, oauth);
	//    _logger = logger;
	//}

	~this()
	{
		close();
	}

	//Channel getChannel(string channel)
	//{
	//    return _channels[channel];
	//}

	struct CancelMsg {};
	struct CancelMsgAck {};
	static void writeLoop(Tid tid, shared TcpSocket socket)
	{
		bool canceled = false;
		while (!canceled)
		{
			import std.concurrency : receive;
			receive(
				(string msg)
				{
					(cast(TcpSocket) socket).send(msg);
				},
				(CancelMsg a)
				{ 
					concurrencySend(tid, CancelMsgAck());
					canceled = true;
				}
			);

			//(cast(TcpSocket) socket).send(receiveOnly!string);
		}
		writeln("write loop done!!!!!!!!!!!!!!!!!");
	}

	void connect()
	{
		import std.stdio;
		import std.array;
		import core.time : dur;

		_reconnectTime = 0;
		while (true)
		{
			if (_reconnectTime > 0)
			{
				_logger.warningf("reconnecting in %ds", _reconnectTime);

				import core.thread : Thread;
				Thread.sleep(dur!"seconds"(_reconnectTime));
			}

			try
			{
				_socket = new TcpSocket;

				Address[] addresses = getAddress(IRC_ADDRESS, IRC_PORT);
				writefln("  %d addresses found.", addresses.length);
				foreach (size_t i, Address a; addresses)
				{
					writefln("  Address %d:", i+1);
					writefln("    IP address: %s", a.toAddrString());
					writefln("    Hostname: %s", a.toHostNameString());
					writefln("    Port: %s", a.toPortString());
					writefln("    Service name: %s", a.toServiceNameString());
				}
				//    
				//foreach (a; addresses)
				//    writefln("%s %s %s", a.addressFamily, a.toServiceNameString(), a.toAddrString(), a.name);
				auto address = addresses[0];
				_socket.connect(address);

				import std.concurrency : spawn, thisTid;
				writeTid = spawn(&writeLoop, thisTid, cast(shared) _socket);
			}
			catch (SocketOSException e)
			{
				_logger.warningf("failed to connect: %s", e.msg);
				_reconnectTime = _reconnectTime == 0 ? 1 : _reconnectTime << 1;
				close();
				continue;
			}
			_connected = true;
			_reconnectTime = 0;

			send("CAP REQ :twitch.tv/tags twitch.tv/commands twitch.tv/membership");
			send("PASS %s".format(_oauth));
			send("NICK %s".format(_nick));

			rejoin();

			ubyte[2048] buffer = new ubyte[2048];
			string received = "";
			ptrdiff_t amountRead;
			while ((amountRead = _socket.receive(buffer)) > 0)
			{
				received ~= cast(string) buffer[0..amountRead];
				ptrdiff_t pos;
				while ((pos = received.indexOf(IRC_DELIMITER)) != -1)
				{
					string packet = received[0..pos];
					received = received[pos + IRC_DELIMITER.length..$];

					_logger.infof("<- %s", packet);
					RawMessage msg = parseMessage(packet);
					handleMessage(msg);
				}
			}

			if (amountRead == 0 || amountRead == Socket.ERROR)
			{
				_logger.warningf("socket disconnected: %s", _socket.getErrorText());
				_reconnectTime = _reconnectTime == 0 ? 1 : _reconnectTime << 1;
				close();
				continue;
			}
		}
	}

	void close()
	{
		import std.concurrency : receiveOnly;

		_connected = false;

		concurrencySend(writeTid, CancelMsg());
		receiveOnly!CancelMsgAck;
		
		_socket.shutdown(SocketShutdown.BOTH);
		_socket.close();
	}

	void join(const string channel)
	{
		if (channel in _channels) return;

		_channels[channel] = new Channel(channel);
		send("JOIN #%s".format(channel.toLower));
	}

	void depart(const string channel)
	{
		send("PART #%s".format(channel.toLower));
	}

	void sendMessage(const string channel, const string message)
	{
		send("PRIVMSG #%s :%s".format(channel.toLower, message));
	}

	// some convenience methods
	void whisper(const string user, const string message)
	{
		sendMessage(_nick, "/w %s %s".format(user, message));
	}

	import core.time : Duration;
	void timeout(const string channel, const string user, const Duration dur)
	{
		sendMessage(channel, "/timeout %s %d".format(user, dur.total!"seconds"));
	}

	void untimeout(const string channel, const string user)
	{
		sendMessage(channel, "/untimeout %s".format(user));
	}

	void mod(const string channel, const string user)
	{
		sendMessage(channel, "/mod %s".format(user));
	}

	void unmod(const string channel, const string user)
	{
		sendMessage(channel, "/unmod %s".format(user));
	}



private:
	enum string IRC_DELIMITER = "\r\n";
	enum string IRC_ADDRESS = "irc.chat.twitch.tv";
	enum ushort IRC_PORT = 6667;
	enum ushort IRC_PORT_TLS = 6697;

	TcpSocket _socket;
	bool _connected;
	long _reconnectTime;
	string _nick, _oauth;
	Channel[string] _channels;
	Logger _logger;
	Tid writeTid;

	void rejoin()
	{
		import std.algorithm.iteration : map;

		if (_channels.empty) return;
		string channels = _channels.keys.join(",#");
		send("JOIN #%s".format(channels));
	}

	void send(const string s)
	{
		if (!_connected) return;
		_logger.infof("-> %s", s);
		//_socket.send(s ~ IRC_DELIMITER);
		concurrencySend(writeTid, s ~ IRC_DELIMITER);
	}

	static RawMessage parseMessage(const string s)
	{
		if (s.empty) return null;
		string[] parts = s.split(' ');	

		// optional @tags
		string[string] tags;
		if (parts[0].startsWith('@'))
		{
			tags = parseTags(parts[0][1..$]); // trim '@'
			parts.popFront();
		}

		// optional :prefix
		string nick, user, host;
		if (parts[0].startsWith(':'))
		{
			parsePrefix(parts[0][1..$], nick, user, host); // trim ':'
			parts.popFront();
		}

		string command = parts[0];
		string params = parts[1..$].join(" "); // TODO: find a way so i dont have to split and rejoin needlessly
		return new RawMessage(tags, nick, user, host, command, parseParams(params));
	}

	unittest
	{
		bool eq(const RawMessage a, const RawMessage b)
		{
			return a.tags == b.tags
				&& a.nick == b.nick
				&& a.user == b.user
				&& a.host == b.host
				&& a.command == b.command
				&& a.params == b.params;
		}

		assert(eq(parseMessage(":tmi.twitch.tv 001 gofir :Welcome, GLHF!"),
				  new RawMessage(null, null, null, "tmi.twitch.tv", "001", ["gofir", "Welcome, GLHF!"])));
		assert(eq(parseMessage("@key=value :nick!user@ho.st CAP * ACK :twitch.tv/tags twitch.tv/commands twitch.tv/membership"),
				  new RawMessage(["key":"value"], "nick", "user", "ho.st", "CAP", ["*", "ACK", "twitch.tv/tags twitch.tv/commands twitch.tv/membership"])));
	}

	static string[string] parseTags(const string s) pure
	{
		string[string] tags;

		foreach (string kv; s.split(';'))
		{
			long eq = kv.indexOf('=');
			if (eq == -1)
			{
				// just a key with no value... e.g. "foo" (not to be confused with "foo=" which has an empty value)
				tags[kv] = cast(string)null;
			}
			else
			{
				string key = kv[0..eq];
				string value = kv[eq+1..$];
				tags[key] = value;
			}
		}

		return tags;
	}

	unittest
	{
		assert(parseTags("key") == ["key":cast(string)null]);
		assert(parseTags("key=") == ["key":""]);
		assert(parseTags("key=value") == ["key":"value"]);
		assert(parseTags("badge-info=;color=#5F9EA0;display-name=gofir;emote-sets=0,33563;user-id=91864073;user-type=")
			   == ["badge-info":"", "color":"#5F9EA0", "display-name":"gofir", "emote-sets":"0,33563", "user-id":"91864073", "user-type":"" ]);
	}

	static void parsePrefix(const string s, out string nick, out string user, out string host)
	{
		// <host>|<nick>[!<user>][@<host>]
		import std.regex : regex, split;
		auto spl = split(s, regex("!|@"));

		if (spl.length == 1)
		{
			if (spl[0].canFind('.'))
				host = spl[0];
			else
				nick = spl[0];
		}
		else if (spl.length == 2)
		{
			nick = spl[0];
			if (s.canFind('!'))
				user = spl[1];
			else
				host = spl[1];
		}
		else if (spl.length == 3)
		{
			nick = spl[0];
			user = spl[1];
			host = spl[2];
		}
	}

	unittest
	{
		{
			string nick, user, host;
			parsePrefix("nick!user@host", nick, user, host);
			assert(nick == "nick" && user == "user" && host == "host");
		}
		{
			string nick, user, host;
			parsePrefix("nick", nick, user, host);
			assert(nick == "nick");
		}
		{
			string nick, user, host;
			parsePrefix("tmi.twitch.tv", nick, user, host);
			assert(host == "tmi.twitch.tv");
		}
	}

	static string[] parseParams(const string s) pure
	{
		string[] params = [];

		if (s.length == 0) return params;
		if (s[0] == ':') return [ s[1..$] ];

		int paramStart = 0;
		int pos = 0;

		do
		{
			if (s[pos] == ' ')
			{
				string middle = s[paramStart..pos];
				params ~= middle;
				paramStart = pos + 1;

				if (s[pos+1] == ':')
				{
					pos++; // skip ' '
					pos++; // skip ':'
					string trailing = "";
					if (pos < s.length) trailing = s[pos..$];
					params ~= trailing;
					// trailing is the final param, so return!
					return params;
				}
			}
			pos++;
		}
		while (pos < s.length);

		params ~= s[paramStart..pos]; // collect the final middle
		return params;
	}

	unittest
	{
		assert(parseParams("") == []);
		assert(parseParams("middle") == ["middle"]);
		assert(parseParams("middle middle") == ["middle", "middle"]);
		assert(parseParams(":trail ing") == ["trail ing"]);
		assert(parseParams("middle :trailing") == ["middle", "trailing"]);
		assert(parseParams("middle :trail ing") == ["middle", "trail ing"]);
		assert(parseParams("middle middle :trail ing") == ["middle", "middle", "trail ing"]);
	}

	void handleMessage(RawMessage raw)
	{
		switch (raw.command) 
		{
			case "353": // aka NAMES
				// note: your own username gets added twice by the server,
				//       once when you first join the channel, then again
				//       at the end of a 353. 
				if (onNames != null)
					onNames(new Names(raw));
				//auto names = ;
				//foreach (user; users)
				//	_channels[channel].addUser(user);

				break;
			case "GLOBALUSERSTATE":
				if (onGlobalUserState != null)
					onGlobalUserState(new GlobalUserState(raw));
				break;
			case "HOSTTARGET":
				if (onHostTarget != null)
					onHostTarget(new HostTarget(raw));
				break;
			case "JOIN":
				//auto join = new Join(raw);
				//_channels[join.channel].addUser(join.nick);
				if (onJoin != null)
					onJoin(new Join(raw));
				//alias s = std.concurrency.send;
				//s(new Names(raw));
				break;
			case "NAMES":
				if (onNames != null)
					onNames(new Names(raw));
				break;
			case "NOTICE":
				if (onNotice)
					onNotice(new Notice(raw));
				break;
			case "PART":
				//auto part = new Part(raw);
				//_channels[part.channel].removeUser(part.nick);
				if (onPart != null)
					onPart(new Part(raw));
				break;
			case "PING":
				send("PONG :tmi.twitch.tv");
				if (onPing != null)
					onPing(new Ping(raw));
				break;
			case "PRIVMSG":
				if (onPrivMsg != null)
					onPrivMsg(new PrivMsg(raw));
				break;
			case "USERSTATE":
				break;
			case "WHISPER":
				if (onWhisper != null)
					onWhisper(new Whisper(raw));
				break;
			default: 
				break;
		}
	}
}
