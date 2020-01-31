module ditch.http;

import std.net.curl;

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

class Users
{
	class Data
	{
		string id;
		string login;
		string displayName;
		string type;
		string broadcasterType;
		string description;
		string profileImageURL;
		string offlineImageURL;
		int viewCount;
		string email;
	}

	Data[] data;
}

template GenAPI(T, string[string] params)
{
	const string GenAPI = 
`%s fetch%s()
{
	
}`.format();
}

//mixin(GenAPI!(Users, ));

class TwitchAPIProcessor
{
	import std.json;

	enum URL = "https://api.twitch.tv/helix/";

	this(string clientID)
	{
		client = HTTP();
		client.addRequestHeader("Client-ID", clientID);
	}

	JSONValue fetch(string query)
	{
		string response = cast(string) get(URL ~ query, client);
		return parseJSON(response);
	}

	T fetch(T)(string query)
	{
		string response = cast(string) get(URL ~ query, client);
	}

private:
	HTTP client;
}