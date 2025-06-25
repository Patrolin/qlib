package tests
import "../src/mem"
import "../src/test"
import "../src/threads"
import "base:intrinsics"
import "core:time"

test_default_context :: proc() {
	// allocator
	x := new(int)
	test.expect_was_allocated(x, "x", 13)
	free(x)

	// temp_allocator
	y := new(int, allocator = context.temp_allocator)
	test.expect_was_allocated(y, "y", 7)
	free(y, allocator = context.temp_allocator)

	// reserve on page fault
	ptr := raw_data(mem.page_alloc(4096, false))
	test.expect_was_allocated((^int)(ptr), "ptr", 13)
}

test_work_queue :: proc() {
	// the work
	work_1 :: proc(data: rawptr) {
		//fmt.printfln("thread %v: work_1", context.user_index)
		data := (^int)(data)
		intrinsics.atomic_add(data, -1)
	}
	work_2 :: proc(data: rawptr) {
		//fmt.printfln("thread %v: work_2", context.user_index)
		data := (^int)(data)
		intrinsics.atomic_add(data, -2)
	}
	N := 100
	checksum := N * 4

	// artificially fill up queue
	M :: len(threads.WaitFreeQueueData) / 3 + 7
	assert(M <= N)
	for _ in 0 ..< M {
		threads.append_work(
			&threads.work_queue,
			threads.Work{procedure = work_1, data = &checksum},
		)
		threads.append_work(
			&threads.work_queue,
			threads.Work{procedure = work_1, data = &checksum},
		)
		threads.append_work(
			&threads.work_queue,
			threads.Work{procedure = work_2, data = &checksum},
		)
	}

	// start the threads
	threads.init_thread_pool(threads.work_queue_thread_proc)

	// then run normally
	for _ in M ..< N {
		threads.append_work(
			&threads.work_queue,
			threads.Work{procedure = work_1, data = &checksum},
		)
		threads.append_work(
			&threads.work_queue,
			threads.Work{procedure = work_1, data = &checksum},
		)
		threads.append_work(
			&threads.work_queue,
			threads.Work{procedure = work_2, data = &checksum},
		)
	}
	threads.join_queue(&threads.work_queue)
	time.sleep(100 * time.Millisecond) // NOTE: normally you would have your own way to detect when the work is done running

	// assert on checksum
	got_checksum := intrinsics.atomic_load(&checksum)
	test.expectf(got_checksum == 0, "checksum should be 0, got: %v", got_checksum)
}
