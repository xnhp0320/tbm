module tbmlib_c @cname("tbm");
import tbmlib::cidr;
import tbmlib;

const uint FIB_TBM_STRIDE = 5;
alias FibCidr @export("FibCidr") = cidr::Cidr {uint};
alias FibTbm @export("FibTbm") = Tbm {FIB_TBM_STRIDE, uint, uint};

fn void tbm_init(FibTbm *self, usz nodes_cnt) @export("tbm_init") {
    self.init(nodes_cnt);
}

fn void? tbm_insert(FibTbm *self, FibCidr prefix, uint v) @export("tbm_insert") {
    return self.insert(prefix, v);
}

fn void? tbm_remove(FibTbm *self, FibCidr prefix) @export("tbm_remove") {
    return self.remove(prefix);
}

fn void tbm_free(FibTbm *self) @export("tbm_free") {
    return self.free();
}

alias IteratorFunc @export("TbmIterateFunc") = fn void(FibCidr *cidr, uint *value, void *aux);
fn void tbm_iterate(FibTbm *self, IteratorFunc f, void *aux) @export("tbm_iterate") {
    return self.iterate(f, aux);
}

fn uint? tbm_lookup(FibTbm *self, uint v) @export("tbm_lookup") {
    return self.lookup(v);
}
