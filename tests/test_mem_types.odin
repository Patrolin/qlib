package tests
import "../src/mem/types"
import "../src/test"

test_map :: proc() {
	m: types.Map(string, int) = {}

	types.add_key(&m, "a")^ = 1
	types.add_key(&m, "b")^ = 2
	valueA, okA := types.get_key(&m, "a")
	test.expectf(okA && (valueA^ == 1), "m[\"a\"] = %v", valueA^)
	valueB, okB := types.get_key(&m, "b")
	test.expectf(okB && (valueB^ == 2), "m[\"b\"] = %v", valueB^)
	valueC, okC := types.get_key(&m, "c")
	test.expectf(!okC && (valueC^ == {}), "m[\"b\"] = %v", valueC^)

	types.remove_key(&m, "a")
	types.remove_key(&m, "b")
	types.remove_key(&m, "c")
	valueA, okA = types.get_key(&m, "a")
	test.expectf(!okA && (valueA^ == {}), "m[\"a\"] = %v", valueA^)
	valueB, okB = types.get_key(&m, "b")
	test.expectf(!okA && (valueB^ == {}), "m[\"b\"] = %v", valueB^)
	valueC, okC = types.get_key(&m, "c")
	test.expectf(!okA && (valueC^ == {}), "m[\"c\"] = %v", valueC^)

	types.delete_map_like(&m)
}

test_set :: proc() {
	m: types.Set(string) = {}

	types.add_key(&m, "a")
	types.add_key(&m, "b")
	okA := types.get_key(&m, "a")
	test.expectf(okA, "m[\"a\"] = %v", okA)
	okB := types.get_key(&m, "b")
	test.expectf(okB, "m[\"b\"] = %v", okB)
	okC := types.get_key(&m, "c")
	test.expectf(!okC, "m[\"b\"] = %v", okC)

	types.remove_key(&m, "a")
	types.remove_key(&m, "b")
	types.remove_key(&m, "c")
	okA = types.get_key(&m, "a")
	test.expectf(!okA, "m[\"a\"] = %v", okA)
	okB = types.get_key(&m, "b")
	test.expectf(!okB, "m[\"b\"] = %v", okB)
	okC = types.get_key(&m, "c")
	test.expectf(!okC, "m[\"c\"] = %v", okC)
	types.delete_map_like(&m)
}
