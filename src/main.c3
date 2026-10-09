module tbm;

import tbmlib;
import tbmlib::cidr;
import tbmlib::fibload;
import std::io;
import std::net;

alias FibCidr = cidr::Cidr {uint};

fn void? insert_fib_entry(InetAddress *addr, uint prefixlen, void *aux) <Tbm> {
    FibCidr c;
    c.from(addr, prefixlen);
    return ((Tbm*)aux).insert(c, c);
}

fn usz? load_ipv4_fib_tbm(Allocator alloc, String filename, Tbm *tbm) <Tbm> {
    return fibload::foreach_ipv4_fib_entry(alloc, filename, &insert_fib_entry{Tbm}, tbm);
}

macro gen_stride_report($s) {
    Tbm{$s, uint, FibCidr} tbm;
    TrivialAllocator{$s, uint, FibCidr} alloc;
    tbm.alloc = &alloc;

    usz rules = load_ipv4_fib_tbm{Tbm{$s, uint, FibCidr}}(mem, "ipv4_fib_large.txt", &tbm)!!;
    io::printf("fib=%s stride=%d %s\n", rules, $s, tbm.memory_stats());
}

macro report_all_stride_memory() {
    $for var $s = 3; $s <= 7; $s++:
        { gen_stride_report($s); }
    $endfor;
}

fn int main(String[] args) {
    report_all_stride_memory();
    return 0;
}
