import SciLean.Analysis.Diffeology.Basic
import SciLean.Analysis.Diffeology.NormedSpace
import SciLean.Data.ArrayN

namespace SciLean


namespace Diffeology.Array.Util
def StableSize (f : α → Array β) (n : ℕ) := ∀ a, n = (f a).size

def fixSize (f : α → Array β) (n) (hn : StableSize f n) : α → ArrayN β n :=
  fun a => ArrayN.mk (f a) (hn a)

def _root_.Array.fixSize (a : Array α) (n) (hn : n = a.size) : ArrayN α n :=
  ArrayN.mk a hn

@[simp]
theorem _root_.Array.fixSize_eta (a : ArrayN α n) :
  a.1.fixSize n a.2 = a := by rfl

@[simp]
theorem fixSize_arrayN_data (f : α → ArrayN β n) :
    fixSize (fun x => (f x).1) n (fun a => (f a).2) = f := by
  unfold fixSize
  simp

theorem differentiable_fixSize
    {X} [NormedAddCommGroup X] [NormedSpace ℝ X]
    {Y} [NormedAddCommGroup Y] [NormedSpace ℝ Y]
    (f : X → Array Y) (n m) (hn : StableSize f n) (hm : StableSize f m)
    (hf : Differentiable ℝ (fixSize f n hn)) : Differentiable ℝ (fixSize f m hm) := by
  have h : m = n := by simp[hn 0, (hm 0).symm]
  subst h
  apply hf

theorem differentiable_fixSize'
    {X} [NormedAddCommGroup X] [NormedSpace ℝ X]
    {Y} [NormedAddCommGroup Y] [NormedSpace ℝ Y]
    (f : X → Array Y) (n m) (hn : StableSize f n) (hm : StableSize f m)
    (hf : Differentiable ℝ (fun x => (f x).fixSize n (hn x))) : Differentiable ℝ (fun x => (f x).fixSize m (hm x)) := by
  have h : m = n := by simp[hn 0, (hm 0).symm]
  subst h
  apply hf


theorem fderiv_fixSize_cast
    {X} [NormedAddCommGroup X] [NormedSpace ℝ X]
    {Y} [NormedAddCommGroup Y] [NormedSpace ℝ Y]
    (f : X → Array Y) (x dx) (n) (hn : StableSize f n) (m) (h : m = n) :
    fderiv ℝ (fixSize f n hn) x dx = cast (by simp_all) (fderiv ℝ (fixSize f m (fun i => h ▸ hn i)) x dx) := by
  subst h
  simp

end Diffeology.Array.Util
open Diffeology.Array.Util

variable
  {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X]

