import SciLean.Categories

import Init.Classical

namespace SciLean

variable {α β γ}

noncomputable
def inverse [Inhabited α] (f : α → β) (b : β)  : α :=
    match Classical.propDecidable (IsInv f) with
      | isTrue h => Classical.choose ((@IsInv.is_inv _ _ f h).2 b)
      | _ => arbitrary

postfix:max "⁻¹" => inverse

namespace Inverse

  variable {β1 β1}
  variable [Inhabited α] [Inhabited β] [Inhabited γ] [Inhabited β1] [Inhabited β2]


  @[simp]
  def inverse_of_inverse (f : α → β) [IsInv f] 
      : (f⁻¹)⁻¹ = f := sorry
  
  @[simp]
  def inverse_of_id 
      : (id : α → α)⁻¹ = id := sorry

  @[simp]
  def inverse_of_id' 
      : (λ a : α => a)⁻¹ = id := sorry

  @[simp]
  def inverse_of_comp (f : β → γ) (g : α → β) [IsInv f] [IsInv g]
      : (f ∘ g)⁻¹ = g⁻¹ ∘ f⁻¹ := sorry

  @[simp]
  def inverse_of_comp_arg1 (f : β1 → β2 → γ) (g1 : α → β1) (b2 : β2) [IsInv (λ b1 => f b1 b2)] [IsInv g1]
      : (λ a => f (g1 a) b2)⁻¹ = g1⁻¹ ∘ (λ b1 => f b1 b2)⁻¹ := sorry

  -------------------------------------------------------------------------

  instance {X} [Vec X] (y : X) : IsInv (λ x => x + y) := sorry

  @[simp]
  def inverse_of_add_arg1 {X} [Vec X] (y : X)
      : (λ x => x + y)⁻¹ = (λ x => x - y) := sorry

  instance {X} [Vec X] (x : X) : IsInv (λ y => x + y) := sorry

  @[simp]
  def inverse_of_add_arg2 {X} [Vec X] (x : X)
      : (λ y => x + y)⁻¹ = (λ y => -x + y) := sorry


  instance {X} [Vec X] (y : X) : IsInv (λ x => x - y) := sorry

  @[simp]
  def inverse_of_sub_arg1 {X} [Vec X] (y : X)
      : (λ x => x - y)⁻¹ = (λ x => x + y) := sorry

  instance {X} [Vec X] (x : X) : IsInv (λ y => x - y) := sorry

  @[simp]
  def inverse_of_sub_arg2 {X} [Vec X] (x : X)
      : (λ y => x - y)⁻¹ = (λ y => x - y) := sorry

  instance (s : ℝ) [NonZero s] : IsInv (λ (r : ℝ)  => r*s) := sorry

  @[simp]
  def inverse_of_mul_arg1 (s : ℝ) [NonZero s]
      : (λ (r : ℝ) => r*s)⁻¹ = (λ r => r/s) := sorry

  instance {X} [Vec X] (r : ℝ) [NonZero r] : IsInv (λ (x : X)  => r*x) := sorry

  @[simp]
  def inverse_of_mul_arg2 {X} [Vec X] (r : ℝ) [NonZero r]
      : (λ (x : X) => r*x)⁻¹ = (λ (x : X) => (1/r)*x) := sorry
  
  instance {X} [Vec X] : IsInv (λ (x : X) => -x) := sorry

  @[simp]
  def inverse_of_neg {X} [Vec X]
      : (λ (x : X) => -x)⁻¹ = (λ (x : X) => -x) := sorry

  example {X Y : Type} [Vec X] [Vec Y] (f : X → Y) [IsInv f] (y' : Y) 
          : (λ x => - (f x) + y')⁻¹ = (λ y => f⁻¹ (-(y - y'))) := by simp

end Inverse
