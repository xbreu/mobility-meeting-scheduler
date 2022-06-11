# Mobility Meeting Scheduler

## Usage

In this section we will present the commands needed to run each implementation of the application in the root directory of the project.

### SICStus

To run the SICStus program, use the following command:

```console
</path/to/sicstus> -l source/sicstus/main.pl --goal "<run_predicate>."
```

*run_predicate* is one of:

1.  `run('/path/to/input/folder')`;
2.  `run('/path/to/input/folder', SearchParameters)`;
3.  `run('/path/to/input/folder', SearchParameters, Statistics)`.

The parameters for the predicates are:
- `SearchParameters` is a list of [parameters for labelling](https://sicstus.sics.se/sicstus/docs/4.2.0/html/sicstus/Enumeration-Predicates.html) of the clpfd library, which means it can include:
  - One of [`leftmost` (default), `min`, `max`, `ff`, `ffc`];
  - One of [`step` (default), `enum`, `bisect`];
  - One of [`up` (default), `down`];
  - Running the first command is equivalent of running the second with [`min`, `bisect`, `down`].
- `Statistics` is one of `false`, `fd` or `all`.
  - Running the second command is equivalent of running the third one with `false`.

In the input folder the program will expect two files:
- flights.json;
- students.json.

To test it with our input files and default search parameters, run:

```console
</path/to/sicstus> -l source/sicstus/main.pl --goal "run('data/new')."
```

And, to execute it with the same files, fd statistics and [`min`, `step`, `up`] as the search parameters run:

```console
</path/to/sicstus> -l source/sicstus/main.pl --goal "run('data/new', [min], fd)."
```

## Context

This project was made by [Alexandre Abreu](https://github.com/xbreu), [Pedro Seixas](https://github.com/pedrojfs17) and [Xavier Pisco](https://github.com/Xavier-Pisco) for the [Constraint logic programming](https://sigarra.up.pt/feup/en/ucurr_geral.ficha_uc_view?pv_ocorrencia_id=486262) course at FEUP in 2021/2022.
