module tbmlib::fibload;
import std::io;
import std::io::file;
import std::net;
import tbmlib::common;

alias FibEntryFn = fn void?(InetAddress *addr, uint prefixlen, void *aux);

<*
  Reads a FIB text file of alternating "ipv4-address" / "prefix-length" lines,
  invoking f for each (address, prefixlen) pair. Each line is freed after use.
  Returns the number of entries; MALFORMED_INPUT if the line count is odd.
*>
fn usz? foreach_ipv4_fib_entry(Allocator allocator, String filename, FibEntryFn f, void *aux) {
    File file = file::open(filename, "r")!;
    defer (void)file.close();
    InetAddress addr;
    usz lines = 0;
    while (try String line = io::readline(allocator, &file)) {
        defer alloc::free(allocator, line.ptr);
        if (lines % 2 == 0) {
            addr = net::ipv4_from_str(line)!;
        } else {
            f(&addr, line.to_uint()!, aux)!;
        }
        lines++;
    }
    if (lines % 2 != 0) {
        return common::MALFORMED_INPUT~;
    }
    return lines / 2;
}
