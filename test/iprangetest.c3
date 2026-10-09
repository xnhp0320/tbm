module iprangetest;
import iprange;
import tbmlib::cidr;
import tbmlib::common;
import std::io;

alias IpRangeList = iprange::IpRangeList{uint};
alias IpRange = iprange::IpRange{uint};
alias SegList = iprange::SegList{uint}; 
alias Seg = iprange::Seg{uint}; 
alias Cidr = cidr::Cidr{uint};
alias IpRangeList6 = iprange::IpRangeList{uint128};
alias IpRange6 = iprange::IpRange{uint128};
alias SegList6 = iprange::SegList{uint128};
alias Seg6 = iprange::Seg{uint128};
alias Cidr6 = cidr::Cidr{uint128};

fn void test_build_seg_0() @test {
    IpRangeList rl;
    rl.init(mem);
    defer rl.free();
    Cidr c = {0xc000_0000, 30};
    rl.push(iprange::iprange_from_cidr{uint}(c));

    SegList sg_list = rl.build_segs()!!;
    defer sg_list.free();
    assert (sg_list[0] == (Seg){ .r = {0xc000_0000, 0xc000_0003}, .idx = 0});
    //foreach (s: sg_list) {
    //    io::printf("%s\n", s);
    //}
}

fn void test_build_segs_empty() @test {
    IpRangeList rl;
    rl.init(mem);
    defer rl.free();

    SegList sg_list = rl.build_segs()!!;
    defer sg_list.free();
    assert(sg_list.len() == 0);
}

fn void test_build_segs_preserves_original_idx() @test {
    IpRangeList rl;
    rl.init(mem);
    defer rl.free();

    // Push in reverse start order so a mutating sort would scramble indices.
    Cidr c = {0xe000_0000, 31};
    rl.push(iprange::iprange_from_cidr{uint}(c));
    c = {0xc000_0000, 30};
    rl.push(iprange::iprange_from_cidr{uint}(c));

    IpRange first = rl[0];
    IpRange second = rl[1];

    SegList sg_list = rl.build_segs()!!;
    defer sg_list.free();

    // Input list must not be reordered.
    assert(rl[0].start == first.start && rl[0].end == first.end);
    assert(rl[1].start == second.start && rl[1].end == second.end);

    assert(sg_list[0] == (Seg){ .r = {0xc000_0000, 0xc000_0003}, .idx = 1});
    assert(sg_list[1] == (Seg){ .r = {0xe000_0000, 0xe000_0001}, .idx = 0});
}

fn void test_cidr_from_iprange_rejects_non_cidr() @test {
    assert(@catch(iprange::cidr_from_iprange{uint}({ .start = 0, .end = 2 })) == iprange::INVALID_RANGE);
    Cidr c = iprange::cidr_from_iprange{uint}({ .start = 0xc000_0000, .end = 0xc000_0003 })!!;
    assert(c.ip == 0xc000_0000);
    assert(c.cidr == 30);
}

fn void test_build_seg_1() @test {
    IpRangeList rl;
    rl.init(mem);
    defer rl.free();
    Cidr c = {0xc000_0000, 30};
    rl.push(iprange::iprange_from_cidr{uint}(c));
    c = {0xc000_0000, 31};
    rl.push(iprange::iprange_from_cidr{uint}(c));

    SegList sg_list = rl.build_segs()!!;
    defer sg_list.free();
    assert (sg_list[0] == (Seg){ .r = {0xc000_0000, 0xc000_0001}, .idx = 1});
    assert (sg_list[1] == (Seg){ .r = {0xc000_0002, 0xc000_0003}, .idx = 0});
    //foreach (s: sg_list) {
    //    io::printf("%s\n", s);
    //}
}

fn void test_build_seg_2() @test {
    IpRangeList rl;
    rl.init(mem);
    defer rl.free();
    Cidr c = {0xc000_0000, 30};
    rl.push(iprange::iprange_from_cidr{uint}(c));
    c = {0xe000_0000, 31};
    rl.push(iprange::iprange_from_cidr{uint}(c));

    SegList sg_list = rl.build_segs()!!;
    defer sg_list.free();
    assert (sg_list[0] == (Seg){ .r = {0xc000_0000, 0xc000_0003}, .idx = 0});
    assert (sg_list[1] == (Seg){ .r = {0xe000_0000, 0xe000_0001}, .idx = 1});
    //foreach (s: sg_list) {
    //    io::printf("%s\n", s);
    //}
}

