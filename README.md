# Ruby HTTP Benchmark

Provides a simple harness for testing Ruby HTTP client throughput with shiny graphs.

## Requirements

* Docker
* Gnuplot
* MRI _or_ JRUby

If running on the Ruby platform, you'll need the libcurl-dev packages for your platform.

| Platform | Package |
| - | - |
| Debian/Ubuntu | `sudo apt install libcurl4-openssl-dev` |

## Running the suite

Ensure you have Docker installed and running, ensure gnuplot is installed and available on your path, `bundle` to install dependencies, then just `rake` to run the suite and plot the results. You'll find the results in `plot/` afterwards.