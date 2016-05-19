[![Dub version](https://img.shields.io/dub/v/asdf.svg)](http://code.dlang.org/packages/asdf)
[![License](https://img.shields.io/dub/l/asdf.svg)](http://code.dlang.org/packages/asdf)
[![codecov.io](https://codecov.io/github/tamediadigital/asdf/coverage.svg?branch=master)](https://codecov.io/github/tamediadigital/asdf?branch=master)
[![Build Status](https://travis-ci.org/tamediadigital/asdf.svg?branch=master)](https://travis-ci.org/tamediadigital/asdf)

# A Simple Document Format

ASDF is a cache oriented string based JSON representation.
It allows to easily iterate over JSON arrays/objects multiple times without parsing them.
ASDF does not parse numbers (they are represented as strings) and does not decode escape sequence in JSON strings.
ASDF values can be removed by setting `deleted` bit on.

For line separated JSON values see `parseJsonByLine` function.
This function accepts a range of chunks instead of a range of lines.

#### Why ASDF?

ASDF is fast. It can be really helpful if you have gigabytes of JSON line separated values.

#### Specification

See [ASDF Specification](https://github.com/tamediadigital/asdf/blob/master/SPECIFICATION.md).

#### I/O Speed

 - Reading JSON line separated values and parsing them to ASDF - 250+ MB per second (SSD).
 - Writing ASDF range to JSON line separated values - 300+ MB per second (SSD).

#### TODO

1. X86-64 string optimizations for LDC.

#### ASDF Example

```D
import std.algorithm;
import std.stdio;
import asdf;

void main()
{
	auto target = Asdf("red");
	File("input.jsonl")
		// Use at least 4096 bytes for real wolrd apps
		.byChunk(4096)
		// 32 is minimal value for internal buffer. Buffer can be realocated to get more memory.
		.parseJsonByLine(4096)
		.filter!(object => object
			// getValue accepts array of keys: {"key0": {"key1": { ... {"keyN-1": <value>}... }}}
			.getValue(["colors"])
			// iterates over an array
			.byElement
			// Comparison with ASDF is little bit faster
			//   then compression with a string.
			.canFind(target))
			//.canFind("tadmp5800"))
		// Formatting uses internal buffer to reduce system delegate and system function calls
		.each!writeln;
}
```

##### Input

Single object per line: 4th and 5th lines are broken.

```json
null
{"colors": ["red"]}
{"a":"b", "colors": [4, "red", "string"]}
{"colors":["red"],
	"comment" : "this is broken (multiline) object"}
{"colors": "green"}
{"colors": "red"]}}
[]
```

##### Output

```json
{"colors":["red"]}
{"a":"b","colors":[4,"red","string"]}
```


#### JSON and ASDF Serialization Examples

##### Simple struct or object
```d
struct S
{
	string a;
	long b;
	private int c; // private feilds are ignored
	package int d; // package feilds are ignored
	// all other fields in JSON are ignored
}
```

##### Selection
```d
struct S
{
	// ignored
	@serializationIgnore
	int temp;
	
	// can be formatted to json
	@serializationIgnoreIn
	int a;
	
	//can be parsed from json
	@serializationIgnoreOut
	int b;
}
```

##### Key overriding
```d
struct S
{
	// key is overrided to "aaa"
	@serializationKeys("aaa")
	int a;

	// overloads multiple keys for parsing
	@serializationKeysIn("b", "_b")
	// overloads key for generation
	@serializationKeysOut("_b_")
	int b;
}
```

##### User-Defined Serialization
```d
struct DateTimeProxy
{
	DateTime datetime;
	alias datetime this;

	static DateTimeProxy deserialize(Asdf data)
	{
		string val;
		deserializeEscapedString(data, val);
		return DateTimeProxy(DateTime.fromISOString(val));
	}

	void serialize(S)(ref S serializer)
	{
		serializer.putEscapedStringValue(datetime.toISOString);
	}
}
```


##### Serialization Proxy
```d
struct S
{
	@serializedAs!DateTimeProxy
	DateTime time;
}
```
