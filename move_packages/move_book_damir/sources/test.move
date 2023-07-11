
module move_book::test {

    use std::vector;

    fun main() {
        
        let v = vector::empty<u64>();
        vector::push_back(&mut v, 5);
        vector::push_back(&mut v, 6);

        assert!(*vector::borrow(&v, 0) == 5, 42);
        assert!(*vector::borrow(&v, 1) == 6, 42);
        assert!(vector::pop_back(&mut v) == 6, 42);
        assert!(vector::pop_back(&mut v) == 5, 42);

    }

    fun empty() {
        
    }

}