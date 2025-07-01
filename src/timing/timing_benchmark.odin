package duration_utils
import "../fmt"
import "../mem"
import "core:strings"

// types
Benchmark :: struct {
	procedure:                         proc(),
	init:                              proc(),
	procedure_name:                    string,
	init_name:                         string,
	timeout:                           Duration,
	d_total_duration, d_init_duration: Duration,
	d_total_cycles, d_init_cycles:     Cycles,
	runs:                              i64,
}
Benchmarks :: [dynamic]Benchmark

// procedures
append_benchmark :: proc(
	benchmarks: ^Benchmarks,
	procedure: proc(),
	init: proc() = nil,
	timeout := 100 * MILLISECOND,
	procedure_name := #caller_expression(procedure),
	init_name := #caller_expression(init),
) {
	append(
		benchmarks,
		Benchmark{procedure, init, procedure_name, init_name, timeout, 0, 0, 0, 0, 0},
	)
}
append_benchmark_group :: proc(benchmarks: ^Benchmarks) {
	append(benchmarks, Benchmark{nil, nil, "", "", 0, 0, 0, 0, 0, 0})
}

run_benchmarks :: proc(benchmarks: ^Benchmarks) {
	BENCHMARK_FORMAT_WITH_INIT :: "%v() / %v()"
	BENCHMARK_FORMAT_WITHOUT_INIT :: "%v()"
	// run benchmarks
	for &benchmark in benchmarks {
		procedure := benchmark.procedure
		timeout := benchmark.timeout
		init_procedure := benchmark.init
		if procedure == nil {continue} 	// skip benchmark groups

		// print debug header
		fmt.print("  ")
		if init_procedure != nil {
			fmt.printfln(BENCHMARK_FORMAT_WITH_INIT, benchmark.init_name, benchmark.procedure_name)
			init_procedure()
		} else {
			fmt.printfln(BENCHMARK_FORMAT_WITHOUT_INIT, benchmark.procedure_name)
		}

		// run benchmark
		if init_procedure != nil {
			start_duration := get_duration()
			start_cycles := get_cycles()
			duration := start_duration
			cycles := start_cycles
			runs: i64 = 0
			total_init_duration: Duration
			total_init_cycles: Cycles
			for {
				// init
				runs += 1
				init_procedure()
				mem.mfence()

				total_init_duration += sub(get_duration(), duration)
				total_init_cycles += sub(get_cycles(), cycles)
				mem.mfence()
				// run procedure
				procedure()
				mem.mfence()

				duration = get_duration()
				cycles = get_cycles()
				mem.mfence()

				if sub(duration, start_duration) >= timeout {break}
			}
			benchmark.d_total_duration = div(sub(duration, start_duration), runs)
			benchmark.d_total_cycles = div(sub(cycles, start_cycles), runs)
			benchmark.d_init_duration = div(total_init_duration, runs)
			benchmark.d_init_cycles = div(total_init_cycles, runs)
			benchmark.runs = runs
		} else {
			start_duration := get_duration()
			start_cycles := get_cycles()
			duration := start_duration
			cycles: Cycles
			runs: i64 = 0
			for {
				runs += 1
				procedure()
				duration = get_duration()
				if sub(duration, start_duration) >= timeout {break}
			}
			cycles = get_cycles()
			benchmark.d_total_duration = div(sub(duration, start_duration), runs)
			benchmark.d_total_cycles = div(sub(cycles, start_cycles), runs)
			benchmark.runs = runs
		}
		// print gap
		fmt.println()
	}
	// print results
	tb: fmt.TableBuilder
	for benchmark in benchmarks {
		if benchmark.procedure == nil {
			fmt.table_append_break(&tb)
			continue
		}
		has_init_proc := benchmark.init != nil

		benchmark_name := ""
		if has_init_proc {
			benchmark_name = fmt.tprintf(
				BENCHMARK_FORMAT_WITH_INIT,
				benchmark.init_name,
				benchmark.procedure_name,
			)
		} else {
			benchmark_name = fmt.tprintf(BENCHMARK_FORMAT_WITHOUT_INIT, benchmark.procedure_name)
		}

		d_init_time := benchmark.d_init_duration
		d_init_cycles := benchmark.d_init_cycles
		d_time := benchmark.d_total_duration - d_init_time
		d_cycles := benchmark.d_total_cycles - d_init_cycles

		time_string := ""
		if has_init_proc {
			time_string = fmt.tprintf("%v / %v", d_init_time, d_time)
		} else {
			time_string = fmt.tprint(d_time)
		}

		cycles_string := ""
		if has_init_proc {
			cycles_string = fmt.tprintf("%v cy / %v cy", d_init_cycles, d_cycles)
		} else {
			cycles_string = fmt.tprintf("%v cy", d_cycles)
		}

		runs := fmt.tprint(benchmark.runs)

		fmt.table_append(&tb, benchmark_name, time_string, cycles_string, runs)
	}
	fmt.print_table(&tb, "  %v: %v, %v, runs: %v")
	// clear queued benchmarks
}
