package alloc_utils
import "base:runtime"

/* TODO: rethink this with half fit allocator in mind */

// types
@(private)
SlotArray :: struct($Key, $Value: typeid) {
	slots:         [^]MapLikeSlot(Key, Value),
	added_slots:   u32,
	removed_slots: u32,
	capacity:      u32,
}
@(private)
MapLikeSlot :: struct($Key, $Value: typeid) {
	key:   Key,
	value: Value,
	hash:  int, // NOTE: hash is checked before string key
	used:  SlotUsed,
}
@(private)
SlotUsed :: enum u8 {
	Free    = 0, // NOTE: ZII
	Used    = 1,
	Removed = 2,
}
Map :: struct($Key, $Value: typeid) {
	using _: SlotArray(Key, Value),
}
void :: struct {
}
#assert(size_of(void) == 0)
Set :: struct($Key: typeid) {
	using _: SlotArray(Key, void),
}

// procedures
@(private)
get_free_or_used_slot :: proc(slots: [^]MapLikeSlot($Key, $Value), capacity: int, key: Key, hash: int) -> ^MapLikeSlot(Key, Value) {
	hash_step := hash | 1 // NOTE: len(slots) must be a power of two
	slot: ^MapLikeSlot(Key, Value) = nil
	for i := hash % capacity;; i += hash_step {
		slot = &slots[i]
		if slot.used == .Free || (slot.hash == hash && slot.key == key) {break}
	}
	return slot
}
MIN_CAPACITY :: 8
MAX_ADDED_PERCENT :: 75
MAX_REMOVED_PERCENT :: 50
@(private)
resize_slot_array :: proc(m: ^SlotArray($Key, $Value), new_capacity: u32) {
	slots := m.slots
	new_added_slots: u32 = 0
	new_slots := make([^]MapLikeSlot(Key, Value), new_capacity)
	if slots != nil {
		for i in 0 ..< m.capacity {
			slot := slots[i]
			if (slot.used == .Used) {
				new_slot := get_free_or_used_slot(new_slots, int(new_capacity), slot.key, slot.hash)
				new_slot^ = slot
				new_added_slots += 1
			}
		}
	}
	m.slots = new_slots
	m.added_slots = new_added_slots // ?TODO: mutex
	m.capacity = new_capacity
	free(slots)
}
reserve_slot_array :: proc(m: ^SlotArray($Key, $Value)) {
	if (m.added_slots + 1) * 100 >= MAX_ADDED_PERCENT * m.capacity { 	// NOTE: handle zero capacity
		new_capacity := m.capacity * 2
		if new_capacity == 0 {new_capacity = MIN_CAPACITY}
		resize_slot_array(m, new_capacity)
	}
}
shrink_slot_array :: proc(m: ^SlotArray($Key, $Value)) {
	capacity := m.capacity
	if m.removed_slots * 100 >= MAX_REMOVED_PERCENT * capacity && capacity > MIN_CAPACITY {
		resize_slot_array(m, capacity / 2)
	}
}
add_key :: proc {
	add_key_map,
	add_key_set,
}
get_key :: proc {
	get_key_or_error_map,
	get_key_or_error_set,
}
remove_key :: proc {
	remove_key_map,
	remove_key_set,
}
delete_map_like :: proc {
	delete_map_like_map,
	delete_map_like_set,
}
add_key_map :: proc(m: ^$M/Map($Key, $Value), key: Key) -> ^Value {
	reserve_slot_array(cast(^SlotArray(Key, Value))m)
	hash0 := hash(key)
	new_slot := get_free_or_used_slot(m.slots, int(m.capacity), key, hash0)
	if new_slot.used == .Free {m.added_slots += 1}
	if new_slot.used == .Removed {m.removed_slots -= 1}
	new_slot.key = key
	new_slot.hash = hash0
	new_slot.used = .Used
	return &new_slot.value
}
@(require_results)
get_key_or_error_map :: proc(m: ^$M/Map($Key, $Value), key: Key) -> (value: ^Value, ok: bool) {
	slot := get_free_or_used_slot(m.slots, int(m.capacity), key, hash(key))
	return &slot.value, slot.used == .Used
}
remove_key_map :: proc(m: ^$M/Map($Key, $Value), key: Key) {
	slot := get_free_or_used_slot(m.slots, int(m.capacity), key, hash(key))
	if slot.used == .Used {
		m.removed_slots += 1
		slot.used = .Removed
		slot.value = {}
	}
	if m.removed_slots * 100 > MAX_REMOVED_PERCENT * m.capacity {
		shrink_slot_array(cast(^SlotArray(Key, Value))m)
	}
}
delete_map_like_map :: proc(m: ^Map($Key, $Value), allocator := context.allocator, loc := #caller_location) {
	runtime.mem_free_with_size(m.slots, int(m.capacity) * size_of(MapLikeSlot(Key, Value)), allocator, loc)
	m.slots = nil
	m.added_slots = 0
	m.removed_slots = 0
	m.capacity = MIN_CAPACITY
}
add_key_set :: proc(m: ^$M/Set($Key), key: Key) {
	reserve_slot_array(cast(^SlotArray(Key, void))m)
	hash0 := hash(key)
	new_slot := get_free_or_used_slot(m.slots, int(m.capacity), key, hash0)
	if new_slot.used == .Free {m.added_slots += 1}
	if new_slot.used == .Removed {m.removed_slots -= 1}
	new_slot.key = key
	new_slot.hash = hash0
	new_slot.used = .Used
}
@(require_results)
get_key_or_error_set :: proc(m: ^$M/Set($Key), key: Key) -> (ok: bool) {
	slot := get_free_or_used_slot(m.slots, int(m.capacity), key, hash(key))
	return slot.used == .Used
}
remove_key_set :: proc(m: ^$M/Set($Key), key: Key) {
	slot := get_free_or_used_slot(m.slots, int(m.capacity), key, hash(key))
	if slot.used == .Used {
		m.removed_slots += 1
		slot.used = .Removed
		slot.value = {}
	}
	if m.removed_slots * 100 > MAX_REMOVED_PERCENT * m.capacity {
		shrink_slot_array(cast(^SlotArray(Key, void))m)
	}
}
delete_map_like_set :: proc(m: ^Set($Key), allocator := context.allocator, loc := #caller_location) {
	runtime.mem_free_with_size(m.slots, int(m.capacity) * size_of(MapLikeSlot(Key, void)), allocator, loc)
	m.slots = nil
	m.added_slots = 0
	m.removed_slots = 0
	m.capacity = MIN_CAPACITY
}

// TODO: better hash, custom hash?
worst_hash :: proc(key: $Key) -> int {
	return 0
}
hash :: worst_hash
