module me::main {
    use sui::tx_context::TxContext;
    use sui::bcs;
    use std::hash;
    
    use game::adventure;
    use game::hero::{Self, Hero};
    use game::inventory::{Self, TreasuryBox};

    use sui::object;

    use std::vector;
    use std::debug;

    struct RandomEvent has copy, drop {
        calculated: u64,
        random_number: u64,
    }

    public fun u64_to_vec(d: u64): vector<u8> {
        bcs::to_bytes(&d)
    }

    #[test]
    public fun test_u64_to_vec() {
        let a = 26;
        let b = vector::empty<u8>();
        vector::push_back(&mut b, 26);
        vector::push_back(&mut b, 0);
        vector::push_back(&mut b, 0);
        vector::push_back(&mut b, 0);
        vector::push_back(&mut b, 0);
        vector::push_back(&mut b, 0);
        vector::push_back(&mut b, 0);
        vector::push_back(&mut b, 0);

        debug::print(&b);
        debug::print(&u64_to_vec(a));

        assert!(u64_to_vec(a) == b, 1234);
    }

    public fun vec_to_u64(d: &vector<u8>): u64 {
        let i = 0;
        let m = 0;
        let len = vector::length(d);
        while (i < len) {
            m = (m << 8) + ((*vector::borrow(d, len - i - 1)) as u64);
            i = i + 1;
        };
        m
    }

    #[test]
    public fun test_vec_to_u64() {
        let a: u64 = 26;
        let b = vector::empty<u8>();
        vector::push_back(&mut b, 26);
        vector::push_back(&mut b, 0);
        vector::push_back(&mut b, 0);
        vector::push_back(&mut b, 0);
        vector::push_back(&mut b, 0);
        vector::push_back(&mut b, 0);
        vector::push_back(&mut b, 0);
        vector::push_back(&mut b, 0);

        debug::print(&vec_to_u64(&b));
        debug::print(&a);

        assert!(vec_to_u64(&b) == a, 1235);
    }

    fun vector_slice<T: copy>(vec: &vector<T>, begin: u64, end: u64): vector<T> {
        let slice = vector::empty<T>();
        let i = begin;
        while (i < end) {
            vector::push_back(&mut slice, *vector::borrow(vec, i));
            i = i + 1;
        };
        slice
    }

    #[test]
    public fun test_vector_slice() {
        let b = vector::empty<u8>();
        vector::push_back(&mut b, 26);
        vector::push_back(&mut b, 27);
        vector::push_back(&mut b, 28);
        vector::push_back(&mut b, 29);
        vector::push_back(&mut b, 30);
        vector::push_back(&mut b, 31);
        vector::push_back(&mut b, 32);
        vector::push_back(&mut b, 33);

        let slice1 = vector_slice(&b, 0, 3);
        let tmp1 = vector::empty<u8>();
        vector::push_back(&mut tmp1, 26);
        vector::push_back(&mut tmp1, 27);
        vector::push_back(&mut tmp1, 28);

        assert!(slice1 == tmp1, 1123);
    }

    fun simulate_seed(ctx: &TxContext, m: u64): vector<u8> {
        // let msg = string::utf8(b"ctx_bytes inside simulation");
        // debug::print(&msg);
        let ctx_bytes = bcs::to_bytes(ctx);
        // debug::print(&ctx_bytes);
        let tx_hash = vector_slice(&ctx_bytes, 21, 21 + ((*vector::borrow(&ctx_bytes, 20)) as u64));

        // Construct mth ctx_bytes from ctx_bytes
        let len = vector::length(&ctx_bytes);
        let common_prefix = vector_slice(&ctx_bytes, 0, len - 8);
        let begin_suffix = vector_slice(&ctx_bytes, len - 8, len);
        let created_num = vec_to_u64(&begin_suffix) + m;
        let end_suffix = u64_to_vec(created_num);

        let mth_ctx_bytes = vector::empty<u8>();
        vector::append(&mut mth_ctx_bytes, common_prefix);
        vector::append(&mut mth_ctx_bytes, end_suffix);
        debug::print(&mth_ctx_bytes);

        // Calculate mth uid from tx_hash & num_created
        let uid_calculation = vector::empty<u8>();
        vector::append(&mut uid_calculation, tx_hash);
        vector::append(&mut uid_calculation, end_suffix);
        let uid_bytes = vector_slice(&hash::sha3_256(uid_calculation), 0, 20);

        // Calculate hash from tx_hash & uid_bytes
        let info: vector<u8> = vector::empty<u8>();
        vector::append<u8>(&mut info, mth_ctx_bytes);
        vector::append<u8>(&mut info, uid_bytes);

        // let msg = string::utf8(b"Info inside simulation");
        // debug::print(&msg);
        debug::print(&info);

        let hash: vector<u8> = hash::sha3_256(info);
        hash
    }

    fun bytes_to_u64(bytes: vector<u8>): u64 {
        let value = 0u64;
        let i = 0u64;
        while (i < 8) {
            value = value | ((*vector::borrow(&bytes, i) as u64) << ((8 * (7 - i)) as u8));
            i = i + 1;
        };
        return value
    }

    /// Generate a random u64
    fun rand_u64_with_seed(_seed: vector<u8>): u64 {
        bytes_to_u64(_seed)
    }

    /// Generate a random integer range in [low, high).
    fun rand_u64_range_with_seed(_seed: vector<u8>, low: u64, high: u64): u64 {
        assert!(high > low, 123321);
        let value = rand_u64_with_seed(_seed);
        (value % (high - low)) + low
    }

    /// Generate a random integer range in [low, high).
    /// `m` indicates the next m'th random number
    public fun rand_u64_range(low: u64, high: u64, ctx: &TxContext, m: u64): u64 {
        rand_u64_range_with_seed(simulate_seed(ctx, m), low, high)
    }

    public entry fun a(h: &mut Hero, ctx: &mut TxContext) {
        let i = 0;
        while (i < 125) {
            adventure::slay_boar(h, ctx);
            i = i + 1;
        };

        hero::level_up(h);

        let next = next_zero(ctx) - 4;
        while (next > 0) {
            object::delete(object::new(ctx));
            next = next - 1;
        };

        adventure::slay_boar_king(h, ctx);
    }

    public entry fun b(box: TreasuryBox, ctx: &mut TxContext) {
        let next = next_zero(ctx);
        while (next > 0) {
            object::delete(object::new(ctx));
            next = next - 1;
        };
        inventory::get_flag(box, ctx);
    }

    public fun next_zero(ctx: &TxContext): u64 {
        let next = 0;
        while (true) {
            let data = rand_u64_range(0, 100, ctx, next);
            if (data == 0 && next >= 4) {
                break
            };
            next = next + 1;
        };
        next
    }
}