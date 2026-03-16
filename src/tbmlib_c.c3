module tbmlib_c;
import tbmlib::cidr;
import tbmlib;

const uint FIB_TBM_STRIDE = 5;
alias FibCidr = cidr::Cidr {uint};
alias FibTbm = Tbm {FIB_TBM_STRIDE, uint, uint};

struct TbmTree @cname("TbmTree") {
    FibTbm tbm;
}

fn void TbmTree.init(&self, usz nodes_cnt) @export @cname("tbm_init") {
    self.tbm.init(nodes_cnt);
}

fn void? TbmTree.insert(&self, FibCidr prefix, uint v) @export @cname("tbm_insert") {
    return self.tbm.insert(prefix, v);
}

fn void? TbmTree.remove(&self, FibCidr prefix) @export @cname("tbm_remove") {
    return self.tbm.remove(prefix);
}

fn void TbmTree.free(&self) @export @cname("tbm_free") {
    return self.tbm.free();
}
