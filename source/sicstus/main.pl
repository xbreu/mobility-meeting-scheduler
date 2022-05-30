:- consult('./constraints.pl').
:- consult('./data.pl').
:- consult('./utils.pl').
:- consult('./variables.pl').
:- use_module(library(clpfd)).

main :-
    % Input
    format('Reading data...', []),
    % Read all data
    read_data(Data),
    % Calculate size of inputs
    format('Done~n', []),

    % Variables
    format('Creating variables...', []),
    create_variables(Data, Variables),
    format('Done~n', []),

    % Contraints
    format('Constraining variables...', []),
    constrain_variables(Data, Variables),
    format('Done~n', []),

    % Enumeration
    format('Finding a solution...', []),
    flatten_variables(Variables, LabelVariables),
    variables_cost(Variables, Cost),
    labeling([minimize(Cost)], LabelVariables), !,
    format('Done~n~n', []),

    print(Variables).
