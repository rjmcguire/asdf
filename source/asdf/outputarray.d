module asdf.outputarray;

import asdf.asdf;

package struct OutputArray
{
	import std.experimental.allocator;
	import std.experimental.allocator.gc_allocator;

	ubyte[] data;
	size_t shift;

	auto result()
	{
		return Asdf(data[0 .. shift]);
	}

	this(size_t initialLength)
	{
		assert(initialLength >= 32);
		data = cast(ubyte[]) GCAllocator.instance.allocate(GCAllocator.instance.goodAllocSize(initialLength));
	}

	size_t skip(size_t len)
	{
		auto ret = shift;
		shift += len;
		if(shift > data.length)
			extend;
		return ret;
	}

	void put(in char[] str)
	{
		size_t newShift = shift + str.length;
		if(newShift < data.length)
			extend(str.length);
		data[shift .. newShift] = cast(ubyte[])str;
		//assert(newShift > shift);
		shift = newShift;
	}

	void put1(ubyte b)
	{
		put1(b, shift);
		shift += 1;
	}

	void put(char b)
	{
		put1(cast(ubyte)b);
	}

	void put4(uint b)
	{
		put4(b, shift);
		shift += 4;
	}

	void put1(ubyte b, size_t sh)
	{
		assert(sh <= data.length);
		if(sh == data.length)
			extend;
		data[sh] = b;
	}

	void put4(uint b, size_t sh)
	{
		immutable newShift = sh + 4;
		if(newShift > data.length)
			extend;

		*cast(uint*) (data.ptr + sh) = b;
	}

	void extend(size_t len)
	{
		size_t length = (data.length) * 2 + len;
		void[] t = data;
		GCAllocator.instance.reallocate(t, length);
		data = cast(ubyte[])t;
	}

	void extend()
	{
		size_t length = (data.length) * 2;
		void[] t = data;
		GCAllocator.instance.reallocate(t, length);
		data = cast(ubyte[])t;
	}
}
