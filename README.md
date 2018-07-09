# Polybench Comparator

This collection of scripts creates and runs regression tests (reference outputs, comparison, and performance) on a variety of compilers.

## Requirements
  * Polybench/C (tested with Polybench/C 4.2)
  * Python 3.x
  
## Usage

Run the tool from the command line as follows (the second argument is optional):
```shell
$ ./test.sh /path/to/polybench [/path/to/results]
```

You can also compare two outputs using the following command:
```shell
$ python3 ./comparator.py /path/to/reference/file /path/to/output/file
```

## Files
 * `comparator.py`: Tool that compares the outputs of polybench tests, returns absolute difference and the percentage of errors.
 * `test.sh`: Compiles and runs tests using the other files. By default, only the gcc compiler is enabled, and the tool runs with parametric and constant loop bounds.
 * `configurations.sh`: Sample configuration functions for popular compilers and polyhedral toolchains. *NOTE*: This file is intended to be included by `test.sh`, not used separately.

## Contributing

Feel free to create issues and pull requests. Any contribution is welcome!

## License

Polybench Comparator is published under the New BSD license, see [LICENSE](LICENSE).
