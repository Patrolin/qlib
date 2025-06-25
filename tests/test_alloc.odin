package tests
import "../src/alloc"
import "../src/test"

test_map :: proc() {
	m: alloc.Map(string, int) = {}

	alloc.add_key(&m, "a")^ = 1
	alloc.add_key(&m, "b")^ = 2
	valueA, okA := alloc.get_key(&m, "a")
	test.expectf(okA && (valueA^ == 1), "m[\"a\"] = %v", valueA^)
	valueB, okB := alloc.get_key(&m, "b")
	test.expectf(okB && (valueB^ == 2), "m[\"b\"] = %v", valueB^)
	valueC, okC := alloc.get_key(&m, "c")
	test.expectf(!okC && (valueC^ == {}), "m[\"b\"] = %v", valueC^)

	alloc.remove_key(&m, "a")
	alloc.remove_key(&m, "b")
	alloc.remove_key(&m, "c")
	valueA, okA = alloc.get_key(&m, "a")
	test.expectf(!okA && (valueA^ == {}), "m[\"a\"] = %v", valueA^)
	valueB, okB = alloc.get_key(&m, "b")
	test.expectf(!okA && (valueB^ == {}), "m[\"b\"] = %v", valueB^)
	valueC, okC = alloc.get_key(&m, "c")
	test.expectf(!okA && (valueC^ == {}), "m[\"c\"] = %v", valueC^)

	alloc.delete_map_like(&m)
}

test_set :: proc() {
	m: alloc.Set(string) = {}

	alloc.add_key(&m, "a")
	alloc.add_key(&m, "b")
	okA := alloc.get_key(&m, "a")
	test.expectf(okA, "m[\"a\"] = %v", okA)
	okB := alloc.get_key(&m, "b")
	test.expectf(okB, "m[\"b\"] = %v", okB)
	okC := alloc.get_key(&m, "c")
	test.expectf(!okC, "m[\"b\"] = %v", okC)

	alloc.remove_key(&m, "a")
	alloc.remove_key(&m, "b")
	alloc.remove_key(&m, "c")
	okA = alloc.get_key(&m, "a")
	test.expectf(!okA, "m[\"a\"] = %v", okA)
	okB = alloc.get_key(&m, "b")
	test.expectf(!okB, "m[\"b\"] = %v", okB)
	okC = alloc.get_key(&m, "c")
	test.expectf(!okC, "m[\"c\"] = %v", okC)
	alloc.delete_map_like(&m)
}