fn void test_build_seg_3() @test {
    IpRangeList rl;
    rl.init(mem);
    defer rl.free();
    Cidr c = {0xc000_0000, 30};
    rl.push(iprange::iprange_from_cidr{uint}(c));
    c = {0xc000_0002, 31};
    rl.push(iprange::iprange_from_cidr{uint}(c));

    SegList sg_list = rl.build_segs()!!;
    defer sg_list.free();
    //foreach (s: sg_list) {
    //    io::printf("%s\n", s);
    //}
    assert (sg_list[0] == (Seg){ .r = {0xc000_0000, 0xc000_0001}, .idx = 0});
    assert (sg_list[1] == (Seg){ .r = {0xc000_0002, 0xc000_0003}, .idx = 1});
}

fn void test_build_seg_4() @test {
    IpRangeList rl;
    rl.init(mem);
    defer rl.free();
    Cidr c = {0xc000_0000, 29};
    rl.push(iprange::iprange_from_cidr{uint}(c));
    c = {0xc000_0002, 31};
    rl.push(iprange::iprange_from_cidr{uint}(c));

    SegList sg_list = rl.build_segs()!!;
    defer sg_list.free();
    //foreach (s: sg_list) {
    //    io::printf("%s\n", s);
    //}
    assert (sg_list[0] == (Seg){ .r = {0xc000_0000, 0xc000_0001}, .idx = 0});
    assert (sg_list[1] == (Seg){ .r = {0xc000_0002, 0xc000_0003}, .idx = 1});
    assert (sg_list[2] == (Seg){ .r = {0xc000_0004, 0xc000_0007}, .idx = 0});
}

fn void test_build_seg_5() @test {
    IpRangeList rl;
    rl.init(mem);
    defer rl.free();
    Cidr c = {0xc000_0000, 29};
    rl.push(iprange::iprange_from_cidr{uint}(c));
    c = {0xc000_0002, 32};
    rl.push(iprange::iprange_from_cidr{uint}(c));

    SegList sg_list = rl.build_segs()!!;
    defer sg_list.free();
    //foreach (s: sg_list) {
    //    io::printf("%s\n", s);
    //}
    assert (sg_list[0] == (Seg){ .r = {0xc000_0000, 0xc000_0001}, .idx = 0});
    assert (sg_list[1] == (Seg){ .r = {0xc000_0002, 0xc000_0002}, .idx = 1});
    assert (sg_list[2] == (Seg){ .r = {0xc000_0003, 0xc000_0007}, .idx = 0});
}

fn void test_build_seg_6() @test {
    IpRangeList rl;
    rl.init(mem);
    defer rl.free();
    Cidr c = {0xc000_0000, 29};
    rl.push(iprange::iprange_from_cidr{uint}(c));
    c = {0xc000_0002, 32};
    rl.push(iprange::iprange_from_cidr{uint}(c));
    c = {0xc000_0002, 31};
    rl.push(iprange::iprange_from_cidr{uint}(c));

    SegList sg_list = rl.build_segs()!!;
    //foreach (i, r: rl) {
    //    io::printf("%s %d\n", r, i);
    //}
    defer sg_list.free();
    //foreach (s: sg_list) {
    //    io::printf("%s\n", s);
    //}
    assert (sg_list[0] == (Seg){ .r = {0xc000_0000, 0xc000_0001}, .idx = 0});
    assert (sg_list[1] == (Seg){ .r = {0xc000_0002, 0xc000_0002}, .idx = 1});
    assert (sg_list[2] == (Seg){ .r = {0xc000_0003, 0xc000_0003}, .idx = 2});
    assert (sg_list[3] == (Seg){ .r = {0xc000_0004, 0xc000_0007}, .idx = 0});
}

fn void test_build_seg_7() @test {
    IpRangeList rl;
    rl.init(mem);
    defer rl.free();
    Cidr c = {0xc000_0000, 31};
    rl.push(iprange::iprange_from_cidr{uint}(c));
    c = {0xc000_0000, 24};
    rl.push(iprange::iprange_from_cidr{uint}(c));
    c = {0xc000_0040, 26};
    rl.push(iprange::iprange_from_cidr{uint}(c));

    SegList sg_list = rl.build_segs()!!;
    defer sg_list.free();
    assert (sg_list[0] == (Seg){ .r = {0xc000_0000, 0xc000_0001}, .idx = 0});
    assert (sg_list[1] == (Seg){ .r = {0xc000_0002, 0xc000_003f}, .idx = 1});
    assert (sg_list[2] == (Seg){ .r = {0xc000_0040, 0xc000_007f}, .idx = 2});
    assert (sg_list[3] == (Seg){ .r = {0xc000_0080, 0xc000_00ff}, .idx = 1});
}

