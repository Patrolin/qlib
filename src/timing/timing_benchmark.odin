package duration_utils
import "../fmt"
import "base:intrinsics"

// types
Benchmarks :: [dynamic]BenchmarkResult
BenchmarkResult :: struct {
	procedure_name: string,
	timeout:        Duration,
	d_duration:     Duration_f64,
	d_cycles:       Cycles_f64,
	runs:           int,
}

// procedures
_do_nothing :: proc() {}
run_benchmark :: proc(benchmarks: ^Benchmarks, $procedure: proc(), procedure_name: string, timeout := 100 * MILLISECOND) {
	append(benchmarks, BenchmarkResult{procedure_name, timeout, 0, 0, 0})
	benchmark := &benchmarks[len(benchmarks) - 1]
	// print debug header
	fmt.printfln("  %v()", procedure_name)
	// preload the procedure and set run count
	start_duration := get_duration()
	duration := start_duration
	runs := 0
	for {
		runs += 1
		#force_inline procedure()
		duration = get_duration()
		if sub(duration, start_duration) >= timeout {break}
	}
	benchmark.runs = runs
	// run benchmark
	mem.mfence()
	start_duration = get_duration()
	start_cycles := get_cycles()

	mem.mfence()
	for i in 0 ..< runs {
		#force_inline procedure() // NOTE: this loop needs to be as tight as possible, so that do_nothing() measures as 0 cy
	}

	mem.mfence()
	cycles := get_cycles()
	duration = get_duration()
	// store the results
	benchmark.d_duration = div(sub(duration, start_duration), runs)
	benchmark.d_cycles = div(sub(cycles, start_cycles), runs)
}
run_benchmark_group :: proc(benchmarks: ^Benchmarks) {
	append(benchmarks, BenchmarkResult{"", 0, 0, 0, 0})
}

print_benchmarks :: proc(benchmarks: ^Benchmarks) {
	// print results
	fmt.println()
	tb: fmt.TableBuilder
	for benchmark in benchmarks {
		if len(benchmark.procedure_name) == 0 {
			fmt.table_append_break(&tb)
			continue
		}
		fmt.table_append(
			&tb,
			fmt.tprintf("%v()", benchmark.procedure_name),
			tprint(benchmark.d_duration),
			tprint(benchmark.d_cycles),
			fmt.tprint(benchmark.runs),
		)
	}
	fmt.print_table(&tb, "  %v: %v, %v, runs: %v")
}
