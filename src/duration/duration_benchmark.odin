package duration_utils
import "../fmt"
import "core:strings"

Benchmark :: struct {
	procedure:           proc(),
	procedure_name:      string,
	timeout:             Duration,
	init_procedure:      proc(),
	init_procedure_name: string,
	d_time:              Duration,
	d_cycles:            Cycles,
	n:                   i64,
}
Benchmarks :: [dynamic]Benchmark
append_benchmark :: proc(
	benchmarks: ^Benchmarks,
	procedure: proc(),
	init_procedure: proc() = nil,
	timeout := 100 * MILLISECOND,
	procedure_name := #caller_expression(procedure),
	init_procedure_name := #caller_expression(init_procedure),
) {
	append(
		benchmarks,
		Benchmark {
			procedure,
			procedure_name,
			timeout,
			init_procedure,
			init_procedure_name,
			0,
			0,
			0,
		},
	)
}
run_benchmarks :: proc(benchmarks: ^Benchmarks) {
	// run benchmarks
	for &benchmark in benchmarks {
		procedure := benchmark.procedure
		timeout := benchmark.timeout
		init_procedure := benchmark.init_procedure

		if init_procedure != nil {
			fmt.printfln("  %v() + %v()", benchmark.init_procedure_name, benchmark.procedure_name)
			init_procedure()
		} else {
			fmt.printfln("  %v()", benchmark.procedure_name)
		}
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
	tb: fmt.TableBuilder
	for benchmark in benchmarks {
		benchmark_name :=
			benchmark.init_procedure != nil ? strings.concatenate({benchmark.init_procedure_name, "(); "}) : ""
		benchmark_name = strings.concatenate({benchmark_name, benchmark.procedure_name, "()"})
		fmt.table_append(&tb, benchmark_name, benchmark.d_time, benchmark.d_cycles, benchmark.n)
	}
	fmt.print_table(&tb, "%v: %v, %v cy, n: %v")
}