fn void test_do_lpm_0() @test {
    IpRangeList rl;
    rl.init(mem);
    defer rl.free();
    Cidr c = {0xc000_0000, 31};
    rl.push(iprange::iprange_from_cidr{uint}(c));
    c = {0xc000_0000, 24};
    rl.push(iprange::iprange_from_cidr{uint}(c));
    c = {0xc000_0040, 26};
    rl.push(iprange::iprange_from_cidr{uint}(c));

    SegList sg_list = rl.build_segs()!!;
    defer sg_list.free();

    assert(sg_list.do_lpm(0xc000_0000)!! == 0);
    assert(sg_list.do_lpm(0xc000_0001)!! == 0);
    assert(sg_list.do_lpm(0xc000_0002)!! == 1);
    assert(sg_list.do_lpm(0xc000_003f)!! == 1);
    assert(sg_list.do_lpm(0xc000_0040)!! == 2);
    assert(sg_list.do_lpm(0xc000_007f)!! == 2);
    assert(sg_list.do_lpm(0xc000_0080)!! == 1);
    assert(sg_list.do_lpm(0xc000_00ff)!! == 1);
}

fn void test_do_lpm_1() @test {
    SegList sg_list;
    sg_list.init(mem);
    defer sg_list.free();
    sg_list.push({ .r = {0xc000_0000, 0xc000_0001}, .idx = 0});
    sg_list.push({ .r = {0xc000_0002, 0xc000_003f}, .idx = 1});
    sg_list.push({ .r = {0xc000_0040, 0xc000_007f}, .idx = 2});
    sg_list.push({ .r = {0xc000_0080, 0xc000_00ff}, .idx = 1});

    assert(@catch(sg_list.do_lpm(0xbfff_ffff)) == common::MISSING);
    assert(@catch(sg_list.do_lpm(0xc000_0100)) == common::MISSING);
}

fn void test_build_seg_8() @test {
    IpRangeList rl;
    rl.init(mem);
    defer rl.free();
    Cidr c = {0xca06_7100, 24};
    rl.push(iprange::iprange_from_cidr{uint}(c));
    c = {0xca06_73a7, 32};
    rl.push(iprange::iprange_from_cidr{uint}(c));
    c = {0xca06_7400, 23};
    rl.push(iprange::iprange_from_cidr{uint}(c));

    SegList sg_list = rl.build_segs()!!;
    defer sg_list.free();

    assert (sg_list[0] == (Seg){ .r = {0xca06_7100, 0xca06_71ff}, .idx = 0});
    assert (sg_list[1] == (Seg){ .r = {0xca06_73a7, 0xca06_73a7}, .idx = 1});
    assert (sg_list[2] == (Seg){ .r = {0xca06_7400, 0xca06_75ff}, .idx = 2});
}

fn void test_build_seg_ipv6_0() @test {
    IpRangeList6 rl;
    rl.init(mem);
    defer rl.free();
    Cidr6 c = {0x2001_0db8_0000_0000_0000_0000_0000_0000, 126};
    rl.push(iprange::iprange_from_cidr{uint128}(c));
    c = {0x2001_0db8_0000_0000_0000_0000_0000_0000, 124};
    rl.push(iprange::iprange_from_cidr{uint128}(c));
    c = {0x2001_0db8_0000_0000_0000_0000_0000_0008, 125};
    rl.push(iprange::iprange_from_cidr{uint128}(c));

    SegList6 sg_list = rl.build_segs()!!;
    defer sg_list.free();
    assert (sg_list[0] == (Seg6){ .r = {0x2001_0db8_0000_0000_0000_0000_0000_0000, 0x2001_0db8_0000_0000_0000_0000_0000_0003}, .idx = 0});
    assert (sg_list[1] == (Seg6){ .r = {0x2001_0db8_0000_0000_0000_0000_0000_0004, 0x2001_0db8_0000_0000_0000_0000_0000_0007}, .idx = 1});
    assert (sg_list[2] == (Seg6){ .r = {0x2001_0db8_0000_0000_0000_0000_0000_0008, 0x2001_0db8_0000_0000_0000_0000_0000_000f}, .idx = 2});
}

