(* ::Package:: *)

(* ::Title:: *)
(*SetSubstitutionEvolution*)


(* ::Text:: *)
(*This is an object that is returned by SetSubstitutionSystem. It allows one to query the set at different generations and different steps.*)


Package["SetReplace`"]


PackageExport["SetSubstitutionEvolution"]


(* ::Text:: *)
(*Keys in the data association.*)


PackageScope["$creatorEvents"]
PackageScope["$destroyerEvents"]
PackageScope["$generations"]
PackageScope["$atomLists"]
PackageScope["$rules"]


(* ::Section:: *)
(*Documentation*)


SetSubstitutionEvolution::usage = usageString[
	"SetSubstitutionEvolution[`...`] is an evolution object generated by ",
	"SetSubstitutionSystem.",
	"\n",
	"SetSubstitutionEvolution[`...`][`g`] yields the set at generation `g`.",
	"\n",
	"SetSubstitutionEvolution[`...`][\"SetAfterEvent\", `s`] yields the set after `s` ",
	"substitution events.",
	"\n",
	"SetSubstitutionEvolution[`...`][\"Properties\"] yields the list of all ",
	"available properties."];


(* ::Section:: *)
(*SyntaxInformation*)


SyntaxInformation[SetSubstitutionEvolution] = {"ArgumentsPattern" -> {___}};


(* ::Section:: *)
(*Boxes*)


