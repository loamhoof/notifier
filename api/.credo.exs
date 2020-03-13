%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "src/", "web/", "apps/"],
        excluded: ["lib/api/validation.ex"]
      },
      checks: [
        # Config checks

        {Credo.Check.Readability.ParenthesesOnZeroArityDefs, parens: true},

        # Optional checks

        {Credo.Check.Consistency.MultiAliasImportRequireUse, false},
        {Credo.Check.Consistency.UnusedVariableNames, []},
        {Credo.Check.Design.DuplicatedCode, []},
        {Credo.Check.Readability.AliasAs, []},
        {Credo.Check.Readability.MultiAlias, false},
        {Credo.Check.Readability.Specs, []},
        {Credo.Check.Readability.SinglePipe, false},
        {Credo.Check.Readability.WithCustomTaggedTuple, false},
        {Credo.Check.Refactor.ABCSize, []},
        {Credo.Check.Refactor.AppendSingleItem, []},
        {Credo.Check.Refactor.DoubleBooleanNegation, []},
        {Credo.Check.Refactor.ModuleDependencies, false},
        {Credo.Check.Refactor.NegatedIsNil, false},
        {Credo.Check.Refactor.PipeChainStart, []},
        {Credo.Check.Refactor.VariableRebinding, []},
        {Credo.Check.Warning.MapGetUnsafePass, []},
        {Credo.Check.Warning.UnsafeToAtom, []},

        # Deactivate checks

        {Credo.Check.Readability.ModuleDoc, false},
      ]
    }
  ]
}
