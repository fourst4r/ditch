module ditch.http;

import vibe.data.json;

class Streams
{
	class Data
	{
		string id;
		string userID;
		string gameID;
		string[] communityIDs;
		string type;
		string title;
		int viewerCount;
		string startedAt;
		string language;
		string thumbnailURL;
	}

	class Pagination
	{
		string cursor;
	}

	Data[] data;
	Pagination pagination;
}

class TwitchAPIError
{
	string error;
	int status;
	string message;
}

class Users
{
	struct Data
	{
		string id;
		string login;
		@name("display_name") string displayName;
		string type;
		@name("broadcaster_type") string broadcasterType;
		string description;
		@name("profile_image_url") string profileImageURL;
		@name("offline_image_url") string offlineImageURL;
		@name("view_count") int viewCount;
		@optional string email;
	}

	Data[] data;
}
public import std.variant;

class TwitchAPIProcessor
{
	import vibe.http.client;
	import vibe.core.log;
	import vibe.stream.operations : readAll, readAllUTF8;
	import std.conv;

	enum URL = "https://api.twitch.tv/helix/";

	this(string clientID)
	{
		_clientID = clientID;
	}

	void fetchUsers(void delegate(Users) callback, Algebraic!(int, string)[] args...)
	in (args.length)
	{
		string url = URL~"users?";
		foreach (Algebraic!(int, string) arg; args)
		{
			import std.format : format;
			if (arg.peek!int)
				url ~= format("&id=%d", arg.get!int);
			else
				url ~= format("&login=%s", arg.get!string);
		}
		fetch(url, HTTPMethod.GET, callback);
	}

	void fetch(T)(string query, HTTPMethod method, void delegate(T) callback)
	{
		requestHTTP(
			query,
			(scope HTTPClientRequest req) {
				req.headers["Client-ID"] = _clientID;
				req.method = method;
			},
			(scope HTTPClientResponse res) {
				if (res.statusCode != HTTPStatus.OK)
					throw new HTTPStatusException(res.statusCode);
				
				T val;
				deserializeJson!T(val, res.readJson());
				if (callback != null)
				    callback(val);
			}
		);
	}

private:
	string _clientID;
}