fn void test_do_lpm_ipv6_0() @test {
    IpRangeList6 rl;
    rl.init(mem);
    defer rl.free();
    Cidr6 c = {0x2001_0db8_0000_0000_0000_0000_0000_0000, 126};
    rl.push(iprange::iprange_from_cidr{uint128}(c));
    c = {0x2001_0db8_0000_0000_0000_0000_0000_0000, 124};
    rl.push(iprange::iprange_from_cidr{uint128}(c));
    c = {0x2001_0db8_0000_0000_0000_0000_0000_0008, 125};
    rl.push(iprange::iprange_from_cidr{uint128}(c));

    SegList6 sg_list = rl.build_segs()!!;
    defer sg_list.free();

    assert(sg_list.do_lpm(0x2001_0db8_0000_0000_0000_0000_0000_0000)!! == 0);
    assert(sg_list.do_lpm(0x2001_0db8_0000_0000_0000_0000_0000_0003)!! == 0);
    assert(sg_list.do_lpm(0x2001_0db8_0000_0000_0000_0000_0000_0004)!! == 1);
    assert(sg_list.do_lpm(0x2001_0db8_0000_0000_0000_0000_0000_0007)!! == 1);
    assert(sg_list.do_lpm(0x2001_0db8_0000_0000_0000_0000_0000_0008)!! == 2);
    assert(sg_list.do_lpm(0x2001_0db8_0000_0000_0000_0000_0000_000f)!! == 2);
    assert(@catch(sg_list.do_lpm(0x2001_0db7_ffff_ffff_ffff_ffff_ffff_ffff)) == common::MISSING);
    assert(@catch(sg_list.do_lpm(0x2001_0db8_0000_0000_0000_0000_0000_0010)) == common::MISSING);
}

fn void test_iprange_from_cidr_edge_prefixes() @test {
    // /0 must not shift by the full bit width (used to panic).
    IpRange r = iprange::iprange_from_cidr{uint}({ .ip = 0, .cidr = 0 });
    assert(r.start == 0);
    assert(r.end == uint::max);

    // /32 has no host bits.
    r = iprange::iprange_from_cidr{uint}({ .ip = 0x0a00_0001, .cidr = 32 });
    assert(r.start == 0x0a00_0001);
    assert(r.end == 0x0a00_0001);

    IpRange6 r6 = iprange::iprange_from_cidr{uint128}({ .ip = 0, .cidr = 0 });
    assert(r6.start == 0);
    assert(r6.end == uint128::max);
}

fn void test_build_segs_ending_at_max() @test {
    IpRangeList rl;
    rl.init(mem);
    defer rl.free();
    // Both ranges end at uint::max; advancing past the last segment must not wrap to 0.
    rl.push(iprange::iprange_from_cidr{uint}({ .ip = 0x8000_0000, .cidr = 1 }));
    rl.push(iprange::iprange_from_cidr{uint}({ .ip = 0xc000_0000, .cidr = 2 }));

    SegList sg_list = rl.build_segs()!!;
    defer sg_list.free();
    assert(sg_list.len() == 2);
    assert(sg_list[0] == (Seg){ .r = {0x8000_0000, 0xbfff_ffff}, .idx = 0 });
    assert(sg_list[1] == (Seg){ .r = {0xc000_0000, 0xffff_ffff}, .idx = 1 });
    // No bogus wrapped segment: lookups below 0x8000_0000 must miss.
    assert(@catch(sg_list.do_lpm(0x7fff_ffff)) == common::MISSING);
    assert(sg_list.do_lpm(0xffff_ffff)!! == 1);
}

fn void test_build_segs_default_route() @test {
    IpRangeList rl;
    rl.init(mem);
    defer rl.free();
    rl.push(iprange::iprange_from_cidr{uint}({ .ip = 0, .cidr = 0 }));

    SegList sg_list = rl.build_segs()!!;
    defer sg_list.free();
    assert(sg_list.len() == 1);
    assert(sg_list[0] == (Seg){ .r = {0, 0xffff_ffff}, .idx = 0 });
}
