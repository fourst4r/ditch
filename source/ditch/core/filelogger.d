module ditch.core.filelogger;

import std.experimental.logger.core;
import std.experimental.logger.filelogger;
import std.stdio;

import std.typecons : Flag;

/** A FileLogger without the source information.
*/
class MyFileLogger : FileLogger
{
	import std.concurrency : Tid;
    import std.datetime.systime : SysTime;
    import std.format : formattedWrite;

	/** A constructor for the `FileLogger` Logger.

    Params:
	fn = The filename of the output file of the `FileLogger`. If that
	file can not be opened for writting an exception will be thrown.
	lv = The `LogLevel` for the `FileLogger`. By default the

    Example:
    -------------
    auto l1 = new FileLogger("logFile");
    auto l2 = new FileLogger("logFile", LogLevel.fatal);
    auto l3 = new FileLogger("logFile", LogLevel.fatal, CreateFolder.yes);
    -------------
    */
    this(const string fn, const LogLevel lv = LogLevel.all) @safe
    {
		this(fn, lv, CreateFolder.yes);
    }

    /** A constructor for the `FileLogger` Logger that takes a reference to
    a `File`.

    The `File` passed must be open for all the log call to the
    `FileLogger`. If the `File` gets closed, using the `FileLogger`
    for logging will result in undefined behaviour.

    Params:
	fn = The file used for logging.
	lv = The `LogLevel` for the `FileLogger`. By default the
	`LogLevel` for `FileLogger` is `LogLevel.all`.
	createFileNameFolder = if yes and fn contains a folder name, this
	folder will be created.

    Example:
    -------------
    auto file = File("logFile.log", "w");
    auto l1 = new FileLogger(file);
    auto l2 = new FileLogger(file, LogLevel.fatal);
    -------------
    */
    this(const string fn, const LogLevel lv, CreateFolder createFileNameFolder) @safe
    {
        super(fn, lv, createFileNameFolder);
    }

    /** A constructor for the `FileLogger` Logger that takes a reference to
    a `File`.

    The `File` passed must be open for all the log call to the
    `FileLogger`. If the `File` gets closed, using the `FileLogger`
    for logging will result in undefined behaviour.

    Params:
	file = The file used for logging.
	lv = The `LogLevel` for the `FileLogger`. By default the
	`LogLevel` for `FileLogger` is `LogLevel.all`.

    Example:
    -------------
    auto file = File("logFile.log", "w");
    auto l1 = new FileLogger(file);
    auto l2 = new FileLogger(file, LogLevel.fatal);
    -------------
    */
    this(File file, const LogLevel lv = LogLevel.all) @safe
    {
        super(file, lv);
    }

    /* This method overrides the base class method in order to log to a file
    without requiring heap allocated memory. Additionally, the `FileLogger`
    local mutex is logged to serialize the log calls.
    */
    override protected void beginLogMsg(string file, int line, string funcName,
										string prettyFuncName, string moduleName, LogLevel logLevel,
										Tid threadId, SysTime timestamp, Logger logger)
        @safe
		{
			import std.string : lastIndexOf;
			ptrdiff_t fnIdx = file.lastIndexOf('/') + 1;
			ptrdiff_t funIdx = funcName.lastIndexOf('.') + 1;

			auto lt = this.file_.lockingTextWriter();
			systimeToISOString(lt, timestamp);
			import std.conv : to;
			formattedWrite(lt, " [%s] ", logLevel.to!string);
		}
}