SetSubstitutionEvolution /:
		MakeBoxes[
			evo : SetSubstitutionEvolution[data_ ? evolutionDataQ],
			format_] := Module[
	{generationsCount, eventsCount, rules, initialSet},
	generationsCount = evo["GenerationsCount"];
	eventsCount = evo["EventsCount"];
	rules = data[$rules];
	initialSet = evo[0];
	BoxForm`ArrangeSummaryBox[
		SetSubstitutionEvolution,
		evo,
		$graphIcon,
		(* Always grid *)
		{{BoxForm`SummaryItem[{"Generations count: ", generationsCount}]},
		{BoxForm`SummaryItem[{"Events count: ", eventsCount}]}},
		(* Sometimes grid *)
		{{BoxForm`SummaryItem[{"Rules: ", Short[rules]}]},
		{BoxForm`SummaryItem[{"Initial set: ", Short[initialSet]}]}},
		format,
		"Interpretable" -> Automatic
	]
]


(* ::Section:: *)
(*Implementation*)


$propertyArgumentCounts = <|
	"Generation" -> {1, 1},
	"SetAfterEvent" -> {1, 1},
	"Rules" -> {0, 0},
	"GenerationsCount" -> {0, 0},
	"EventsCount" -> {0, 0},
	"AtomsCountFinal" -> {0, 0},
	"AtomsCountTotal" -> {0, 0},
	"ExpressionsCountFinal" -> {0, 0},
	"ExpressionsCountTotal" -> {0, 0},
	"CausalGraph" -> {0, Infinity},
	"Properties" -> {0, 0}
|>;


(* ::Subsection:: *)
(*Argument checks*)


(* ::Subsubsection:: *)
(*Unknown property*)


SetSubstitutionEvolution::unknownProperty =
	"Property `` must be one of SetSubstitutionEvolution[...][\"Properties\"].";


SetSubstitutionEvolution[data_ ? evolutionDataQ][s : Except[_Integer], ___] := 0 /;
	!MemberQ[Keys[$propertyArgumentCounts], s] &&
	Message[SetSubstitutionEvolution::unknownProperty, s]


(* ::Subsubsection:: *)
(*Property argument counts*)


SetSubstitutionEvolution::pargx =
	"Property \"`1`\" requested with `2` argument`3`; " <>
	"`4``5``6``7` argument`8` `9` expected."


makePargxMessage[property_, givenArgs_, expectedArgs_] := Message[
	SetSubstitutionEvolution::pargx,
	property,
	givenArgs,
	If[givenArgs == 1, "", "s"],
	If[expectedArgs[[1]] != expectedArgs[[2]], "between ", ""],
	expectedArgs[[1]],
	If[expectedArgs[[1]] != expectedArgs[[2]], " and ", ""],
	If[expectedArgs[[1]] != expectedArgs[[2]], expectedArgs[[2]], ""],
	If[expectedArgs[[1]] != expectedArgs[[2]] || expectedArgs[[1]] != 1, "s", ""],
	If[expectedArgs[[1]] != expectedArgs[[2]] || expectedArgs[[1]] != 1, "are", "is"]
]


SetSubstitutionEvolution[data_ ? evolutionDataQ][s_String, args___] := 0 /;
	With[{argumentsCountRange = $propertyArgumentCounts[s]},
		Not[MissingQ[argumentsCountRange]] &&
		Not[argumentsCountRange[[1]] <= Length[{args}] <= argumentsCountRange[[2]]] &&
		makePargxMessage[s, Length[{args}], argumentsCountRange]]


(* ::Subsection:: *)
(*Properties*)


SetSubstitutionEvolution[data_ ? evolutionDataQ]["Properties"] :=
	Keys[$propertyArgumentCounts]


(* ::Subsection:: *)
(*Rules*)


SetSubstitutionEvolution[data_ ? evolutionDataQ]["Rules"] := data[$rules]


(* ::Subsection:: *)
(*GenerationsCount*)


SetSubstitutionEvolution[data_ ? evolutionDataQ]["GenerationsCount"] := Max[
	0,
	Max @ data[$generations],
	1 + Max @ data[$generations][[
		Position[
			data[$destroyerEvents], Except[Infinity], {1}, Heads -> False][[All, 1]]]]]


(* ::Subsection:: *)
(*EventsCount*)


SetSubstitutionEvolution[data_ ? evolutionDataQ]["EventsCount"] :=
	Max[0, DeleteCases[Join[data[$destroyerEvents], data[$creatorEvents]], Infinity]]


(* ::Subsection:: *)
(*SetAfterEvent*)


(* ::Subsubsection:: *)
(*Argument checks*)


SetSubstitutionEvolution::eventTooLarge = "Event `` requested out of `` total.";


SetSubstitutionEvolution[data_ ? evolutionDataQ]["SetAfterEvent", s_Integer] := 0 /;
	With[{eventsCount = SetSubstitutionEvolution[data]["EventsCount"]},
		!(- eventsCount - 1 <= s <= eventsCount) &&
		Message[SetSubstitutionEvolution::eventTooLarge, s, eventsCount]]


SetSubstitutionEvolution::eventNotInteger = "Event `` must be an integer.";


SetSubstitutionEvolution[data_ ? evolutionDataQ]["SetAfterEvent", s_] := 0 /;
	!IntegerQ[s] &&
	Message[SetSubstitutionEvolution::eventNotInteger, s]


(* ::Subsubsection:: *)
(*Positive steps*)


SetSubstitutionEvolution[data_ ? evolutionDataQ]["SetAfterEvent", s_Integer] /;
		0 <= s <= SetSubstitutionEvolution[data]["EventsCount"] :=
	data[$atomLists][[Intersection[
		Position[data[$creatorEvents], _ ? (# <= s &)][[All, 1]],
		Position[data[$destroyerEvents], _ ? (# > s &)][[All, 1]]]]]


(* ::Subsubsection:: *)
(*Negative steps*)


SetSubstitutionEvolution[data_ ? evolutionDataQ]["SetAfterEvent", s_Integer] /;
		- SetSubstitutionEvolution[data]["EventsCount"] - 1 <= s < 0 :=
	SetSubstitutionEvolution[data][
		"SetAfterEvent", s + 1 + SetSubstitutionEvolution[data]["EventsCount"]]


(* ::Subsection:: *)
(*Generation*)


(* ::Text:: *)
(*Note that depending on how evaluation was done (i.e., the order of substitutions), it is possible that some expressions of a requested generation were not yet produced, and thus expressions for the previous generation would be used instead. That, however, should never happen if the evolution object is produced with SetSubstitutionSystem.*)


(* ::Subsubsection:: *)
(*Argument checks*)


SetSubstitutionEvolution::generationTooLarge =
	"Generation `` requested out of `` total.";


SetSubstitutionEvolution[data_ ? evolutionDataQ]["Generation", g_Integer] := 0 /;
	With[{generationsCount = SetSubstitutionEvolution[data]["GenerationsCount"]},
		!(- generationsCount - 1 <= g <= generationsCount) &&
		Message[SetSubstitutionEvolution::generationTooLarge, g, generationsCount]]


SetSubstitutionEvolution::generationNotInteger = "Generation `` must be an integer.";


SetSubstitutionEvolution[data_ ? evolutionDataQ]["Generation", g_] := 0 /;
	!IntegerQ[g] &&
	Message[SetSubstitutionEvolution::generationNotInteger, g]


(* ::Subsubsection:: *)
(*Positive generations*)


SetSubstitutionEvolution[data_ ? evolutionDataQ]["Generation", g_Integer] /;
		0 <= g <= SetSubstitutionEvolution[data]["GenerationsCount"] := With[{
	futureEventsToInfinity = Dispatch @ Thread[Union[
			data[$creatorEvents][[
				Position[data[$generations], _ ? (# > g &)][[All, 1]]]],
			data[$destroyerEvents][[
				Position[data[$generations], _ ? (# >= g &)][[All, 1]]]]] ->
		Infinity]},
	data[$atomLists][[Intersection[
		Position[
			data[$creatorEvents] /. futureEventsToInfinity,
			Except[Infinity],
			1,
			Heads -> False][[All, 1]],
		Position[
			data[$destroyerEvents] /. futureEventsToInfinity, Infinity][[All, 1]]]]]]


(* ::Subsubsection:: *)
(*Negative generations*)


SetSubstitutionEvolution[data_ ? evolutionDataQ]["Generation", g_Integer] /;
		- SetSubstitutionEvolution[data]["GenerationsCount"] - 1 <= g < 0 :=
	SetSubstitutionEvolution[data][
		"Generation", g + 1 + SetSubstitutionEvolution[data]["GenerationsCount"]]


(* ::Subsubsection:: *)
(*Omit "Generation"*)


SetSubstitutionEvolution[data_ ? evolutionDataQ][g_Integer] :=
	SetSubstitutionEvolution[data]["Generation", g]


(* ::Subsection:: *)
(*AtomsCountFinal*)


SetSubstitutionEvolution[data_ ? evolutionDataQ]["AtomsCountFinal"] :=
	Length[Union @@ SetSubstitutionEvolution[data]["SetAfterEvent", -1]]


(* ::Subsection:: *)
(*AtomsCountTotal*)


SetSubstitutionEvolution[data_ ? evolutionDataQ]["AtomsCountTotal"] :=
	Length[Union @@ data[$atomLists]]


(* ::Subsection:: *)
(*ExpressionsCountFinal*)


SetSubstitutionEvolution[data_ ? evolutionDataQ]["ExpressionsCountFinal"] :=
	Length[SetSubstitutionEvolution[data]["SetAfterEvent", -1]]


(* ::Subsection:: *)
(*ExpressionsCountTotal*)


SetSubstitutionEvolution[data_ ? evolutionDataQ]["ExpressionsCountTotal"] :=
	Length[data[$atomLists]]


(* ::Subsection:: *)
(*CausalGraph*)


(* ::Text:: *)
(*This produces a causal network for the system. This is a Graph with all events as vertices, and directed edges connecting them if the same event is a creator and a destroyer for the same expression (i.e., if two events are causally related).*)


(* ::Subsubsection:: *)
(*Argument checks*)


(* ::Text:: *)
(*We need to check: (1) arguments given are actually options, (2) they are valid options for the Graph object.*)


SetSubstitutionEvolution::nonopt =
	"Options expected (instead of `1`) " <>
	"beyond position 1 for \"CausalGraph\" property. " <>
	"An option must be a rule or a list of rules.";


SetSubstitutionEvolution[data_ ? evolutionDataQ]["CausalGraph", o___] := 0 /;
	!MatchQ[{o}, OptionsPattern[]] &&
	Message[SetSubstitutionEvolution::nonopt, Last[{o}]]


SetSubstitutionEvolution::optx =
	"Unknown option `1` for \"CausalGraph\" property. " <>
	"Only Graph options are accepted.";


SetSubstitutionEvolution[data_ ? evolutionDataQ][
		"CausalGraph", o : OptionsPattern[]] := 0 /;
	With[{incorrectOptions = Complement[{o}, FilterRules[{o}, Options[Graph]]]},
		incorrectOptions != {} &&
		Message[SetSubstitutionEvolution::optx, Last[incorrectOptions]]]


(* ::Subsubsection:: *)
(*Implementation*)


SetSubstitutionEvolution[data_ ? evolutionDataQ][
		"CausalGraph", o : OptionsPattern[]] /;
			(Complement[{o}, FilterRules[{o}, Options[Graph]]] == {}) :=
	Graph[
		DeleteCases[Union[data[$creatorEvents], data[$destroyerEvents]], 0 | Infinity],
		Select[FreeQ[#, 0 | Infinity] &] @
			Thread[data[$creatorEvents] \[DirectedEdge] data[$destroyerEvents]],
		o]


(* ::Section:: *)
(*Argument Checks*)


(* ::Text:: *)
(*Argument Checks should be evaluated after Implementation, otherwise ::corrupt messages will be created while assigning SubValues.*)


(* ::Subsection:: *)
(*Argument count*)


SetSubstitutionEvolution[args___] := 0 /;
	!Developer`CheckArgumentCount[SetSubstitutionEvolution[args], 1, 1] && False


(* ::Subsection:: *)
(*Association has correct fields*)


SetSubstitutionEvolution::corrupt =
	"SetSubstitutionEvolution does not have a correct format. " ~~
	"Use SetSubstitutionSystem for construction.";


evolutionDataQ[data_Association] := Sort[Keys[data]] ===
	Sort[{$creatorEvents, $destroyerEvents, $generations, $atomLists, $rules}]


evolutionDataQ[___] := False


SetSubstitutionEvolution[data_] := 0 /;
	!evolutionDataQ[data] &&
	Message[SetSubstitutionEvolution::corrupt]