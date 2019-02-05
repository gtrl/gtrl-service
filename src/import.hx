
import haxe.Timer;
import haxe.Timer.delay;

import js.Error;
import js.Promise;

#if nodejs
import js.Node.console;
import js.Node.process;
import js.node.Buffer;
import js.node.Fs;
import js.node.Url;
import Sys.print;
import Sys.println;
import sys.FileSystem;
import om.Term;
#end

import om.Json;
import om.Nil;
import om.Time;
import om.error.*;

using om.ArrayTools;
using om.FloatTools;
using om.StringTools;
