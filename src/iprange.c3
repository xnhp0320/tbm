module iprange <KeyType>;

import std::collections::range;
import std::collections::list;
import tbmlib::cidr;
import tbmlib::common;

faultdef INVALID_RANGE;

typedef IpRange = inline range::Range {KeyType};

fn sz? IpRange.to_format(&self, Formatter *f) @dynamic {
    return f.printf("[%x %x]", self.start, self.end);
}

alias Cidr @private = cidr::Cidr {KeyType};

<* @require common::@cidr_valid(cidr)
*>
fn IpRange iprange_from_cidr(Cidr cidr) {
    IpRange self;
    self.start = cidr.ip;
    if (cidr.cidr < $Typeof(cidr.ip)::size * 8) {
        self.end = cidr.ip | (((KeyType)1 << ($Typeof(cidr.ip)::size * 8 - cidr.cidr)) - 1);
    } else {
        self.end = cidr.ip;
    }

    return self;
}

fn Cidr? cidr_from_iprange(IpRange r) {
    if (r.end < r.start) {
        return INVALID_RANGE~;
    }
    KeyType mask = r.end - r.start;
    // Inclusive CIDR range <=> mask is 0b1..1 and start is aligned to that mask.
    if ((mask & (mask + 1)) != 0 || (r.start & mask) != 0) {
        return INVALID_RANGE~;
    }
    return { .ip = r.start, .cidr = (uint)(KeyType::size * 8 - mask.popcount()) };
}

alias IpRangeList = List {IpRange};

import std::io;
import std::io::file;
import std::net;
import std::sort;
import std::collections::priorityqueue;

fn bool IpRange.less(&self, IpRange other) {
    return self.start < other.start; 
}

fn void? load_ipv4_rangelist(Allocator alloc, String filename, IpRangeList *rl) {
    File f = file::open(filename, "r")!;
    defer (void)f.close();
    usz idx = 0;
    InetAddress addr;
    while (1) {
        if (try String line = io::readline(alloc, &f)) {
            if (idx % 2 == 0) {
                addr = net::ipv4_from_str(line)!;
            } else {
                uint cidr = line.to_uint()!;
                Cidr c;
                c.from(&addr, cidr);
                rl.push(iprange_from_cidr(c));
            }
        } else {
            break;
        }
        idx ++;
    }
    if (idx % 2 != 0) {
        return common::MALFORMED_INPUT~;
    }
}

struct IndexedRange {
    IpRange r;
    uint orig_idx;
}

fn bool IndexedRange.less(&self, IndexedRange other) {
    return self.r.start < other.r.start;
}

alias IndexedRangeList = List {IndexedRange};
alias IdxList = List {uint};

fn uint? pick_winner(IdxList *idx_list, IndexedRangeList *items) {
    uint winner_pos = idx_list.[0];
    uint prefixlen = cidr_from_iprange(items.[winner_pos].r)!.cidr;
    foreach (pos : idx_list.array_view()[1 .. ]) {
        Cidr c = cidr_from_iprange(items.[pos].r)!;
        if (c.cidr > prefixlen) {
            winner_pos = pos;
            prefixlen = c.cidr;
        }
    }
    return items.[winner_pos].orig_idx;
}

struct Seg (Printable) {
    IpRange r;
    uint idx; // index into the original (pre-sort) IpRangeList
}

fn bool Seg.equals(self, Seg other) @operator(==) {
    return self.r.start == other.r.start && self.r.end == other.r.end && self.idx == other.idx;
}

fn sz? Seg.to_format(&self, Formatter *f) @dynamic {
    return f.printf("[%x %x] %s\n", self.r.start, self.r.end, self.idx);
}

struct HeapItem {
    KeyType end;
    uint idx;
}

fn bool HeapItem.less(&self, HeapItem other) {
    return self.end < other.end;
}

alias Heap = PriorityQueue {HeapItem};
alias SegList = List {Seg};

fn uint? SegList.do_lpm(&self, KeyType ip) {
    if (self.len() == 0) {
        return common::MISSING~;
    }

    sz lo = 0;
    sz hi = (sz)self.len() - 1;

    while (lo <= hi) {
        sz mid = lo + ((hi - lo) / 2);
        Seg seg = self.[(usz)mid];
        if (ip < seg.r.start) {
            hi = mid - 1;
            continue;
        }
        if (ip > seg.r.end) {
            lo = mid + 1;
            continue;
        }
        return seg.idx;
    }

    return common::MISSING~;
}

fn SegList? IpRangeList.build_segs(&self) {
    SegList sg_list;
    sg_list.init(mem);
    if (self.len() == 0) {
        return sg_list;
    }

    IndexedRangeList items;
    items.init(mem);
    defer items.free();
    uint i = 0;
    foreach (r : self) {
        items.push({ .r = r, .orig_idx = i });
        i++;
    }
    quicksort(&items);

    List{uint} in_heap;
    in_heap.init(mem);
    defer in_heap.free();

    Heap h;
    h.init(mem);
    defer h.free();

    h.push({items.[0].r.end, 0});
    KeyType start = items.[0].r.start;
    in_heap.push(0);

    uint idx = 1;
    while OUTER: (idx < items.len()) {
        KeyType curr_start = items.[idx].r.start;

        while (start <= curr_start) {
            if (curr_start == start) {
                //do not generate segs.
                in_heap.push(idx);
                h.push({items.[idx].r.end, idx});
                idx++;
                continue OUTER;
            }

            if (h.len() == 0) {
                start = curr_start;
                in_heap.push(idx);
                h.push({items.[idx].r.end, idx});
                idx++;
                continue OUTER;
            }

            //curr_start > start
            HeapItem top = h.first()!;
            if (curr_start <= top.end) {
                //[start, curr_start], [curr_start + 1, ..]
                uint winner = pick_winner(&in_heap, &items)!;
                sg_list.push({.r = {start, curr_start - 1}, .idx = winner });
                start = curr_start;
                in_heap.push(idx);
                h.push({items.[idx].r.end, idx});
                idx ++;
                continue OUTER;
            } else {
                while (h.len() > 0 && curr_start > h.first()!.end) {
                    top = h.first()!;
                    if (top.end >= start) {
                        uint winner = pick_winner(&in_heap, &items)!;
                        sg_list.push({.r = {start, top.end}, .idx = winner });
                        start = top.end + 1;
                    }
                    top = h.pop()!;
                    in_heap.remove_item(top.idx);
                }
            }
        }
    }

    //start should be the last range's start
    assert (start == items.array_view()[^1].r.start);
    HeapItem top;
    while (h.len() > 0) {
        top = h.first()!;
        if (top.end >= start) {
            uint winner = pick_winner(&in_heap, &items)!;
            sg_list.push({.r = {start, top.end}, .idx = winner });
            start = top.end + 1;
        }
        top = h.pop()!;
        in_heap.remove_item(top.idx);
    }
    return sg_list;
}
