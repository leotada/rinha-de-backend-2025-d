module utils.env;

import core.stdc.stdlib: getenv;
import std.string: toStringz, fromStringz;


// This module provides a function to safely retrieve environment variables.
// It returns a default value if the environment variable is not set or is empty.
@trusted:
string getEnv(string key, string defaultValue) {
    auto envPtr = getenv(key.toStringz());
    if (envPtr is null) {
        return defaultValue;
    }
    string value = fromStringz(envPtr).idup;
    if (value.length == 0) {
        return defaultValue;
    }
    return value;
}