instance : Diffeology (Array X) where
  -- plots n f := ∃ (h : StableSize f (f 0).size),
  --   Differentiable ℝ (fun x => fixSize f (f 0).size h x)
  plots n f := ∃ (h : StableSize f (f 0).size),
    Differentiable ℝ (fun x => (f x).fixSize (f 0).size (h x))
  smooth_comp := by
    intros n m p f hp hf; simp_all[Membership.mem,Set.Mem];
    cases' hp with n' hp
    -- cases' hp with hn hp
    constructor
    have h := (Differentiable.comp hp hf)
    simp at h
    apply differentiable_fixSize' _ _ _ _ _ h
    intro x; simp[(n' (f x)).symm, n' (f 0)]
  const_plot := by
    intros n x; simp_all[Membership.mem,Set.Mem,StableSize]
    have h : Differentiable ℝ (fun _ : Fin n → ℝ => ArrayN.mk (n:=x.size) x (by simp)) := by fun_prop
    convert h


open Classical in
noncomputable
instance : TangentSpace (Array X) (fun x => ArrayN X x.size) where
  tangent c _ u du :=
    if h : StableSize c (c 0).size then
      cast (by rw[h u]) (fderiv ℝ (fun x => fixSize c _ h x) u du)
    else
      0

  smooth_comp := by
    intros n m p f hp hf u du
    have a := Classical.choose hp
    have b := Classical.choose (Diffeology.smooth_comp hp hf)
    simp_all
    conv =>
      lhs
      enter [2,1]
      conv =>
        enter [2]
        equals ((fixSize p _ (by intro x; simp[(a x).symm, a (f 0)])) ∘ f) => funext x; unfold fixSize; simp
      rw[fderiv.comp (hf:=by fun_prop)
          (hg:=by apply differentiable_fixSize' (hf := Classical.choose_spec hp))]
    simp[Function.comp_def]

    let n := (p (f 0)).size; let m := (p 0).size
    rw [fderiv_fixSize_cast (n:=n) (m:=m)]
    simp; simp[a (f 0),m]

  tangent_const := by
    intros x dx t dt
    simp; dsimp; intro h
    have h : (fderiv ℝ (fun _ => ArrayN.mk (n:=dx.size) dx rfl) t) dt = 0 := by fun_trans
    exact h

  curve x dx t := (ArrayN.mk x rfl + t 0 • dx).1
  curve_at_zero := by simp
  curve_is_plot := by
    intro x dx
    simp[Diffeology.plots,Membership.mem,Set.Mem]
    apply Exists.intro (by intro x; simp)
    apply differentiable_fixSize' (n:=x.size) (hn:=by intro x; simp)
    simp; fun_prop
  tangent_curve_at_zero := by
    intros x dx dt; simp;
    have : StableSize (fun t : Fin 1 → ℝ => (ArrayN.mk x (by rfl) + t 0 • dx).data) x.size := by intro x; simp
    simp_all
    let m := x.size
    rw [fderiv_fixSize_cast (n:=_) (m:=m)]
    simp; fun_trans; simp
  tangent_linear := by
    intro n f ⟨hf,hf'⟩ t
    constructor <;> (simp[hf]; simp[hf t])

#check Sigma.mk

set_option pp.proofs.withType true in
set_option pp.proofs true in
open Classical in
noncomputable
instance : TangentBundle (Array X) (Σ a : Array X, ArrayN X a.size) where
  tangentMap c _ u du :=
    if h : StableSize c (c 0).size then
      ⟨c u, cast (by rw[h u]) (fderiv ℝ (fun x => fixSize c _ h x) u du)⟩
    else
      ⟨c u, 0⟩
  smul := fun s ⟨x,dx⟩ => ⟨x, s • dx⟩
  one_smul := by
    intro ⟨x,dx⟩
    calc
      _ = ⟨x, (1:ℝ)•dx⟩ := by rfl
      _ = _ := by simp
  mul_smul := by
    intro s r ⟨x,dx⟩
    calc
      _ = ⟨x, (s*r)•dx⟩ := by rfl
      _ = ⟨x, s•r•dx⟩ := by simp[mul_smul]
      _ = _ := by rfl
  proj := Sigma.fst
  tip a := ⟨a,0⟩
  proj_smul := by sorry
  smul_zero := sorry
  proj_tip := by simp
  tangentMap_proj := by
    intros n c; intros
    by_cases (StableSize c (c 0).size) <;> simp_all
  tangentMap_comp := by
    intros n m c hc f hf x dx
    have h : StableSize (c ∘ f) (c (f 0)).size := sorry
    simp [hc.1,h]
    have := hc.1
    sorry
  smul_tangentMap := by sorry
  exp := fun ⟨x,dx⟩ t => ⟨x, t 0•dx⟩
  exp_plot c := by
    constructor
    · unfold Array.fixSize;
      apply differentiable_fixSize (n:=c.1.size) (hn:=fun _ => rfl) (hm := fun _ => rfl)
        (hf:=by unfold fixSize; simp)

  exp_at_zero := sorry

  tangentMap_const := sorry
  tangentMap_exp := by
    intro ⟨x,dx⟩
    simp [StableSize]
    funext du
    let m := x.size
    rw[fderiv_fixSize_cast (m:=m) (h:=rfl)]
    unfold fixSize StableSize FiberBundle.proj; simp
    sorry


-- def arrayPlot {n} {p : (Fin n → ℝ) → Array X} (hp : p ∈ Diffeology.plots

variable {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X]


theorem Array.get.arg_a.MDifferentiable_rule (i : ℕ) (x₀ : X) :
    MDifferentiable (fun x : Array X => x.getD i x₀) where
  plot_preserving := by
    intro n p hp
    simp[Function.comp_def]
    let m : ℕ := (p 0).size
    let p' := fixSize p (p 0).size hp.1
    if hi : i < m then
      let i' : Fin m := ⟨i, hi⟩
      have h : (fun x => (p x)[i]?.getD x₀) = (fun x => (p' x)[i']) := sorry
      rw[h]
      have : Differentiable ℝ (fun x => p' x) := fun x => hp.2 x
      intro x; fun_prop
    else
      have h : (fun x => (p x)[i]?.getD x₀) = (fun x => x₀) := by sorry
      rw[h]
      intro x; fun_prop

  plot_independence := sorry


theorem Array.get.arg_a.mderiv_rule (i : ℕ) (x₀ : X) :
    mderiv (fun x : Array X => x.getD i x₀)
    =
    fun x dx =>
      if hi : i < x.size then
        ArrayType.get dx ⟨i,hi⟩
      else
        0 := sorry
