// odin test tests/utils/threads
package test_threads_utils
import "../../src/alloc"
import "../../src/os"
import "../../src/test"
import "../../src/threads"
import "base:intrinsics"
import "core:fmt"
import "core:testing"
import "core:time"

@(test)
tests_work_queue :: proc(t: ^testing.T) {
	test.start_test(t)
	test.set_fail_timeout(time.Second)
	threads.init() // NOTE: something about setting our own context breaks the testing.expectf() when we have multiple threads..
	/* NOTE: don't start the threads yet */

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
	for i in 0 ..< M {
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

	// then run normally
	threads.init_thread_pool(threads.work_queue_thread_proc)
	for i in M ..< N {
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

	threads.free_all_for_tests()
	test.end_test()
}
