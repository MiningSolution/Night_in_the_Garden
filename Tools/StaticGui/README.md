# Static GUI generator

`StarterGui/*.model.json` are generated from `builders/*.luau` (the original
Create*UI scripts). `GuiRecorder.luau` runs a builder with a recorder in place of
`Instance.new` and keeps every property it sets.

    python3 Tools/StaticGui/build_models.py /path/to/luau

- needs the `luau` CLI (https://github.com/luau-lang/luau/releases)
- top-level `X:Connect(function ... end)` blocks in builders are skipped; runtime
  behaviour belongs in the controllers (`Utils/GuiEffects.lua`)
- the same GuiRecorder can run in Studio with the real `Instance.new` to build the
  GUI into StarterGui and print a fingerprint to compare with the generator output
- check the result with `rojo build default.project.json -o test.rbxlx`
