# Mobility Meeting Scheduler

## Usage

### SICStus

To run the SICStus program, execute the following command in the root directory of the project:

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

### OR-Tools

To run the OR-Tools version of the program you first need to [install OR-Tools on your computer](https://developers.google.com/optimization/install)

Then just use the following command on the "or-tools" folder:
```console
python main.py
```

To run the other implementation of a solution to this problem just use the same command but in the "old" sub-folder.

### DOcplex

To run the DOcplext version of the program, execute the Jupyter Notebook on [source/cplex/model.ipynb](../source/cplex/model.ipynb).

## Context

This project was made by [Alexandre Abreu](https://github.com/xbreu), [Pedro Seixas](https://github.com/pedrojfs17) and [Xavier Pisco](https://github.com/Xavier-Pisco) for the [Constraint logic programming](https://sigarra.up.pt/feup/en/ucurr_geral.ficha_uc_view?pv_ocorrencia_id=486262) course at FEUP in 2021/2022.
