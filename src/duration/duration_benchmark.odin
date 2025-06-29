package duration_utils
import "core:fmt"

Benchmark :: struct {
	procedure:      proc(),
	procedure_name: string,
	timeout:        Duration,
	d_time:         Duration,
	d_cycles:       Cycles,
	n:              i64,
}
Benchmarks :: [dynamic]Benchmark
append_benchmark :: proc(
	benchmarks: ^Benchmarks,
	procedure: proc(),
	timeout := 100 * MILLISECOND,
	procedure_name := #caller_expression(procedure),
) {
	append(benchmarks, Benchmark{procedure, procedure_name, timeout, 0, 0, 0})
}
run_benchmarks :: proc(benchmarks: ^Benchmarks) {
	// run benchmarks
	for &benchmark in benchmarks {
		fmt.printfln("  %v()", benchmark.procedure_name)
		procedure := benchmark.procedure
		timeout := benchmark.timeout
		start_time := now()
		start_cycles := now_cycles()
		time := start_time
		n: i64 = 0
		for sub(time, start_time) <= timeout {
			procedure()
			n += 1
			time = now()
		}
		cycles := now_cycles()
		benchmark.d_time = div(sub(time, start_time), n)
		benchmark.d_cycles = div(sub(cycles, start_cycles), n)
		benchmark.n = n
		fmt.println()
	}
	// print results
	for benchmark in benchmarks {
		fmt.printfln(
			"%v(): %v, %v cy, n: %v",
			benchmark.procedure_name,
			benchmark.d_time,
			benchmark.d_cycles,
			benchmark.n,
		)
	}
}
