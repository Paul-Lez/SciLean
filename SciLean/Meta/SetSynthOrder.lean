import Lean.Elab.Command
import Lean.Elab.MatchExpr
import Lean.Meta.Instances

/-!
# Specify the synthesization order for instances
-/

namespace Lean.Meta

/-- Specify the synthesization order for instances. -/
def Instances.setSynthOrder (declName : Name) (synthOrder : Array Nat) : CoreM Unit := do
  let some entry := Meta.instanceExtension.getState (← getEnv) |>.instanceNames.find? declName |
    throwError "'{declName}' does not have [instance] attribute"
  instanceExtension.add { entry with synthOrder } entry.attrKind

end Lean.Meta

namespace Lean.Elab.Command

open Meta

/-- Specify the synthesization order for instances. -/
elab "set_synth_order " name:ident synthOrder:term : command => do
  let q := Term.MatchExpr.toDoubleQuotedName name
  elabCommand (← `(command| run_meta Instances.setSynthOrder $q $synthOrder))

end Lean.Elab.Command
