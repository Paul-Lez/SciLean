import SciLean.Analysis.Diffeology.PlotHomotopy
import SciLean.Analysis.Diffeology.Prod
import SciLean.Analysis.Diffeology.NormedSpace


namespace SciLean

local notation:max "ℝ^" n:max => (Fin n) → ℝ

open Diffeology in
class Connection {X : Type*} (E : X → Type*) [Diffeology X] [∀ x, Diffeology (E x)] where
  /-- Lifts curve `c` on the base space `X` to the fibers `E (c x)` given a single fiber value `v`.

  Also known as parrallel transport of `v` along `c`. -/
  lift (c : ℝ^1 → X) (s t) (v : E (c s)) : E (c t)

  lift_inv (c : ℝ^1 → X) (hc : c ∈ plots 1) (s) (v : E (c s)) (t) :
    lift c t s (lift c s t v) = v

  lift_trans (c : ℝ^1 → X) (hc : c ∈ plots 1) (s r t) (v : E (c s)) :
    lift c r t (lift c s r v) = lift c s t v

  smooth_comp {n m}
    {p : ℝ^n → Sigma E} {x}
    {ht : PlotPointHomotopy (fun u => (p u).1) x}
    {hp₂ : ht.transportSection' lift (fun u => (p u).2) ∈ plots n}
    (f : ℝ^m → ℝ^n) (hf : ContDiff ℝ ⊤ f)
    (ht' : PlotPointHomotopy (fun u => (p (f u)).1) x) :
    ht'.transportSection' lift (fun u => (p (f u)).2) ∈ plots m

  const_lift {n} {x y : X}
    {path : PlotHomotopy (fun _ : ℝ^n => x) (fun _ : ℝ^n => y)}
    (p : ℝ^n → E x) (hp : p ∈ plots n) :
    PlotPointHomotopy.transportSection' path lift p ∈ plots n


def PlotPointHomotopy.transportSection
    {X : Type*} {E : X → Type*} [Diffeology X] [∀ x, Diffeology (E x)] [Connection E]
    {p : (Fin n → ℝ) → X} {x : X}
    (ht : PlotPointHomotopy p x)
    (v : (u : (Fin n → ℝ)) → E (p u)) : (Fin n → ℝ) → E x :=
  ht.transportSection' Connection.lift v


open Diffeology Util in
instance {X : Type*} (E : X → Type*) [Diffeology X] [∀ x, Diffeology (E x)] [Connection E] :
    Diffeology (Sigma E) where

  plots n c :=
    (fun u => (c u).1) ∈ plots n
    ∧
    ∀ (x : X) (ht : PlotPointHomotopy (fun u => (c u).1) x),
      ht.transportSection (fun x => (c x).2) ∈ plots n

  plot_comp := by
    intro n m p f hp hf
    have hp₁ := hp.1
    have hp₂ := hp.2
    constructor
    · apply plot_comp hp₁ hf
    · intro x ht
      unfold PlotPointHomotopy.transportSection
      apply Connection.smooth_comp (f:=f) (hf:=hf)
            (ht:=(ht.toPathAt 0).compPathLeft (PlotHomotopy.toPoint _ hp₁ (f 0)))
      · apply hp₂

  const_plot := by
    intros n xdx
    constructor
    · apply Diffeology.const_plot
    · intros x₀ ht
      simp at ht
      unfold PlotPointHomotopy.transportSection
      apply Connection.const_lift
      apply const_plot


variable
  {X : Type*} [Diffeology X]
  {E : X → Type*} [∀ x, Diffeology (E x)] [Connection E]

def DDSmooth (f : (x : X) → E x) : Prop :=
  DSmooth (fun x => Sigma.mk x (f x))

class DVec (X : Type*) extends AddCommGroup X, Module ℝ X, Diffeology X, TangentSpace X (fun _ => X) where
  add_smooth : TSSmooth (fun x : X×X => x.1+x.2)
  smul_smooth : TSSmooth (fun x : ℝ×X => x.1•x.2)


instance [AddCommGroup X] [Module ℝ X] : Diffeology X := sorry
instance [AddCommGroup X] [Module ℝ X] : TangentSpace X (fun _ => X) := sorry

instance [AddCommGroup X] [Module ℝ X] : Connection (fun _ : α => X) := sorry

open TangentSpace in
instance {X : Type*} [Diffeology X] (TX : X → Type*) [∀ x, AddCommGroup (TX x)] [∀ x, Module ℝ (TX x)]
    [TangentSpace X TX] [∀ x, Diffeology (TX x)] [Connection TX] :
    TangentSpace (Sigma TX) (fun x => TX x.1 × TX x.1) := sorry


instance   {X : Type*} [Diffeology X] {TX : X → Type*} [∀ x, AddCommGroup (TX x)] [∀ x, Module ℝ (TX x)] [TangentSpace X TX]
  {E : X → Type*} [∀ x, Diffeology (E x)]
  {TE : (x : X) → E x → Type*} [∀ x e, AddCommGroup (TE x e)] [∀ x e, Module ℝ (TE x e)] [∀ x, TangentSpace (E x) (TE x)] [Connection E] :
  TangentSpace (Sigma E) (fun x => TX x.1 × TE x.1 x.2) := sorry


-- def covDeriv
--   {X : Type*} [Diffeology X] {TX : X → Type*} [∀ x, AddCommGroup (TX x)] [∀ x, Module ℝ (TX x)] [TangentSpace X TX] [TangentSpace X TX]
--   {E : X → Type*} [∀ x, Diffeology (E x)]
--   {TE : (x : X) → E x → Type*} [∀ x e, AddCommGroup (TE x e)] [∀ x e, Module ℝ (TE x e)] [∀ x, TangentSpace (E x) (TE x)] [Connection E]
--   (f : (x : X) → E x) (x : X) (dx : TX x) : TE _ (f x)  :=
--   let c := TangentSpace.exp x dx
--   let c' := fun x => f (c x)
--   let c' := fun t => Sigma.mk (c t) (f (c t))
--   let v'' := TangentSpace.tangentMap c' sorry 0 1
--   cast (by simp[c',c]; rw[TangentSpace.exp_at_zero]) v''.2


open Classical in
noncomputable
def covDeriv
  {X : Type*} [Diffeology X] {TX : X → Type*}
  [∀ x, AddCommGroup (TX x)] [∀ x, Module ℝ (TX x)] [TangentSpace X TX]
  {Y : Type*} [Diffeology Y] {TY : Y → Type*}
  [∀ y, AddCommGroup (TY y)] [∀ y, Module ℝ (TY y)] [TangentSpace Y TY]
  {E : Y → Type*} [∀ x, Diffeology (E x)] {TE : (y : Y) → E y → Type*}
  [∀ y e, AddCommGroup (TE y e)] [∀ y e, Module ℝ (TE y e)] [∀ y, TangentSpace (E y) (TE y)] [Connection E]
  {g : X → Y} (f : (x : X) → E (g x)) (x : X) (dx : TX x) : TE _ (f x)  :=
  let c := TangentSpace.exp x dx
  let c' := fun t => Sigma.mk (g (c t)) (f (c t))
  if hc : c' ∈ Diffeology.plots 1 then
    let v'' := TangentSpace.tangentMap c' hc 0 1
    cast (by simp[c',c]; rw[TangentSpace.exp_at_zero]) v''.2
  else
    0


example {X} [AddCommGroup X] [Module ℝ X] [Diffeology X] [TangentSpace X (fun _ => X)] :
  TangentSpace (X×X) (fun _ => X × X) := by infer_instance

open TangentSpace


variable (n : ℕ)

#synth TangentSpace (Fin n → ℝ) (fun x => Fin n → ℝ)

-- instance {W : Type*} [Diffeology W] {X : Type*} [Diffeology X] (f : W → X) [Fact (DSmooth f)] (E : X → Type*) [∀ x, Diffeology (E x)]
--   [Connection E] : Connection (fun w => E (f w)) := sorry

noncomputable
instance {X : Type*} [Diffeology X] (TX : X → Type*) [∀ x, DVec (TX x)]
    [TangentSpace X TX] [∀ x, Diffeology (TX x)] [Connection TX] :
    TangentSpace (Sigma TX) (fun x => TX x.1 × TX x.1) where

  tangentMap {n} p hp u du :=
    let dy := tangentMap (fun u => (p u).1) hp.1 u du
    let dz := covDeriv (fun u => (p u).2) u du
    (dy,dz)
  tangentMap_comp := sorry
  tangentMap_const := sorry
  tangentMap_linear := sorry
  exp := sorry
  exp_at_zero := sorry
  exp_is_plot := sorry
  tangentMap_exp_at_zero := sorry
